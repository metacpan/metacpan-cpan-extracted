package App::MechaCPAN::Perl;

use v5.14;
use autodie;
use Config;
use FindBin;
use File::Spec;
use App::MechaCPAN qw/:go/;

our @args = (
  'threads!',
  'jobs=i',
  'skip-tests!',
  'skip-local!',
  'skip-lib!',
  'smart-tests!',
  'devel!',
  'shared-lib!',
  'build-reusable!',
);

my $perl5_ver_re = qr/v? 5 [.] (\d{1,2}) (?: [.] (\d{1,2}) )?/xms;
my $perl5_re     = qr/^ $perl5_ver_re $/xms;

our $JOBS = 2;    # The number of jobs to run with make

sub go
{
  my $class = shift;
  my $opts  = shift;
  my $src   = shift;
  my @argv  = shift;

  if ( $^O eq 'MSWin32' )
  {
    info 'Cannot build perl on Win32';
    return 0;
  }

  my $orig_dir = &get_project_dir;
  my $dest_dir = &dest_dir;
  my @dest_dir = File::Spec->splitdir("$dest_dir");
  my $dest_len = $#dest_dir;
  my $perl_dir = "$dest_dir/perl";
  my $pv_ver;    # Version in .perl-version file

  # Attempt to find the perl version if none was given
  if ( -f '.perl-version' )
  {
    open my $pvFH, '<', '.perl-version';
    $pv_ver = do { local $/; <$pvFH> };
    $pv_ver =~ s/\s+//xmsg;
    if ( $pv_ver !~ $perl5_re )
    {
      info "$pv_ver in .perl-version doesn't look like a perl5 version";
      undef $pv_ver;
    }
  }

  my ( $src_tz, $version ) = _get_targz( $src // $pv_ver );

  # If _get_targz couldn't find a version, guess based on the file
  if ( !$version && $src_tz =~ m($perl5_ver_re [^/]* $)xms )
  {
    my $major = $1;
    my $minor = $2;

    $version = "5.$major.$minor";
    info("Looks like $src_tz is perl $version, assuming that's true");
  }

  local $JOBS = $opts->{jobs} // $JOBS;

  if ( $opts->{'build-reusable'} )
  {
    return build_reusable( $version, $perl_dir, $src_tz, $opts );
  }

  if ( -e -x "$perl_dir/bin/perl" )
  {
    unless ( $opts->{is_restarted_process} )
    {
      # If it exists, we're probably running it by now.
      if ( $version && $^V ne "v$version" )
      {
        info(
          $version,
          "perl has already been installed ($^V, not $version)"
        );
      }
      else
      {
        success( $version, "perl has already been installed" );
      }
    }
    return 0;
  }

  my $verstr = "perl $version";
  info $verstr, "Fetching $verstr";

  my $src_dir = inflate_archive($src_tz);

  my @src_dirs = File::Spec->splitdir("$src_dir");
  chdir $src_dir;

  if ( -e -x File::Spec->catdir( @src_dirs, qw/bin perl/ ) )
  {
    return _install_binary( File::Spec->catdir(@src_dirs), $version );
  }

  if ( !-e 'Configure' )
  {
    my @files = glob('*');
    if ( @files != 1 )
    {
      die qq{Could not find perl to configure.}
        . qq{Inflated to "$src_dir" extracted from $src_tz};
    }
    chdir $files[0];
  }

  my $local_dir = File::Spec->catdir( @dest_dir, qw/lib perl5/ );
  my $lib_dir
    = File::Spec->catdir( @dest_dir[ 0 .. $dest_len - 1 ], qw/lib/ );

  my @otherlib = (
    !$opts->{'skip-local'}              ? $local_dir : (),
    !$opts->{'skip-lib'} && -d $lib_dir ? $lib_dir   : (),
  );

  my @config = (
    _build_configure( $perl_dir, $opts ),
    q[-Accflags=-DAPPLLIB_EXP=\"] . join( ":", @otherlib ) . q[\"],
    qq[-A'eval:scriptdir=$perl_dir/bin'],
  );

  local %ENV = %ENV;
  delete @ENV{qw(PERL5LIB PERL5OPT)};

  # Make sure no tomfoolery is happening with perl, like plenv shims
  $ENV{PATH} = $Config{binexp} . ":$ENV{PATH}";

  eval {
    require Devel::PatchPerl;
    info $verstr, "Patching $verstr";
    Devel::PatchPerl->patch_source();
  };

  info $verstr, "Configuring $verstr";
  _run_configure(@config);

  info $verstr, "Building $verstr";
  _run_make();

  my $skip_tests = $opts->{'skip-tests'};

  if ( !$skip_tests && $opts->{'smart-tests'} )
  {
    $skip_tests = $pv_ver eq $version;
  }

  if ( !$skip_tests )
  {
    info $verstr, "Testing $verstr";
    _run_make('test_harness');
  }

  info $verstr, "Installing $verstr";
  _run_make('install');

  success "Installed $verstr";

  chdir $orig_dir;

  &restart_script();

  return 0;
}

# These are split out mostly so we can control testing

sub _build_configure
{
  my $perl_dir = shift;
  my $opts     = shift;

  my @config = (
    q[-des],
    qq[-Dprefix=$perl_dir],
  );

  if ( $opts->{threads} )
  {
    push @config, '-Dusethreads';
  }

  if ( $opts->{'shared-lib'} )
  {
    push @config, '-Duseshrplib';
  }

  if ( $opts->{devel} )
  {
    push @config, '-Dusedevel';
  }

  return @config;
}

sub _run_configure
{
  my @config = @_;
  run qw[sh Configure], @config;
}

sub _run_make
{
  my @cmd = @_;
  state $make = $Config{make};
  state $can_jobs;

  if ( !defined $can_jobs )
  {
    $can_jobs = '';
    my $make_help = run( $make, '-h' );

    if ( $make_help =~ m/^\s*-j\s+/xms )
    {
      $can_jobs = '-j';
    }
  }

  my @jobs_cmd;
  if ( $JOBS > 1 && $can_jobs )
  {
    @jobs_cmd = ( $can_jobs, $JOBS );
  }

  # Give perl more time to be silent during the make process than normal
  local $App::MechaCPAN::TIMEOUT = $App::MechaCPAN::TIMEOUT * 10;

  run $make, @jobs_cmd, @cmd;
}

sub slugline
{
  my $perl = shift || File::Spec->canonpath($^X);

  my $script = <<'EOD';
  use strict;
  use Config;
  my $libcname = 'unknown';
  my $libcver  = 'ukn';
  my $archname = ( split '-', $Config{archname} )[0];
  my $osname   = $Config{osname};
  my $threads  = $Config{usethreads} ? 'threads-' : '';

  if ( $Config{gnulibc_version} )
  {
    $libcname = 'glibc';
    $libcver  = $Config{gnulibc_version};
  }
  else
  {
    my $libc_re         = qr/libc (\W|$)/xms;
    my ($libc_basename) = grep {m/$libc_re/} split( / /, $Config{libsfiles} );
    my ($libc_path) = grep {m/$libc_basename/} split / /, $Config{libsfound};
    my $libc_so     = $libc_path;
    $libc_so =~ s/[.]a([\d.]*)$/.so$1/;
    if ( -x $libc_so )
    {
      my $help = run($libc_so);
      if ( $help =~ m/^ musl \s libc .* Version \s* ([0-9.]+)/xms )
      {
        $libcname = 'musl';
        $libcver  = $1;
      }
    }
  }
  print "perl-$^V-$archname-$osname-$threads$libcname-$libcver";
EOD

  my $script_file = humane_tmpfile;
  $script_file->print($script);
  $script_file->close;

  my $slugline = run( $perl, "$script_file" );
  chomp $slugline;

  return $slugline;
}

sub _check_perl_binary
{
  my $perl_bin = shift;

  # We include POSIX, that's a good litmus that libc is not completely broken
  # and we use crypt to test that the crypt lib is loadable. This is simply
  # a bare minimum check and it may change in the future
  my @check = qw/-MPOSIX -e crypt('00','test')/;

  return eval { run "$perl_bin", @check; 1 };
}

sub build_reusable
{
  my $version  = shift;
  my $perl_dir = shift;
  my $src_tz   = shift;
  my $opts     = shift;

  # Determine what to compress it with
  my $compress
    = eval  { run(qw/xz --version/);    'xz' }
    // eval { run(qw/bzip2 --version/); 'bzip2' }
    // eval { run(qw/gzip --version/);  'gzip' }
    // die 'Cannot find anything to compress with';

  # Make sure we can call tar before we get too far
  die 'Cannot find tar to create an archive'
    if !( eval { run(qw/tar --version/) } );

  $perl_dir = humane_tmpdir("perl-$version");
  my $verstr = "perl $version";
  info $verstr, "Fetching $verstr";

  my $src_dir = inflate_archive($src_tz);

  my @src_dirs = File::Spec->splitdir("$src_dir");
  chdir $src_dir;

  if ( !-e 'Configure' )
  {
    my @files = glob('*');
    if ( @files != 1 )
    {
      die qq{Could not find perl to configure.}
        . qq{Inflated to "$src_dir" extracted from $src_tz};
    }
    chdir $files[0];
  }

  my $local_dir = File::Spec->catdir(qw/... .. lib perl5/);
  my $lib_dir   = File::Spec->catdir(qw/... .. .. lib/);

  my @otherlib = (
    !$opts->{'skip-local'} ? $local_dir : (),
    !$opts->{'skip-lib'}   ? $lib_dir   : (),
  );

  my @config = (
    _build_configure( $perl_dir, $opts ),
    q[-Accflags=-DAPPLLIB_EXP=\"] . join( ":", @otherlib ) . q[\"],
    q{-Dstartperl='#!/usr/bin/env\ perl'},
    q{-Dperlpath='/usr/bin/env\ perl'},
    qq{-Dinstallprefix=/v$version},
    qq{-Dprefix=/v$version},
    q{-Dman1dir=.../../man/man1},
    q{-Dman3dir=.../../man/man3},
    q{-Duserelocatableinc},
  );

  local %ENV = %ENV;
  delete @ENV{qw(PERL5LIB PERL5OPT)};
  $ENV{DESTDIR} = $perl_dir;

  # Make sure no tomfoolery is happening with perl, like plenv shims
  $ENV{PATH} = $Config{binexp} . ":$ENV{PATH}";

  eval {
    require Devel::PatchPerl;
    info $verstr, "Patching $verstr";
    Devel::PatchPerl->patch_source();
  };

  info $verstr, "Configuring $verstr";
  _run_configure(@config);

  info $verstr, "Building $verstr";
  _run_make();

  my $skip_tests = $opts->{'skip-tests'} // $opts->{'smart-tests'};

  if ( !$skip_tests )
  {
    info $verstr, "Testing $verstr";
    _run_make('test_harness');
  }

  info $verstr, "Installing $verstr";
  _run_make('install');

  # Verify that the relocatable bits worked
  if ( !_check_perl_binary( "$perl_dir/v$version/bin/perl" ) )
  {
    die "The built relocatable binary appears broken";
  }

  my $slugline = slugline("$perl_dir/v$version/bin/perl");
  my $orig_dir = &get_project_dir;
  my $output   = "$slugline.tar.$compress";
  chdir $perl_dir;
  run("tar cf - v$version/ | $compress > $orig_dir/$output");

  success $verstr, "Created $verstr: $output";

  return 0;
}

sub _install_binary
{
  my $src_dir  = shift;
  my $version  = shift;
  my @src_dirs = File::Spec->splitdir("$src_dir");
  my $dest_dir = &dest_dir;
  my $perl_dir = File::Spec->catdir( $dest_dir, 'perl' );

  info $version, "Installing $version";

  use File::Copy qw/copy move/;
  use File::Path qw/make_path/;
  use Fatal qw/copy move/;

  chdir $dest_dir;
  my $output = eval { run "$src_dir/bin/perl", '-e', 'print $^V' };
  chomp $output;

  if ( $output ne "v$version" )
  {
    die qq{Binary versions mismatch expectations: }
      . qq{"$output" (found) ne "$version" (expected)};
  }

  # Attempt to run something more rigorous
  if ( !_check_perl_binary( "$src_dir/bin/perl" ) )
  {
    die qq{Binary does not appear to be usable};
  }

  make_path($perl_dir);
  move( $src_dir, $perl_dir );

  success "Installed binary $version";

  return 0;
}

sub _dnld_url
{
  my $version = shift;
  my $minor   = shift;
  my $mirror  = 'http://www.cpan.org/src/5.0';

  return "$mirror/perl-5.$version.$minor.tar.gz";
}

sub _get_targz
{
  my $src = shift;

  # If there's no src, find the newest version.
  if ( !defined $src )
  {
    # Do a terrible job of guessing what the current version is
    use Time::localtime;
    my $year = localtime->year() + 1900;

    # 5.12 was released in 2010, and approximatly every May, a new even
    # version was released
    my $major = ( $year - 2010 ) * 2 + ( localtime->mon < 4 ? 10 : 12 );

    # Verify our guess
    {
      my $dnld     = _dnld_url( $major, 0 ) . ".md5.txt";
      my $contents = '';
      my $where    = eval { fetch_file( $dnld => \$contents ) };

      if ( !defined $where && $major > 12 )
      {
        $major -= 2;
        redo;
      }
    }
    $src = "5.$major";
  }

  # file

  if ( -e $src )
  {
    return ( rel_start_to_abs($src), '' );
  }

  my $url;

  # URL
  if ( $src =~ url_re )
  {
    return ( $src, '' );
  }

  # CPAN
  if ( $src =~ $perl5_re )
  {
    my $version = $1;
    my $minor   = $2;

    # They probably want the latest if minor wasn't given
    if ( !defined $minor )
    {
      # 11 is the highest minor version seen as of this writing
      my @possible = ( 0 .. 15 );

      while ( @possible > 1 )
      {
        my $i = int( @possible / 2 );
        $minor = $possible[$i];
        my $dnld     = _dnld_url( $version, $minor ) . ".md5.txt";
        my $contents = '';
        my $where    = eval { fetch_file( $dnld => \$contents ) };

        if ( defined $where )
        {
          # The version exists, which means it's higher still
          @possible = @possible[ $i .. $#possible ];
        }
        else
        {
          # The version doesn't exit. That means higher versions don't either
          @possible = @possible[ 0 .. $i - 1 ];
        }
      }
      $minor = $possible[0];
    }

    return ( _dnld_url( $version, $minor ), "5.$version.$minor" );
  }

  die "Cannot find $src\n";
}

1;
__END__

=encoding utf-8

=head1 NAME

App::MechaCPAN::Perl - Mechanize the installation of Perl.

=head1 SYNOPSIS

  # Install 5.24 into local/
  user@host:~$ mechacpan perl 5.24

=head1 DESCRIPTION

The C<perl> command is used to install L<perl> into C<local/>. This removes the packages dependency on the operating system perl.

=head2 Methods

=head3 go( \%opts, $version )

There is only a single public function that should be called. This will install the version of perl given in C<$version> using the options in C<\%opts>. The options available are listed in the L<arguments|/Arguments> section below.

C<$version> is either 0 or 1 parameter:

=over

=item If 0 parameters are given and there is a .perl-version file, it will try and use that as the version to install.

=item Otherwise, if 0 parameters are given, it will attempt to find and install the newest, stable version of perl.

=item If the parameter is a major version (5.XX), it will attempt to find and install the newest minor version of that major version.

=item If the parameter is a minor version (5.XX.X), it will attempt to download and install that exact version.

=item If the parameter is a file, it will try to use that file as a perl source tarball.

=item If the parameter is a file, and it contains an executable "bin/perl", it will try to install that file as a binary perl tarball.

=item If the parameter looks like a URL, it will fetch that URL and try to use it as a perl source tarball.

=back

=head2 Arguments

=head3 threads

By default, perl is compiled without threads. If you'd like to enable threads, use this argument.

=head3 shared-lib

By default, perl will generate a libperl.a file.  If you need libperl.so, then use this argument.

=head3 build-reusable

Giving this options will change the mode of operation from installing L<perl> into C<local/> to generating a reusable, relocatable L<perl> archive. This uses the same parameters (i.e. L</devel> and L</threads>) to generate the binary, although do note that the C<lib/> directory is always included unless L</skip-lib> is provided. The archive name will generally reflect what systems it can run on. Because of the nature of how L<perl> builds binaries, it cannot guarantee that it will work on any given system, but if will have the best luck if you use it on the same version of a distribution.

Once you have a reusable binary archive, C<App::MechaCPAN::Perl> can use that archive as a source file and install the binaries into the local directory. This can be handy if you are building a lot of identical systems and only want to build L<perl> once.

=head3 jobs

How many make jobs to use when running make. The code must guess if make supports running multiple jobs, and as such, it may not work for all versions of make. Defaults to 2.

=head3 skip-tests

Test for perl are ran by default. If you are sure that the tests will pass and you want to save some time, you can skip the testing phase with this option.

=head3 smart-tests

As an alternative to telling C<App::MechaCPAN::Perl> to use tests or not, C<App::MechaCPAN::Perl> can try to be clever and guess if it needs to run tests. If there is a C<.perl-version> file and it is the same version that is being installed, then tests will be skips. The thinking is that if there is a C<.perl-version> file, then it is likely that perl has been installed and tested before.

C<smart-tests> are off by default, but are enabled by L<App::MechaCPAN::Deploy> when there is a C<cpanfile.snapshot> file. See L<App::MechaCPAN::Install/smart-tests>.

=head3 skip-local

Since perl and modules will be installed by L<App::MechaCPAN> into C<local/>, by default C<local/> will be added to C<@INC>. This means that if you use the C<local/> installed perl you do not need to use L<local::lib> or other C<@INC> tricks. If you want to suppress this behavior, use this flag.

=head3 skip-lib

If a C<lib/> directory exists in the same directory as the C<local/> directory, then C<lib/> will also bee added to C<@INC>. This is helpful if you're installing to run an application that includes a C<lib/> directory. If you do not want this to be added, use this flag.

=head3 devel

By default, perl will not compile a development version without -Dusedevel passed to configure. This adds that flag to the configure step so that perl will install unstable development versions. This is B<NOT> recommended except for testing.

=head1 WIN32 LIMITATION

Building perl from scratch on Win32 is nothing like building it on other platforms. At this point, the perl command does not work on Win32.

=head1 AUTHOR

Jon Gentle E<lt>cpan@atrodo.orgE<gt>

=head1 COPYRIGHT

Copyright 2017- Jon Gentle

=head1 LICENSE

This is free software. You may redistribute copies of it under the terms of the Artistic License 2 as published by The Perl Foundation.

=head1 SEE ALSO

=over

=item L<plenv|https://github.com/tokuhirom/plenv>

=item L<App::perlbrew>

=back

=cut
