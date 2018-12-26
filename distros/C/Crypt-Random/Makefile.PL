use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	       => 'Crypt::Random',
    'AUTHOR'       => 'Vipul Ved Prakash <mail@vipul.net>',
    'VERSION_FROM' => 'lib/Crypt/Random.pm',
    'EXE_FILES'    => [ 'bin/makerandom' ],
    'PREREQ_PM'    => { 'Math::Pari' => '2.001804', 
                        'Class::Loader' => '2.00',
                        'Statistics::ChiSquare' => '1.0000'
                      } 
);
