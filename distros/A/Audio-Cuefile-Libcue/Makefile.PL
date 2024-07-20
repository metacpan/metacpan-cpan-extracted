use 5.006002;
use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Audio::Cuefile::Libcue',
    VERSION_FROM      => 'lib/Audio/Cuefile/Libcue.pm',
    ABSTRACT          => 'Perl interface to the libcue cuesheet reading library',
    AUTHOR            => 'Greg Kennedy <kennedy.greg@gmail.com>',
    LICENSE           => 'perl',
    LIBS              => ['-lcue'],
);
