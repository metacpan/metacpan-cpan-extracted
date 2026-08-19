#!/usr/bin/env perl
use v5.36;
use Test::More;

use_ok('Protocol::HAP::Bridge');

# Test bridge creation
{
    my $bridge = Protocol::HAP::Bridge->new(
        name => 'Test Bridge',
    );
    
    ok(defined $bridge, 'Bridge object created');
    isa_ok($bridge, 'Protocol::HAP::Bridge');
    isa_ok($bridge, 'Protocol::HAP::Accessory');
    is($bridge->{aid}, 1, 'Bridge has AID 1');
}

# Test default values
{
    my $bridge = Protocol::HAP::Bridge->new();
    
    ok(defined $bridge->{name}, 'Default name set');
    like($bridge->{name}, qr/Bridge/i, 'Default name contains "Bridge"');
}

# Test adding bridged accessories
{
    my $bridge = Protocol::HAP::Bridge->new();
    
    require Protocol::HAP::Accessory;
    my $accessory = Protocol::HAP::Accessory->new(
        aid => 2,
        name => 'Test Device',
    );
    
    $bridge->add_bridged_accessory($accessory);
    
    my @bridged = $bridge->get_bridged_accessories();
    is(scalar @bridged, 1, 'One bridged accessory');
    is($bridged[0]->{aid}, 2, 'Bridged accessory has correct AID');
}

# Test multiple bridged accessories
{
    my $bridge = Protocol::HAP::Bridge->new();
    
    require Protocol::HAP::Accessory;
    for my $i (2..4) {
        my $acc = Protocol::HAP::Accessory->new(aid => $i, name => "Device $i");
        $bridge->add_bridged_accessory($acc);
    }
    
    my @bridged = $bridge->get_bridged_accessories();
    is(scalar @bridged, 3, 'Three bridged accessories');
}

# Test get_all_accessories
{
    my $bridge = Protocol::HAP::Bridge->new();
    
    require Protocol::HAP::Accessory;
    my $acc1 = Protocol::HAP::Accessory->new(aid => 2, name => 'Device 1');
    my $acc2 = Protocol::HAP::Accessory->new(aid => 3, name => 'Device 2');
    
    $bridge->add_bridged_accessory($acc1);
    $bridge->add_bridged_accessory($acc2);
    
    my @all = $bridge->get_all_accessories();
    is(scalar @all, 3, 'Three total accessories (bridge + 2)');
    is($all[0]->{aid}, 1, 'First is bridge');
    is($all[1]->{aid}, 2, 'Second is device 1');
    is($all[2]->{aid}, 3, 'Third is device 2');
}

# Test get_accessory by AID
{
    my $bridge = Protocol::HAP::Bridge->new();
    
    require Protocol::HAP::Accessory;
    my $acc = Protocol::HAP::Accessory->new(aid => 2, name => 'Test Device');
    $bridge->add_bridged_accessory($acc);
    
    my $found_bridge = $bridge->get_accessory(1);
    ok(defined $found_bridge, 'Bridge found by AID 1');
    is($found_bridge->{aid}, 1, 'Correct bridge returned');
    
    my $found_acc = $bridge->get_accessory(2);
    ok(defined $found_acc, 'Accessory found by AID 2');
    is($found_acc->{aid}, 2, 'Correct accessory returned');
    
    my $not_found = $bridge->get_accessory(99);
    ok(!defined $not_found, 'Non-existent AID returns undef');
}

# Test JSON serialization
{
    my $bridge = Protocol::HAP::Bridge->new(name => 'My Bridge');
    
    require Protocol::HAP::Accessory;
    my $acc = Protocol::HAP::Accessory->new(aid => 2, name => 'Device');
    $bridge->add_bridged_accessory($acc);
    
    my $json = $bridge->to_json();
    
    ok(exists $json->{accessories}, 'JSON has accessories array');
    is(ref $json->{accessories}, 'ARRAY', 'Accessories is array');
    is(scalar @{$json->{accessories}}, 2, 'Two accessories in JSON');
    is($json->{accessories}[0]{aid}, 1, 'First is bridge');
    is($json->{accessories}[1]{aid}, 2, 'Second is bridged device');
}

# Test event forwarding
{
    my $bridge = Protocol::HAP::Bridge->new();
    
    my $callback_called = 0;
    my $callback_aid;
    
    $bridge->add_event_callback(sub {
        $callback_called = 1;
        ($callback_aid) = @_;
    });
    
    require Protocol::HAP::Accessory;
    my $acc = Protocol::HAP::Accessory->new(aid => 2, name => 'Device');
    $bridge->add_bridged_accessory($acc);
    
    # Trigger an event on the bridged accessory
    $acc->notify_change(10);
    
    ok($callback_called, 'Bridge callback called from bridged accessory');
}

done_testing();
