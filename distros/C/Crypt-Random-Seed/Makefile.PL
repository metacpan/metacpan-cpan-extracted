use 5.006000;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %os_prereq;

if ($^O eq 'MSWin32') {
  # Make sure we use a newish version of Win32::API for 64-bit
  my $api_version = (~0 > 281474976710656) ? 0.62 : 0;
  %os_prereq = (
                       'Win32'            => 0,
                       'Win32::API'       => $api_version,
                       #'Win32::API::Type' => 0,  # a submodule of Win32::API
               );
}

WriteMakefile1(
    NAME         => 'Crypt::Random::Seed',
    ABSTRACT     => "Provide strong randomness for seeding",
    VERSION_FROM => 'lib/Crypt/Random/Seed.pm', # finds $VERSION
    LICENSE      => 'perl',
    AUTHOR       => 'Dana A Jacobsen <dana@acm.org>',

    BUILD_REQUIRES=>{
                      'Test::More'       => '0.45',
                    },
    PREREQ_PM     => {
                       'Exporter'        => '5.562',
                       'base'            => 0,
                       'constant'        => 0,
                       'Carp'            => 0,
                       'Fcntl'           => 0,
                       %os_prereq,
                       'Crypt::Random::TESHA2' => 0,
                     },

    META_MERGE    => {
                      resources  => {
                       homepage   => 'https://github.com/danaj/Crypt-Random-Seed',
                       repository => 'https://github.com/danaj/Crypt-Random-Seed',
                       },
                     },
    MIN_PERL_VERSION => 5.006002,
);

sub WriteMakefile1 {   # Cribbed from eumm-upgrade by Alexandr Ciornii
  my %params = @_;
  my $eumm_version = $ExtUtils::MakeMaker::VERSION;
  $eumm_version = eval $eumm_version;

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
