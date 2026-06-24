package CPAN::Maker;

# a CPAN distribution creation utility

use strict;
use warnings;

use CPAN::Maker::Constants qw( :all );
use CPAN::Maker::Utils;
use CLI::Simple::Constants qw(:booleans :chars);
use CLI::Simple::Utils qw(choose slurp);

use Carp;
use Cwd;
use Data::Dumper;
use English qw( -no_match_vars );
use ExtUtils::MM;
use File::Basename qw(basename fileparse);
use File::Find;
use File::Process qw( process_file filter );
use File::Temp qw( tempfile );
use File::Copy qw(cp);
use File::ShareDir qw(dist_dir dist_file);
use JSON qw( encode_json decode_json );
use List::Util qw( pairs );
use Log::Log4perl::Level;
use Scalar::Util qw( reftype );
use YAML::Tiny qw(Load Dump LoadFile);
use version;

use Role::Tiny::With;

with 'CPAN::Maker::Role::ModuleUtils';
with 'CPAN::Maker::Role::FileUtils';

our $VERSION = '1.9.2';

__PACKAGE__->use_log4perl( level => 'info' );

use parent qw(CLI::Simple);

caller or __PACKAGE__->main();

########################################################################
sub init {
########################################################################
  my ($self) = @_;

  if ( $self->get_version ) {
    $self->command('version');
    return;
  }

  my $log_level = $self->get_log_level;
  $self->_set_log_level($log_level);

  my $project_root = $self->get_project_root;

  $self->set_project_root( $project_root // $ENV{PROJECT_HOME} // getcwd );

  # set the min perl version for deteriming core modules
  $self->_min_perl_version;

  # invoked by bash script to generate Makefile.PL - no buildspec
  if ( !$self->get_buildspec && $self->get_module ) {
    $self->command('write-makefile');
  }

  return;
}

########################################################################
sub _set_log_level {
########################################################################
  my ( $self, $log_level ) = @_;

  my @numeric_levels = (
    $ERROR => 1,
    $WARN  => 2,
    $INFO  => 3,
    $DEBUG => 4,
    $TRACE => 5,
  );

  my @text_levels = (
    error => 1,
    warn  => 2,
    info  => 3,
    debug => 4,
    trace => 5,
  );

  my $numeric_level = choose {

    if ( $log_level =~ /^(?:[12345])$/xsm ) {
      $log_level = { reverse @numeric_levels }->{$log_level};
      return $self->get_log_level;
    }
    elsif ( ($log_level) = grep { $log_level eq $_ } @text_levels ) {
      return {@text_levels}->{$log_level};
    }
    else {
      $log_level = {@text_levels}->{info};
    }
  };

  $self->get_logger->level( { reverse @numeric_levels }->{$numeric_level} );

  $self->set_log_level($numeric_level);

  return $numeric_level;
}

########################################################################
sub cmd_version {
########################################################################
  my ($self) = @_;

  print $PROGRAM_NAME . ' v' . $VERSION . $NL;

  return $SUCCESS;
}

########################################################################
sub cmd_validate {
########################################################################
  my ($self) = @_;

  my $is_validator_available = eval { require JSON::Validator; 1; };

  die "ERROR: JSON::Validator must be installed to validate your 'buildspec.yml' file.\n"
    if !$is_validator_available;

  my ($file) = $self->get_args;
  $file //= $self->get_buildspec // 'buildspec.yml';

  croak "ERROR: $file not found\n" if !-e $file;

  my $buildspec = $self->read_buildspec($file);

  if ( $self->validate_buildspec($buildspec) ) {
    $self->get_logger->info("$file is valid");
    return $SUCCESS;
  }
  else {
    $self->get_logger->error("$file is invalid");
    return $FAILURE;
  }
}

########################################################################
sub cmd_build {
########################################################################
  my ($self) = @_;

  die "ERROR: no buildspec.yml specified.\n"
    if !$self->get_buildspec;

  # processing a build specification...
  # parse buildspec and then call the bash script which actually builds the CPAN tarball
  my %args = $self->parse_buildspec;

  my $log_level = $self->get_log_level;

  if ( $log_level =~ /^(?:[12345])$/xsm ) {
    $args{'-L'} = $log_level;
  }

  my $cmd = join $SPACE, %args;

  $self->get_logger->debug( sub { return Dumper( [ args    => \%args ] ); } );
  $self->get_logger->trace( sub { return Dumper( [ command => $cmd ] ); } );

  exec 'make-cpan-dist ' . $cmd
    if !$self->get_dryrun;

  print {*STDOUT} sprintf "make-cpan-dist %s\n", $cmd;

  return $SUCCESS;
}

########################################################################
sub cmd_makefile {
########################################################################
  my ($self) = @_;

  croak 'no module specified'
    if !$self->get_module;

  croak 'no dependencies'
    if !$self->get_requires;

  my $author   = $self->get_author   // 'Anonymouse <anonymouse@example.com>';
  my $abstract = $self->get_abstract // 'my awesome Perl module!';

  return $self->write_makefile ? $SUCCESS : $FAILURE;
}

########################################################################
sub get_exe_file_list {
########################################################################
  my ( $self, $file ) = @_;

  my $lines;

  if ($file) {
    ($lines) = process_file(
      $file,
      chomp            => $TRUE,
      skip_blank_lines => $TRUE,
      process          => sub {
        my $f = pop @_;
        $f =~ s/^.*\/(.*)$/bin\/$1/xsm;
        return $f;
      }
    );
  }

  return $lines ? @{$lines} : ();
}

########################################################################
sub fetch_perl_version {
########################################################################
  my ( $self, $requires ) = @_;

  my $version;

  return
    if !-e $requires;

  process_file(
    $requires,
    chomp   => $TRUE,
    process => sub {
      my $module = pop @_;

      if ( $module !~ /^perl\s+/xsm ) {
        return ();
      }

      ( undef, $version ) = split /\s+/xsm, $module;
      return;
    }
  );

  return $version;
}

########################################################################
sub get_provides {
########################################################################
  my ( $self, $file ) = @_;

  my %provides;
  my @missing;

  my $work_dir = $self->get_work_dir;

  if ($file) {
    my ($lines) = process_file(
      $file,
      chomp            => $TRUE,
      skip_blank_lines => $TRUE,
      prefix           => 'lib',
      process          => sub {
        my $module = pop @_;
        my $args   = pop @_;

        if ( !$module ) {
          return ();
        }

        my $prefix = $args->{prefix};

        my $include_path = $prefix;

        if ($work_dir) {
          $include_path = sprintf '%s/%s', $work_dir, $include_path;
        }

        my $module_version = $self->get_module_version( $module, $include_path );

        my ( $provided_module, $version ) = @{$module_version}{qw( module version)};

        if ( !defined $version ) {
          warn sprintf "provided module '%s' not found in %s\n", $module, $include_path;
          push @missing, $module;
        }
        else {
          $provides{$provided_module} = {
            file    => sprintf( '%s/%s', $prefix, $module_version->{file} ),
            version => $version,
          };
        }

        return $provided_module;
      }
    );
  }

  # @missing is a list of modules in our provides file that do not map
  # to an actual file. This is probably due to a module containing
  # multiple classes. In that case if they were included in the
  # provides list, then the packager most likely wants us to find the
  # file they belong to.
  #
  # Iterate through the list of valid modules and search their files
  # for our missing modules.

  if (@missing) {
    warn sprintf "Attempting to find %s files that belong to these modules.\n%s", scalar(@missing), join "\n", @missing;

    my $dir = sprintf '%s/lib', $self->get_work_dir;

    my @file_list;

    find(
      sub {
        return if !-f;
        push @file_list, $File::Find::name;
      },
      $dir
    );

    unshift @INC, $dir;

    foreach my $module (@missing) {
      foreach my $file (@file_list) {
        my $text = slurp($file);
        next if $text !~ /^package\s+$module;/xsm;  # preliminary scan

        # remove all pod so we don't get false positives
        $text =~ s/^=pod(.*?)=cut//xsmg;
        next if $text !~ /^package\s+$module;/xsm;

        # see if we can get the version...this might work since we
        # added $work_dir to @INC. $work_dir
        # contains all the .pm modules to be packaged. It might not
        # work for other reaasons (like some required packages are not
        # installed?)
        my $version = eval {
          local $SIG{__WARN__} = sub { };
          require $file;
          no strict 'refs'; ## no critic
          return ${ $module . '::VERSION' };
        };

        $version //= 'undef';
        my $rel_path = $file;
        $rel_path =~ s/$work_dir\///xsm;

        $provides{$module} = {
          file    => $rel_path,
          version => $version,
        };

        print {*STDERR} sprintf "found %s version %s in %s\n", $module, $version, $rel_path;
      }
    }

    shift @INC;
  }

  return %provides;
}

########################################################################
sub read_resources {
########################################################################
  my ( $self, $file ) = @_;

  return get_json_file($file);
}

########################################################################
sub write_resources {
########################################################################
  my ( $self, $resources, %args ) = @_;

  my $resources_file;

  if ($resources) {
    $resources_file = 'resources';

    open my $fh, '>', $resources_file
      or croak "could not open resources for writing\n";

    print {$fh} JSON->new->pretty->encode($resources);

    close $fh
      or croak "could not close file $resources_file\n";
  }

  return %args;
}

########################################################################
sub write_pl_files {
########################################################################
  my ( $self, $pl_files, %args ) = @_;

  return %args
    if !$pl_files;

  my ( $fh, $filename ) = tempfile( 'make-cpan-dist-XXXXX', TMPDIR => $TRUE );

  print {$fh} join $SPACE, %{$pl_files};

  close $fh;

  $args{y} = $filename;

  return %args;
}

########################################################################
sub _write_provides {
########################################################################
  my ( $self, $fh, $provides ) = @_;

  croak "provides must be an array\n"
    if !is_array($provides);

  foreach my $file ( sort @{$provides} ) {
    next if !$file;
    print {$fh} "$file\n";
  }

  return;
}

########################################################################
sub write_provides {
########################################################################
  my ( $self, $provides, %args ) = @_;

  return %args
    if !$provides;

  my $provides_file = 'provides';

  open my $fh, '>', $provides_file
    or croak "could not open 'provides' for writing\n";

  $self->_write_provides( $fh, $provides );

  close $fh
    or croak "could not close 'provides'\n";

  $args{P} = $provides_file;

  return %args;
}

########################################################################
sub write_makefile {
########################################################################
  my ($self) = @_;

  my $core            = $self->get_core_modules;
  my $MODULE_ABSTRACT = $self->get_abstract;
  my $AUTHOR          = $self->get_author;
  my $project_root    = $self->get_project_root;

  my $email;
  my $author;

  if ( $AUTHOR && $AUTHOR =~ /^([^<]+)\s+<([^>]+)>\s*$/xsm ) {
    $author = $1;
    $email  = $2;
  }

  my $PM_MODULE = $self->get_module;

  my %buildspec = (
    version => $VERSION,
    project => {
      description => $MODULE_ABSTRACT,
      author      => {
        name   => $AUTHOR // 'Anonymouse',
        mailto => $email  // 'anonymouse@example.org',
      },
    },
    'pm-module' => $PM_MODULE,
  );

  my $VERSION_FROM = $self->get_version_from // $self->get_module;

  if ( $VERSION_FROM !~ /\//xsm ) {
    $VERSION_FROM = 'lib/' . $self->make_path_from_module($VERSION_FROM);
  }

  $buildspec{'version-from'} = $VERSION_FROM;

  local $Data::Dumper::Terse    = $TRUE;
  local $Data::Dumper::Sortkeys = $TRUE;
  local $Data::Dumper::Indent   = 2;
  local $Data::Dumper::Pad      = $SPACE x $INDENT;

  # dependencies = key name taken as file name if not provided
  foreach my $d (qw(requires test_requires build_requires recommends)) {
    $self->set( $d, $self->get($d) || $d );
  }

  $buildspec{dependencies} = {
    requires         => $self->get_requires,
    'test-requires'  => $self->get_test_requires,
    'build-requires' => $self->get_build_requires,
    recommends       => $self->get_recommends,
  };

  foreach (qw(requires test-requires build-requires recommends)) {
    my $dependency_file = $buildspec{dependencies}->{$_};
    $dependency_file =~ s/$project_root\/?//xsm;
    next if -s $dependency_file;

    delete $buildspec{dependencies}->{$_};
  }

  my $MIN_PERL_VERSION = $self->get_min_perl_version // $DEFAULT_PERL_VERSION;

  my $require_versions = $self->get_require_versions;

  my $PRE_REQ = Dumper $self->fetch_requires(
    requires             => $self->get_requires,
    include_core_modules => $core,
    include_version      => $require_versions,
    min_perl_version     => $MIN_PERL_VERSION,
  );

  $PRE_REQ = trim($PRE_REQ);
  $PRE_REQ =~ s/[@](\d+)/== $1/xsmg;

  my $TEST_REQ = {};

  if ( $self->get_test_requires && -s $self->get_test_requires ) {
    $TEST_REQ = Dumper $self->fetch_requires(
      requires             => $self->get_test_requires,
      include_core_modules => $core,
      include_version      => $require_versions,
      min_perl_version     => $MIN_PERL_VERSION,
    );
  }
  else {
    $TEST_REQ = '{}';
  }

  $TEST_REQ = trim($TEST_REQ);
  $TEST_REQ =~ s/[@](\d+)/== $1/xsmg;

  my $build_req      = {};
  my $build_requires = $self->get_build_requires;

  if ( $build_requires && -s $build_requires ) {
    $build_req = $self->fetch_requires(
      requires             => $build_requires,
      include_core_modules => $TRUE,
      include_version      => $require_versions,
      min_perl_version     => $MIN_PERL_VERSION,
    );
  }

  foreach my $m (qw( ExtUtils::MakeMaker File::ShareDir::Install)) {
    $build_req->{$m} = $build_req->{$m} || $FALSE;
  }

  $build_req = Dumper $build_req;

  my @exe_file_list;
  $buildspec{path} = {
    'pm-module' => $self->get_module_path,
    recurse     => $self->get_recurse ? 'yes' : 'no',
  };

  my $exe_files = $self->get_exe_files || $self->get_exec_path;

  if ( $exe_files && -s $exe_files ) {
    @exe_file_list = $self->get_exe_file_list($exe_files);
    $self->set_exec_path($exe_files);
  }

  foreach my $p ( pairs qw(exe-files exec-path scripts scripts-path tests tests-path) ) {
    my ( $spec_option, $path ) = @{$p};

    next
      if !$self->get($path);

    my $real_path = $self->get($path);

    my $project_file = sprintf '%s/%s', $project_root, $real_path;

    if ( -e $project_file ) {
      $buildspec{path}->{$spec_option} = $real_path;
    }
    else {
      $buildspec{$spec_option} = $self->fetch_relative_filelist( $project_root, $real_path );

      # remove temporary files?
      if ( $real_path =~ /make\-cpan\-dist\-[[:alpha:]]{5}/xsm ) {
        unlink $real_path;
      }
    }
  }

  if ( my $path = $self->get_extra_path ) {
    $buildspec{'extra-files'} = $path;
  }

  my $EXE_FILES = Dumper \@exe_file_list;

  # was: blindly putting all exe_files into MAN3PODS
  # fix: MAN1PODS only for scripts that actually contain POD

  my %man1pods;

  foreach (@exe_file_list) {
    my ( $name, $path, $ext ) = fileparse( $_, qr/[.][^.]+\z/xsm );

    # only include scripts that actually contain POD
    my $content = eval { slurp($_) } // q{};
    next if $content !~ /^=(head\d|pod|over|item|begin|encoding)/xsm;

    $man1pods{$_} = sprintf 'blib/man1/%s.1', $name;
  }

  my $MAN1PODS = Dumper \%man1pods;

  my %provides;

  if ( -e 'provides' ) {
    %provides = $self->get_provides('provides');
    $buildspec{provides} = [ keys %provides ];
  }

  my $resources_path = $self->get_resources // 'resources';
  my $resources;

  if ( -e $resources_path ) {
    $resources = $self->read_resources($resources_path);
    $buildspec{resources} = $resources;
  }

  my $recommends = {};

  if ( $self->get_recommends && -s $self->get_recommends ) {
    $recommends = $self->fetch_requires(
      requires             => $self->get_recommends,
      include_core_modules => $core,
      include_version      => $require_versions,
      min_perl_version     => $MIN_PERL_VERSION,
    );
  }

  my $META_MERGE = 'META_MERGE ' . $FAT_ARROW;

  {
    local $Data::Dumper::Pair = $FAT_ARROW;
    $META_MERGE .= Dumper(
      { 'meta-spec' => { version => 2 },
        'provides'  => \%provides,
        ( keys %{$recommends} ? ( 'prereqs' => { 'runtime' => { 'recommends' => $recommends, } } ) : () ),
        $resources ? ( 'resources' => $resources ) : ()
      }
    );
  }

  my $timestamp = scalar localtime;

  $buildspec{'min-perl-version'} = $MIN_PERL_VERSION;

  #  From: https://metacpan.org/pod/ExtUtils::MakeMaker
  #
  #  MakeMaker can run programs to generate files for you at build
  #  time. By default any file named *.PL (except Makefile.PL and
  #  Build.PL) in the top level directory will be assumed to be a Perl
  #  program and run passing its own basename in as an argument. This
  #  basename is actually a build target, and there is an intention, but
  #  not a requirement, that the *.PL file make the file passed to to as
  #  an argument. For example...
  #
  # perl foo.PL foo
  #
  my %pl_list;

  my $pl_files = $self->get_pl_files;

  if ( $pl_files && -s $pl_files ) {
    my @file_list = split /\n/xsm, slurp($pl_files);

    foreach my $pl_file (@file_list) {
      my ( $file, $target ) = split /\s+/xsm, $pl_file;
      $pl_list{$file} = $target;
    }

    $buildspec{'pl-files'} = \%pl_list;
  }

  my $PL_FILES = Dumper( \%pl_list );

  $buildspec{postamble} = $self->get_postamble;

  my $MAKEFILE = <<"END_OF_TEXT";
# autogenerated by $PROGRAM_NAME on $timestamp

use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::ShareDir::Install;

\$File::ShareDir::Install::INCLUDE_DOTFILES = 1;

if ( -d 'share' ) {
  install_share 'share';
}

WriteMakefile(
  NAME             => '$PM_MODULE',
  MIN_PERL_VERSION => '$MIN_PERL_VERSION',
  AUTHOR           => '$AUTHOR',
  VERSION_FROM     => '$VERSION_FROM',
  ABSTRACT         => '$MODULE_ABSTRACT',
  LICENSE          => 'perl',
  PL_FILES         => $PL_FILES,
  EXE_FILES        => $EXE_FILES,
  MAN1PODS         => $MAN1PODS,
  PREREQ_PM        => $PRE_REQ,
  BUILD_REQUIRES   => {
    'ExtUtils::MakeMaker'     => '6.64',
    'File::ShareDir::Install' => $NO_VERSION,
    },
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker'     => '6.64',
    'File::ShareDir::Install' => $NO_VERSION,
    },
  TEST_REQUIRES => $TEST_REQ,
  $META_MERGE
);
END_OF_TEXT

  $MAKEFILE .= <<'END_OF_MAKEFILE';
package MY;

use File::ShareDir::Install;
use English qw(-no_match_vars);

sub postamble {
  my $self = shift;

  my @ret = File::ShareDir::Install::postamble($self);

  my $postamble = join "\n", @ret;

  if ( -e 'postamble' ) {

    local $RS = undef;

    open my $fh, '<', 'postamble'
      or die "could not open postamble\n";

    $postamble .= <$fh>;

    close $fh;
  }

  return $postamble;
}

1;
END_OF_MAKEFILE

  print $MAKEFILE;

  $self->get_logger->debug( sub { return $MAKEFILE } );

  $self->write_buildspec_file( \%buildspec );

  return $TRUE;
}

########################################################################
sub write_buildspec_file {
########################################################################
  my ( $self, $buildspec ) = @_;

  my $buildspec_file = $self->get_create_buildspec;
  my $overwrite      = $self->get_overwrite;

  return
    if !$buildspec_file;

  die "$buildspec_file exists\n"
    if -e $buildspec_file && !$overwrite;

  open my $fh, '>', $buildspec_file
    or die "could not open $buildspec_file for writing\n";

  print {$fh} Dump($buildspec);

  close $fh;

  return;
}

########################################################################
sub parse_dependencies {
########################################################################
  my ( $self, $dependencies, %args ) = @_;

  if ($dependencies) {
    croak 'malformed buildspec.yml file - dependencies section with no keys?'
      if !keys %{$dependencies};

    $dependencies->{'core-modules'}     //= 'no';
    $dependencies->{'required-modules'} //= 'yes';

    if ( $dependencies->{path} ) {  # deprecatd
      $args{D} = $dependencies->{path};
      warn "path is deprecated: use requires\n";
    }

    if ( $dependencies->{requires} ) {
      $args{D} = $dependencies->{requires};
    }

    if ( $dependencies->{'test-requires'} ) {
      $args{T} = $dependencies->{'test-requires'};
    }

    if ( $dependencies->{'build-requires'} ) {
      $args{B} = $dependencies->{'build-requires'};
    }

    if ( $dependencies->{recommends} ) {
      $args{Y} = $dependencies->{recommends};
    }

    if ( $dependencies->{'core-modules'} eq 'yes' ) {
      $args{c} = $EMPTY;
    }

    if ( $dependencies->{'required-modules'} eq 'no' ) {
      $args{n} = $EMPTY;
    }

    if ( my $resolver = $dependencies->{resolver} ) {
      if ( $resolver eq 'scandeps' ) {
        $args{s} = $EMPTY;
      }
      else {
        $args{r} = $dependencies->{resolver};
      }
    }

    if ( $args{D} && $args{r} ) {
      croak "use either path or resolver for dependencies, but not both\n";
    }
  }

  return %args;
}

########################################################################
sub parse_include_version {
########################################################################
  my ( $self, $version, %args ) = @_;

  return %args
    if !defined $version;

  if ( $version =~ /(no|0|off)/ixsm ) {
    $args{A} = $EMPTY;
  }

  return %args;
}

########################################################################
sub parse_project {
########################################################################
  my ( $self, $project, %args ) = @_;

  return %args
    if !$project;

  if ( $project->{author} ) {
    my $name = $project->{author}->{name} // 'anonymouse';
    $args{a} = $name;

    if ( my $mailto = $project->{author}->{mailto} ) {
      $args{a} .= ' <' . $mailto . '>';
    }

    $args{a} = sprintf q{'%s'}, $args{a};
  }

  # -d
  if ( my $description = $project->{description} ) {
    $args{d} = sprintf q{'%s'}, $description;
  }

  # -g
  if ( my $git = $project->{git} ) {
    $args{g} = $git;
  }

  return %args;
}

########################################################################
sub parse_pm_module {
########################################################################
  my ( $self, $pm_module, %args ) = @_;

  return %args
    if !$pm_module;

  $args{m} = $pm_module;

  return %args;
}

########################################################################
sub read_buildspec {
########################################################################
  my ( $self, $file ) = @_;

  croak 'file not found or empty ' . $file . $NL
    if !-s $file;

  local $RS = undef;
  open my $fh, '<', $file or croak "could not open $file: $OS_ERROR\n";
  my $text = <$fh>;
  close $fh;

  my $normalized = (
    $text =~ s/^(\s*)(\w+)(\s*:)/
    my ($pre, $key, $post) = ($1, $2, $3);
    $key =~ s|_|-|g;
    "$pre$key$post"/xsmgre
  );

  if ( $normalized ne $text ) {
    my $current = $file . '.current';
    open my $out, '>', $current or croak "could not write $current: $OS_ERROR\n";
    print {$out} $normalized;
    close $out;
    $self->get_logger->warn("deprecated underscore keys found - normalized buildspec written to $current");
  }

  my $buildspec = eval { Load($normalized) };

  croak 'could not read ' . $file . $NL . $EVAL_ERROR . $NL
    if $EVAL_ERROR || !$buildspec;

  return $buildspec;
}

# this method converts a buildspec into options to be passed to shell script
# which eventually calls this script to create the Makefile.PL
########################################################################
sub parse_buildspec {
########################################################################
  my ($self) = @_;

  my $file = $self->get_buildspec;

  my $project_root = $self->get_project_root;

  my $buildspec = $self->read_buildspec($file);

  croak 'invalid buildspec.yml'
    if !$self->validate_buildspec($buildspec);

  my %args;

  if ( $buildspec->{'min-perl-version'} ) {
    $args{M} = $buildspec->{'min-perl-version'};
  }

  if ( $buildspec->{'version-from'} ) {
    $args{V} = $buildspec->{'version-from'};
  }

  if ($project_root) {
    $args{H} = $project_root;
  }

  if ( my $postamble = $self->get_postamble ) {
    $args{F} = $postamble;
  }

  if ( $buildspec->{'exe-files'} ) {
    $args{e} = $self->create_temp_filelist( $project_root, $buildspec->{'exe-files'} );
  }

  if ( $buildspec->{tests} ) {
    $args{t} = $self->create_temp_filelist( $project_root, $buildspec->{tests} );
  }

  if ( $buildspec->{scripts} ) {
    $args{S} = $self->create_temp_filelist( $project_root, $buildspec->{scripts} );
  }

  %args = $self->write_resources( $buildspec->{resources}, %args );

  %args = $self->parse_project( $buildspec->{project}, %args );

  %args = $self->parse_pm_module( $buildspec->{'pm-module'}, %args );

  %args = $self->parse_include_version( $buildspec->{'include-version'}, %args );

  %args = $self->parse_dependencies( $buildspec->{dependencies}, %args );

  %args = $self->parse_path( $project_root, $buildspec->{path}, %args );

  %args = $self->write_extra_files(
    extra_files  => $buildspec->{'extra-files'},
    extra        => $buildspec->{extra},
    args         => \%args,
    project_root => $project_root,
  );

  %args = $self->write_provides( $buildspec->{provides}, %args );

  %args = $self->write_pl_files( $buildspec->{'pl-files'}, %args );

  if ( my $links = $buildspec->{'man-links'} ) {
    my $man_links_content = $self->_generate_man_links($links);

    my ( $fh, $filename ) = tempfile( 'make-cpan-dist-XXXXX', TMPDIR => $TRUE );

    # preserve existing postamble if one was specified
    if ( $args{F} && -e $args{F} ) {
      local $RS = undef;
      open my $existing, '<', $args{F}
        or die "could not read postamble $args{F}: $OS_ERROR\n";
      print {$fh} <$existing>;
      close $existing;
    }

    print {$fh} $man_links_content;
    close $fh;

    $args{F} = $filename;
  }

  # set boolean args from options

  my @boolean_args = qw( verbose v cleanup !x scandeps s require-versions !A );

  foreach my $pair ( pairs @boolean_args ) {
    my ( $key, $value ) = @{$pair};

    if ( $value =~ /^\!(.*)$/xsm ) {
      if ( $self->get($1) ) {
        $self->set( $1, undef );
      }
    }
    elsif ( $self->get($key) ) {
      $args{$value} = $EMPTY;
    }
  }

  # set value args from buildspec
  foreach my $pair ( pairs qw( destdir o extra f ) ) {
    my ( $key, $value ) = @{$pair};

    if ( $buildspec->{$key} ) {
      $args{$value} = $buildspec->{$key};
    }
  }

  foreach my $k ( keys %args ) {
    $args{ $DASH . $k } = $args{$k};
    delete $args{$k};
  }

  $self->get_logger->debug( Dumper( [ args => \%args ] ) );

  return %args;
}

########################################################################
sub _generate_man_links {
########################################################################
  my ( $self, $links ) = @_;

  my $content = q{};

  for my $entry ( @{$links} ) {
    for my $p ( pairs %{$entry} ) {
      my ( $alias, $module ) = @{$p};

      # derive the .pm path from the module name and check for POD
      ( my $pm_path = "lib/$module.pm" ) =~ s|::|/|gxsm;

      if ( -e $pm_path ) {
        my $pm_content = eval { slurp($pm_path) } // q{};

        if ( $pm_content !~ /^=(head\d|pod|over|item|begin|encoding)/xsm ) {
          next;
        }
      }
      else {
        next;
      }

      $content .= <<"POSTAMBLE";
install ::
\t-\$(NOECHO) ln -sf \$(DESTINSTALLMAN3DIR)/$module.3pm \$(DESTINSTALLMAN3DIR)/$alias.3pm; \
\t\$(NOECHO) echo \$(DESTINSTALLMAN3DIR)/$alias.3pm >> \$(DESTINSTALLSITEARCH)/auto/\$(FULLEXT)/.packlist
POSTAMBLE
    }
  }

  return $content;
}

########################################################################
sub fetch_requires {
########################################################################
  my ( $self, %args ) = @_;

  my ( $requires, $core_modules, $min_perl_version, $include_version )
    = @args{qw(requires include_core_modules min_perl_version include_version)};

  my $logger = $self->get_logger;

  $logger->trace( sprintf 'processing %s file',       $requires );
  $logger->trace( sprintf "\t include_version: [%s]", $include_version ? 'yes' : 'no' );
  $logger->trace( sprintf "\tmin_perl_version: [%s]", $min_perl_version );
  $logger->trace( sprintf "\t    core_modules: [%s]", $core_modules ? 'yes' : 'no' );

  my %modules;

  process_file(
    $requires,
    chomp            => $TRUE,
    skip_blank_lines => $TRUE,
    skip_comments    => $TRUE,
    filter           => sub {
      my ( $fh, $all_lines, $args, $line ) = @_;
      $line = filter( $fh, $all_lines, $args, $line );

      return ()    if $line && $line =~ /^perl\s+/xsm;
      return $line if !defined $line;
      return $line if $core_modules;
      return $line if $line =~ /^[+]/xsm;
      return is_core( $line, $min_perl_version ) ? undef : $line;
    },
    process => sub {
      my $line = pop @_;

      $line =~ s/^[+]//xsm;

      my ( $module, $version ) = split /\s+/xsm, $line;

      $logger->trace( sprintf "\tprocessing line (%s): %s", basename($requires), $line );

      $logger->trace( sprintf "\t\t[%s:%s]", $module, $version // $EMPTY );

      if ( !$include_version ) {
        $version = '0';
      }
      else {
        $version ||= '0';
      }

      $modules{$module} = $version;

      return $line;
    }
  );

  return \%modules;
}

########################################################################
sub get_modules {
########################################################################
  my ( $self, $module_list ) = @_;

  my ($modules) = process_file( $module_list, chomp => $TRUE );

  return $modules;
}

########################################################################
sub validate_buildspec {
########################################################################
  my ( $self, $buildspec ) = @_;

  return $TRUE
    if !$self->get_validate;

  my $schema_file = eval { dist_file( 'CPAN-Maker', 'buildspec-schema.json' ) };

  if ( !$schema_file || !-e $schema_file ) {
    $self->get_logger->warn('buildspec-schema.json not found - skipping validation');
    return $TRUE;
  }

  my @errors = JSON::Validator->new->schema($schema_file)->validate($buildspec);

  if (@errors) {
    $self->get_logger->error('buildspec.yml validation failed:');
    $self->get_logger->error( ' - ' . $_ ) for @errors;
    return $FALSE;
  }

  return $TRUE;
}

########################################################################
sub _min_perl_version {
########################################################################
  my ($self) = @_;

  my $min_perl_version = choose {
    return $self->get_min_perl_version
      if $self->get_min_perl_version;

    return $self->fetch_perl_version( $self->get_requires )
      if $self->get_requires;

    return $DEFAULT_PERL_VERSION;
  };

  $min_perl_version = version->parse($min_perl_version)->stringify;

  $self->set_min_perl_version($min_perl_version);

  return;
}

########################################################################
sub main {
########################################################################

  my @option_specs = qw(
    abstract|A=s
    author|a=s
    build-requires|B=s
    buildspec|b=s
    cleanup!
    core-modules!
    create-buildspec=s
    debug|D
    dryrun
    exe-files|e=s
    exec-path=s
    extra-path=s
    help|h
    log-level|l=s
    min-perl-version|M=s
    module-path=s
    module|m=s
    overwrite
    pager|P!
    pl-files=s
    postamble=s
    project-root|p=s
    recommends=s
    recurse
    require-versions|R!
    requires|r=s
    resources=s
    scandeps|s
    scripts-path=s
    test-requires|t=s
    tests-path=s
    validate!
    verbose|V
    version-from=s
    version|v
    work-dir|w=s
  );

  my $is_json_validator_available = eval { require JSON::Validator; 1 };  # default: true if available

  my $default_options = {
    cleanup          => $TRUE,
    pager            => $TRUE,
    require_versions => $TRUE,
    validate         => $is_json_validator_available // $FALSE,
  };

  my %commands = (
    default          => \&cmd_build,
    build            => \&cmd_build,
    version          => \&cmd_version,
    'write-makefile' => \&cmd_makefile,
    'validate'       => \&cmd_validate,
  );

  my $cli = CPAN::Maker->new(
    commands       => \%commands,
    option_specs   => \@option_specs,
    default_option => $default_options,
  );

  exit $cli->run();
}

1;

__END__

=pod

=head1 NAME

CPAN::Maker - create a CPAN distribution

=head1 SYNOPSIS

 cpan-maker options

 cpan-maker -b buildspec.yml

=head2 Options

 -a, --author                author
 -A, --abstract              description of the module
 -B, --build-requires        build dependencies
 -b, --buildspec             read a buildspec and create command line
     --cleanup, --no-cleanup remove temp files, default: cleanup
     --create-buildspec      name of a buildspec file to create
 -d, --debug                 debug mode
     --dryrun                dryrun
     --exe-files             path to the executables list
     --extra-path            path to the extra files list
 -h, --help                  help
 -l, --log-level             ERROR, WARN, INFO, DEBUG, TRACE
 -m, --module                module name
 -M, --min-perl-version      minimum perl version to consider core, default: 5.010
 -P, --pager, --no-pager     use a pager for help, default: use pager
     --pl-files              path to the PL_FILES list (see perldoc ExtUtils::MakeMaker)
     --postamble             name of the file containing the postamble instructions
 -p, --project-root          default: current working directory
     --recurse               whether to recurse directors when searching for files
 -r, --requires              dependency list
 -R, --require-versions      add version numbers to dependencies
     --no-require-versions   
     --scripts-path          path to the scripts listing
 -t, --test-requires         test dependencies
     --tests-path            path to the tests listing
 -s, --scandeps              use scandeps for dependency checking
 -V, --verbose               verbose output
 -v, --version               version
     --version-from          module name that provide version

This script is typically called with the C<--buildspec> option
specifying a YAML file that contains the options for building a CPAN
distribution.  Calling this script without the C<--buildspec> option
will only result in a C<Makefile.PL> being written to STDOUT.

When invoked with a buildspec it will parse the YAML file and call the
C<make-cpan-dist> bash script that actually creates the CPAN
distribution.

See man CPAN::Maker for more details.

=head2 Commands

=over 4

=item * build

Parse a C<buildspec.yml> file and build the CPAN distribution tarball.
This is the default command - it is invoked automatically when

C<-b buildspec.yml> is passed without an explicit command.

  cpan-maker build -b buildspec.yml
  cpan-maker -b buildspec.yml

=item * validate

Validate a C<buildspec.yml> file against the JSON Schema. Reports all
errors before exiting. Returns a non-zero exit status if validation
fails, making it suitable for use in CI pipelines.

  cpan-maker validate
  cpan-maker validate path/to/buildspec.yml
  cpan-maker -b path/to/buildspec.yml validate

I<Note: If your file uses underscore-style keys (C<pm_module>,
C<extra_files>, etc.) they are automatically normalized to their
canonical hyphenated forms and a corrected copy is written to
`buildspec.yml.current`. Useful as a first step when migrating an
existing project or upgrading C<CPAN::Maker>.>

=item * write-makefile

Generate a C<Makefile.PL> from the options passed by the
C<make-cpan-dist> bash script. This command is invoked internally
during the build pipeline and is not intended for direct use.

=item * version

Print the installed version of C<CPAN::Maker> and exit.

  cpan-maker version

=back

See man CPAN::Maker for more details.

=head1 DESCRIPTION

Utility that is part of a toolchain to create a CPAN distribution.

This utility should normally be called with the C<--buildspec> option
specifying a YAML file that describes the distribution to be
packaged. The toolchain can:

=over 5

=item * find Perl module dependencies in your modules and scripts

=item * create a C<Makefile.PL>

=item * package your artifacts from your project hierarchy into a CPAN distribution

=back

If the script is passed a YAML file (C<--buildspec>) then the script
will parse the build specification and call the bash script
C<make-cpan-dist> with all of the necessary flags to build a
tarball. If you do not provide a build specification this script will
only create the C<Makefile.PL> file for you.  It will be left to you
to modify the C<Makefile.PL> if necessary and then package the
artifacts into a CPAN distribution.

You can also call the bash script yourself, supplying all of the
necessary options.  When L<using the bash script|/"USING THE BASH
SCRIPT">, it will ultimately call this script to create the
C<Makefile.PL> and before creating your CPAN distribution.

=head1 ENVIRONMENT VARIABLES

=over 5

=item PRESERVE_MAKEFILE

Set this environment variable to a true value if you want the script
to preserve the F<Makefile.PL> after it builds the distribution
(useful for inspecting the result of the build). It will be copied to
your current working directory.

=item SKIP_TESTS

Set this environment variable to skip tests during the build.

=item DEBUG

Set this environment variable to enable debug mode. The bash script
will echo all commands run. This is useful for debugging unexpected
output or problems with the final distribution.

=back

 See https://github.com/rlauer6/CPAN-Maker.git for more documentation.

=head1 VERSION

This documentation refers to version 1.9.2

=head1 USING THE BASH SCRIPT

Assuming you have a module named C<Foo::Bar> in a directory named
F<lib> and some tests in a directory named F<t>, you might try:

 make-cpan-dist -l lib -t t -m Foo::Bar \
  -a 'Rob Lauer <rlauer6@comcast.net>' -d 'the Foo::Bar module!'

I<NOTE: Running the Bash script in any directory of your project if it
is part of a F<git> repository will use the root of the repository as
your project home directory.  If you are not in a F<git> repository
AND do not supply the -H option (project home), then the current
directory will be considered the project home directory. This means
that options like -l will be relative to the current directory.>

=head2 Using F<buildspec.yml>

 cpan-maker -b buildspec.yml

Calling this utility directly with the C<-b> option will parse the
buildspec and invoke the C<bash> script with all of the appropriate
options. This is the preferred way of using this toolchain. The format
of the YAML build file is described below.

I<IMPORTANT: All files specified in the F<buildspec.ym> file must be
specified as absolute paths or they should be relative to the
project's root directory, B<NOT THE CURRENT WORKING DIRECTORY!>>

=head1 OPTION DETAILS

=over 5

=item -A, --abstract

A short description of the module purpose.

=item -a, --author

When supplying the author on the command line, include the email
address in angle brackets as shown in the example.

Example: -a 'Rob Lauer <rlauer6@comcast.net>'

If this is a I<git> project then the bash script will attempt to get
your name and email from the git configuration.

=item -B, --build-requires

Name of the file that contains the dependencies for building the distribution.

=item -b, --buildspec

Name of build specification file in YAML format.  The build
specification file will be parsed and supply the necessary options to
the bash script for creating your distribution.  See L</BUILD SPECIFICATION FORMAT>.

=item -c, --cleanup

Cleanup temp directories and files.  The default is to cleanup all
temporary files, use the C<--no-cleanup> option if you want to examine
some of the temporary files.

=item -C, --create-buildspec

Name of a buildspec file to create from the options passed to this
script.

I<Note that this file may need to be modified if the options passed to
the file are not sufficient to create an acceptable buildspec.>

=item -d, --debug

Debug mode. Outputs lot's of diagnostics for debugging the
interpretation of the options passed and the F<Makefile.PL> creation
process.

=item --dryrun

Typically used when calling the bash script directly, this will output
the command to be executed and all of the options to
F<cpan-maker>.

=item -h, --help

Print the options to F<cpan-maker> to STDOUT. For more help try
C<make-cpan-dist -h> for the options to the bash script.

Additional information can be found
L<here|https://github.com/rlauer/make-cpan-dist>

=item -l, --log-level

Log level.

Valid values: error|warn|info|debug

default: error

=item -m, --module

Name of the Perl module to package.

=item -M, --min-perl-version

The minium version of perl to consider core when resolving dependencies.

=item -P, --pager, --no-pager

Use a pager for help.

default: --pager

=item --pl-files

Path to the PL_FILE list.

From: https://metacpan.org/pod/ExtUtils::MakeMaker

I<MakeMaker can run programs to generate files for you at build time. By
default any file named *.PL (except Makefile.PL and Build.PL) in the
top level directory will be assumed to be a Perl program and run
passing its own basename in as an argument. This basename is actually
a build target, and there is an intention, but not a requirement, that
the *.PL file make the file passed to to as an argument. For
example...>

 perl foo.PL foo

=item --postamble

Name of a file that contains the C<Makefile.PL> postamble section.

=item -p, --project-root

Root of the project to use when looking for files to package.

default: current working directory

=item --recurse

Recurse sub-directories when looking for files to package.

=item -r, --requires

Name of a file that contains the list of dependencies if other than F<requires>.

default: requires

=item -R, --require-versions, --no-require-versions

Whether to add version numbers to dependencies.

default: --require-versions

=item -s, --scandeps

Use F<scandeps.pl> for dependency checking instead of
F<scandeps-static.pl> (L<Module::ScanDeps::Static>).

default: F<scandeps-static.pl>

=item --scripts-path

Path to the file containing a list of script files.

=item -t, --test-requires

Name of the file that contains the dependencies for running tests included in your distribution if other than F<test-requires>.

default: test-requires

=item --tests-path

Path to the file containing a list of test files.

=item -V, --verbose

Verbose output.

=item -v, --version

Returns the version of this script.

=item --version-from

Name of the module that provides the package version. Defaults to the
main module being packaged.

=back


=head1 BUILD SPECIFICATION FORMAT

Example:

  version: 1.9.2
  project:
    git: https://github.com/rlauer6/perl-Amazon-Credentials
    description: "AWS credentials discoverer"
    author:
      name: Rob Lauer
      mailto: rlauer6@comcast.net
  pm-module: Amazon::Credentials
  include-version: no
  dependencies:
    resolver: scandeps
    requires: requires
    test-requires: test-requires
    required-modules: no
  path:
    recurse: yes
    pm-module: src/main/perl/lib
    tests: src/main/perl/t
    exe-files: src/main/perl/bin
  exclude-files: exclude_files
  extra: extra-files
  extra-files:
    - file
    - /usr/local/share/my-project:
      - file
  provides: provides
  postamble: postamble
  man-links:
  resources:
    homepage: 'http://github.com/rlauer6/perl-Amazon-API'
    bugtracker:
      web: 'http://github.com/rlauer6/perl-Amazon-API/issues'
      mailto: rlauer6@comcast.net
    repository:
      url: 'git://github.com/rlauer6/perl-Amazon-API.git'
      web: 'http://github.com/rlauer6/perl-Amazon-API'
      type: 'git'

The sections are described below:

=over 10

=item version

The version of of the specification format.  This should correspond
with the version of C<CPAN::Maker> that supports the format. It may be
used in future versions to validate the specification file.

=item project

=over 15

=item git

The path to a C<git> project. If this is included in the buildspec
then the bash script will clone that repo and use that repo as the
target of the build.  If the cloned repo includes a F<configure.ac>
file root directory the script will attempt to build the repo as a
autoconfiscated project.

 autoconf -i --force
 ./configure
 make

If F<configure.ac> is not found, the project will simply be cloned and
it will be assumed the Perl modules and artifacts to be packaged are
somewhere to be found in the project tree (as described in your
buildspec file). You should make sure that you set the C<path> section
accordingly so that the utility knows were to find your Perl modules.

I<I'm actually not sure how useful this feature is. I'm guessing that
the scenario for use might be if you have the buildspec file somewhere
other than the repo you wish to build or you don't own or don't want
to fork a project but want to build a CPAN distribution from it?>

=item description

The description of the module as it will be appear in the CPAN
repository.

=item author

The I<author> section should contain a name and email address.

=over 20

=item name

The author's name.

=item mailto

The author's email address.

=back

=back

=item pm-module

The name of the Perl module.

=item postamble

The name of a file that contains additional C<makefile> statements
that are appended to the F<Makefile> created by
F<Makefile.PL>. Typically, this will look something like:

 postamble ::

 install::
        # do something

=item man-links

Create symbolic links for executables to module man pages. Typically
used to create symlinks to modulinos. For example if C<Foo::Bar> is
implemented as a modulino and C<foo-bar> is the wrapper script, then
adding:

  man-links:
    - foo-bar: Foo::Bar

...would allow C<man foo-bar> to bring up the man page for C<Foo::Bar>.
The target module must contain POD - if no POD is found the link is
silently skipped.

=item include-version

If dependencies are resolved automatically, include the version
number. To disable this set this value to 'no'.

default: yes

=item dependencies

The I<dependencies> section, if present may contain the fully
qualified path to a file that contains a list of dependencies. If
the name of the file is F<cpanfile>, then the file is assumed to be in
I<cpanfile> format, otherwise the file should be a simple list of Perl
module names optionally followed by a version number.

 Amazon::Credentials 1.15

By default, the script will look for F<scandeps-static.pl> as the
dependency resolver, however you can override this by specifying the
name of program that will produce a list of modules.  If you specify
the special name I<scandeps>, the scripts will use F<scandeps.pl>.

I<NOTE: F<scandeps-static.pl> is provided by
L<Module::ScanDeps::Static> and is (at least by this author to be a
bit superior to F<scandeps.pl>.>

=over 15

=item recommends

Fully qualified path to a file listing optional recommended
dependencies. Modules listed here will appear under
C<prereqs.runtime.recommends> in the generated META files, and can be
installed with C<cpanm --with-recommends>.

Example F<recommends> file:

  Apache::ConfigParser 0
  Apache2::Request 0
  Apache2::Upload 0
  mod_perl2 0

=item requires

Fully qualified path to a dependency list for module.

=item test-requires

Fully qualified path to a dependency list for tests.

=item build-requires

Fully qualified path to a dependency list for build.

=item resolver (optional)

Name of a program that will provide a list of depenencies when passed
a module name. Use the special name C<scandeps> to use Perl's
C<scandeps.pl>.  When using C<scandeps.pl>, the C<-R> option will be
used to prevent C<scandeps.pl> from recursing. Neither
C</usr/lib/rpm/perl.req> or C<scandeps.pl> are completely
reliable. Your methodology might be to use these to get a good start
on a file containing dependencies and then add/subtract as required
for your use case.

When preparing the list of files to list as requirements in the
C<PREREQ_PM> section of the C<Makefile.PL>, the script will
automatically remove any modules that are already included with Perl.

=item required-modules

If the resolver should look for modules that are C<required>d by your
scripts and modules.

default: yes

=back

=item path (optional)

=over 15

=item pm-module

The path where the Perl module to be packaged can be found.  By
default, the current working directory will be searched or the root of
the search if the C<recurse> value is set to 'yes'.

default: current working directory

=item recurse (optional)

Specifies whether to or not to look in subdirectories of the path
specified by C<pm_module> for additional modules to package.

default: yes

=item tests (optional)

The path where tests to be specified in the F<Makefile.PL> will be
found.

=item exe-files

Path where executable Perl modules will be found. Files that are to be
included in the distribution must have executable permissions.

Examples:

 src/main/perl/bin
 bin/

=item scripts

Path where executable scripts (e.g. bash) will be found. Files that are to be
included in the distribution must have executable permissions.

Examples:

 src/main/bash/bin
 bin/

=back

=item provides (optional)

By default the package will specify the primary module to be packaged
and any additional modules that were found if the C<recurse> option
was set to 'yes'.

=item recommends

Name of a file containing optional recommended dependencies. These are
modules that enhance functionality but are not required for basic
operation. When installed with C<cpanm --with-recommends>, these will
be installed alongside the required dependencies. If not specified,
defaults to a file named F<recommends> if present.

Example use case: optional Apache/mod_perl dependencies that are only
needed in a specific deployment environment.

=item resources (optional)

Values to add to the I<resources> section of the META_MERGE argument
passed to L<ExtUtils::MakeMaker> when creating the F<Makefile.PL>
file.

See L<https://metacpan.org/pod/CPAN::Meta::Spec> for more details.

=item extra (optional)

Name of a file that contains a list of files to be included in the
package. These files are included in the package but not installed.

=item extra-files (optional)

List of files to be included in package.

Example:

 extra-files:
   - ChangeLog
   - README
   - examples:
     - src/examples <= include all files in this directory

 extra-files:
   - ChangeLog
   - README
   - examples:
      - src/examples/foo.pl
      - src/examples/boo.pl

I<CAUTION: specifying a directory will include ALL of the files in
that directory. It is a better practice list the specific files you
want to include or provide a manifest of files in the C<extra> key.>

 extra: manifest

If you include in your C<extra-files> specification, a 'share'
directory, then that directory will be installed as part of the
distribution. The location of those files will be relative to the
distribution's share directory and can be found like this:

 perl -MFile::ShareDir=dist_dir -e 'print dist_dir(q{My-Project});'

The specification...

 extra-files:
   - share:   <= indicates ../auto/share/dist/My-Project
     - resources/foo.cfg

...would package the file F<foo.cg> from your project's F<resources>
directory to the distribution's share directory. While this specification...

 extra-files:
   - share/resources: <= indicates ../auto/share/dist/My-Project/resources
     - resources/foo.cfg

...would package the file F<foo.cfg> in the distribution's share
directory under the F<resources> directory.

I<All other files in the C<extra-files> section will be added to the
root of the tarball but will not be installed.>

=item scripts

Array of script names or a path to the scripts that should be included
in the distribution. Files should be relative to the project root.

=item exe-files

Array of Perl script names or a path to the scripts that should be included
in the distribution. Files should be relative to the project root.

=back

=head2 Key Naming

Keys in the buildspec may be written with either hyphens (C<pm-module>)
or underscores (C<pm_module>). The hyphenated form is canonical.
If underscore keys are detected, they are automatically normalized before
parsing and a corrected copy of your buildspec is written to
F<buildspec.yml.current> for your reference. Your original file is
never modified.

=head1 DEPENDENCIES

By default the script will look for dependencies in files named
F<requires> and F<test-requires>.  These can be created automatically
by the C<bash> script (C<make-cpan-dist>).

You can specify a different name for the files with the C<-r> and
C<-t> options.

B<You must however have a file that contains the dependency list in
order to create a CPAN distribution.>

Again, if you use the C<bash> script that invokes this utility or are
calling this utility with a F<buildspec.yml> file, these files can be
I<automatically> created for you based on your options.  If you
provide your own F<requires> or F<test-requires> file, modules should
be specified as shown below unless the name of the dependency file is
L<C<cpanfile>|/"dependencies">.

  module-name version

Example:

 AWS::Signature4::Lite 1.0.0
 ...

=head1 AUTHOR

Rob Lauer - <rlauer@treasurersbriefcase.com>

=cut
