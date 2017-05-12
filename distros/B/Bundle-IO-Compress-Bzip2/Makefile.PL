require 5.006 ;
use ExtUtils::MakeMaker;
use strict;

WriteMakefile (
        NAME            => 'Bundle::IO::Compress::Bzip2',
        VERSION_FROM    => 'lib/Bundle/IO/Compress/Bzip2.pm', # finds $VERSION
        dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
        (
            $] >= 5.005
                ? (ABSTRACT_FROM => 'lib/Bundle/IO/Compress/Bzip2.pm',
                   AUTHOR        => 'Paul Marquess <pmqs@cpan.org>')
                : ()
        ),
        (
            ExtUtils::MakeMaker->VERSION() gt '6.30' 
                ?  ('LICENSE'  => 'perl')         
                : ()
        ),

    );  
