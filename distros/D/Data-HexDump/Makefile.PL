# -*- mode: Perl -*-

use ExtUtils::MakeMaker;

WriteMakefile(NAME         => "Data::HexDump",
              VERSION_FROM => "lib/Data/HexDump.pm",
              dist         => { COMPRESS => "gzip", SUFFIX => "gz" },
              clean        => { FILES => '*.bak *.old mibs/*.dump lib/*/*~' },
              EXE_FILES    => [ qw(hexdump) ],
);
