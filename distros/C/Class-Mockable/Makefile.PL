use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Class::Mockable',
    META_MERGE => {
        license => 'other',
        resource => {
	    repository => 'https://github.com/DrHyde/perl-modules-Class-Mockable'
        }
    },
  VERSION_FROM => 'lib/Class/Mockable.pm',
  PREREQ_PM    => {
    'Data::Compare'     => 0,
    'Data::Dumper'      => 0,
    'Scalar::Util'      => 0,
    'Test::More'        => 0,
    'Capture::Tiny'     => 0.21,
    'PadWalker'         => 1.0, # earlier versions don't have closed_over()
    'Test::Class'       => 0,
    'Test::Class::Load' => 0,
  },
);
