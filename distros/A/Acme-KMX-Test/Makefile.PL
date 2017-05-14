use ExtUtils::MakeMaker;
 
WriteMakefile(
  NAME          => 'Acme::KMX::Test',
  AUTHOR        => 'KMX <kmx@cpan.org>',
  VERSION_FROM  => 'lib/Acme/KMX/Test.pm',
  ABSTRACT_FROM => 'lib/Acme/KMX/Test.pm',
  PM => {
   'lib/Acme/KMX/Test.pm' => '$(INST_LIB)/Acme/KMX/Test.pm',
   'Pokus1.pm'            => '$(INST_LIB)/Acme/KMX/Pokus1.pm',
   'Pokus2.pm'            => '$(INST_LIB)/Acme/KMX/Pokus2.pm',
  },
  dist  => { TARFLAGS => '--owner=0 --group=0 -cvf' },
  clean => { FILES => 'Pokus1.pm Pokus2.pm' },
  META_MERGE   => {
    no_index => {
      file => [qw( Pokus1.pm.PL Pokus2.pm.PL )],
    },
    provides => {
      'Acme::KMX::Test'   => { file => 'lib/Acme/KMX/Test.pm' },
      'Acme::KMX::Pokus1' => { file => 'Pokus1.pm.PL' },
      'Acme::KMX::Pokus2' => { file => 'Pokus2.pm.PL' },
      #'Acme::KMX::Pokus1' => { file => 'GENERATED/Pokus1.pm' },
      #'Acme::KMX::Pokus2' => { file => 'GENERATED/Pokus2.pm' },
    },
  },
);
