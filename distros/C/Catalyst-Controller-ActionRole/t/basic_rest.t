use strict;
use warnings;
use Test::More;

BEGIN {
    if (!eval {require Catalyst::Action::REST; Catalyst::Action::REST->VERSION(0.74)}) {
        plan skip_all => 'This test needs Catalyst::Action::REST >=0.74';
    }

    plan tests => 3;
}

use FindBin;
use lib "$FindBin::Bin/lib";

use Catalyst::Test 'TestAppREST';

my %roles = (
    foo  => 'TestAppREST::ActionRole::Moo',
);

while (my ($path, $role) = each %roles) {
    my $resp = request("/foo/${path}");
    ok($resp->is_success);
    is($resp->content, $role);
    is($resp->header('X-Affe'), 'Tiger');
}
