package t::test;

use strict;
use warnings;

use Path::Class;
use lib file(__FILE__)->dir->parent->subdir('lib')->stringify;
use lib lib => 't/lib' => glob 'modules/*/lib';


sub import {
    my ($class) = @_;

    strict->import;
    warnings->import;

    my ($package, $file) = caller;

    my $code = qq[
        package $package;
        use strict;
        use warnings;

        use parent qw(Test::Class);
        use Test::More;
        use Test::Fatal qw(lives_ok dies_ok exception);
        use Test::Deep;
        use Test::Deep::JSON;

        END { $package->runtests }
    ];

    eval $code;
    die $@ if $@;
}

1;
