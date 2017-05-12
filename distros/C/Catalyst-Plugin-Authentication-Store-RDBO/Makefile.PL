
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Catalyst::Plugin::Authentication::Store::RDBO',
    AUTHOR        => 'Uwe Voelker <uwe.voelker@gmx.de>',
    VERSION_FROM  => 'lib/Catalyst/Plugin/Authentication/Store/RDBO.pm',
    ABSTRACT_FROM => 'lib/Catalyst/Plugin/Authentication/Store/RDBO.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
                      'Catalyst::Plugin::Authentication' => 0,
                      'Rose::DB::Object'                 => 0,
                      'Set::Object'                      => 0,
                      'Test::More'                       => 0,
                     },
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean         => { FILES => 'lib/Catalyst/Plugin/Authentication/Store/RDBO.pm-*' },
);
