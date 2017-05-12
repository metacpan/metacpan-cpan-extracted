use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Burpsuite::Parser',
    AUTHOR              => 'Joshua "Jabra" Abraham < jabra@spl0it.org >',
    VERSION_FROM        => 'lib/Burpsuite/Parser.pm',
    ABSTRACT_FROM       => 'lib/Burpsuite/Parser.pod',
    PREREQ_PM           => {
                'Test::More'        => '0',
                'Test::Class'        => '0',
                'Object::InsideOut' => '0',
                'XML::LibXML'	    => '0',
    },
    'INSTALLDIRS' => 'site',    
    'dist' => {
        'SUFFIX'       => ".gz",
        'DIST_DEFAULT' => 'all tardist',
        'COMPRESS'     => "gzip -9f"
    },
    'realclean' => { 'FILES' => '' },
    'clean'     => { 'FILES' => '' },

);
