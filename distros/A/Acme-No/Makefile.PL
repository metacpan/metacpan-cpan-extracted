use 5.005_03;

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Acme::No',
    'VERSION_FROM'	=> 'No.pm',
    'PREREQ_PM'		=> {Test::More => 0.44,
                            Filter::Util::Call => 1.06,
                            File::Spec => 0.8,
                            IO::File => 0,
                            Carp => 0},
    clean        	=> { FILES => 't/lib/*.pl t/lib/*.pm' },
);
