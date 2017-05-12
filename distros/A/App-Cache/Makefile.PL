#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    'PL_FILES'     => {},
    'INSTALLDIRS'  => 'site',
    'NAME'         => 'App::Cache',
    'VERSION_FROM' => 'lib/App/Cache.pm',
    'ABSTRACT'     => 'Easy application-level caching',
    'LICENSE'      => 'perl',
    'AUTHOR'       => 'Leon Brocard <acme@astray.com>',
    'PREREQ_PM'    => {
        'File::Find::Rule'               => '0',
        'File::HomeDir'                  => '0',
        'Storable'                       => '0',
        'HTTP::Cookies'                  => '0',
        'Test::More'                     => '0',
        'Class::Accessor::Chained::Fast' => '0',
        'LWP::UserAgent'                 => '0',
        'Path::Class'                    => '0',
        'File::stat'                     => '0'
    }
);

