use ExtUtils::MakeMaker;

WriteMakefile1(
    NAME         => 'Data::BitStream::XS',
    ABSTRACT     => 'A class implementing a stream of bits and coding methods',
    VERSION_FROM => 'lib/Data/BitStream/XS.pm',
    LICENSE      => 'perl',
    AUTHOR       => 'Dana A Jacobsen <dana@acm.org>',

    LIBS         => [''],   # e.g., '-lm'
    DEFINE       => '',     # e.g., '-DHAVE_SOMETHING'
    INC          => '',     # e.g., '-I/usr/include/other'
    OBJECT       => 'bitlist.o sequences.o XS.o',

    TEST_REQUIRES => {
                     'Test::More'       => '0.45',
                     },
    PREREQ_PM    => {
                      'Exporter'         => '5.562',
                      'XSLoader'         => '0.01',
                      'Carp'             => 0,
                    },
    META_MERGE => {
                    resources  => {
                      license    => [ 'http://dev.perl.org/licenses/' ],
                      homepage   => 'https://github.com/danaj/BitStreamXS',
                      repository => {
                        url  => 'https://github.com/danaj/BitStreamXS',
                      },
                    },
                    prereqs => {
                      runtime => {
                        recommends => { 'Data::BitStream' => 0.08, },
                      },
                    },
                  },

    MIN_PERL_VERSION => 5.006002,
);

sub WriteMakefile1 {
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
