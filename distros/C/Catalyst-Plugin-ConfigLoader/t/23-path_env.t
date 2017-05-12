use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More;

BEGIN {
    eval { require Catalyst; Catalyst->VERSION( '5.80001' ); };

    plan skip_all => 'Catalyst 5.80001 required' if $@;
    plan tests => 3;

    $ENV{ TESTAPP_CONFIG } = 'test.perl';
    use_ok 'Catalyst::Test', 'TestApp';
}

ok my ( $res, $c ) = ctx_request( '/' ), 'context object';

is_deeply [ $c->get_config_path ], [ qw( test.perl perl ) ], 'path is "test.perl"';
