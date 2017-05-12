# use 5.008;

use strict;

use lib qw(inc);
use Config;
use Devel::CheckLib;
use ExtUtils::MakeMaker;

# Check that we have a C compiler
check_lib_or_exit();

my %mm_args = (
  ( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),
  NAME          => 'Data::Structure::Util',
  AUTHOR        => 'Andy Armstrong <andy@hexten.net>',
  VERSION_FROM  => 'lib/Data/Structure/Util.pm',
  ABSTRACT_FROM => 'lib/Data/Structure/Util.pm',
  PL_FILES      => {},
  PREREQ_PM     => {
    'Digest::MD5'  => 0,
    'Scalar::Util' => '1.01',
    'Storable'     => 0,
  },
  TEST_REQUIRES => {
    'Test::More'   => 0,
    'Test::Pod'    => 0,
    'Test::Simple' => 0,
  },
  LICENSE => 'perl',
  MIN_PERL_VERSION => '5.008',
  META_MERGE => {
    resources => {
      repository => 'https://github.com/AndyA/Data--Structure--Util',
    },
  },
  LIBS   => [''],
  DEFINE => '',
  INC    => '',
  dist   => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES => 'Data-Structure-Util-*' },
);

WriteMakefile1( %mm_args );

sub WriteMakefile1 {  #Compatibility code for old versions of EU::MM. Written by Alexandr Ciornii, version 0.23. Added by eumm-upgrade.
  my %params=@_;
  my $eumm_version=$ExtUtils::MakeMaker::VERSION;
  $eumm_version=eval $eumm_version;
  die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
  die "License not specified" if not exists $params{LICENSE};
  if ($params{AUTHOR} and ref($params{AUTHOR}) eq 'ARRAY' and $eumm_version < 6.5705) {
    $params{META_ADD}->{author}=$params{AUTHOR};
    $params{AUTHOR}=join(', ',@{$params{AUTHOR}});
  }
  if ($params{TEST_REQUIRES} and $eumm_version < 6.64) {
    $params{BUILD_REQUIRES}={ %{$params{BUILD_REQUIRES} || {}} , %{$params{TEST_REQUIRES}} };
    delete $params{TEST_REQUIRES};
  }
  if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
    #EUMM 6.5502 has problems with BUILD_REQUIRES
    $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
    delete $params{BUILD_REQUIRES};
  }
  delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
  delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
  delete $params{META_MERGE} if $eumm_version < 6.46;
  delete $params{META_ADD} if $eumm_version < 6.46;
  delete $params{LICENSE} if $eumm_version < 6.31;
  delete $params{AUTHOR} if $] < 5.005;
  delete $params{ABSTRACT_FROM} if $] < 5.005;
  delete $params{BINARY_LOCATION} if $] < 5.005;

  WriteMakefile(%params);
}

