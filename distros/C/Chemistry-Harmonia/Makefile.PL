use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Chemistry::Harmonia',
    VERSION_FROM      => 'lib/Chemistry/Harmonia.pm',
    LICENSE           => 'perl',
    PREREQ_PM         => {
	    'Algorithm::Combinatorics'	=> '0.27',
	    'Chemistry::File::Formula'	=> '0.37',
	    'String::CRC::Cksum'	=> '0.91',
	    'Math::Assistant'	=> '0.05',
	    'Math::BigInt'	=> '1.997',
	    'Math::BigRat'	=> '0.2602',
	    'Carp'		=> '0',
	    'Test::More'	=> '0.98',
	    'Test::LongString'	=> '0.15',
	    'Test::Pod'		=> '1.45',
	    'Data::Dumper'	=> '2.145',
    },
    dist => {
        COMPRESS => 'gzip -9f',
        SUFFIX => 'gz',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Chemistry/Harmonia.pm',
       AUTHOR         => 'Alessandro Gorohovski <an.gorohovski@gmail.com>') : ()),
);
