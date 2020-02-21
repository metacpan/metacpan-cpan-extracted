use strict;
use warnings;

BEGIN {
  unless(eval q{ use 5.008001; 1 })
  {
    print "Sorry!  Perl 5.8.1 or better required\n";
    exit;
  }
}

use ExtUtils::MakeMaker;
use File::Path qw( rmtree );
use Config;

my %args = (
  ABSTRACT           => 'Discover or download and install pkgconf + libpkgconf',
  AUTHOR             => [ 'Graham Ollis <plicease@cpan.org>' ],
  DISTNAME           => 'Alien-pkgconf',
  LICENSE            => 'perl',
  MIN_PERL_VERSION   => '5.008001',
  NAME               => 'Alien::pkgconf',
  VERSION_FROM       => 'lib/Alien/pkgconf.pm',

  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => 0,
    'JSON::PP'            => '2.27400',
  },
  TEST_REQUIRES      => {
    'Test2'        => '1.302073',
    'Test2::V0'    => '0.000065',
    'Test::Alien'  => '0.08',
  },
  BUILD_REQUIRES => {
    'HTTP::Tiny'           => '0.044',
    'Archive::Tar'         => '2.24',
    'JSON::PP'             => '2.27400',
    # as of 1.2.1 upstream provides .gz
    # packages again
    #'Alien::xz'            => '0.01',
  },
  PREREQ_PM => {
    'File::ShareDir' => '1.102',
  },

  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url  => "http://github.com/Perl5-Alien/Alien-pkgconf.git",
        web  => "http://github.com/Perl5-Alien/Alien-pkgconf",
      },
      bugtracker => "http://github.com/Perl5-Alien/Alien-pkgconf/issues",
      x_MailingList => "https://groups.google.com/forum/#!forum/perl5-alien",
      x_IRC => "irc://irc.perl.org/#native",
    },
    dynamic_config => 1,
  },

);

if($^O eq 'cygwin' || $^O eq 'solaris')
{
  $args{BUILD_REQUIRES}->{'Alien::patch'} = '0.09';
}

my($dll) = eval {
  require FFI::CheckLib;
  FFI::CheckLib::find_lib_or_die(
    lib => 'pkgconf',
  );
};

my $install_type = 'share';

rmtree '_alien', 0, 0 if -d '_alien';

eval {

  die "ALIEN_FORCE" if $ENV{ALIEN_FORCE};
  die "ALIEN_INSTALL_TYPE" if defined $ENV{ALIEN_INSTALL_TYPE}
                           && $ENV{ALIEN_INSTALL_TYPE} eq 'share';

  system 'pkgconf', '--atleast-version=1.5.2', 'libpkgconf';
  die "no pkgconf" if $?;
  my $cflags = `pkgconf --cflags libpkgconf`;
  die "getting cflags" if $?;
  chomp $cflags;
  my $libs   = `pkgconf --libs libpkgconf`;
  die "getting libs" if $?;
  chomp $libs;
  my $version = `pkgconf --modversion libpkgconf`;
  die "getting version" if $?;
  chomp $version;

  require File::Spec;
  require JSON::PP;
  my $status_filename = File::Spec->catfile('_alien', '05stage.json');
  mkdir '_alien' unless -d '_alien';
  open my $fh, '>', $status_filename;
  print $fh JSON::PP::encode_json({
    cflags       => $cflags,
    libs         => $libs,
    install_type => 'system',
    version      => $version,
    ($dll ? (dll => $dll ) : ()),
  });
  close $fh;

  $install_type = 'system';

};

my $error = $@;

if(defined $ENV{ALIEN_INSTALL_TYPE})
{
  if($ENV{ALIEN_INSTALL_TYPE} ne $install_type)
  {
    warn $error if $error;
    die "requested install type $ENV{ALIEN_INSTALL_TYPE}, but could not be accomidated";
  }
}

print "install type: $install_type\n";

if($install_type eq 'system')
{
  delete $args{BUILD_REQUIRES}->{$_} for qw( HTTP::Tiny Archive::Tar Alien::xz );
}
elsif($install_type eq 'share')
{
  $args{BUILD_REQUIRES}->{'IO::Socket::SSL'} = 1.56;
  $args{BUILD_REQUIRES}->{'Net::SSLeay'}     = 1.49;
}

if($^O eq 'MSWin32' && $install_type eq 'share')
{
  $args{BUILD_REQUIRES}->{'Alien::MSYS'} = '0.07';
}

my %fallback = (
  %{ $args{TEST_REQUIRES} },
  %{ $args{BUILD_REQUIRES} },
  %{ $args{PREREQ_PM} },
);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  $args{PREREQ_PM} = \%fallback;
  delete $args{TEST_REQUIRES};
  delete $args{BUILD_REQUIRES};
}

delete $args{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%args);

sub MY::postamble {

$install_type eq 'share'

? <<'SHARE_INSTALL'

alien_probe _alien/01probe.json:
	$(FULLPERL) script/probe.pl $(INSTALLDIRS) $(INSTALLARCHLIB) $(INSTALLSITEARCH) $(INSTALLVENDORARCH)

alien_fetch _alien/02fetch.json:
	$(FULLPERL) script/fetch.pl

alien_extract _alien/03extract.json: _alien/02fetch.json
	$(FULLPERL) script/extract.pl

alien_build: _alien/04build_dll.json _alien/04build_static.json

alien_build_dll _alien/04build_dll.json : _alien/03extract.json _alien/01probe.json
	$(FULLPERL) script/build.pl dll

alien_build_static _alien/04build_static.json : _alien/03extract.json _alien/01probe.json
	$(FULLPERL) script/build.pl static

alien_stage _alien/05stage.json: _alien/04build_dll.json _alien/04build_static.json
	$(FULLPERL) script/stage.pl

alien_clean:
	$(FULLPERL) script/clean.pl

pure_all :: _alien/05stage.json

realclean purge :: alien_clean

SHARE_INSTALL

: <<'SYSTEM_INSTALL';

alien_system _alien/00system.json : _alien/05stage.json
	$(FULLPERL) script/system.pl

alien_clean:
	$(FULLPERL) script/clean.pl

pure_all :: _alien/00system.json

realclean purge :: alien_clean

SYSTEM_INSTALL

}
