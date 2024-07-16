use strict;
use warnings;
use Data::HexDump;
use Test::More tests => 16 + 1;
use Test::NoWarnings;

BEGIN {
    use_ok('Data::Radius::Dictionary');
    use_ok('Data::Radius::Constants', qw(:all));
    use_ok('Data::Radius::Packet');
};

my $dict = Data::Radius::Dictionary->load_file('./radius/dictionary');
ok($dict, 'dictionary loaded');

my $p = Data::Radius::Packet->new(secret => 'top-secret', dict => $dict);
ok($p, 'object');

# accounting
my ($acct_req, $req_id, $auth) = $p->build(
    type => ACCOUNTING_REQUEST,
    av_list => [
        { Name => 'Acct-Status-Type', Value => 'Start' },
        { Name => 'Message-Authenticator', Value => '' },
    ],
    with_msg_auth => 1, # must not be used
);
ok($acct_req, 'accounting packet build');

my ($t, $id, $auth_p, $av) = $p->parse($acct_req);
is($t, ACCOUNTING_REQUEST, 'packet type');
is($id, $req_id, 'request id');
is_deeply($av, [
    { Name => 'Acct-Status-Type', Value => 'Start', Type => 'integer', Vendor => undef, Tag => undef },
], 'no Message-Authenticator in attributes');

my @warn = Test::NoWarnings->warnings();
is(@warn, 2, 'got 2 warnings');
my $w = shift(@warn);
ok($w->getMessage() =~ /^Message-Authenticator is not used for accounting/, 'warn: with_msg_auth=1 ignored');
$w = shift(@warn);
ok($w->getMessage() =~ /^Message-Authenticator attribute is ignored/, 'warn: Empty Message-Authenticator is ignored');

foreach $w (@warn) {
    fail($w->getMessage());
}

Test::NoWarnings->clear_warnings();

# defaults without warnings
($acct_req, $req_id, $auth) = $p->build(
    type => ACCOUNTING_REQUEST,
    av_list => [
        { Name => 'Acct-Status-Type', Value => 'Start' },
    ],
);
ok($acct_req, 'accounting packet build');

($t, $id, $auth_p, $av) = $p->parse($acct_req);
is($t, ACCOUNTING_REQUEST, 'packet type');
is($id, $req_id, 'request id');
is_deeply($av, [
    { Name => 'Acct-Status-Type', Value => 'Start', Type => 'integer', Vendor => undef, Tag => undef },
], 'no Message-Authenticator in attributes');
