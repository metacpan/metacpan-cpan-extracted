use strict;
use warnings;
use Test::More tests => 5;

use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN {
    use_ok 'CatalystX::Test::MessageDriven', 'StompTestApp' or die;
};

# successful request - type is minimum attributes
my $req = "---\ntype: ping\n";
my $res = request('testcontroller', $req);
ok($res, 'response to ping message');
ok($res->is_success, 'successful response');

# unsuccessful empty request - no type
$req = "--- ~\n";
$res = request('testcontroller', $req);
ok($res, 'response to empty message');
ok($res->is_error, 'unsuccessful response');

