package App::MechaCPAN::Perl;

use v5.14;
use autodie;
use Config;
use File::Fetch qw//;
use App::MechaCPAN qw/:go/;

our @args = (
  'threads!',
  'skip-tests!',
  'skip-local!',
  'skip-lib!',
  'smart-tests!',
  'devel!',
);

my $perl5_ver_re = qr/v? 5 [.] (\d{1,2}) (?: [.] (\d{1,2}) )?/xms;
my $perl5_re     = qr/^ $perl5_ver_re $/xms;

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

  my $orig_dir = &dest_dir;
  my @orig_dir = File::Spec->splitdir("$orig_dir");
  my $orig_len = $#orig_dir;
  my $dest_dir = "$orig_dir/perl";
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

  if ( -e -x "$dest_dir/bin/perl" )
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

  chdir $src_dir;

  if ( !-e 'Configure' )
  {
    my @files = glob('*');
    if ( @files > 1 )
    {
      die 'Could not find perl to configure';
    }
    chdir $files[0];
  }

  my $local_dir = File::Spec->catdir( @orig_dir, qw/lib perl5/ );
  my $lib_dir
    = File::Spec->catdir( @orig_dir[ 0 .. $orig_len - 1 ], qw/lib/ );

  my @otherlib = (
    !$opts->{'skip-local'} ? $local_dir : (),
    !$opts->{'skip-lib'} && -d $lib_dir ? $lib_dir : (),
  );

  my @config = (
    q[-des],
    qq[-Dprefix=$dest_dir],
    q[-Accflags=-DAPPLLIB_EXP=\"] . join( ":", @otherlib ) . q[\"],
    qq[-A'eval:scriptdir=$dest_dir/bin'],
  );

  if ( $opts->{threads} )
  {
    push @config, '-Dusethreads';
  }

  if ( $opts->{devel} )
  {
    push @config, '-Dusedevel';
  }

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
sub _run_configure
{
  my @config = @_;
  run qw[sh Configure], @config;
}

sub _run_make
{
  my @cmd = @_;
  state $make = $Config{make};
  run $make, @cmd;
}

sub _dnld_url
{
  my $version = shift;
  my $minor   = shift;
  my $mirror  = 'http://www.cpan.org/src/5.0';

  return "$mirror/perl-5.$version.$minor.tar.bz2";
}

sub _get_targz
{
  my $src = shift;

  local $File::Fetch::WARN;

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
      my $dnld = _dnld_url( $major, 0 ) . ".md5.txt";
      my $ff       = File::Fetch->new( uri => $dnld );
      my $contents = '';
      my $where    = $ff->fetch( to => \$contents );

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
    return ( $src, '' );
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
        my $dnld = _dnld_url( $version, $minor ) . ".md5.txt";
        my $ff       = File::Fetch->new( uri => $dnld );
        my $contents = '';
        my $where    = $ff->fetch( to => \$contents );

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

=item If the parameter looks like a URL, it will fetch that URL and try to use it as a perl source tarball.

=back

=head2 Arguments

=head3 threads

By default, perl is compiled without threads. If you'd like to enable threads, use this argument.

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
