use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Dancer::Plugin::Auth::Facebook',
    AUTHOR        => 'Prajith <prajith@ndimensionz.com, prajithpalakkuda@gmail.com>',
    VERSION_FROM  => 'lib/Dancer/Plugin/Auth/Facebook.pm',
    ABSTRACT_FROM => 'lib/Dancer/Plugin/Auth/Facebook.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Dancer'                => 0,
        'Dancer::Plugin'        => 0,
        'Carp'                  => 0,
        'Net::Facebook::Oauth2' => 0.10,
    },
    META_MERGE => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            bugtracker  => 'https://github.com/Prajithp/Dancer-Plugin-Auth-Facebook/issues',
            repository  => 'https://github.com/Prajithp/Dancer-Plugin-Auth-Facebook',
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Dancer-Plugin-Auth-Facebook*' },
);

