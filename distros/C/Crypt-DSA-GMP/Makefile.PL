use ExtUtils::MakeMaker;

WriteMakefile1(
    NAME         => 'Crypt::DSA::GMP',
    ABSTRACT     => 'DSA Signatures and Key Generation',
    VERSION_FROM => 'lib/Crypt/DSA/GMP.pm',
    LICENSE      => 'perl_5',
    AUTHOR       => 'Dana A Jacobsen <dana@acm.org>',

    BUILD_REQUIRES=>{
                      'Test::More'       => '0.45',
                    },
    PREREQ_PM    => {
                      'Digest::SHA'            => '5.22',
                      'MIME::Base64'           => 0,
                      'Data::Buffer'           => '0.04',  # new_with_init
                      'Math::BigInt'           => '1.78',  # try
                      'Math::BigInt::GMP'      => 0,
                      'Math::Prime::Util::GMP' => '0.15',  # M-R random
                      'Crypt::Random::Seed'    => 0,
                      'Exporter'               => '5.562',
                      'Carp'                   => 0,
                      'base'                   => 0,
                    },
    META_MERGE   => {
               'meta-spec'  => {
                  version => '2',
                  url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
               },
               no_index => { package => ['BufferWithInt'] },
               resources    => {
                  homepage   => 'https://github.com/danaj/Crypt-DSA-GMP',
                  repository => 'https://github.com/danaj/Crypt-DSA-GMP',
               },
               recommends   => {
                  'Convert::PEM'   => '0.07', # For Crypt::DSA::GMP::Key::PEM
                  'Convert::ASN1'  => 0,      # To serialize/deserialize sigs
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
