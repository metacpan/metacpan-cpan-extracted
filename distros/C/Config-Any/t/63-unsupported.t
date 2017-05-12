use strict;
use warnings;

use Test::More tests => 3;

use lib 't/lib';
use Config::Any;

{
    my $result = eval {
        Config::Any->load_files(
            { files => [ 't/conf/conf.unsupported' ], use_ext => 1 } );
    };

    ok( !defined $result, 'empty result' );
    ok( $@,               'error thrown' );
    like(
        $@,
        qr/required support modules are not available/,
        'error message'
    );
}
