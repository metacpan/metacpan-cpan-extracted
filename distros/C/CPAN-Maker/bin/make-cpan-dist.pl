#!/bin/env perl

package CPAN::Maker;

# a CPAN distribution creation utility

use strict;
use warnings;

use CPAN::Maker::Constants qw( :all );
use CPAN::Maker::Utils qw( :all );

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
use Getopt::Long qw(:config no_ignore_case );
use JSON qw( encode_json decode_json );
use List::Util qw( pairs );
use Log::Log4perl qw( :easy );
use Log::Log4perl::Level;
use Pod::Usage;
use Pod::Find qw(pod_where);
use Scalar::Util qw( reftype );
use YAML::Tiny;
use version;

our $VERSION = '1.5.46';  ## no critic (RequireInterpolationOfMetachars)

caller or __PACKAGE__->main();

########################################################################
sub help {
########################################################################
  my ($options) = @_;

  my $token;

  if ( $options->{pager} ) {
    $token = eval {
      require IO::Pager;

      IO::Pager::open( *STDOUT, '|-:utf8', 'Unbuffered' );
    };
  }

  my $file = pod_where( { -inc => $TRUE }, 'CPAN::Maker' );

  return pod2usage( { -input => $file, -exitval => 1, -verbose => 1 } );
}

########################################################################
sub _is_obj {
########################################################################
  my ( $this, $type ) = @_;

  return ref $this && reftype($this) eq $type;
}

########################################################################
sub is_array {
########################################################################
  my ($this) = @_;

  return _is_obj( $this, 'ARRAY' );
}

########################################################################
sub is_scalar {
########################################################################
  my ($this) = @_;

  return !ref $this;
}

########################################################################
sub is_hash {
########################################################################
  my ($this) = @_;

  return _is_obj( $this, 'HASH' );
}

########################################################################
sub get_exe_file_list {
########################################################################
  my ($file) = @_;

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
sub get_perl_version {
########################################################################
  my ($requires) = @_;

  my $version;

  if ( !-e $requires ) {
    return;
  }

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
  my ( $file, %options ) = @_;

  my %provides;
  my @missing;

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

        if ( $options{'work-dir'} ) {
          $include_path = $options{'work-dir'} . $SLASH . $include_path;
        }

        my $module_version = get_module_version( $module, $include_path );

        my ( $provided_module, $version )
          = @{$module_version}{qw( module version)};

        if ( !defined $version ) {
          warn sprintf "provided module '%s' not found in %s\n", $module, $include_path;
          push @missing, $module;
        }
        else {
          $provides{$provided_module} = {
            file    => sprintf( '%s/%s', $prefix, $module_version->{'file'} ),
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
    warn sprintf "Attempting to find files that belong to these modules.\n", scalar @missing;
    my $dir = $options{'work-dir'} . '/lib';

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
        my $text = slurp_file($file);
        next if $text !~ /^package\s+$module;/xsm;  # preliminary scan

        # remove all pod so we don't get false positives
        $text =~ s/^=pod(.*?)=cut//xsmg;
        next if $text !~ /^package\s+$module;/xsm;

        # see if we can get the version...this might work since we
        # added $options{'work-dir'} to @INC. $options{'work-dir'}
        # contains all the .pm modules to be packaged. It might not
        # work for other reaasons (like some required packages are not
        # installed?)
        my $version = eval {
          local $SIG{__WARN__} = sub { };
          require $file;
          return eval '$' . $module . '::VERSION';
        };

        $version //= 'undef';
        my $rel_path = $file;
        $rel_path =~ s/$options{'work-dir'}\///xsm;

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
sub get_resources {
########################################################################
  goto &get_json_file;
}

########################################################################
sub get_json_file {
########################################################################
  my ($file) = @_;

  my ($json) = process_file(
    $file,
    - chomp     => 1,
    merge_lines => 1
  );

  return decode_json($json);
}

########################################################################
sub write_resources {
########################################################################
  my ( $resources, %args ) = @_;

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
  my ( $pl_files, %args ) = @_;

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
  my ( $fh, $provides ) = @_;

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
  my ( $provides, %args ) = @_;

  return %args
    if !$provides;

  my $provides_file = 'provides';

  open my $fh, '>', $provides_file
    or croak "could not open 'provides' for writing\n";

  _write_provides( $fh, $provides );

  close $fh
    or croak "could not close 'provides'\n";

  $args{P} = $provides_file;

  return %args;
}

########################################################################
sub write_makefile {
########################################################################
  my (%options) = @_;

  my $core            = $options{'core-modules'};
  my $MODULE_ABSTRACT = $options{abstract};
  my $AUTHOR          = $options{author};
  my $project_root    = $options{'project-root'};

  my $email;
  my $author;

  if ( $AUTHOR && $AUTHOR =~ /^([^<]+)\s+<([^>]+)>\s*$/xsm ) {
    $author = $1;
    $email  = $2;
  }

  my $PM_MODULE = $options{module};

  my %buildspec = (
    version => $VERSION,
    project => {
      description => $MODULE_ABSTRACT,
      author      => {
        name   => $AUTHOR // 'Anonymouse',
        mailto => $email  // 'anonymouse@example.org',
      },
    },
    pm_module => $PM_MODULE,
  );

  my $VERSION_FROM = $options{'version-from'} // $options{module};

  if ( $VERSION_FROM !~ /\//xsm ) {
    $VERSION_FROM = 'lib/' . make_path_from_module($VERSION_FROM);
  }

  $buildspec{'version-from'} = $VERSION_FROM;

  local $Data::Dumper::Terse    = $TRUE;
  local $Data::Dumper::Sortkeys = $TRUE;
  local $Data::Dumper::Indent   = 2;
  local $Data::Dumper::Pad      = $SPACE x $INDENT;

  # dependencies
  foreach my $d (qw(requires test-requires build-requires )) {
    $options{$d} = $options{$d} || $d;
  }

  $buildspec{dependencies} = {
    $options{requires}       ? ( requires       => $options{requires} )         : (),
    $options{test_requires}  ? ( test_requires  => $options{'test-requires'} )  : (),
    $options{build_requires} ? ( build_requires => $options{'build-requires'} ) : (),
  };

  foreach (qw(requires test_requires build_requires)) {
    next if !$buildspec{dependencies}->{$_};

    $buildspec{dependencies}->{$_} =~ s/$project_root\/?//xsm;
  }

  my $PRE_REQ = Dumper get_requires( $options{'requires'}, $core, $options{'min-perl-version'} );
  $PRE_REQ = trim($PRE_REQ);
  $PRE_REQ =~ s/([@]\d+)/== $2/xsmg;

  my $TEST_REQ = {};

  if ( $options{'test-requires'} && -s $options{'test-requires'} ) {
    $TEST_REQ = Dumper get_requires( $options{'test-requires'}, $core, $options{'min-perl-version'} );
  }
  else {
    $TEST_REQ = '{}';
  }

  $TEST_REQ = trim($TEST_REQ);
  $TEST_REQ =~ s/\@(\d+)/== $1/xsmg;

  my $build_req = {};

  if ( $options{'build-requires'} && -s $options{'build-requires'} ) {
    $build_req = get_requires( $options{'build-requires'}, $TRUE, $options{'min-perl-version'} );
  }

  foreach my $m (qw( ExtUtils::MakeMaker File::ShareDir::Install)) {
    $build_req->{$m} = $build_req->{$m} || $FALSE;
  }

  $build_req = Dumper $build_req;

  my @exe_file_list;
  $buildspec{path} = {
    pm_module => $options{'module-path'},
    recurse   => $options{recurse} ? 'yes' : 'no',
  };

  my $exe_files = $options{'exe-files'} || $options{'exec-path'};

  if ( $exe_files && -s $exe_files ) {
    @exe_file_list = get_exe_file_list($exe_files);
    $options{'exec-path'} = $exe_files;
  }

  foreach my $p ( pairs qw(exe-files exec-path scripts scripts-path tests tests-path) ) {
    next
      if !$options{ $p->[1] };

    my $project_file = sprintf '%s/%s', $project_root, $options{ $p->[1] };

    if ( -e $project_file ) {
      $buildspec{path}->{ $p->[0] } = $options{ $p->[1] };
    }
    else {
      $buildspec{ $p->[0] } = fetch_relative_filelist( $project_root, $options{ $p->[1] } );

      # remove temporary files?
      if ( $options{ $p->[1] } =~ /make\-cpan\-dist\-[[:alpha:]]{5}/xsm ) {
        unlink $options{ $p->[1] };
      }
    }
  }

  if ( $options{'extra-path'} ) {
    $buildspec{'extra-files'} = $options{'extra-path'};
  }

  my $EXE_FILES = Dumper \@exe_file_list;

  my %provides;

  if ( -e 'provides' ) {
    %provides = get_provides( 'provides', %options );
    $buildspec{provides} = [ keys %provides ];
  }

  my $resources_path = $options{resources} // 'resources';
  my $resources;

  if ( -e $resources_path ) {
    $resources = get_resources($resources_path);
    $buildspec{resources} = $resources;
  }

  my $META_MERGE = 'META_MERGE ' . $FAT_ARROW;

  {
    local $Data::Dumper::Pair = $FAT_ARROW;

    $META_MERGE .= Dumper(
      { 'meta-spec' => { version => 2 },
        'provides'  => \%provides,
        $resources ? ( 'resources' => $resources ) : ()
      }
    );
  }

  my $timestamp = scalar localtime;

  my $MIN_PERL_VERSION = $options{'min-perl-version'} // $PERL_VERSION;

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

  my $pl_files = $options{'pl-files'};

  if ( $pl_files && -s $pl_files ) {
    my @file_list = split /\n/xsm, slurp_file($pl_files);

    foreach my $pl_file (@file_list) {
      my ( $file, $target ) = split /\s+/xsm, $_;
      $pl_list{$file} = $target;
    }

    $buildspec{'pl-files'} = \%pl_list;
  }

  my $PL_FILES = Dumper( \%pl_list );

  $buildspec{postamble} = $options{postamble};

  my $MAKEFILE = <<"END_OF_TEXT";
# autogenerated by $PROGRAM_NAME on $timestamp

use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::ShareDir::Install;

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

  DEBUG sub { return $MAKEFILE };

  write_buildspec_file( \%buildspec, \%options );

  return $SUCCESS;
}

########################################################################
sub write_buildspec_file {
########################################################################
  my ( $buildspec, $options ) = @_;

  my ( $buildspec_file, $overwrite ) = @{$options}{qw(create-buildspec overwrite)};

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
sub fetch_file_list {
########################################################################
  my (%args) = @_;

  my ( $file_list, $destdir, $project_root ) = @args{qw(file_list destination project_root exclude)};

  my @expanded_list;
  my @exclude = grep {/^!/xsm} @{$file_list};

  foreach (@exclude) {
    s/^!//xsm;
  }

  foreach my $f ( grep { !/^!/xsm } @{$file_list} ) {
    my $fqp = sprintf '%s/%s', $project_root, $f;

    DEBUG Dumper( [ 'fetch_file_list:', $fqp ] );

    # no recurse of directories!
    my $cwd = cwd();

    if ( -d $fqp ) {
      eval {
        find(
          { follow => $TRUE,
            wanted => sub {
              return
                if /^[.]/xsm || -d $_;

              die 'done'
                if cwd() ne $fqp;

              my $name = $_;

              foreach my $e (@exclude) {

                if ( $e =~ /^\/([^\/]+)\/$/xsm ) {
                  my $pat = qr/$1/xsm;

                  if ( $name =~ /$pat/ ) {
                    return;
                  }
                }

                return
                  if $e eq $name;
              }

              push @expanded_list, "$File::Find::name $destdir/$name";
            }
          },
          $fqp
        );
      };

      chdir $cwd;

      # remove project root since bash script will add it
      for (@expanded_list) {
        s/^$project_root//xsm;
      }
    }
    else {
      # the intent is to cp files to root of distribution (not
      # to install the files during package installation...the
      # exception being if items are installed into share
      # directory
      die "ERROR: missing file in list ($fqp) - check your `extra-files` section\n"
        if !-e $fqp;

      my ( $name, $path, $ext ) = fileparse( $fqp, qr/[.][^.]+/xsm );
      push @expanded_list, sprintf '%s %s/%s%s', $f, $destdir, $name, $ext;
    }
  }

  return @expanded_list;
}

# To find files installed to sharedir...
#
#  use File::ShareDir;
#  print File::ShareDir::dist_dir('Bedrock');

# file name or hash
# extra-files:
#   - share:
#     - README.md
#     - ChangeLog
#   - examples: src/examples
# extra-files:
#   - file

########################################################################
sub write_extra_files {
########################################################################
  my (%params) = @_;

  DEBUG('writing extra-files');

  my ( $extra_files, $extra, $project_root ) = @params{qw(extra_files extra project_root)};

  my %args = %{ $params{args} };

  $extra_files //= [];

  croak "extra-files must be an array!\n" . Dumper( [ $extra_files, \%params ] )
    if !is_array($extra_files);

  my $extra_files_path = $extra || 'extra-files';

  my @file_list;

  foreach my $e ( @{$extra_files} ) {
    DEBUG Dumper( [ extra => $e ] );

    if ( !ref $e ) {  # file or directory
      push @file_list,
        fetch_file_list(
        file_list    => [$e],
        destination  => $EMPTY,
        project_root => $project_root,
        );
    }
    elsif ( is_hash($e) ) {
      # if the extra-files entry is a hash, then the key of that hash
      # represents the destination directory.  The value must be an
      # array of scalars that can represent individual files within
      # the project or whole directories within the project that
      # should be written to the destination directory
      #
      # DO NOT DO THIS...
      # extra-files:
      #   - t: foo.t
      #
      # DO THIS INSTEAD...
      # extra-files:
      #   - t:
      #       - foo.t
      #
      #
      my ($destdir) = keys %{$e};
      my $file_list = $e->{$destdir};

      croak 'directory args for extra-files must be an array!'
        if !is_array($file_list);

      push @file_list,
        fetch_file_list(
        file_list    => $file_list,
        destination  => $destdir,
        project_root => $project_root,
        );

    }
  }

  if (@file_list) {
    open my $fh, '>', $extra_files_path
      or croak "could not append to $extra_files_path\n";

    foreach my $f (@file_list) {
      print {$fh} "$f\n";
    }

    close $fh
      or croak "could not close $extra_files_path\n";
  }

  $args{f} = $extra_files_path;

  return %args;
}

########################################################################
sub parse_path {
########################################################################
  my ( $project_root, $path, %args ) = @_;

  if ($path) {
    if ( $path->{'recurse'}
      && $path->{'recurse'} =~ /(yes|no)/ixsm ) {
      $args{R} = $path->{'recurse'};
    }
    elsif ( $path->{'recurse'} ) {
      croak "use only yes or no for 'recurse' option\n";
    }

    # -l
    if ( $path->{'pm_module'} ) {
      $args{l} = $path->{'pm_module'};
    }

    if ( $path->{'exclude_files'} ) {
      $args{E} = $path->{'exclude_files'};
    }

    # -e
    if ( $path->{exe_files} ) {
      check_path( $project_root, $path->{exe_files}, 'exe_files' );

      $args{e} = $path->{exe_files};
    }

    # -S
    if ( $path->{scripts} ) {
      check_path( $project_root, $path->{scripts}, 'scripts' );

      $args{S} = $path->{scripts};
    }

    # -t
    if ( $path->{tests} ) {
      check_path( $project_root, $path->{tests}, 'tests' );

      $args{t} = $path->{tests};
    }
  }

  return %args;
}

########################################################################
sub check_path {
########################################################################
  my ( $project_root, $path, $option_name ) = @_;

  die sprintf "ERROR: '%s' must be a scalar representing a path not %s\n", $option_name, reftype($path)
    if ref $path;

  my $exists = $path =~ /^\//xsm ? -d $path : -d "$project_root/$path";

  die "no such path: [$path] - must be absolute or relative to $project_root\n"
    if !$exists;

  return $TRUE;
}

########################################################################
sub parse_dependencies {
########################################################################
  my ( $dependencies, %args ) = @_;

  if ($dependencies) {
    croak 'malformed buildspec.yml file - dependencies section with no keys?'
      if !keys %{$dependencies};

    $dependencies->{core_modules}     //= 'no';
    $dependencies->{required_modules} //= 'yes';

    if ( $dependencies->{path} ) {  # deprecatd
      $args{D} = $dependencies->{path};
      warn "path is deprecated: use requires\n";
    }

    if ( $dependencies->{requires} ) {
      $args{D} = $dependencies->{requires};
    }

    if ( $dependencies->{test_requires} ) {
      $args{T} = $dependencies->{test_requires};
    }

    if ( $dependencies->{build_requires} ) {
      $args{B} = $dependencies->{build_requires};
    }

    if ( $dependencies->{core_modules} eq 'yes' ) {
      $args{c} = $EMPTY;
    }

    if ( $dependencies->{required_modules} eq 'no' ) {
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
  my ( $version, %args ) = @_;

  if ( defined $version ) {
    if ( $version =~ /(no|0|off)/xsm ) {
      $args{A} = $EMPTY;
    }
  }
  return %args;
}

########################################################################
sub parse_project {
########################################################################
  my ( $project, %args ) = @_;

  if ($project) {
    if ( $project->{author} ) {
      $args{a} = $project->{author}->{name};

      if ( $project->{author}->{mailto} ) {
        $args{a} .= ' <' . $project->{author}->{mailto} . '>';
      }

      $args{a} = sprintf q{'%s'}, $args{a};
    }

    # -d
    if ( $project->{description} ) {
      $args{d} = sprintf q{'%s'}, $project->{description};
    }

    # -g
    if ( $project->{git} ) {
      $args{g} = $project->{git};
    }
  }

  return %args;
}

########################################################################
sub parse_pm_module {
########################################################################
  my ( $pm_module, %args ) = @_;

  if ($pm_module) {
    $args{m} = $pm_module;
  }
  return %args;
}

########################################################################
sub get_buildspec {
########################################################################
  my ($file) = @_;

  croak 'file not found or empty ' . $file . $NL
    if !-s $file;

  my $buildspec = eval { YAML::Tiny->read($file)->[0]; };

  croak 'could not read ' . $file . $NL . $EVAL_ERROR . $NL
    if $EVAL_ERROR || !$buildspec;

  $buildspec->{min_perl_version} = $buildspec->{'min-perl-version'};
  $buildspec->{include_version}  = $buildspec->{'include-version'};

  return $buildspec;
}

# this method converts a buildspec into options to be passed to shell script
# which eventually calls this script to create the Makefile.PL
########################################################################
sub parse_buildspec {
########################################################################
  my (%options) = @_;

  my $file = $options{buildspec};

  my $buildspec = get_buildspec($file);

  my $project_root = $options{'project-root'};

  croak 'bad build file'
    if !validate_object( $buildspec, $options{'yaml-spec'} );

  my %args;

  if ( $buildspec->{min_perl_version} ) {
    $args{M} = $buildspec->{min_perl_version};
  }

  if ( $buildspec->{'version_from'} || $buildspec->{'version-from'} ) {
    $args{V} = $buildspec->{version_from} // $buildspec->{'version-from'};
  }

  if ( $options{'project-root'} ) {
    $args{H} = $options{'project-root'};
  }

  if ( $options{postamble} ) {
    $args{F} = $options{postamble};
  }

  if ( $buildspec->{exe_files} ) {
    $args{e} = create_temp_filelist( $project_root, $buildspec->{exe_files} );
  }

  if ( $buildspec->{tests} ) {
    $args{t} = create_temp_filelist( $project_root, $buildspec->{tests} );
  }

  if ( $buildspec->{scripts} ) {
    $args{S} = create_temp_filelist( $project_root, $buildspec->{scripts} );
  }

  %args = write_resources( $buildspec->{resources}, %args );

  %args = parse_project( $buildspec->{project}, %args );

  %args = parse_pm_module( $buildspec->{pm_module}, %args );

  %args = parse_include_version( $buildspec->{include_version}, %args );

  %args = parse_dependencies( $buildspec->{dependencies}, %args );

  %args = parse_path( $options{'project-root'}, $buildspec->{path}, %args );

  %args = write_extra_files(
    extra_files  => $buildspec->{'extra-files'},
    extra        => $buildspec->{extra},
    args         => \%args,
    project_root => $options{'project-root'}
  );

  %args = write_provides( $buildspec->{provides}, %args );

  %args = write_pl_files( $buildspec->{pl_files}, %args );

  # set boolean args from options

  my @boolean_args = qw( verbose v cleanup !x scandeps s require-versions !A );

  foreach my $pair ( pairs @boolean_args ) {
    my ( $key, $value ) = @{$pair};

    if ( $value =~ /^\!(.*)$/xsm ) {
      if ( $options{$1} ) {
        delete $options{$1};
      }
    }
    elsif ( $options{$key} ) {
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

  DEBUG Dumper( [ args => \%args ] );

  return %args;
}

########################################################################
sub create_temp_filelist {
########################################################################
  my ( $project_root, $filelist ) = @_;

  if ( ref $filelist && reftype($filelist) eq 'ARRAY' ) {
    my ( $fh, $filename ) = tempfile( 'make-cpan-dist-XXXXX', TMPDIR => $TRUE );

    foreach my $file ( @{$filelist} ) {
      my $path = $file =~ /^\//xsm ? $file : "$project_root/$file";

      die "error: no such file $path\n"
        if !-e $path;

      print {$fh} "$path\n";
    }

    close $fh;

    return $filename;
  }
  elsif ( !ref $filelist ) {
    return $filelist
      if -e $filelist;

    die "no such file $filelist\n";
  }
}

########################################################################
sub get_requires {
########################################################################
  my ( $requires, $core_modules, $min_perl_version ) = @_;

  my %modules;

  process_file(
    $requires,
    chomp            => $TRUE,
    skip_blank_lines => $TRUE,
    filter           => sub {
      my ( $fh, $all_lines, $args, $line ) = @_;
      $line = filter( $fh, $all_lines, $args, $line );

      return ()    if $line && $line =~ /^perl\s+/xsm;
      return $line if !defined $line;
      return $line if $core_modules;
      return $line if $line =~ /^[+]/xsm;

      return is_core( $line, $min_perl_version )
        ? undef
        : $line;
    },
    process => sub {
      my $line = pop @_;

      $line =~ s/^[+]([^+]*)$/$1/xsm;

      my ( $module, $version ) = split /\s/xsm, $line;
      $version = $version || '0';

      $modules{$module} = $version;

      return $line;
    }
  );

  return \%modules;
}

########################################################################
sub get_modules {
########################################################################
  my ($module_list) = @_;

  my ($modules) = process_file( $module_list, chomp => $TRUE );

  return $modules;
}

########################################################################
sub get_yaml_specfile {
########################################################################
  my ($options) = @_;

  my ($lines) = process_file(
    *DATA,
    chomp     => $TRUE,
    next_line => sub {
      my ( $fh, $all_lines, $args ) = @_;

      my $line = <$fh>;

      return
        if !$line || $line =~ /^\=pod/xsm;  # signal end of file

      return $line;
    }
  );

  return Load join "\n", @{$lines};
}

########################################################################
sub validate_object {
########################################################################
  my ( $obj, $spec, $err ) = @_;

  $err = $err // 0;

  if ( reftype($obj) eq 'HASH' ) {
    foreach my $k ( keys %{$obj} ) {
      if ( !exists $spec->{$k} ) {
        carp "ERROR: not a valid key ($k)\n" . Dumper [ $k, $spec ];
        $err++;
      }

      if ( ref $spec->{$k} ) {
        if ( !ref $obj->{$k}
          || reftype( $obj->{$k} ) ne reftype( $spec->{$k} ) ) {
          warn "ERROR: wrong type for ($k) - $k must be " . reftype( $spec->{$k} ) . "\n";
          $err++;
        }
        else {
          validate_object( $obj->{$k}, $spec->{$k}, $err );
        }
      }
    }
  }
  else {  # just validate arrays are arrays for now, deep dive TBD
    $err = reftype($spec) =~ /ARRAY|HASH/xsm;
  }

  return $err ? $FALSE : $TRUE;
}

########################################################################
sub fetch_relative_filelist {
########################################################################
  my ( $project_root, $file ) = @_;

  my @file_list = grep { !!$_ } split /\n/xsm, slurp_file($file);

  foreach (@file_list) {
    s/$project_root\/?//xsm;
  }

  return \@file_list;
}

########################################################################
sub slurp_file {
########################################################################
  my ($file) = @_;

  open my $fh, '<', $file
    or croak "could not open $file for reading\n";

  local $RS = undef;

  my $content = <$fh>;

  close $fh;

  return $content;
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
    recurse
    require-versions|R!
    requires|r=s
    resources=s
    scandeps|s
    scripts-path=s
    test-requires|t=s
    tests-path=s
    verbose|V
    version-from=s
    version|v
    work-dir|w=s
  );

  my %options = ( cleanup => 1, pager => 1 );

  my $retval = GetOptions( \%options, @option_specs );

  if ( !$retval || $options{help} ) {
    help( \%options );

    exit;
  }

  $options{'project-root'} //= $ENV{PROJECT_HOME} // getcwd;

  $options{'yaml-spec'} = get_yaml_specfile;

  if ( $options{'min-perl-version'} ) {
    $options{'min-perl-version'}
      = version->parse( $options{'min-perl-version'} )->stringify;
  }
  else {
    if ( $options{requires} ) {
      $options{'min-perl-version'} = get_perl_version( $options{requires} );
    }

    $options{'min-perl-version'} //= $DEFAULT_PERL_VERSION;
  }

  if ( !exists $options{'require-versions'} ) {
    $options{'require-versions'} = $TRUE;
  }

  if ( $options{version} ) {
    print $PROGRAM_NAME . ' v' . $VERSION . $NL;

    exit $SH_SUCCESS;
  }

  my $log_level = $options{'log-level'};

  if ($log_level) {
    if ( $log_level =~ /\A[1-5]\z$/xsm ) {
      $log_level = ( $ERROR, $WARN, $INFO, $DEBUG, $TRACE )[ $log_level - 1 ];
    }
    else {
      $log_level = {
        ERROR => $ERROR,
        WARN  => $WARN,
        INFO  => $INFO,
        DEBUG => $DEBUG,
        TRACE => $TRACE,
      }->{ uc $options{'log-level'} };
    }

  }
  elsif ( $options{debug} ) {
    $log_level = $DEBUG;
  }

  if ( !$log_level ) {
    $log_level = $ERROR;
  }

  Log::Log4perl->easy_init($log_level);

  if ( $options{buildspec} ) {

    my %args = parse_buildspec(%options);

    if ($log_level) {
      $args{'-L'} = {
        $ERROR => 1,
        $WARN  => 2,
        $INFO  => 3,
        $DEBUG => 4,
        $TRACE => 5,
      }->{$log_level};
    }

    if ( !$options{dryrun} ) {
      exec 'make-cpan-dist ' . join $SPACE, %args;
    }
    else {
      print 'make-cpan-dist ' . ( join $SPACE, %args ) . $NL;
    }
  }
  else {
    croak 'no module specified'
      if !$options{module};

    croak 'no dependencies'
      if !$options{requires};

    $options{author}   = $options{author}   // 'Anonymouse <anonymouse@example.com>';
    $options{abstract} = $options{abstract} // 'my awesome Perl module!';

    if ( !write_makefile(%options) ) {
      help();
      exit $SH_FAILURE;
    }
  }

  exit $SH_SUCCESS;
}

1;

__DATA__
---
version: "1.5.46"
min_perl_version: "type:string"
min-perl-version: "type:string"
project:
  git: "type:string"
  description: "type:string"
  author:
    name: "type:string"
    mailto: "type:string"
pm_module:
include_version: "type:boolean"
include-version: "type:boolean"
dependencies:
  resolver: "type:string"
  path: "type:string"
  requires: "type:string"
  test_requires: "type:string"
  build_requires: "type:string"
  core_modules: "type::boolean"
  required_modules: "type:boolean"
pl_files:
postamble: "type:string"
path:
  recurse: "type:boolean"
  pm_module: "type:string"
  tests: "type:string"
  exe_files: "type:string"
  scripts: "type:string"
  exclude_files: "type:string"
extra: "type:string"
extra-files:
provides: "type:string"
resources:
  homepage: "type:string"
  bugtracker:
    web: "type:string"
    mailto: "type:string"
  repository:
    url: "type:string"
    web: "type:string"
    type: "type:string"
scripts:
exe_files:
version-from: "type:string"

=pod

=head1 NAME

make-cpan-dist.pl - CPAN distribution creation utility

=head1 SYNOPSIS

 make-cpand-dist.pl -b buidlspec.yml

=head1 DESCRIPTION

See man CPAN::Maker for detailed documentation

=head1 AUTHOR

Rob Lauer - <bigfoot@cpan.org>

=cut
