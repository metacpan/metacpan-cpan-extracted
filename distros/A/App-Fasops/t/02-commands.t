use strict;
use warnings;
use Test::More tests => 3;
use App::Cmd::Tester;

use App::Fasops;

my $result = test_app( 'App::Fasops' => [qw(commands )] );

like(
    $result->stdout,
    qr{list the application's commands},
    'default commands outputs'
);

is( $result->stderr, '', 'nothing sent to sderr' );

is( $result->error, undef, 'threw no exceptions' );
