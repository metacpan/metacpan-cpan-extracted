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
use File::Temp qw( tempfile tempdir );
use File::Copy qw(cp);
use File::Path qw(make_path);
use IPC::Open3;
use Symbol qw(gensym);
use File::ShareDir qw(dist_dir dist_file);
use JSON qw( encode_json decode_json );
use List::Util qw( pairs uniq );
use Log::Log4perl::Level;
use Scalar::Util qw( reftype );
use YAML::Tiny qw(Load Dump LoadFile);
use version;

use Role::Tiny::With;

with 'CPAN::Maker::Role::ModuleUtils';
with 'CPAN::Maker::Role::FileUtils';

our $VERSION = '2.0.5';

__PACKAGE__->use_log4perl( level => 'info', color => $FALSE );

use parent qw(CLI::Simple);

caller or exit __PACKAGE__->main();

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
sub cmd_create_cpanfile {
########################################################################
  my ($self) = @_;

  my @file_list = $self->get_args;

  die "ERROR: usage cpan-maker create-cpanfile file1 file2 ...\n"
    if !@file_list;

  my @requires;

  foreach (@file_list) {
    push @requires, split /\n/xsm, slurp($_);
  }

  my @filtered_requires;

  foreach (@requires) {
    next if /^[#]/xsm;
    s/^[+]//xsm;
    push @filtered_requires, $_;
  }

  @requires = uniq sort @filtered_requires;

  my $fh = choose {
    my $outfile = $self->get_outfile;

    return \*STDOUT
      if $outfile eq q{-};

    $outfile //= 'cpanfile';

    $self->set_outfile($outfile);

    open my $fh, '>', $outfile
      or die "ERROR: could not open cpanfile for writing: $OS_ERROR\n";

    return $fh;
  };

  foreach (@requires) {
    my (@module) = split /\s+/xsm, $_;

    my $req = {
      module  => shift @module,
      version => shift @module,
    };

    if (@module) {
      foreach my $e (@module) {
        die "ERROR: invalid entry only dist, url or mirror permitted after version\n"
          if $e !~ /^(?:dist=|url=|mirror=)/xsm;

        my (@args) = split /=/, $e;
        $req->{ $args[0] } = $args[1];
      }
    }

    if ( keys %{$req} == 2 ) {
      print {$fh} sprintf qq{requires "%s", "%s";\n}, $req->{module} // q{}, $req->{version} // q{};
    }
    else {
      my @extra;
      foreach ( keys %{$req} ) {
        next if /^(?:module|version)/xsm;
        push @extra, sprintf '  %s => "%s"', $_, $req->{$_};
      }

      print {$fh} sprintf qq{requires "%s", "%s";\n}, $req->{module} // q{}, $req->{version} // q{};

      print {$fh} sprintf ",\n%s", join ",\n", @extra;
      print {$fh} ";\n";
    }
  }

  if ( $self->get_outfile ne '-' ) {
    close $fh;
  }

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

  my %args = $self->parse_buildspec;

  $self->_apply_buildspec_args(%args);

  $self->get_logger->debug( sub { return Dumper( [ args => \%args ] ) } );

  if ( $self->get_dryrun ) {
    print {*STDOUT} Dumper( \%args );
    return $SUCCESS;
  }

  my $builddir = tempdir( 'cpan-maker-XXXXXX', TMPDIR => $TRUE, CLEANUP => !$self->get_no_cleanup );

  $self->get_logger->debug("builddir: $builddir");

  my $cwd          = getcwd;
  my $project_root = $self->get_project_root // $cwd;

  chdir $project_root
    or die "ERROR: could not chdir to $project_root: $OS_ERROR\n";

  my $provides_file = $self->stage_distribution( builddir => $builddir, args => \%args );

  $self->set_work_dir($builddir);

  {
    my $makefile_pl = "$builddir/Makefile.PL";

    $self->get_logger->info("writing $makefile_pl");

    # write provides into cwd ($project_root) before write_makefile reads it;
    # it will be copied to $builddir after chdir
    if ( $provides_file && -e $provides_file ) {
      cp( $provides_file, 'provides' )
        or die "ERROR: could not copy provides file: $OS_ERROR\n";
    }

    $self->write_makefile( dest => $makefile_pl );
  }

  chdir $builddir
    or die "ERROR: could not chdir to $builddir: $OS_ERROR\n";

  # move provides into builddir (write_makefile may have already used it;
  # it must be in builddir for make manifest to find it, but excluded via MANIFEST.SKIP)
  if ( -e "$project_root/provides" ) {
    cp( "$project_root/provides", "$builddir/provides" )
      or die "ERROR: could not copy provides to builddir: $OS_ERROR\n";
    unlink "$project_root/provides";
  }

  my $destdir = $self->get_destdir // $cwd;

  # write MANIFEST.SKIP to prevent MYMETA files, Makefile, and
  # intermediate build artifacts from being included in the distribution
  {
    open my $fh, '>', 'MANIFEST.SKIP'
      or die "ERROR: could not write MANIFEST.SKIP: $OS_ERROR\n";
    print {$fh} "Makefile\$\nMYMETA.json\nMYMETA.yml\nprovides\n";
    close $fh;
  }

  my @steps = ( [ $^X, 'Makefile.PL' ], [ 'make', 'manifest' ], [ 'make', 'dist' ], );

  push @steps, [ 'make', 'test' ]
    if !$self->get_skip_tests;

  for my $step (@steps) {
    my $rc = $self->_run_cmd( @{$step} );
    if ( $rc != 0 ) {
      chdir $cwd;
      die sprintf "ERROR: '%s' failed with exit code %d\n", join( $SPACE, @{$step} ), $rc;
    }
  }

  my @tarballs = glob '*.tar.gz';

  die "ERROR: no tarball produced by make dist\n"
    if !@tarballs;

  my $tarball = ( sort @tarballs )[-1];

  cp( $tarball, $destdir )
    or die "ERROR: could not copy $tarball to $destdir: $OS_ERROR\n";

  $self->get_logger->info("distribution written to $destdir/$tarball");

  if ( $self->get_preserve_makefile ) {
    cp( 'Makefile.PL', $destdir )
      or die "ERROR: could not copy Makefile.PL to $destdir: $OS_ERROR\n";
  }

  chdir $cwd;

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

  return $self->write_makefile( dest => \*STDOUT ) ? $SUCCESS : $FAILURE;
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
  my ( $self, %params ) = @_;

  my $dest = $params{dest} // \*STDOUT;

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

  if ( ref $dest ) {
    print {$dest} $MAKEFILE;
  }
  else {
    open my $fh, '>', $dest
      or die "ERROR: could not open $dest for writing: $OS_ERROR\n";
    print {$fh} $MAKEFILE;
    close $fh
      or die "ERROR: could not close $dest: $OS_ERROR\n";
  }

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
\t-\$(NOECHO) ln -sf \$(INSTALLMAN3DIR)/$module.3pm \$(DESTINSTALLMAN3DIR)/$alias.3pm; \
\t\$(NOECHO) echo \$(INSTALLMAN3DIR)/$alias.3pm >> \$(DESTINSTALLSITEARCH)/auto/\$(FULLEXT)/.packlist
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
sub _apply_buildspec_args {
########################################################################
  my ( $self, %args ) = @_;

  my %map = (
    '-m' => 'module',
    '-a' => 'author',
    '-d' => 'abstract',
    '-D' => 'requires',
    '-T' => 'test_requires',
    '-B' => 'build_requires',
    '-Y' => 'recommends',
    '-M' => 'min_perl_version',
    '-V' => 'version_from',
    '-l' => 'module_path',
    '-S' => 'scripts_path',
    '-t' => 'tests_path',
    '-F' => 'postamble',
    '-R' => 'recurse',
  );

  for my $flag ( keys %map ) {
    next if !exists $args{$flag};
    my $val = $args{$flag};
    $val =~ s/^'(.*)'$/$1/xsm  # strip shell quoting added by parse_project
      if defined $val;
    $self->set( $map{$flag}, $val );
  }

  return;
}

########################################################################
# _run_cmd: run an external command, logging its output.
#
# STDERR is deliberately merged into STDOUT (via '>&STDOUT') so we read
# a SINGLE pipe with a SINGLE loop below. This is not cosmetic -- it
# avoids a classic IPC::Open3 deadlock.
#
# The deadlock we are avoiding: open3 connects the child's STDOUT and
# STDERR to two separate pipes, each with a fixed (~64K) kernel buffer.
# If the parent drains one pipe to EOF *before* reading the other (e.g.
# `while (<$out>) {...} while (<$err>) {...}`), a child that emits more
# than a buffer's worth on the *second* stream blocks in write(), the
# parent won't read that stream until the first hits EOF, and the first
# never EOFs because the child can't exit -- both sides wait forever.
#
# This stayed hidden for small services (output < one buffer) and only
# surfaced on large APIs like CloudFront, whose `make manifest`/`make
# dist` emit enough output to fill a pipe. Merging the streams removes
# the second pipe entirely, so there is nothing to block on.
#
# Do NOT "fix" this by making the handles hot/autoflush -- that changes
# WHEN bytes are written, not the pipe capacity or who drains it, and if
# anything makes the deadlock more reliable. The only real fixes are to
# drain both streams concurrently or to merge them (done here). If the
# STDERR/STDOUT split is ever needed back, switch to IPC::Run3, which
# spools each stream to a temp file and sidesteps the deadlock that way.
########################################################################

########################################################################
sub _run_cmd {
########################################################################
  my ( $self, @cmd ) = @_;

  $self->get_logger->info( join $SPACE, @cmd );

  my $pid = open3( my $in, my $out, '>&STDOUT', @cmd );  # child STDERR dup'd onto STDOUT
  close $in;

  while ( my $line = <$out> ) {
    chomp $line;
    $self->get_logger->info($line);
  }

  waitpid $pid, 0;

  return $CHILD_ERROR >> 8;
}

########################################################################
sub stage_distribution {
########################################################################
  my ( $self, %params ) = @_;

  my ( $builddir, $args ) = @params{qw(builddir args)};

  my $buildspec    = $self->read_buildspec( $self->get_buildspec );
  my $project_root = $self->get_project_root;

  # --- lib/ ---
  my $pm_path = $self->get_module_path // $buildspec->{path}{'pm-module'} // 'lib';

  $pm_path = "$project_root/$pm_path"
    if $pm_path !~ /^\//xsm;

  if ( -d $pm_path ) {
    my ( $provides_fh, $provides_file ) = tempfile( 'cpan-maker-provides-XXXXXX', TMPDIR => $TRUE );

    find(
      { follow => $TRUE,
        wanted => sub {
          return if -d $_;
          return if !/\.(?:pm|pod)$/xsm;

          my $rel = $File::Find::name;
          $rel =~ s{^\Q$pm_path\E/?}{}xsm;

          my $dest = "$builddir/lib/$rel";
          make_path( File::Basename::dirname($dest) );
          cp( $File::Find::name, $dest )
            or die "ERROR: could not copy $File::Find::name to $dest: $OS_ERROR\n";

          # record .pm files for the provides list
          if (/\.pm$/xsm) {
            my $module = $rel;
            $module =~ s{/}{::}xsmg;
            $module =~ s{\.pm$}{}xsm;
            print {$provides_fh} "$module\n";
          }
        },
      },
      $pm_path,
    );

    close $provides_fh;
    $params{provides_file_ref} = \$provides_file;
  }

  # --- bin/ (exe-files) ---
  my $exe_path = $self->get_exec_path // $buildspec->{path}{'exe-files'};

  if ($exe_path) {
    $exe_path = "$project_root/$exe_path"
      if $exe_path !~ /^\//xsm;

    if ( -d $exe_path ) {
      make_path("$builddir/bin");

      my ( $list_fh, $list_file ) = tempfile( 'cpan-maker-exe-XXXXXX', TMPDIR => $TRUE );

      find(
        { follow => $TRUE,
          wanted => sub {
            return if -d $_ || !-x $_;
            my $dest = "$builddir/bin/" . File::Basename::basename($File::Find::name);
            cp( $File::Find::name, $dest )
              or die "ERROR: could not copy $File::Find::name: $OS_ERROR\n";
            print {$list_fh} "$dest\n";
          },
        },
        $exe_path,
      );

      close $list_fh;
      $self->set_exec_path($list_file);
    }
  }

  # --- t/ ---
  my $tests_path = $self->get_tests_path // $buildspec->{path}{tests};

  if ($tests_path) {
    $tests_path = "$project_root/$tests_path"
      if $tests_path !~ /^\//xsm;

    if ( -d $tests_path ) {
      make_path("$builddir/t");
      find(
        { follow => $TRUE,
          wanted => sub {
            return if -d $_ || !/\.t$/xsm;
            cp( $File::Find::name, "$builddir/t/" . File::Basename::basename($File::Find::name) )
              or die "ERROR: could not copy $File::Find::name: $OS_ERROR\n";
          },
        },
        $tests_path,
      );
    }
  }

  # --- extra-files ---
  my $extra_files = $buildspec->{'extra-files'};

  if ($extra_files) {
    my @file_list;

    for my $e ( @{$extra_files} ) {
      if ( !ref $e ) {
        push @file_list,
          $self->fetch_file_list(
          file_list    => [$e],
          destination  => $EMPTY,
          project_root => $project_root,
          );
      }
      elsif ( ref $e eq 'HASH' ) {
        my ($destdir) = keys %{$e};
        my $file_list = $e->{$destdir};
        push @file_list,
          $self->fetch_file_list(
          file_list    => $file_list,
          destination  => $destdir,
          project_root => $project_root,
          );
      }
    }

    for my $entry (@file_list) {
      my ( $src, $dest ) = split /\s+/xsm, $entry, 2;

      $src  = "$project_root/$src" if $src !~ /^\//xsm;
      $dest = $dest ? "$builddir/$dest" : "$builddir/" . File::Basename::basename($src);

      make_path( File::Basename::dirname($dest) );
      cp( $src, $dest )
        or die "ERROR: could not copy $src to $dest: $OS_ERROR\n";
    }
  }

  # --- postamble ---
  my $postamble = $self->get_postamble // $buildspec->{postamble};

  if ( $postamble && -e $postamble ) {
    cp( $postamble, "$builddir/postamble" )
      or die "ERROR: could not copy postamble: $OS_ERROR\n";
  }

  my $provides_file = $params{provides_file_ref} ? ${ $params{provides_file_ref} } : $EMPTY;

  return $provides_file;
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
    color!
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
    outfile|o=s
    pager|P!
    pl-files=s
    postamble=s
    project-root|p=s
    recommends=s
    recurse
    require-versions|R!
    requires|r=s
    resources=s
    destdir=s
    no-cleanup
    preserve-makefile
    skip-tests
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
    'build'           => \&cmd_build,
    'create-cpanfile' => \&cmd_create_cpanfile,
    'default'         => \&cmd_build,
    'validate'        => \&cmd_validate,
    'version'         => \&cmd_version,
    'write-makefile'  => \&cmd_makefile,
  );

  my $cli = CPAN::Maker->new(
    commands        => \%commands,
    option_specs    => \@option_specs,
    default_options => $default_options,
  );

  return $cli->run();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Maker - create a CPAN distribution

=head1 SYNOPSIS

 cpan-maker -b buildspec.yml
 cpan-maker build -b buildspec.yml
 cpan-maker create-cpanfile file1 file2 ...

=head2 Options

 -a, --author                author
 -A, --abstract              description of the module
 -B, --build-requires        build dependencies
 -b, --buildspec             buildspec YAML file
     --cleanup, --no-cleanup remove temp dir after build (default: cleanup)
     --create-buildspec      name of a buildspec file to create
 -d, --debug                 debug mode
     --destdir               destination directory for the tarball (default: cwd)
     --dryrun                dump parsed buildspec args and exit
     --exe-files             path to the executables list
     --extra-path            path to the extra files list
 -h, --help                  help
 -l, --log-level             ERROR, WARN, INFO, DEBUG, TRACE
 -m, --module                module name
 -M, --min-perl-version      minimum perl version to consider core (default: 5.010)
     --no-cleanup            preserve temp dir after build
     --no-require-versions   omit version numbers from dependencies
 -o, --outfile               output file for create-cpanfile (default: cpanfile, - for STDOUT)
 -P, --pager, --no-pager     use a pager for help (default: use pager)
     --pl-files              path to the PL_FILES list (see perldoc ExtUtils::MakeMaker)
     --postamble             name of the file containing the postamble instructions
     --preserve-makefile     copy Makefile.PL to destdir after build
 -p, --project-root          default: current working directory
     --recurse               recurse directories when searching for files
 -R, --require-versions      add version numbers to dependencies
     --scripts-path          path to the scripts listing
     --skip-tests            skip C<make test> during build
     --tests-path            path to the tests listing
 -V, --verbose               verbose output
 -v, --version               version
     --version-from          module that provides the version

=head2 Commands

=over 4

=item * build

Parse a C<buildspec.yml> file and build the CPAN distribution tarball.
This is the default command and is invoked automatically when
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
F<buildspec.yml.current>.>

=item * write-makefile

Generate a C<Makefile.PL> to STDOUT from options passed on the command
line. Useful for inspecting the generated C<Makefile.PL> without
running a full build.

  cpan-maker write-makefile -m Foo::Bar -r requires -a 'A. U. Thor <au@example.com>'

=item * create-cpanfile

Generate a F<cpanfile> from one or more dependency list files. Each file
contains one dependency per line in the format:

  Module::Name version [dist=name] [url=URL] [mirror=URL]

Lines beginning with C<#> are treated as comments and ignored. A leading
C<+> on a module name (as used in C<CPAN::Maker::Bootstrapper> dependency
files to pin a version) is stripped before processing. Duplicate entries
are removed and the output is sorted alphabetically.

By default the result is written to F<cpanfile> in the current directory.
Use C<-o -> to write to STDOUT instead.

  cpan-maker create-cpanfile requires test-requires
  cpan-maker create-cpanfile -o - requires > cpanfile
  cpan-maker create-cpanfile -o my-cpanfile requires test-requires

The optional C<dist=>, C<url=>, and C<mirror=> qualifiers map to the
corresponding C<cpanfile> source directives, allowing you to pin
dependencies to a specific distribution, URL, or mirror.

=item * version

Print the installed version of C<CPAN::Maker> and exit.

  cpan-maker version

=back

=head1 DESCRIPTION

C<CPAN::Maker> is a utility for creating CPAN distribution tarballs
from a declarative YAML build specification. It handles dependency
resolution, C<Makefile.PL> generation, file staging, and packaging
entirely in Perl — no external bash scripts are required.

The build pipeline, invoked via C<cpan-maker -b buildspec.yml>:

=over 5

=item * parses and validates the build specification

=item * stages distribution files (lib, bin, t, extra-files, postamble)
into a temporary build directory

=item * generates a C<Makefile.PL> in the build directory

=item * runs C<perl Makefile.PL>, C<make manifest>, C<make dist>, and
optionally C<make test>

=item * copies the resulting tarball to the destination directory

=back

I<Note: Prior to version 2.0.0, the build was delegated to an external
bash script (C<make-cpan-dist>). That script is no longer invoked and
is retained only as a compatibility shim. All build logic now runs
within C<cpan-maker> itself.>

=head1 OPTION DETAILS

=over 5

=item -A, --abstract

A short description of the module purpose.

=item -a, --author

Author name and email address.

  Example: -a 'Rob Lauer <rlauer6@comcast.net>'

=item -B, --build-requires

Path to a file listing build-time dependencies.

=item -b, --buildspec

Path to the build specification file in YAML format.
See L</BUILD SPECIFICATION FORMAT>.

=item --cleanup, --no-cleanup

Remove the temporary build directory after the build completes. The
default is to remove it. Use C<--no-cleanup> to preserve the directory
for inspection.

=item -C, --create-buildspec

Write a buildspec file derived from the current options to the named
file.

=item -d, --debug

Enable debug logging.

=item --destdir

Directory where the finished tarball (and C<Makefile.PL> if
C<--preserve-makefile> is set) will be written. Defaults to the
current working directory.

=item --dryrun

Parse the buildspec and dump the resulting argument hash without
running the build.

=item -h, --help

Print the option summary.

=item -l, --log-level

Log level. Valid values: C<error>, C<warn>, C<info>, C<debug>,
C<trace>. Default: C<error>.

=item -m, --module

Name of the primary Perl module to package.

=item -M, --min-perl-version

Minimum Perl version used when determining which modules are core.
Default: C<5.010>.

=item --no-cleanup

Preserve the temporary build directory after the build. Equivalent to
C<--no-cleanup>; the directory path is logged at C<debug> level.

=item -o, --outfile

Output file path for the C<create-cpanfile> command. Defaults to
F<cpanfile> in the current directory. Pass C<-> to write to STDOUT.

=item -P, --pager, --no-pager

Route help output through a pager. Default: use pager.

=item --pl-files

Path to a file listing C<PL_FILES> targets.
See L<ExtUtils::MakeMaker> for the format.

=item --postamble

Path to a file containing C<Makefile> postamble instructions to append
to the generated C<Makefile.PL>.

=item --preserve-makefile

Copy the generated C<Makefile.PL> to C<--destdir> after the build.
Useful for inspecting the result.

=item -p, --project-root

Root of the project tree. Paths in the buildspec are resolved relative
to this directory. Defaults to the current working directory.

=item --recurse

Recurse into subdirectories of the C<pm-module> path when collecting
modules. Default: yes.

=item -R, --require-versions, --no-require-versions

Include version numbers in the generated C<PREREQ_PM> section.
Default: include versions.

=item --skip-tests

Skip C<make test> during the build.

=item --version-from

Module name from which the distribution version is extracted.
Defaults to the primary module.

=back

=head1 ENVIRONMENT VARIABLES

No environment variables are used by C<cpan-maker>. Options previously
controlled by C<PRESERVE_MAKEFILE>, C<SKIP_TESTS>, and C<DEBUG>
environment variables (which applied to the now-removed bash script)
are now available as C<--preserve-makefile>, C<--skip-tests>, and
C<--debug> command-line options.

=head1 BUILD SPECIFICATION FORMAT

The preferred way to use C<cpan-maker> is with a F<buildspec.yml>
file:

 cpan-maker -b buildspec.yml

=head2 Minimal example

 project:
   description: My awesome module
   author:
     name:   A. U. Thor
     mailto: au@example.com

 pm-module: Foo::Bar

 dependencies:
   requires:      requires
   test-requires: test-requires

=head2 Full key reference

=over 5

=item project

=over 15

=item description

Short description of the module. Used as C<ABSTRACT> in
C<Makefile.PL>.

=item author

=over 10

=item name

Author's full name.

=item mailto

Author's email address.

=back

=item git

URI of the project's git repository.

=back

=item pm-module

The fully-qualified name of the primary module to package
(e.g. C<Foo::Bar>).

=item version-from

Module from which the version number is read. Defaults to C<pm-module>.

=item min-perl-version

Minimum Perl version to assume when deciding which modules are core.
Default: C<5.010>.

=item man-links

List of C<name: Module::Name> pairs. For each entry a man page symlink
is created so that C<man name> resolves to the module's man page.

  man-links:
    - foo-bar: Foo::Bar

=item include-version

Whether to include version numbers in dependency declarations.
Set to C<no> to omit. Default: C<yes>.

=item dependencies

=over 15

=item requires

Path to a file listing runtime dependencies. Defaults to a file named
F<requires> in the project root.

=item test-requires

Path to a file listing test dependencies.

=item build-requires

Path to a file listing build-time dependencies.

=item recommends

Path to a file listing optional recommended dependencies. These appear
under C<prereqs.runtime.recommends> in generated META files and are
installed by C<cpanm --with-recommends>.

=item resolver (optional)

Name of a program that produces a dependency list when passed a module
name. Use the special value C<scandeps> to invoke F<scandeps.pl>.

=item required-modules

Whether the resolver should follow C<require> statements. Default: C<yes>.

=back

=item path (optional)

=over 15

=item pm-module

Directory containing the module files. Default: F<lib>.

=item recurse (optional)

Whether to recurse into subdirectories. Default: C<yes>.

=item tests (optional)

Directory containing test files (C<*.t>).

=item exe-files

Directory containing executable Perl scripts. Only files with
executable permissions are included.

  Examples:
    src/main/perl/bin
    bin/

=item scripts

Directory containing non-Perl executable scripts (e.g. bash).
Only files with executable permissions are included.

=back

=item provides (optional)

Explicit list of modules provided by this distribution. By default all
C<.pm> files found under the C<pm-module> path are listed.

=item resources (optional)

Values added to the C<resources> section of C<META_MERGE> in the
generated C<Makefile.PL>. See L<CPAN::Meta::Spec> for the format.

=item extra-files (optional)

List of files to be included in the package.

Examples:

 extra-files:
   - ChangeLog
   - README
   - examples:
       - src/examples  <= include all files in this directory

 extra-files:
   - ChangeLog
   - README
   - examples:
       - src/examples/foo.pl
       - src/examples/boo.pl

I<CAUTION: specifying a directory will include ALL of the files in
that directory. It is better practice to list the specific files you
want to include, or provide a manifest of files via the C<extra> key:>

 extra: manifest

If you include a C<share> destination in your C<extra-files>
specification, those files will be installed as part of the
distribution under the share directory. The installed location can be
found at runtime with:

 perl -MFile::ShareDir=dist_dir -e 'print dist_dir(q{My-Project});'

The specification...

 extra-files:
   - share:        <= indicates ../auto/share/dist/My-Project
       - resources/foo.cfg

...would package F<resources/foo.cfg> from your project into the
distribution's share directory root. While this specification...

 extra-files:
   - share/resources:   <= indicates ../auto/share/dist/My-Project/resources
       - resources/foo.cfg

...would package F<foo.cfg> into the F<resources> subdirectory of the
distribution's share directory.

I<All other files in the C<extra-files> section will be added to the
root of the tarball but will not be installed.>

=item extra (optional)

Path to a manifest file listing additional files to include, one per
line.

=back

=head2 Key Naming

Keys may be written with hyphens (C<pm-module>) or underscores
(C<pm_module>). The hyphenated form is canonical. If underscore keys
are detected they are normalised before parsing and a corrected copy of
the buildspec is written to F<buildspec.yml.current>. The original file
is never modified.

=head1 DEPENDENCIES

Runtime and test dependencies are read from plain-text files, one
module per line with an optional version number:

  Amazon::Credentials 1.15
  HTTP::Tiny

By default the files are named F<requires> and F<test-requires>. The
paths can be overridden in the C<dependencies> section of the
buildspec.

If the dependency file is named F<cpanfile> it is parsed in cpanfile
format.

=head1 VERSION

This documentation refers to version 2.0.1

=head1 AUTHOR

Rob Lauer - <rlauer@treasurersbriefcase.com>

=cut
