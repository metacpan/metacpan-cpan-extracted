use ExtUtils::MakeMaker;
use strict;
use warnings;


WriteMakefile(
    'NAME'              => 'Compress::LZMA::Simple',
    'VERSION_FROM'      => 'lib/Compress/LZMA/Simple.pm',
    'INC'               => '-I/usr/local/include',
    'LIBS'              => '-L/usr/local/lib -llzma -lm -lc',
    'clean'             => { FILES => '*~ hoge moge' },
);
