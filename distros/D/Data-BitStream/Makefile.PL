use ExtUtils::MakeMaker;

WriteMakefile1(
    NAME         => 'Data::BitStream',
    ABSTRACT     => "A class implementing a stream of bits and coding methods",
    VERSION_FROM => 'lib/Data/BitStream.pm', # finds $VERSION
    LICENSE      => 'perl',
    AUTHOR       => 'Dana A Jacobsen <dana@acm.org>',

    TEST_REQUIRES => {
                     # I'm using subtest.  Could go back to 0.82 without it.
                     'Test::More'       => '0.94',
                     },
    PREREQ_PM => {
                     # Using just the import method of Exporter
                     'Exporter'         => '5.57',
                     'Carp'             => 0,

                     # This module used to use Mouse:
                     # 'Mouse'            => '0.58',
                     # 'Mouse::Role'      => '0.58',
                     # Then we tied Moose (2.0205 - 2.0602):
                     # 'Moose'            => 0,
                     # 'Moose::Role'      => 0,
                     # 'MooseX::Types::Moose' => 0,
                     # And now Moo.
                      'Moo'                    => 1.000006,
                      'Moo::Role'              => 0,
                      'MooX::Types::MooseLike' => 0,
                     # Technically not needed, but big performance help
                      'Class::XSAccessor'      => 0,
                 },

    META_MERGE => {
                    resources  => {
                      license    => [ 'http://dev.perl.org/licenses/' ],
                      homepage   => 'https://github.com/danaj/BitStream',
                      repository => {
                        url  => 'https://github.com/danaj/BitStream',
                      },
                    },
                    prereqs => {
                      runtime => {
                        recommends => { 'Data::BitStream::XS' => 0.06, },
                      },
                    },
                    optional_features => {
                          bitvec =>  {
                              description => 'The Bit::Vector implementation, just for example',
                              requires => { 'Bit::Vector' => 0, },
                          },
                          mpu =>  {
                              description => 'Fast primes for Goldbach codes, if Data::BitStream::XS is not available',
                              requires => { 'Math::Prime::Util' => 0, },
                          },
                          release_testing =>  {
                              description => 'Extra modules for author testing',
                              requires => { 'Test::Pod' => 1.41,
                                            'Test::Pod::Coverage' => 1.08,
                                            'Test::Perl::Critic' => 0,
                                            'Test::Kwalitee' => 0,
                                          },
                          },
                    },
                  },

    # I have not tested with any version of Perl previous to 5.6.2.  v5.6.2
    # does work, though is forced to 32-bit if it detects 64-bit arithmetic is
    # broken.  Data::BitStream::XS works fine on 5.6.2 because it is using C
    # for the bit operations.
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
