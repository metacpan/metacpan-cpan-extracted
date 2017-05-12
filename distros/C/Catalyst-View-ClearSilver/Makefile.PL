use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Catalyst::View::ClearSilver',
    AUTHOR        => 'Jiro Nishiguchi <jiro@cpan.org>',
    VERSION_FROM  => 'lib/Catalyst/View/ClearSilver.pm',
    PL_FILES      => {},
    PREREQ_PM => {
        'Test::More'  => 0.32,
        'ClearSilver' => 0,
        'Catalyst'    => 5.60,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Catalyst-View-ClearSilver-*' },
);
