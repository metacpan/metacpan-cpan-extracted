use strict;
use warnings;
use Test::More tests => 6;

use FindBin;
use lib "$FindBin::Bin/lib";

use Catalyst::Test 'TestApp';

my %actions = (
    one  => [qw(
        TestApp::ActionRole::First
    )],
    two  => [qw(
        TestApp::ActionRole::First
        TestApp::ActionRole::Second
    )]
);

while (my ($path, $roles) = each %actions) {
    my $resp = request("/executionviadoes/${path}");
    ok($resp->is_success,
        "request to /$path is succesful"
    );
    is($resp->content, join(',', sort @$roles),
        "all roles applied"
    );
    is($resp->header('X-Executed-Times'), scalar @$roles,
        "...and called once only"
    );
}
