use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Banal::Config',
    AUTHOR           => q{"aulusoy" <"dev (at) ulusoy.name">},
    VERSION_FROM     => 'lib/Banal/Config.pm',
    ABSTRACT_FROM    => 'lib/Banal/Config.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
    	'Carp'				=> 1.25,
     	'Carp::Heavy'		=> 0,
      	'Data::Dumper'		=> 2.00,
    	'Scalar::Util'		=> 1.35,
    	'File::Spec'		=> 0,

    	'Banal::DateTime'   => 0.02,
        'Banal::Utils'      => 0.05,
        
        'Config::General'   => 2.56,
        'Moose' 			=> 2.00,
       
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Banal-Config-*' },
);
