use strict;
use warnings;
use Test::More;

use lib qw 't/lib';
use BracketTestSchema;

ok( BracketTestSchema->init_schema(populate => 1),
    'Populate test schema and create config file to be used by subsequent tests'
);
$ENV{CATALYST_CONFIG} = 't/var/bracket.yml';
use_ok( 'Catalyst::Test', 'Bracket' );

ok( request('/login')->is_success, 'Request /login' );

done_testing();