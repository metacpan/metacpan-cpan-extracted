use strict;
use warnings;
use Test::More tests => 3;
use App::Cmd::Tester;

use App::Egaz;

my $result = test_app( 'App::Egaz' => [qw(commands )] );

like( $result->stdout, qr{list the application's commands}, 'default commands outputs' );

is( $result->stderr, '', 'nothing sent to sderr' );

is( $result->error, undef, 'threw no exceptions' );
