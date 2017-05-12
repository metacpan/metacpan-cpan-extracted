require 5.006 ;
use ExtUtils::MakeMaker;
use strict;

WriteMakefile (
        NAME            => 'Bundle::Compress::Zlib',
        VERSION_FROM    => 'lib/Bundle/Compress/Zlib.pm', # finds $VERSION
        dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
        (
            $] >= 5.005
                ? (ABSTRACT_FROM => 'lib/Bundle/Compress/Zlib.pm',
                   AUTHOR        => 'Kevin W. Henwood <Khen1950fx@aol.com> and Paul Marquess <pmqs@cpan.org>')
                : ()
        ),
        (
            ExtUtils::MakeMaker->VERSION() gt '6.30' 
                ?  ('LICENSE'  => 'perl')         
                : ()
        ),

    );  

