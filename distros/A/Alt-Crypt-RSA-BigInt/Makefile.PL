use ExtUtils::MakeMaker;
use lib 'inc'; # load our bundled version of Devel::CheckLib
use Devel::CheckLib;

my %bigint_preq;

if ( check_lib(lib => 'gmp', header => 'gmp.h') ) {
  # GMP found.  Life is *good*.
  %bigint_preq = (
                      'Math::BigInt::GMP'      => 0,
                      'Math::Prime::Util::GMP' => 0,
                 );
} elsif ( check_lib(lib => 'pari', header => 'pari/pari.h') ) {
  # Pari found.  Slower than GMP in this application, but still adequate.
  %bigint_preq = (
                      'Math::BigInt::Pari'     => 0,
                 );
} else {
  # Yech, no big int libraries found.
  print <<EO_BIGINT;
 

 **********************************************************
 *
 * Building without GMP or Pari support.
 *
 * Operations will be very slow.
 *
 * Strongly consider installing GMP and Math::BigInt::GMP.
 *
 **********************************************************
EO_BIGINT
}

WriteMakefile1(
    NAME         => 'Alt::Crypt::RSA::BigInt',
    ABSTRACT     => 'RSA public-key cryptosystem, using Math::BigInt',
    VERSION_FROM => 'lib/Alt/Crypt/RSA/BigInt.pm',
    LICENSE      => 'perl',
    AUTHOR       => 'Dana A Jacobsen <dana@acm.org>',

    BUILD_REQUIRES=>{
                      'Test::More'       => '0.45',
                      'Benchmark'        => 0,
                      'MIME::Base64'     => 0,
                    },
    PREREQ_PM    => {
                      'Math::BigInt'           => '1.78', # try => backend
                      'Math::Prime::Util'      => '0.64', # built in csprng
                      'Carp'                   => 0,
                      'Exporter'               => 0,
                      'Crypt::CBC'             => '2.17',
                      'Crypt::Blowfish'        => 0,
                      'Data::Dumper'           => 0,
                      'Tie::EncryptedHash'     => 0,
                      'Convert::ASCII::Armour' => 0,
                      'Sort::Versions'         => 0,
                      'Digest::SHA'            => 0,
                      'Digest::MD5'            => 0,
                      'Digest::MD2'            => 0,
                      'Class::Loader'          => 0,
                      'Data::Buffer'           => 0,
                      %bigint_preq,
                    },

    # This should be worked on.  For now, no 5.6.x.
    MIN_PERL_VERSION => 5.008,
    META_MERGE   => {
                      'meta-spec'  => { version => '2' },
                      dynamic_config => 1,  # Check for GMP on install
                      no_index   => { directory => [qw(lib/Crypt)] },
                      resources  => {
                         homepage   => 'https://github.com/danaj/Alt-Crypt-RSA-BigInt',
                         repository => 'git://github.com/danaj/Alt-Crypt-RSA-BigInt.git',
                       },
                      recommends => {
                        'Crypt::RIPEMD160' => 0.05,
                      },
                    },
);

sub WriteMakefile1 {   # Cribbed from eumm-upgrade by Alexandr Ciornii
  my %params = @_;
  my $eumm_version = $ExtUtils::MakeMaker::VERSION;
  $eumm_version = eval $eumm_version;

  if ($params{TEST_REQUIRES} and $eumm_version < 6.6303) {
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
