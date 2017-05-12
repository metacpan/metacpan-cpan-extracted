use Test::More tests => 3;

use FindBin;
use lib "$FindBin::Bin/lib";

use Catalyst::Test qw/TestApp/;

my $content = get('/');
like( $content, qr/h1 {/,'Correctly merged css.');
like( $content, qr/h1\s{.+h1\s{.+h2\s{/mxs,'Correctly merged css.');
my $content = get('/test');
like( $content, qr/h1\s{.+h1\s{.+h2\s{/mxs,'Also with Hashref.');

