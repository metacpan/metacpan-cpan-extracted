package App::ArduinoBuilder;

use 5.022;
use strict;
use warnings;
use utf8;

use App::ArduinoBuilder::Builder 'build_archive', 'build_object_files', 'link_executable', 'run_hook';
use App::ArduinoBuilder::Config 'get_os_name';
use App::ArduinoBuilder::FilePath 'find_latest_revision_dir', 'list_sub_directories', 'find_all_files_with_extensions';
use App::ArduinoBuilder::Logger;
use App::ArduinoBuilder::System 'find_arduino_dir', 'system_cwd';

use File::Basename;
use File::Spec::Functions;
use Getopt::Long;
use List::Util 'any', 'none', 'first';
use Pod::Usage;

our $VERSION = '0.04';

sub Run {
  my $project_dir;
  my $build_dir;

  my (@skip, @force, @only);
  GetOptions(
      'help|h' => sub { pod2usage(-exitval => 0, -verbose => 2)},
      'project-dir|project|p=s' => \$project_dir,
      'build-dir|build|b=s' => \$build_dir,
      'log-level|l=s' => sub { App::ArduinoBuilder::Logger::set_log_level($_[1]) },
      'skip=s@' => sub { push @skip, split /,/, $_[1] },  # skip this step
      'force=s@' => sub { push @force, split /,/, $_[1] },  # even if it would be skipped by the dependency checker
      'only=s@' => sub { push @only, split /,/, $_[1] },  # run only these steps (skip all others)
      'stack-trace-on-error|stack' => sub { App::ArduinoBuilder::Logger::print_stack_on_fatal_error(1) },
    ) or pod2usage(-exitval => 2, -verbose =>0);

  my $project_dir_is_cwd = 0;
  if (!$project_dir) {
    $project_dir_is_cwd = 1;
    $project_dir = system_cwd();
  }

  my $config = App::ArduinoBuilder::Config->new(
      files => [catfile($project_dir, 'arduino_builder.local'),
                catfile($project_dir, 'arduino_builder.config')],
      allow_missing => 1,
      allow_partial => 1,
      resolve => 1);

  $config->set('builder.project_dir' => $project_dir);

  if (!$build_dir) {
    if ($config->exists('builder.default_build_dir')) {
      $build_dir = $config->get('builder.default_build_dir');
    } elsif (!$project_dir_is_cwd) {
      $build_dir = system_cwd();
    } else {
      fatal 'No builder.default_build_dir config and --build_dir was not passed when building from the project directory.';
    }
  }

  if (!$config->exists('builder.package.path')) {
    fatal 'At least one of builder.package.path or builder.package.name must be specified in the config' unless $config->exists('builder.package.name');
    # TODO: the core package can also be installed in a "hardware" directory in
    # the sketch directory. We should search for it there.
    my $arduino_dir = find_arduino_dir();
    fatal "The builder.package.path config is not set and Arduino installation directory not found" unless $arduino_dir;
    debug "Using arduino directory: ${arduino_dir}";
    my $package_name = $config->get('builder.package.name');
    my @tests = (catdir($arduino_dir, 'packages', $package_name), catdir($arduino_dir, 'hardware', $package_name));
    my @dirs = grep { -d } @tests;
    fatal "Cannot find the package directory for '${package_name}' inside Arduino directory: ${arduino_dir}" unless @dirs;
    debug "Using package directory: ${dirs[0]}";
    $config->set('builder.package.path' => $dirs[0]);
  } else {
    if ($config->exists('builder.package.name')) {
      warning 'Both builder.package.path and builder.package.name were specified in the config. Only the former will be used.';
    } else {
      $config->set('builder.package.name' => basename($config->get('builder.package.path')));
    }
  }

  my $package_path = $config->get('builder.package.path');
  fatal "Package path does not exist: ${package_path}" unless -d $package_path;
  my $hardware_dir = catdir($package_path, 'hardware');
  $hardware_dir = $package_path unless -d $hardware_dir;
  if (!$config->exists('builder.package.arch')) {
    my @arch_dirs = list_sub_directories($hardware_dir);
    if (@arch_dirs == 1) {
      debug "Using arch '${arch_dirs[0]}'";
      $config->set('builder.package.arch' => $arch_dirs[0]);
    } else {
      fatal 'The builder.package.arch config is not set and more than one arch is present in the package: '.$hardware_dir;
    }
  }
  my $hardware_path = find_latest_revision_dir(catdir($hardware_dir, $config->get('builder.package.arch')));

  debug "Project config: \n%s", sub { $config->dump('  ') };

  my $boards_local_config_path = catfile($hardware_path, 'boards.local.txt');
  if (-f $boards_local_config_path) {
    my $board_name = $config->get('builder.package.board');
    my $board = App::ArduinoBuilder::Config->new(file => $boards_local_config_path, resolve => 1, allow_partial => 1)->filter($board_name);
    $config->merge($board);
  }

  my $boards_config_path = catfile($hardware_path, 'boards.txt');
  if (-f $boards_config_path) {
    my $board_name = $config->get('builder.package.board');
    my $board = App::ArduinoBuilder::Config->new(file => $boards_config_path, resolve => 1, allow_partial => 1)->filter($board_name);
    fatal "Board '${board_name}' not found in boards.txt." if $board->empty();
    $config->merge($board);
  } else {
    warning "Could not find boards.txt file.";
  }

  my $menu_config = $config->filter('builder.menu');
  my $board_menu = $config->filter('menu');
  for my $m ($menu_config->keys()) {
    my $v = $menu_config->get($m);
    $config->merge($board_menu->filter("${m}.${v}"));
  }

  # TODO: Handles core, variant and tools references:
  # https://arduino.github.io/arduino-cli/0.32/platform-specification/#core-reference

  my @package_config_files = grep { -f } map { catfile($hardware_path, $_) } qw(platform.local.txt platform.txt programmers.local.txt programmers.txt);
  map { $config->read_file($_) } @package_config_files;

  # https://arduino.github.io/arduino-cli/0.32/platform-specification/#global-predefined-properties
  $config->set('runtime.platform.path' => $hardware_path);
  # Unclear what the runtime.hardware.path variable is supposed to point to.
  $config->set('runtime.os' => get_os_name());
  $config->set('runtime.ide.version' => '2040');  # The version that we are emulating currently (2.4.0).
  $config->set('ide_version' => '2040');
  $config->set('software' => 'ARDUINO');
  # todo: name, _id, build.fqbn, and the time options
  # Note: build.source.path is the root of the source. So, if we build from an
  # src sub-directory (for example), it should be that directory and not the
  # root of the project directory.
  $config->set('build.source.path' => $project_dir);
  $config->set('sketch_path' => $project_dir);
  $config->set('build.path' => $build_dir);
  $config->set('build.project_name' => $config->get('builder.project_name'));
  $config->set('build.arch' => $config->get('builder.package.arch'));
  $config->set('build.core.path', catdir($hardware_path, 'cores', $config->get('build.core')));
  $config->set('build.system.path', catdir($hardware_path, 'system'));
  $config->set('build.variant.path', catdir($hardware_path, 'variants', $config->get('build.variant')));

  my @tools_dirs = (catdir($package_path, 'tools'));
  for my $tools_dir (@tools_dirs) {
    next unless -d $tools_dir;
    my @tools = list_sub_directories($tools_dir);
    for my $t (@tools) {
      debug "Found tool: $t";
      my $tool_path = catdir($tools_dir, $t);
      my $latest_tool_path = find_latest_revision_dir($tool_path);
      $config->set("runtime.tools.${t}.path", $latest_tool_path);
      for my $v (list_sub_directories($tools_dir)) {
        $config->set("runtime.tools.${t}-${v}.path", catdir($tool_path, $v));
      }
    }
  }

  # TODO: we should create config for all the tools defined by all the other
  # platform (not overriding the existing definitions). There are some other
  # considerations that we are not handling yet from:
  # https://arduino.github.io/arduino-cli/0.32/package_index_json-specification/#how-a-tools-path-is-determined-in-platformtxt

  # TODO: we should probably never call resolve because variables can change
  # but the config could have a cache of resolved values with invalidation on
  # the right variable change. BUT we still need to do the os_name suffix
  # resolution.
  $config->resolve(allow_partial => 1);

  my $run_step = sub {
    my ($step) = @_;
    return (none { $_ eq $step } @skip) && (!@only || any { $_ eq $step } @only);
  };
  my $force = sub {
    my ($step) = @_;
    return any { $_ eq $step } @force;
  };


  my $builder = App::ArduinoBuilder::Builder->new($config);
  my $built_something = 0;

  $builder->run_hook('prebuild');

  $config->append('includes', '"-I'.$config->get('build.core.path').'"');
  $config->append('includes', '"-I'.$config->get('build.variant.path').'"');

  # This should be set to 1 first, if we start with doing library discovery at
  # some point.
  $config->set('build.library_discovery_phase' => 0);

  if ($run_step->('core')) {
    info 'Building core...';
    $builder->run_hook('core.prebuild');
    my $built_core = $builder->build_archive([$config->get('build.core.path'), $config->get('build.variant.path')], catdir($build_dir, 'core'), 'core.a', $force->('core'));
    info ($built_core ? '  Success' : '  Already up-to-date');
    $built_something |= $built_core;
    $builder->run_hook('core.postbuild');
  }

  # Reference for all this library part:
  # https://arduino.github.io/arduino-cli/0.32/library-specification/
  # For now, we are not doing library discovery automatically. See also this:
  # https://arduino.github.io/arduino-cli/0.32/sketch-build-process/#dependency-resolution
  my $lib_config = $config->filter('builder.library');
  my @all_libs = $lib_config->keys();  # We will add config in lib_config, so let’s get the set of keys now.
  # We are first adding all the includes path for all the library before building any of them.
  for my $l ($lib_config->keys()) {
    my $lib_dir = $lib_config->get($l);
    fatal "Library directory does not exist for library '${l}': ${lib_dir}" unless -d $lib_dir;
    my $lib_properties_file = catfile($lib_dir, 'library.properties');
    my $has_lib_properties = -f $lib_properties_file;
    my $recursive_lib = $has_lib_properties && -d catdir($lib_dir, 'src');
    # These config entry (and any other added to $lib_config) are undocummented and should never be
    # set by the user.
    $lib_config->set($l.'.is_flat' => !$recursive_lib);
    if ($recursive_lib) {
      $config->append('includes', '"-I'.catdir($lib_dir, 'src').'"');
    } else {
      $config->append('includes', "\"-I${lib_dir}\"");
    }
    if ($has_lib_properties) {
      my $lib_properties = App::ArduinoBuilder::Config->new(file => $lib_properties_file);
      $lib_config->set($l.'.name' => $lib_properties->get('name', default => $l));
    }
  }
  # TODO: we are ignoring the dot_a_linkage properties of the libraries (unclear what it brings)
  # and also the precompiled
  if ($run_step->('libraries')) {
    info 'Building libraries...';
    for my $l (@all_libs) {
      # Todo: we could add "lib-$l" pseudo-steps, but we need to take care of the --only
      # interaction with the 'libraries' step.
      info '  Building library %s...', $lib_config->get("${l}.name");
      my $base_dir = $lib_config->get($l);
      my $output_dir = catdir($build_dir, 'libs', $l);
      my $built_lib;
      if ($lib_config->get("${l}.is_flat")) {
        my $utility_dir = catdir($base_dir, 'utility');
        my @dirs = ($base_dir, (-d $utility_dir ? $utility_dir : ()));
        $built_lib = $builder->build_object_files(\@dirs, $output_dir, [], $force->('libraries'), 1);
      }  else {
        $built_lib = $builder->build_object_files(catdir($base_dir, 'src'), $output_dir, [], $force->('libraries'));
      }
      info ($built_lib ? '    Success' : '    Already up-to-date');
      $built_something |= $built_lib;
    }
  }

  $config->append('includes', '"-I'.$config->get('build.source.path').'"');

  if ($run_step->('sketch')) {
    info 'Building sketch...';
    $builder->run_hook('sketch.prebuild');
    my $built_sketch = $builder->build_object_files($config->get('build.source.path'), catdir($build_dir, 'sketch'), [$build_dir], $force->('sketch'));
    info ($built_sketch ? '  Success' : '  Already up-to-date');
    $built_something |= $built_sketch;
    $builder->run_hook('sketch.postbuild');
  }
  # Bug: there is a similar bug to the one in build_archive: if a source file is
  # removed, we won’t remove it’s object file. I guess we could try to detect it.
  # Meanwhile it’s probably acceptable to ask for a cleanup from time to time.
  my @object_files = find_all_files_with_extensions(catdir($build_dir, 'sketch'), ['o']);
  push @object_files, find_all_files_with_extensions(catdir($build_dir, 'libs'), ['o']);
  debug 'Object files: '.join(', ', @object_files);

  info 'Linking binary...';
  if (($built_something && $run_step->('link')) || $force->('link')) {
    $built_something = 1;
    $builder->run_hook('linking.prelink');
    $builder->link_executable(\@object_files, 'core.a');
    $builder->run_hook('linking.postlink');
    info '  Success';
  } else {
    info '  Already up-to-date';
  }

  info 'Extracting binary data';
  if (($built_something && $run_step->('objcopy')) || $force->('objcopy')) {
    $builder->run_hook('objcopy.preobjcopy');
    $builder->objcopy();
    $builder->run_hook('objcopy.postobjcopy');
    info '  Success';
  } else {
    info '  Already up-to-date';
  }

  info 'Success!';
}

1;
