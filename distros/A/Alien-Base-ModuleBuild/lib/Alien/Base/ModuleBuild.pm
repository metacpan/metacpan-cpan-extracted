package Alien::Base::ModuleBuild;

use strict;
use warnings;
use 5.008001;
use parent 'Module::Build';
use Capture::Tiny 0.17 qw/capture tee/;
use File::chdir;
use File::Spec;
use File::Basename qw/fileparse/;
use Carp;
no warnings;
use Archive::Extract;
use warnings;
use Sort::Versions;
use List::Util qw( uniq any );
use ExtUtils::Installed;
use File::Copy qw/move/;
use Env qw( @PATH );
use Shell::Guess;
use Shell::Config::Generate;
use File::Path qw/mkpath/;
use Config;
use Text::ParseWords qw( shellwords );
use Alien::Base::PkgConfig;
use Alien::Base::ModuleBuild::Cabinet;
use Alien::Base::ModuleBuild::Repository;
use Alien::Base::ModuleBuild::Repository::HTTP;
use Alien::Base::ModuleBuild::Repository::FTP;
use Alien::Base::ModuleBuild::Repository::Local;

# ABSTRACT: A Module::Build subclass for building Alien:: modules and their libraries
our $VERSION = '1.17'; # VERSION

# setup protocol specific classes
# Alien:: author can override these defaults using alien_repository_class property
my %default_repository_class = (
  default => 'Alien::Base::ModuleBuild::Repository',
  http    => 'Alien::Base::ModuleBuild::Repository::HTTP',
  https   => 'Alien::Base::ModuleBuild::Repository::HTTP',
  ftp     => 'Alien::Base::ModuleBuild::Repository::FTP',
  local   => 'Alien::Base::ModuleBuild::Repository::Local',
);

our $Verbose;
$Verbose = $ENV{ALIEN_VERBOSE} if defined $ENV{ALIEN_VERBOSE};

our $Force;
our $ForceSystem;
_compute_force();

sub _compute_force
{
  undef $Force;
  undef $ForceSystem;

  if(defined $ENV{ALIEN_INSTALL_TYPE})
  {
    if($ENV{ALIEN_INSTALL_TYPE} eq 'share')
    {
      $Force       = 1;
      $ForceSystem = 0;
    }
    elsif($ENV{ALIEN_INSTALL_TYPE} eq 'system')
    {
      $Force       = 0;
      $ForceSystem = 1;
    }
    else  # anything else, including 'default'
    {
      $Force       = 0;
      $ForceSystem = 0;
    }
  }
  elsif(defined $ENV{ALIEN_FORCE})
  {
    $Force = $ENV{ALIEN_FORCE};
  }
}

################
#  Parameters  #
################

## Extra parameters in A::B::MB objects (all (toplevel) should start with 'alien_')

# alien_name: name of library (pkg-config)
__PACKAGE__->add_property('alien_name');

# alien_ffi_name: name of library (the "foo" in libfoo)
__PACKAGE__->add_property('alien_ffi_name');

# alien_temp_dir: folder name for download/build
__PACKAGE__->add_property( alien_temp_dir => '_alien' );

# alien_install_type: allow to override alien install type
__PACKAGE__->add_property( alien_install_type => undef );

# alien_share_dir: folder name for the "install" of the library
# this is added (unshifted) to the @{share_dir->{dist}}
# N.B. is reset during constructor to be full folder name
__PACKAGE__->add_property('alien_share_dir' => '_share' );

# alien_selection_method: name of method for selecting file: (todo: newest, manual)
#   default is specified later, when this is undef (see alien_check_installed_version)
__PACKAGE__->add_property( alien_selection_method => 'newest' );

# alien_build_commands: arrayref of commands for building
__PACKAGE__->add_property(
  alien_build_commands =>
  default => [ '%c --prefix=%s', 'make' ],
);

# alien_test_commands: arrayref of commands for testing the library
# note that this might be better tacked onto the build-time commands
__PACKAGE__->add_property(
  alien_test_commands =>
  default => [ ],
);

# alien_build_commands: arrayref of commands for installing the library
__PACKAGE__->add_property(
  alien_install_commands =>
  default => [ 'make install' ],
);

# alien_version_check: command to execute to check if install/version
__PACKAGE__->add_property( alien_version_check => '%{pkg_config} --modversion %n' );

# pkgconfig-esque info, author provides these by hand for now, will parse .pc file eventually
__PACKAGE__->add_property( 'alien_provides_cflags' );
__PACKAGE__->add_property( 'alien_provides_libs' );

# alien_repository: hash (or arrayref of hashes) of information about source repo on ftp
#   |-- protocol: ftp or http
#   |-- protocol_class: holder for class type (defaults to 'Net::FTP' or 'HTTP::Tiny')
#   |-- host: ftp server for source
#   |-- location: ftp folder containing source, http addr to page with links
#   |-- pattern: qr regex matching acceptable files, if has capture group those are version numbers
#   |-- platform: src or platform, matching os_type M::B method
#   |
#   |-- (non-api) connection: holder for Net::FTP-like object (needs cwd, ls, and get methods)
__PACKAGE__->add_property( 'alien_repository'         => [] );
__PACKAGE__->add_property( 'alien_repository_default' => {} );
__PACKAGE__->add_property( 'alien_repository_class'   => {} );

# alien_isolate_dynamic
__PACKAGE__->add_property( 'alien_isolate_dynamic' => 0 );
__PACKAGE__->add_property( 'alien_autoconf_with_pic' => 1 );

# alien_inline_auto_include
__PACKAGE__->add_property( 'alien_inline_auto_include' => [] );

# use MSYS even if %c isn't found
__PACKAGE__->add_property( 'alien_msys' => 0 );

# Alien packages that provide build dependencies
__PACKAGE__->add_property( 'alien_bin_requires' => {} );

# Do a staged install to blib instead of trying to install to the final location.
__PACKAGE__->add_property( 'alien_stage_install' => 1 );

# Should modules be installed into arch specific directory?
# Most alien dists will have arch specific files in their share so it makes sense to install
# the module in the arch specific location.  If you are alienizing something that isn't arch
# specific, like javascript source or java byte code, then you'd want to set this to 0.
# For now this will default to off.  See gh#119 for a discussion.
__PACKAGE__->add_property( 'alien_arch' => defined $ENV{ALIEN_ARCH} ? $ENV{ALIEN_ARCH} : 0 );

__PACKAGE__->add_property( 'alien_helper' => {} );

__PACKAGE__->add_property( 'alien_env' => {} );

# Extra enviroment variable to effect to "configure"
__PACKAGE__->add_property( 'alien_extra_site_config' => {} );

################
#  ConfigData  #
################

# working_directory: full path to the extracted source or binary of the library
# pkgconfig: hashref of A::B::PkgConfig objects created from .pc file found in working_directory
# install_type: either system or share
# version: version number installed or available
# Cflags: holder for cflags if manually specified
# Libs:   same but libs
# name: holder for name as needed by pkg-config
# finished_installing: set to true once ACTION_install is finished, this helps testing now and real checks later

############################
#  Initialization Methods  #
############################

sub new {
  my $class = shift;
  my %args = @_;

  # merge default and user-defined repository classes
  $args{alien_repository_class}{$_} ||= $default_repository_class{$_}
    for keys %default_repository_class;

  my $self = $class->SUPER::new(%args);

  ## Recheck Force System
  if(!defined($ENV{ALIEN_INSTALL_TYPE}) && !defined($ENV{ALIEN_FORCE}) && defined($self->alien_install_type)) {
    if   ($self->alien_install_type eq 'share' ) { $Force = 1; $ForceSystem = 0; }
    elsif($self->alien_install_type eq 'system') { $Force = 0; $ForceSystem = 1; }
  }

  $self->config_data("Force" => $Force);
  $self->config_data("ForceSystem" => $ForceSystem);

  $self->alien_helper->{pkg_config} = 'Alien::Base::PkgConfig->pkg_config_command'
    unless defined $self->alien_helper->{pkg_config};

  my $ab_version = eval {
    require Alien::Base;
    Alien::Base->VERSION;
  };
  $ab_version ||= 0;

  # setup additional temporary directories, and yes we have to add File::ShareDir manually
  if($ab_version < 0.77) {
    $self->_add_prereq( 'requires', 'File::ShareDir', '1.00' );
  }

  # this just gets passed from the Build.PL to the config so that it can
  # be used by the auto_include method
  $self->config_data( 'inline_auto_include' => $self->alien_inline_auto_include );

  if($Force || !$self->alien_check_installed_version) {
    if (any { /(?<!\%)\%c/ } map { ref($_) ? @{$_} : $_ } @{ $self->alien_build_commands }) {
      $self->config_data( 'autoconf' => 1 );
    }

    if ($^O eq 'MSWin32' && ($self->config_data( 'autoconf') || $self->alien_msys)) {
      $self->_add_prereq( 'build_requires', 'Alien::MSYS', '0' );
      $self->config_data( 'msys' => 1 );
    } else {
      $self->config_data( 'msys' => 0 );
    }

    foreach my $tool (keys %{ $self->alien_bin_requires  }) {
      my $version = $self->alien_bin_requires->{$tool};
      if($tool eq 'Alien::CMake' && $version < 0.07) {
        $version = '0.07';
      }
      $self->_add_prereq( 'build_requires', $tool, $version );
    }

    my @repos = ref $args{alien_repository} eq 'ARRAY'
      ? @{ $args{alien_repository} }
      : ( $args{alien_repository} );

    foreach my $repo (@repos)
    {
      next unless defined $repo;
      if(($repo->{protocol}||'') eq 'https')
      {
        $self->_add_prereq( 'build_requires', 'IO::Socket::SSL', '1.56' );
        $self->_add_prereq( 'build_requires', 'Net::SSLeay',     '1.49' );
      }
    }

  }


  # force newest for all automated testing
  #TODO (this probably should be checked for "input needed" rather than blindly assigned)
  if ($ENV{AUTOMATED_TESTING}) {
    $self->alien_selection_method('newest');
  }

  $self->config_data( 'finished_installing' => 0 );

  if(any { /(?<!\%)\%p/ } map { ref($_) ? @{$_} : $_ } @{ $self->alien_build_commands }) {
    carp "%p is deprecated, See https://metacpan.org/pod/Alien::Base::ModuleBuild::API#p";
  }

  return $self;
}

sub alien_init_temp_dir {
  my $self = shift;
  my $temp_dir = $self->alien_temp_dir;
  my $share_dir = $self->alien_share_dir;

  # make sure we are in base_dir
  local $CWD = $self->base_dir;

  unless ( -d $temp_dir ) {
    mkdir $temp_dir or croak "Could not create temporary directory $temp_dir";
  }
  $self->add_to_cleanup( $temp_dir );

  unless ( -d $share_dir ) {
    mkdir $share_dir or croak "Could not create temporary directory $share_dir";
  }
  $self->add_to_cleanup( $share_dir );

  # add share dir to share dir list
  my $share_dirs = $self->share_dir;
  unshift @{ $share_dirs->{dist} }, $share_dir;
  $self->share_dir( $share_dirs );
  {
    local $CWD = $share_dir;
    open my $fh, '>', 'README' or die "Could not open README for writing (in directory $share_dir)\n";
    print $fh <<'END';
This README file is autogenerated by Alien::Base.

Currently it exists for testing purposes, but it might eventually contain information about the file(s) installed.
END
  }
}

####################
#  ACTION methods  #
####################

sub ACTION_alien_fakebuild {
  my $self = shift;

  # needed for any helpers provided by alien_bin_requires
  $self->_alien_bin_require($_) for keys %{ $self->alien_bin_requires };

  print "# Build\n";
  foreach my $cmd (@{ $self->alien_build_commands })
  {
    my @cmd = map { $self->alien_interpolate($_) } ref($cmd) ? @$cmd : ($cmd);
    print "+ @cmd\n";
  }
  print "# Build install\n";
  foreach my $cmd (@{ $self->alien_install_commands })
  {
    my @cmd = map { $self->alien_interpolate($_) } ref($cmd) ? @$cmd : ($cmd);
    print "+ @cmd\n";
  }
}

sub ACTION_code {
  my $self = shift;
  $self->notes( 'alien_blib_scheme' => $self->alien_detect_blib_scheme );

  # PLEASE NOTE, BOTH BRANCHES CALL SUPER::ACTION_code !!!!!!!
  if ( $self->notes('ACTION_alien_completed') ) {

    $self->SUPER::ACTION_code;

  } else {

    $self->depends_on('alien_code');
    $self->SUPER::ACTION_code;
  }

  my $module = $self->module_name;
  my $file   = File::Spec->catfile($self->blib, 'lib', split /::/, "$module\::Install::Files.pm");
  unless (-e $file) {
    mkpath(File::Spec->catdir($self->blib, 'lib', split /::/, "$module\::Install"), { verbose => 0 });
    open my $fh, '>', $file;
    print $fh <<EOF;
package $module\::Install::Files;
use strict;
use warnings;
require $module;
sub Inline { shift; $module->Inline(\@_) }
1;

=begin Pod::Coverage

  Inline

=end Pod::Coverage

=cut
EOF
    close $fh;
  }

  if($self->alien_arch) {
    my @parts = split /::/, $module;
    my $arch_dir = File::Spec->catdir($self->blib, 'arch', 'auto', @parts);
    File::Path::mkpath($arch_dir, 0, oct(777)) unless -d $arch_dir;
    open my $fh, '>', File::Spec->catfile($arch_dir, $parts[-1].".txt");
    print $fh "Alien based distribution with architecture specific file in share\n";
    close $fh;
  }

  $self->depends_on('alien_install') if $self->alien_stage_install;
}

sub process_share_dir_files {
  my $self = shift;
  $self->SUPER::process_share_dir_files(@_);

  # copy the compiled files into blib if running under blib scheme
  $self->depends_on('alien_install') if $self->notes('alien_blib_scheme') || $self->alien_stage_install;
}

sub alien_extract_archive {
  my ($self, $archive) = @_;
  print "Extracting Archive ... ";
  my $ae = Archive::Extract->new( archive => $archive );
  $ae->extract or croak "Archive extraction failed!";
  print "Done\n";
  return $ae->extract_path;
}

sub ACTION_alien_code {
  my $self = shift;
  local $| = 1; # don't buffer stdout

  $self->alien_init_temp_dir;

  $self->config_data( name => $self->alien_name );
  $self->config_data( ffi_name => $self->alien_ffi_name );

  my $version;
  $version = $self->alien_check_installed_version
    unless $self->config_data('Force');

  if ($version) {
    $self->config_data( install_type => 'system' );
    $self->config_data( version => $version );
    my %system_provides;
    $system_provides{Cflags} = $self->alien_provides_cflags
      if defined $self->alien_provides_cflags;
    $system_provides{Libs}   = $self->alien_provides_libs
      if defined $self->alien_provides_libs;
    $self->config_data( system_provides => \%system_provides );
    return;
  }

  if ($self->config_data('ForceSystem')) {
    die "Requested system install, but system package not detected."
  }

  my @repos = $self->alien_create_repositories;

  my $cabinet = Alien::Base::ModuleBuild::Cabinet->new;

  foreach my $repo (@repos) {
    $cabinet->add_files( $repo->probe );
  }

  $cabinet->sort_files;

  {
    local $CWD = $self->alien_temp_dir;

    my $file = $cabinet->files->[0];

    unless (defined $file) {
      die "no files found in repository";
    }

    $version = $file->version;
    $self->config_data( alien_version => $version ); # Temporary setting, may be overridden later

    print "Downloading File: " . $file->filename . " ... ";
    my $filename = $file->get;
    croak "Error downloading file" unless $filename;
    print "Done\n";

    my $extract_path = _catdir(File::Spec->rel2abs($self->alien_extract_archive($filename)));

    $self->config_data( working_directory => $extract_path );
    $CWD = $extract_path;

    if ( $file->platform eq 'src' ) {
      print "Building library ... ";
      unless ($self->alien_do_commands('build')) {
        print "Failed\n";
        croak "Build not completed";
      }
    }

    print "Done\n";

  }

  $self->config_data( install_type => 'share' );
  $self->config_data( original_prefix => $self->alien_library_destination );

  my $pc = $self->alien_load_pkgconfig;
  my $pc_version = (
    $pc->{$self->alien_name} || $pc->{_manual}
  )->keyword('Version');

  unless (defined $version) {
    local $CWD = $self->config_data( 'working_directory' );
    $version = $self->alien_check_built_version
  }

  if (! $version && ! $pc_version) {
    print STDERR "If you are the author of this Alien dist, you may need to provide a an\n";
    print STDERR "alien_check_built_version method for your Alien::Base::ModuleBuild\n";
    print STDERR "class.  See:\n";
    print STDERR "https://metacpan.org/pod/Alien::Base::ModuleBuild#alien_check_built_version\n";
    carp "Library looks like it installed, but no version was determined";
    $self->config_data( version => 0 );
    return
  }

  if ( $version and $pc_version and versioncmp($version, $pc_version)) {
    carp "Version information extracted from the file name and pkgconfig data disagree";
  }

  $self->config_data( version => $pc_version || $version );

  # prevent building multiple times (on M::B::dispatch)
  $self->notes( 'ACTION_alien_completed' => 1 );

  return;
}

sub ACTION_alien_test {
  my $self = shift;
  print "Testing library (if applicable) ... ";
  if ($self->config_data( 'install_type' ) eq 'share') {
    if (defined (my $wdir = $self->config_data( 'working_directory' ))) {
      local $CWD = $wdir;
      $self->alien_do_commands('test') or die "Failed\n";
    }
  }
  print "Done\n";
}

sub ACTION_test {
  my $self = shift;
  $self->depends_on('alien_test');
  $self->SUPER::ACTION_test;
}

sub ACTION_install {
  my $self = shift;
  $self->SUPER::ACTION_install;
  if($self->alien_stage_install) {
    $self->alien_relocation_fixup;
  } else {
    $self->depends_on('alien_install');
  }
}

sub ACTION_alien_install {
  my $self = shift;

  local $| = 1; # don't buffer stdout

  return if $self->config_data( 'install_type' ) eq 'system';

  my $destdir = $self->destdir;
  my $target = $self->alien_library_destination;

  if(defined $destdir && !$self->alien_stage_install)
  {
    # Note: no longer necessary when doing a staged install
    # prefix the target directory with $destdir so that package builds
    # can install into a fake root
    $target = File::Spec->catdir($destdir, $target);
  }

  {
    local $CWD = $target;

    # The only form of introspection that exists is to see that the README file
    # which was placed in the share_dir (default _share) exists where we expect
    # after installation.
    unless ( -e 'README' ) {
      die "share_dir mismatch detected ($target)\n"
    }
  }

  if(!$self->config_data( 'finished_installing' ))
  {
    local $CWD = $self->config_data( 'working_directory' );
    local $ENV{DESTDIR} = $ENV{DESTDIR};
    $ENV{DESTDIR} = $destdir if defined $destdir && !$self->alien_stage_install;
    print "Installing library to $CWD ... ";
    $self->alien_do_commands('install') or die "Failed\n";
    print "Done\n";
  }

  if ( $self->alien_isolate_dynamic ) {
    local $CWD = $target;
    print "Isolating dynamic libraries ... ";
    mkdir 'dynamic' unless -d 'dynamic';
    foreach my $dir (qw( bin lib )) {
      next unless -d $dir;
      opendir(my $dh, $dir);
      my @dlls = grep { /\.so/ || /\.(dylib|bundle|la|dll|dll\.a)$/ } grep !/^\./, readdir $dh;
      closedir $dh;
      foreach my $dll (@dlls) {
        my $from = File::Spec->catfile($dir, $dll);
        my $to   = File::Spec->catfile('dynamic', $dll);
        unlink $to if -e $to;
        move($from, $to);
      }
    }
    print "Done\n";
  }

  # refresh metadata after library installation
  $self->alien_refresh_manual_pkgconfig( $self->alien_library_destination );
  $self->config_data( 'finished_installing' => 1 );

  if ( $self->notes( 'alien_blib_scheme') || $self->alien_stage_install) {

    ### TODO: empty if should be claned up before 0.017.
    ### we used to call process_files_by_extension('pm')
    ### here, but with gh#121 it is unecessary
    ## reinstall config_data to blib
    #$self->process_files_by_extension('pm');

  } else {

    # to refresh config_data
    $self->SUPER::ACTION_config_data;

    # reinstall config_data
    $self->SUPER::ACTION_install;

    # refresh the packlist
    $self->alien_refresh_packlist( $self->alien_library_destination );
  }
}

#######################
#  Pre-build Methods  #
#######################

sub alien_check_installed_version {
  my $self = shift;
  my $command = $self->alien_version_check;

  my %result = $self->do_system($command, {verbose => 0});
  my $version = ($result{success} && $result{stdout}) || 0;

  return $version;
}

sub alien_create_repositories {
  my $self = shift;

  ## get repository specs
  my $repo_default = $self->alien_repository_default;
  my $repo_specs = $self->alien_repository;

  # upconvert to arrayref if a single hashref is passed
  if (ref $repo_specs eq 'HASH') {
    $repo_specs = [ $repo_specs ];
  }

  my $module_env_part = uc $self->module_name;
  $module_env_part =~ s/^ALIEN:://;
  $module_env_part =~ s/::/_/g;
  my $env_prefix = 'ALIEN_'.$module_env_part.'_REPO_';

  # Catch e.g. 'ALIEN_MYMODULE_REPO_HTTP_HOST' variables to override repo config
  my @env_overrides =
    grep { index($_, $env_prefix) == 0 }
    keys %ENV;

  unless(@$repo_specs)
  {
    print STDERR "If you are the author of this Alien dist, you need to provide at least\n";
    print STDERR "one repository in your Build.PL.  See:\n";
    print STDERR "https://metacpan.org/pod/Alien::Base::ModuleBuild::API#alien_repository\n";
    croak "No repositories specified.";
  }

  my @repos;
  foreach my $repo ( @$repo_specs ) {
    #merge defaults into spec
    foreach my $key ( keys %$repo_default ) {
      next if defined $repo->{$key};
      $repo->{$key} = $repo_default->{$key};
    }

    $repo->{platform} = 'src' unless defined $repo->{platform};

    foreach my $var (@env_overrides) {
        my $var_tail = lc substr($var, length($env_prefix));
        my ($var_protocol, $var_key) = split /_/, $var_tail, 2;

        if ($repo->{protocol} eq $var_protocol) {
            $repo->{$var_key} = $ENV{$var};
        }
    }

    push @repos, $self->alien_repository_class($repo->{protocol} || 'default')->new( $repo );
  }

  # check validation, including c compiler for src type
  @repos =
    grep { $self->alien_validate_repo($_) }
    @repos;

  unless (@repos) {
    croak "No valid repositories available";
  }

  return @repos;

}

sub alien_validate_repo {
  my $self = shift;
  my ($repo) = @_;
  my $platform = $repo->{platform};

  # return true if platform is undefined
  return 1 unless defined $platform;

  # if $valid is src, check for c compiler
  if ($platform eq 'src') {
    return !$repo->{c_compiler_required} || $self->have_c_compiler;
  }

  # $valid is a string (OS) to match against
  return $self->os_type eq $platform;
}

sub alien_library_destination {
  my $self = shift;

  # send the library into the blib if running under the blib scheme
  my $lib_dir =
    $self->notes('alien_blib_scheme') || $self->alien_stage_install
    ? File::Spec->catdir( $self->base_dir, $self->blib, 'lib' )
    : $self->install_destination($self->alien_arch ? 'arch' : 'lib');

  my $dist_name = $self->dist_name;
  my $dest = _catdir( $lib_dir, qw/auto share dist/, $dist_name );
  return $dest;
}

# CPAN testers often run tests without installing modules, but rather add
# blib dirs to @INC, this is a problem, so here we try to deal with it
sub alien_detect_blib_scheme {
  my $self = shift;

  return 0 if $self->alien_stage_install;
  return $ENV{ALIEN_BLIB} if defined $ENV{ALIEN_BLIB};

  # check to see if Alien::Base::ModuleBuild is running from blib.
  # if so it is likely that this is the blib scheme

  (undef, my $dir, undef) = File::Spec->splitpath( __FILE__ );
  my @dirs = File::Spec->splitdir($dir);

  shift @dirs while @dirs && $dirs[0] ne 'blib';
  return unless @dirs;

  if ( $dirs[1] && $dirs[1] eq 'lib' ) {
    print qq{'blib' scheme is detected. Setting ALIEN_BLIB=1. If this has been done in error, please set ALIEN_BLIB and restart build process to disambiguate.\n};
    return 1;
  }

  carp q{'blib' scheme is suspected, but uncertain. Please set ALIEN_BLIB and restart build process to disambiguate. Setting ALIEN_BLIB=1 for now.};
  return 1;
}

###################
#  Build Methods  #
###################

sub _shell_config_generate
{
  my $scg = Shell::Config::Generate->new;
  $scg->comment(
    'this script sets the environment needed to build this package.',
    'generated by: ' . __FILE__,
  );
  $scg;
}

sub _filter_defines
{
  join ' ', grep !/^-D/, shellwords($_[0]);
}

sub _alien_bin_require {
  my($self, $mod) = @_;

  my $version = $self->alien_bin_requires->{$mod};

  unless(eval { $mod->can('new') })
  {
    my $pm = "$mod.pm";
    $pm =~ s/::/\//g;
    require $pm;
    $mod->VERSION($version) if $version;
  }

  if($mod->can('alien_helper')) {
    my $helpers = $mod->alien_helper;
    foreach my $k (keys %$helpers) {
      my $v = $helpers->{$k};
      next if defined $self->alien_helper->{$k};
      $self->alien_helper->{$k} = $v;
    }
  }
}

sub alien_do_system {
  my $self = shift;
  my $command = shift;

  local %ENV = %ENV;

  if ($self->config_data( 'msys' )) {
    $self->alien_bin_requires->{'Alien::MSYS'} ||= 0
  }

  my $config;

  foreach my $mod (keys %{ $self->alien_bin_requires }) {
    $self->_alien_bin_require($mod);

    my %path;

    if ($mod eq 'Alien::MSYS') {
      $path{Alien::MSYS->msys_path} = 1;
    } elsif ($mod eq 'Alien::TinyCC') {
      $path{Alien::TinyCC->path_to_tcc} = 1;
    } elsif ($mod eq 'Alien::Autotools') {
      $path{$_} = 1 for map { Alien::Autotools->$_ } qw( autoconf_dir automake_dir libtool_dir );
    } elsif (eval { $mod->can('bin_dir') }) {
      $path{$_} = 1 for $mod->bin_dir;
    }

    # remove anything already in PATH
    delete $path{$_} for grep { defined $_ } @PATH;
    # add anything else to start of PATH
    unshift @PATH, sort keys %path;

    $config ||= _shell_config_generate();
    $config->prepend_path( PATH => sort keys %path );
  }

  # If we are using autoconf, then create a site.config file
  # that specifies the same compiler and compiler linker flags
  # as were used for building Perl.  This is helpful for
  # mixed 32/64bit platforms where 32bit is the default but
  # Perl is 64bit.
  if($self->config_data('autoconf') && !defined $ENV{CONFIG_SITE}) {

    local $CWD;
    pop @CWD;

    my $ldflags = $Config{ldflags};
    $ldflags .= " -Wl,-headerpad_max_install_names"
      if $^O eq 'darwin';

    my %extra_site_config = %{ $self->alien_extra_site_config };
    open my $fh, '>', 'config.site';
    print $fh "CC='$Config{cc}'\n";
    # -D define flags should be stripped because they are Perl
    # specific.
    print $fh "CFLAGS='"   . join(" ", _filter_defines($Config{ccflags}), (delete($extra_site_config{CFLAGS}) ||"")) . "'\n";
    print $fh "CPPFLAGS='" . join(" ", _filter_defines($Config{cppflags}), (delete($extra_site_config{CPPFLAGS}) ||"")) . "'\n";
    print $fh "CXXFLAGS='" . join(" ", _filter_defines($Config{ccflags}), (delete($extra_site_config{CXXFLAGS}) ||"")) . "'\n";
    print $fh "LDFLAGS='"  . join(" ", $ldflags, (delete($extra_site_config{LDFLAGS}) ||"") ) . "'\n";
    for (keys %extra_site_config) {
        print $fh "$_='$extra_site_config{$_}'\n";
    }
    close $fh;

    my $config ||= _shell_config_generate();
    my $config_site = File::Spec->catfile($CWD, 'config.site');
    $config_site =~ s{\\}{/}g if $^O eq 'MSWin32';
    $config->set( CONFIG_SITE => $config_site );
    $ENV{CONFIG_SITE} = $config_site;
  }

  foreach my $key (sort keys %{ $self->alien_env })
  {
    my $value = $self->alien_interpolate($self->alien_env->{$key});
    defined $value ? $ENV{$key} = $value : delete $ENV{$key};
    $config ||= _shell_config_generate();
    $config->set( $key => $value );
  }

  if($config) {
    if($^O eq 'MSWin32') {
      local $CWD;
      pop @CWD;
      $config->generate_file( Shell::Guess->command_shell, 'env.bat' );
      $config->generate_file( Shell::Guess->cmd_shell,     'env.cmd' );
      $config->generate_file( Shell::Guess->power_shell,   'env.ps1' );
    } else {
      local $CWD;
      pop @CWD;
      $config->generate_file( Shell::Guess->bourne_shell,  'env.sh'  );
      $config->generate_file( Shell::Guess->c_shell,       'env.csh' );
    }
  }

  $self->do_system( ref($command) ? @$command : $command );
}

# alias for backwards compatibility
*_env_do_system = \&alien_do_system;

sub alien_check_built_version {
  return;
}

sub alien_do_commands {
  my $self = shift;
  my $phase = shift;

  my $attr = "alien_${phase}_commands";
  my $commands = $self->$attr();

  print "\n+ cd $CWD\n";

  foreach my $command (@$commands) {

    my %result = $self->alien_do_system( $command );
    unless ($result{success}) {
      carp "External command ($result{command}) failed! Error: $?\n";
      return 0;
    }
  }

  return 1;
}

# wrapper for M::B::do_system which interpolates alien_ vars first
# futher it either captures or tees depending on the value of $Verbose
sub do_system {
  my $self = shift;
  my $opts = ref $_[-1] ? pop : { verbose => 1 };

  my $verbose = $Verbose || $opts->{verbose};

  # prevent build process from cwd-ing from underneath us
  local $CWD;
  my $initial_cwd = $CWD;

  my @args = map { $self->alien_interpolate($_) } @_;

  print "+ @args\n";

  my $old_super_verbose = $self->verbose;
  $self->verbose(0);
  my ($out, $err, $success) =
    $verbose
    ? tee     { $self->SUPER::do_system(@args) }
    : capture { $self->SUPER::do_system(@args) }
  ;
  $self->verbose($old_super_verbose);

  my %return = (
    stdout => $out,
    stderr => $err,
    success => $success,
    command => join(' ', @args),
  );

  # restore wd
  $CWD = $initial_cwd;

  return wantarray ? %return : $return{success};  ## no critic (Policy::Community::Wantarray)
}

sub _alien_execute_helper {
  my($self, $helper) = @_;
  my $code = $self->alien_helper->{$helper};
  die "no such helper: $helper" unless defined $code;

  if(ref($code) ne 'CODE') {
    my $perl = $code;
    $code = sub {
      my $value = eval $perl; ## no critic (Policy::BuiltinFunctions::ProhibitStringyEval)
      die $@ if $@;
      $value;
    };
  }

  $code->();
}

sub alien_interpolate {
  my $self = shift;
  my ($string) = @_;

  my $prefix = $self->alien_exec_prefix;
  my $configure = $self->alien_configure;
  my $share  = $self->alien_library_destination;
  my $name   = $self->alien_name || '';

  # substitute:
  #   install location share_dir (placeholder: %s)
  $string =~ s/(?<!\%)\%s/$share/g;
  #   local exec prefix (ph: %p)
  $string =~ s/(?<!\%)\%p/$prefix/g;
  #   correct incantation for configure on platform
  $string =~ s/(?<!\%)\%c/$configure/g;
  #   library name (ph: %n)
  $string =~ s/(?<!\%)\%n/$name/g;
  #   current interpreter ($^X) (ph: %x)
  my $perl = $self->perl;
  $string =~ s/(?<!\%)\%x/$perl/g;
  $perl =~ s{\\}{/}g if $^O eq 'MSWin32';
  $string =~ s/(?<!\%)\%X/$perl/g;

  # Version, but only if needed.  Complain if needed and not yet
  # stored.
  if ($string =~ /(?<!\%)\%v/) {
    my $version = $self->config_data( 'alien_version' );
    if ( ! defined( $version ) ) {
      carp "Version substution requested but unable to identify";
    } else {
      $string =~ s/(?<!\%)\%v/$version/g;
    }
  }

  $string =~ s/(?<!\%)\%\{([a-zA-Z_][a-zA-Z_0-9]+)\}/$self->_alien_execute_helper($1)/eg;

  #remove escapes (%%)
  $string =~ s/\%(?=\%)//g;

  return $string;
}

sub alien_exec_prefix {
  my $self = shift;
  if ( $self->is_windowsish ) {
    return '';
  } else {
    return './';
  }
}

sub alien_configure {
  my $self = shift;
  my $configure;
  if ($self->config_data( 'msys' )) {
    $configure = 'sh configure';
  } else {
    $configure = './configure';
  }
  if ($self->alien_autoconf_with_pic) {
    $configure .= ' --with-pic';
  }
  $configure;
}

########################
#  Post-Build Methods  #
########################

sub alien_load_pkgconfig {
  my $self = shift;

  my $dir = _catdir($self->config_data( 'working_directory' ));
  my $pc_files = $self->rscan_dir( $dir, qr/\.pc$/ );

  my %pc_objects = map {
    my $pc = Alien::Base::PkgConfig->new($_);
    $pc->make_abstract( pcfiledir => $dir );
    ($pc->{package}, $pc)
  } @$pc_files;

  $pc_objects{_manual} = $self->alien_generate_manual_pkgconfig($dir)
    or croak "Could not autogenerate pkgconfig information";

  $self->config_data( pkgconfig => \%pc_objects );
  return \%pc_objects;
}

sub alien_refresh_manual_pkgconfig {
  my $self = shift;
  my ($dir) = @_;

  my $pc_objects = $self->config_data( 'pkgconfig' );
  $pc_objects->{_manual} = $self->alien_generate_manual_pkgconfig($dir)
    or croak "Could not autogenerate pkgconfig information";

  $self->config_data( pkgconfig => $pc_objects );

  return 1;
}

sub alien_generate_manual_pkgconfig {
  my $self = shift;
  my ($dir) = _catdir(shift);

  my $paths = $self->alien_find_lib_paths($dir);

  my @L =
    map { "-L$_" }
    map { _catdir( '${pcfiledir}', $_ ) }
    @{$paths->{lib}};

  my $provides_libs = $self->alien_provides_libs;

  #if no provides_libs then generate -l list from found files
  unless ($provides_libs) {
    my @files = map { "-l$_" } @{$paths->{lib_files}};
    $provides_libs = join( ' ', @files );
  }

  my $libs = join( ' ', @L, $provides_libs );

  my @I =
    map { "-I$_" }
    map { _catdir( '${pcfiledir}', $_ ) }
    @{$paths->{inc}};

  my $provides_cflags = $self->alien_provides_cflags;
  push @I, $provides_cflags if $provides_cflags;
  my $cflags = join( ' ', @I );

  my $manual_pc = Alien::Base::PkgConfig->new({
    package  => $self->alien_name,
    vars     => {
      pcfiledir => $dir,
    },
    keywords => {
      Cflags  => $cflags || '',
      Libs    => $libs || '',
      Version => '',
    },
  });

  return $manual_pc;
}

sub _alien_file_pattern_dynamic {
  my $self = shift;
  my $ext = $self->config('so'); #platform specific .so extension
  return qr/\.[\d.]*(?<=\.)$ext[\d.]*(?<!\.)|(\.h|$ext)$/;
};

sub _alien_file_pattern_static {
  my $self = shift;
  my $ext = quotemeta $self->config('lib_ext');
  return qr/(\.h|$ext)$/;
}

sub alien_find_lib_paths {
  my $self = shift;
  my ($dir) = @_;

  my $libs = $self->alien_provides_libs;
  my @libs;
  @libs = map { my $f = $_; $f =~ s/^-l//; $f } grep { /^-l/ } split /\s+/, $libs if $libs;

  my (@lib_files, @lib_paths, @inc_paths);

  foreach my $file_pattern ($self->_alien_file_pattern_static, $self->_alien_file_pattern_dynamic) {

    my @files =
      map { File::Spec->abs2rel( $_, $dir ) }  # make relative to $dir
      grep { ! -d }
      @{ $self->_rscan_destdir( $dir, $file_pattern ) };

    for (@files) {

      my ($file, $path, $ext) = fileparse( $_, $file_pattern );
      next unless $ext; # just in case

      $path = File::Spec->catdir($path); # remove trailing /

      if ($ext eq '.h') {
        push @inc_paths, $path;
        next;
      }

      $file =~ s/^lib//;

      if (@libs) {
        next unless any { $file eq $_ } @libs;
      }

      next if any { $file eq $_ } @lib_files;

      push @lib_files, $file;
      push @lib_paths, $path;
    }
  }

  @lib_files = uniq @lib_files;
  @lib_files = sort @lib_files;

  @lib_paths = uniq @lib_paths;
  @inc_paths = uniq @inc_paths;

  return { lib => \@lib_paths, inc => \@inc_paths, lib_files => \@lib_files };
}

sub alien_refresh_packlist {
  my $self = shift;
  my $dir = shift || croak "Must specify a directory to include in packlist";

  return unless $self->create_packlist;

  my %installed_args;
  $installed_args{extra_libs} = [map { File::Spec->catdir($self->destdir, $_) } @INC]
    if defined $self->destdir;

  my $inst = ExtUtils::Installed->new( %installed_args );
  my $packlist = $inst->packlist( $self->module_name );
  print "Using " .  $packlist->packlist_file . "\n";

  my $changed = 0;
  my $files = $self->_rscan_destdir($dir);
  # This is kind of strange, but MB puts the destdir paths in the
  # packfile, when arguably it should not.  Usually you will want
  # to turn off packlists when you you are building an rpm anyway,
  # but for the sake of maximum compat with MB we add the destdir
  # back in after _rscan_destdir has stripped it out.
  $files = [ map { File::Spec->catdir($self->destdir, $_) } @$files ]
    if defined $self->destdir;
  for my $file (@$files) {
    next if $packlist->{$file};
    print "Adding $file to packlist\n";
    $changed++;
    $packlist->{$file}++;
  };

  $packlist->write if $changed;
}

sub alien_relocation_fixup {
  my($self) = @_;

  # so far relocation fixup is only needed on OS X
  return unless $^O eq 'darwin';

  my $dist_name = $self->dist_name;
  my $share = _catdir( $self->install_destination($self->alien_arch ? 'arch' : 'lib'), qw/auto share dist/, $dist_name );

  require File::Find;
  File::Find::find(sub {
    if(/\.dylib$/)
    {
      # save the original mode and make it writable
      my $mode = (stat $File::Find::name)[2];
      chmod 0755, $File::Find::name unless -w $File::Find::name;

      my @cmd = (
        'install_name_tool',
        '-id' => $File::Find::name,
        $File::Find::name,
      );
      print "+ @cmd\n";
      system @cmd;

      # restore the original permission mode
      chmod $mode, $File::Find::name;
    }
  }, $share);
}

sub _rscan_destdir {
  my($self, $dir, $pattern) = @_;
  my $destdir = $self->destdir;
  $dir = _catdir($destdir, $dir) if defined $destdir;
  my $files = $self->rscan_dir($dir, $pattern);
  $files = [ map { my $dir = $_; $dir =~ s/^$destdir//; $dir } @$files ] if defined $destdir;
  $files;
}

# File::Spec uses \ as the file separator on MSWin32, which makes sense
# since it is the default "native" file separator, but in practice / is
# supported everywhere that matters and is significantly less problematic
# in a number of common use cases (e.g. shell quoting).  This is a short
# cut _catdir for this rather common pattern where you want catdir with
# / as the file separator on Windows.
sub _catdir {
  my $dir = File::Spec->catdir(@_);
  $dir =~ s{\\}{/}g if $^O eq 'MSWin32';
  $dir;
}

sub alien_install_network {
  defined $ENV{ALIEN_INSTALL_NETWORK} ? !!$ENV{ALIEN_INSTALL_NETWORK} : 1;
}

sub alien_download_rule {

  if(defined $ENV{ALIEN_DOWNLOAD_RULE}) {
    return 'warn' if $ENV{ALIEN_DOWNLOAD_RULE} eq 'default';
    return $ENV{ALIEN_DOWNLOAD_RULE} if $ENV{ALIEN_DOWNLOAD_RULE} =~ /^(warn|digest|encrypt|digest_or_encrypt|digest_and_encrypt)$/;
    warn "unknown ALIEN_DOWNLOAD_RULE \"ALIEN_DOWNLOAD_RULE\", using \"warn\" instead";
  }

  return 'warn';
}

1;

=pod

=encoding UTF-8

=head1 NAME

Alien::Base::ModuleBuild - A Module::Build subclass for building Alien:: modules and their libraries

=head1 VERSION

version 1.17

=head1 SYNOPSIS

In your Build.PL:

 use Alien::Base::ModuleBuild;
 
 my $builder = Alien::Base::ModuleBuild->new(
   module_name => 'Alien::MyLibrary',
 
   configure_requires => {
     'Alien::Base::ModuleBuild' => '0.005',
     'Module::Build' => '0.28'
   },
   requires => {
     'Alien::Base' => '0.005',
   },
 
   alien_name => 'mylibrary', # the pkg-config name if you want
                              # to use pkg-config to discover
                              # system version of the mylibrary
 
   alien_repository => {
     protocol => 'https',
     host     => 'myhost.org',
     location => '/path/to/tarballs',
     pattern  => qr{^mylibrary-([0-9\.]+)\.tar\.gz$},
   },
 
   # this is the default:
   alien_build_commands => [
     "%c --prefix=%s", # %c is a platform independent version of ./configure
     "make",
   ],
 
   # this is the default for install:
   alien_install_commands => [
     "make install",
   ],
 
   alien_isolate_dynamic => 1,
 );

=head1 DESCRIPTION

B<NOTE>: Please consider for new development of L<Alien>s that you use
L<Alien::Build> and L<alienfile> instead.  Like this module they work
with L<Alien::Base>.  Unlike this module they are more easily customized
and handle a number of corner cases better.  For a good place to start,
please see L<Alien::Build::Manual::AlienAuthor>.  Although the
Alien-Base / Alien-Build team will continue to maintain this module,
(we will continue to fix bugs where appropriate), we aren't adding any
new features to this module.

This is a subclass of L<Module::Build>, that with L<Alien::Base> allows
for easy creation of Alien distributions.  This module is used during the
build step of your distribution.  When properly configured it will

=over 4

=item use pkg-config to find and use the system version of the library

=item download, build and install the library if the system does not provide it

=back

=head1 METHODS

=head2 alien_check_installed_version

[version 0.001]

 my $version = $abmb->alien_check_installed_version;

This function determines if the library is already installed as part of
the operating system, and returns the version as a string.  If it can't
be detected then it should return empty list.

The default implementation relies on C<pkg-config>, but you will probably
want to override this with your own implementation if the package you are
building does not use C<pkg-config>.

=head2 alien_check_built_version

[version 0.006]

 my $version = $amb->alien_check_built_version;

This function determines the version of the library after it has been
built from source.  This function only gets called if the operating
system version can not be found and the package is successfully built.
The version is returned on success.  If the version can't be detected
then it should return empty list.  Note that failing to detect a version
is considered a failure and the corresponding C<./Build> action will
fail!

Any string is valid as a version as far as L<Alien::Base> is concerned.
The most useful value would be a number or dotted decimal that most
software developers recognize and that software tools can differentiate.
In some cases packages will not have a clear version number, in which
case the string C<unknown> would be a reasonable choice.

The default implementation relies on C<pkg-config>, and other heuristics,
but you will probably want to override this with your own implementation
if the package you are building does not use C<pkg-config>.

When this method is called, the current working directory will be the
build root.

If you see an error message like this:

 Library looks like it installed, but no version was determined

After the package is built from source code then you probably need to
provide an implementation for this method.

=head2 alien_extract_archive

[version 0.024]

  my $dir = $amb->alien_extract_archive($filename);

This function unpacks the given archive and returns the directory
containing the unpacked files.

The default implementation relies on L<Archive::Extract> that is able
to handle most common formats. In order to handle other formats or
archives requiring some special treatment you may want to override
this method.

=head2 alien_do_system

[version 0.024]

  my %result = $amb->alien_do_system($cmd)

Similar to
L<Module::Build's do_system|Module::Build::API/"do_system($cmd, @args)">,
also sets the path and several environment variables in accordance
to the object configuration (i.e. C<alien_bin_requires>) and
performs the interpolation of the patterns described in
L<Alien::Base::ModuleBuild::API/"COMMAND INTERPOLATION">.

Returns a set of key value pairs including C<stdout>, C<stderr>,
C<success> and C<command>.

=head2 alien_do_commands

 $amb->alien_do_commands($phase);

Executes the commands for the given phase.

=head2 alien_interpolate

 my $string = $amb->alien_interpolate($string);

Takes the input string and interpolates the results.

=head2 alien_install_network

[version 1.16]

 my $bool = $amb->alien_install_network;

Returns true if downloading source from the internet is allowed.  This
is true unless C<ALIEN_INSTALL_NETWORK> is defined and false.

=head2 alien_download_rule

[version 1.16]

 my $rule = $amb->alien_download_rule;

This will return one of C<warn>, C<digest>, C<encrypt>, C<digest_or_encrypt>
or C<digest_and_encrypt>.  This is based on the C<ALIEN_DOWNLOAD_RULE>
environment variable.

=head1 GUIDE TO DOCUMENTATION

The documentation for C<Module::Build> is broken up into sections:

=over

=item General Usage (L<Module::Build>)

This is the landing document for L<Alien::Base::ModuleBuild>'s parent class.
It describes basic usage and background information.
Its main purpose is to assist the user who wants to learn how to invoke
and control C<Module::Build> scripts at the command line.

It also lists the extra documentation for its use. Users and authors of Alien::
modules should familiarize themselves with these documents. L<Module::Build::API>
is of particular importance to authors.

=item Alien-Specific Usage (L<Alien::Base::ModuleBuild>)

This is the document you are currently reading.

=item Authoring Reference (L<Alien::Base::Authoring>)

This document describes the structure and organization of
C<Alien::Base> based projects, beyond that contained in
C<Module::Build::Authoring>, and the relevant concepts needed by authors who are
writing F<Build.PL> scripts for a distribution or controlling
C<Alien::Base::ModuleBuild> processes programmatically.

Note that as it contains information both for the build and use phases of
L<Alien::Base> projects, it is located in the upper namespace.

=item API Reference (L<Alien::Base::ModuleBuild::API>)

This is a reference to the C<Alien::Base::ModuleBuild> API beyond that contained
in C<Module::Build::API>.

=item Using the resulting L<Alien> (L<Alien::Build::Manual::AlienUser>)

Once you have an L<Alien> you or your users can review this manual for how to use
it.  Generally speaking you should have some useful usage information in your
L<Alien>'s POD, but some authors choose to direct their users to this manual
instead.

=item Using L<Alien::Build> instead (L<Alien::Build::Manual>)

As mentioned at the top, you are encouraged to use the L<Alien::Build> and
L<alienfile> system instead.  This manual is a starting point for the other
L<Alien::Build> documentation.

=back

=head1 ENVIRONMENT

=over 4

=item B<ALIEN_ARCH>

Set to a true value to install to an arch-specific directory.

=item B<ALIEN_DOWNLOAD_RULE>

This controls security options for fetching alienized packages over the internet.
The legal values are:

=over 4

=item C<warn>

Warn if the package is either unencrypted or lacks a digest.  This is currently
the default, but will change in the near future.

=item C<digest>

Fetch will not happen unless there is a digest for the alienized package.

=item C<encrypt>

Fetch will not happen unless via an encrypted protocol like C<https>, or if the
package is bundled with the L<Alien>.

=item C<digest_or_encrypt>

Fetch will only happen if the alienized package has a cryptographic signature digest,
or if an encrypted protocol like C<https> is used, or if the package is bundled with
the L<Alien>.  This will be the default in the near future.

=item C<digest_and_encrypt>

Fetch will only happen if the alienized package has a cryptographic signature digest,
and is fetched via a secure protocol (like C<https>).  Bundled packages are also
considered fetch via a secure protocol, but will still require a digest.

=back

=item B<ALIEN_FORCE>

Skips checking for an installed version and forces reinstalling the Alien target.

=item B<ALIEN_INSTALL_NETWORK>

If true (the default if not defined), then network installs will be allowed.
Set to C<0> or another false value to turn off network installs.

=item B<ALIEN_INSTALL_TYPE>

Set to C<share> or C<system> to override the install type.  Set to C<default> or unset
to restore the default.

=item B<ALIEN_VERBOSE>

Enables verbose output from L<M::B::do_system|Module::Build#do_system>.

=item B<ALIEN_${MODULENAME}_REPO_${PROTOCOL}_${KEY}>

Overrides $KEY in the given module's repository configuration matching $PROTOCOL.
For example, C<ALIEN_OPENSSL_REPO_FTP_HOST=ftp.example.com>.

=back

=head1 SEE ALSO

=over

=item L<Alien::Build>

=item L<alienfile>

=item L<Alien::Build::Manual::AlienAuthor>

=item L<Alien>

=back

=head1 THANKS

Thanks also to

=over

=item Christian Walde (Mithaldu)

For productive conversations about component interoperability.

=item kmx

For writing Alien::Tidyp from which I drew many of my initial ideas.

=item David Mertens (run4flat)

For productive conversations about implementation.

=item Mark Nunberg (mordy, mnunberg)

For graciously teaching me about rpath and dynamic loading,

=back

=head1 AUTHOR

Original author: Joel A Berger E<lt>joel.a.berger@gmail.comE<gt>

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

David Mertens (run4flat)

Mark Nunberg (mordy, mnunberg)

Christian Walde (Mithaldu)

Brian Wightman (MidLifeXis)

Graham Ollis (plicease)

Zaki Mughal (zmughal)

mohawk2

Vikas N Kumar (vikasnkumar)

Flavio Poletti (polettix)

Salvador Fandiño (salva)

Gianni Ceccarelli (dakkar)

Pavel Shaydo (zwon, trinitum)

Kang-min Liu (劉康民, gugod)

Nicholas Shipp (nshp)

Petr Písař (ppisar)

Alberto Simões (ambs)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2022 by Joel A Berger.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
__POD__


