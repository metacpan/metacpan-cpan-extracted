use Test::More;
use strict;

BEGIN {
    use_ok('Business::Payment::ClearingHouse');
    use_ok('Business::Payment::ClearingHouse::Charge');
}

my $house = Business::Payment::ClearingHouse->new;

{
    my $charge = Business::Payment::ClearingHouse::Charge->new(
        currency => 'USD',
        number => '4111111111111111',
        subtotal => 100,
        tax => 10
    );

    my $uuid = $house->preauth($charge);
    ok(defined($uuid), 'got uuid from preauth');

    my $ret = $house->postauth($uuid);
    ok($ret, 'postuath');
}

{
    my $charge = Business::Payment::ClearingHouse::Charge->new(
        currency => 'USD',
        number => '4111111111111111',
        subtotal => 200,
        tax => 20
    );

    my $uuid = $house->auth($charge);
    ok(defined($uuid), 'got uuid from auth');
}

{
    my $charge = Business::Payment::ClearingHouse::Charge->new(
        currency => 'USD',
        number => '4111111111111111',
        subtotal => 50,
    );

    my $uuid = $house->credit($charge);
    ok(defined($uuid), 'got uuid from credit');
}

{
    my $charge = Business::Payment::ClearingHouse::Charge->new(
        currency => 'USD',
        number => '4111111111111111',
        subtotal => 200,
        tax => 20
    );

    my $uuid = $house->auth($charge);
    ok(defined($uuid), 'got uuid from auth');

    my $ret = $house->void($uuid);
    ok($ret, 'void');
}

my $preauthid;
{
    my $charge = Business::Payment::ClearingHouse::Charge->new(
        currency => 'USD',
        number => '4111111111111111',
        subtotal => 100,
        tax => 10
    );

    $preauthid = $house->preauth($charge);
    ok(defined($preauthid), 'got uuid from preauth');
}

my $total = $house->settle;
cmp_ok($total, '==', 280, 'settled amount');

{
    my $ret = $house->postauth($preauthid);
    ok($ret, 'post settle postauth');
}

my $othertotal = $house->settle;
cmp_ok($othertotal, '==', 110, 'post-settle postauth settle');

done_testing;