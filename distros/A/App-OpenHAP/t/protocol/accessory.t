#!/usr/bin/env perl
use v5.36;
use Test::More;

use_ok('Protocol::HAP::Accessory');

# Test accessory creation
{
    my $accessory = Protocol::HAP::Accessory->new(
        aid => 1,
        name => 'Test Accessory',
        manufacturer => 'Test Corp',
        model => 'Model X',
        serial => 'TEST-001',
    );
    
    ok(defined $accessory, 'Accessory object created');
    isa_ok($accessory, 'Protocol::HAP::Accessory');
    is($accessory->{aid}, 1, 'AID set correctly');
    is($accessory->{name}, 'Test Accessory', 'Name set correctly');
}

# Test default values
{
    my $accessory = Protocol::HAP::Accessory->new(aid => 2);
    
    ok(defined $accessory->{name}, 'Default name set');
    ok(defined $accessory->{manufacturer}, 'Default manufacturer set');
    ok(defined $accessory->{model}, 'Default model set');
    ok(defined $accessory->{serial}, 'Default serial set');
}

# Test Accessory Information service
{
    my $accessory = Protocol::HAP::Accessory->new(
        aid => 1,
        name => 'Test',
        manufacturer => 'Acme',
        model => 'Model1',
        serial => 'SN001',
        firmware_revision => '1.0.0',
    );
    
    my @services = $accessory->get_services();
    ok(@services > 0, 'Accessory has services');
    
    # The first service must be Accessory Information
    my $info_service = $services[0];
    ok(defined $info_service, 'Accessory Information service exists');
    is($info_service->{iid}, 1, 'Accessory Information has IID 1');
}

# Test adding services
{
    my $accessory = Protocol::HAP::Accessory->new(aid => 1);
    
    require Protocol::HAP::Service;
    my $service = Protocol::HAP::Service->new(type => 'Switch', iid => 10);
    
    $accessory->add_service($service);
    
    my @services = $accessory->get_services();
    # The accessory must have AccessoryInformation and Switch
    is(scalar @services, 2, 'Two services present');
}

# Test get_characteristic
{
    my $accessory = Protocol::HAP::Accessory->new(aid => 1);
    
    # Get the characteristic from the AccessoryInformation service
    my $char = $accessory->get_characteristic(2);  # IID 2 is Identify
    ok(defined $char, 'Characteristic found');
}

# Test JSON serialization
{
    my $accessory = Protocol::HAP::Accessory->new(
        aid => 1,
        name => 'Test Accessory',
    );
    
    my $json = $accessory->to_json();
    
    ok(exists $json->{aid}, 'JSON has aid');
    ok(exists $json->{services}, 'JSON has services');
    is($json->{aid}, 1, 'AID correct in JSON');
    is(ref $json->{services}, 'ARRAY', 'Services is array');
}

# Test event callbacks
{
    my $accessory = Protocol::HAP::Accessory->new(aid => 1);
    
    my $callback_called = 0;
    my $callback_aid;
    my $callback_iid;
    
    $accessory->add_event_callback(sub {
        $callback_called = 1;
        ($callback_aid, $callback_iid) = @_;
    });
    
    $accessory->notify_change(11);
    
    ok($callback_called, 'Event callback called');
    is($callback_aid, 1, 'Callback received correct AID');
    is($callback_iid, 11, 'Callback received correct IID');
}

# Test multiple event callbacks
{
    my $accessory = Protocol::HAP::Accessory->new(aid => 1);
    
    my $count1 = 0;
    my $count2 = 0;
    
    $accessory->add_event_callback(sub { $count1++ });
    $accessory->add_event_callback(sub { $count2++ });
    
    $accessory->notify_change(11);
    
    is($count1, 1, 'First callback called');
    is($count2, 1, 'Second callback called');
}

done_testing();
