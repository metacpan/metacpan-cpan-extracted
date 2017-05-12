use strict;
use warnings;
use Test::More;
use FindBin;

use lib ( "$FindBin::Bin/lib", "$FindBin::Bin/../lib" );
use Test::Rest;

use_ok 'Catalyst::Test', 'Test::Serialize';

my $t = Test::Rest->new( 'content_type' => 'text/view' );

my $monkey_template = "I am a simple view";
my $mres = request( $t->get( url => '/monkey_get' ) );
ok( $mres->is_success, 'GET the monkey succeeded' );
is( $mres->content, $monkey_template, "GET returned the right data" );

my $mres_post = request( $t->post( url => '/monkey_put', data => 1 ) );
ok( $mres_post->is_success, "POST to the monkey passed." );

my $t2 = Test::Rest->new( 'content_type' => 'text/explodingview' );
my $res = request( $t2->get( url => '/monkey_get' ) );

ok (! $res->is_success, 'View errors result in failure');
like( $res->content, qr/don't know how/, 'The error looks okay');

1;

done_testing;
