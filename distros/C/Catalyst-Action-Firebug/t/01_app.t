use Test::Base;

plan tests => 3;

use FindBin;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );

$ENV{FIREBUG_DEBUG} = 1;

use Catalyst::Test 'TestApp';
TestApp->setup;

ok( my $html = get('/'), 'Request ok' );
like( $html, qr!<html.*debug="true".*>!, 'Insert [debug="true"] ok' );
like( $html, qr!firebug\.js!, 'Insert firebug script ok' );

1;
