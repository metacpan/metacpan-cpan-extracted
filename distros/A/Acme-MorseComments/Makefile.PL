use 5.000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Acme::MorseComments',
    VERSION_FROM      => 'lib/Acme/MorseComments.pm',
    PREREQ_PM         => { PPI => 0.8 },
    ($] >= 5.005
        ? (ABSTRACT_FROM  => 'lib/Acme/MorseComments.pm',
           AUTHOR         => 'Justin Wheeler '
                           . '<morsecomments@datademons.com>')
        : ()),
);
