use strict;
use warnings;
use Test::More;

# If an Error in thrown in the code, is it caught and sent back to us
# as a bless object in YAML form, or is it stringyfied into an error message
#

use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN {
    eval {
        require YAML;
        YAML->import('Load', 'Dump')
    };
    if ($@) {
	plan 'skip_all' => 'YAML not installed, skipping message-catch-error test';
        exit;
    }
}

BEGIN {
    plan tests => 6;
    use_ok 'CatalystX::Test::MessageDriven', 'StompTestApp' or die;
};


# successful request - type is minimum attributes
my $req = "---\ntype: ping\n";
my $res = request('testcontroller', $req);
ok($res, 'response to ping message');
ok($res->is_success, 'successful response');

# successful request - type will trigger an error object to be thrown
$req = "---\ntype: throwerror\n";
$res = request('testcontroller', $req);
ok($res, 'response to throwerror message');
ok(!$res->is_success, 'unsuccessful response');

my $response;

eval {
    $response = Load($res->content);
};

ok( ref($response) eq 'StompTestApp::Error', 'successful error thrown');
