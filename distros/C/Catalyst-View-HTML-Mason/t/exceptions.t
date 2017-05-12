use strict;
use warnings;
use Test::More;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/lib";

use Catalyst::Test 'TestAppErrors';

if($Catalyst::VERSION > 5.90053) {
  plan skip_all => "This test doesn't work with your version of Catalyst";
}

is(get('/'), "tiger\n" x 2, 'Basic rendering' );

if ( $Catalyst::VERSION >= 5.89000 ) {
  my $res = request('/invalid_template');
  ok( ! $res->is_success, 'got a 500 when rendering nonexistent template' );
  like( $res->content, qr/Can't find component/, 'got expected error in body' );
}
else {
  dies_ok {
    get('/invalid_template');
  } 'Rendering nonexistent template dies as expected';
}

done_testing;
