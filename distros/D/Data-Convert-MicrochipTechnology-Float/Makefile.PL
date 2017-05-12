

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Data::Convert::MicrochipTechnology::Float',
    VERSION_FROM => 'lib/Data/Convert/MicrochipTechnology/Float.pm', # finds \$VERSION
    AUTHOR       => 'Michael R. Davis (account=>perl,tld=>com,domain=>michaelrdavis)',
    ABSTRACT     => 'Converts Microchip Technology 32 bit Float to a perl number',
    PREREQ_PM    => {
                     'Test::More' => 0,
                     'Test::Number::Delta' => 0,
                     'vars' => 0,
                     'strict' => 0,
                    },
);
