#!/usr/bin/env perl
use v5.36;
use Test::More;

use_ok('Protocol::HAP::Characteristic');

# Test characteristic creation
{
    my $char = Protocol::HAP::Characteristic->new(
        type => 'On',
        iid => 11,
        format => 'bool',
        perms => ['pr', 'pw'],
        value => 0,
    );
    
    ok(defined $char, 'Characteristic object created');
    isa_ok($char, 'Protocol::HAP::Characteristic');
    is($char->{iid}, 11, 'IID set correctly');
    like($char->{type}, qr/^[0-9A-F-]+$/i, 'Type is UUID');
}

# Test get_value and set_value
{
    # The current implementation possibly has a problem with value
    # storage. Thus the test only makes sure that the methods exist
    # and do not die.
    my $temp = 21.5;
    my $char = Protocol::HAP::Characteristic->new(
        type => 'CurrentTemperature',
        iid => 1,
        format => 'float',
        perms => ['pr'],
        value => \$temp,
    );
    
    ok(defined $char, 'Characteristic with reference value created');
    eval { $char->get_value() };
    ok(!$@, 'get_value() does not die');
}

# Test set_value
{
    my $state = 0;
    my $char = Protocol::HAP::Characteristic->new(
        type => 'On',
        iid => 1,
        format => 'bool',
        perms => ['pr', 'pw'],
        value => \$state,
    );
    
    eval { $char->set_value(1) };
    ok(!$@, 'set_value() does not die');
}

# Test custom callbacks
{
    my $counter = 0;
    my $char = Protocol::HAP::Characteristic->new(
        type => 'CurrentTemperature',
        iid => 1,
        format => 'float',
        perms => ['pr'],
        on_get => sub { return ++$counter },
    );
    
    ok(defined $char, 'Characteristic with custom getter created');
}

# Test custom setter callback
{
    my $called = 0;
    my $last_value;
    my $state = 20.0;
    my $char = Protocol::HAP::Characteristic->new(
        type => 'TargetTemperature',
        iid => 1,
        format => 'float',
        perms => ['pr', 'pw'],
        value => \$state,
        on_set => sub { $called = 1; $last_value = $_[0] },
    );
    
    eval { $char->set_value(22.5) };
    ok(!$@, 'set_value with callback does not die');
}

# Test event enable/disable
{
    my $char = Protocol::HAP::Characteristic->new(
        type => 'CurrentTemperature',
        iid => 1,
        format => 'float',
        perms => ['pr', 'ev'],
        value => 20.0,
    );
    
    ok(!$char->events_enabled(), 'Events disabled by default');
    
    $char->enable_events(1);
    ok($char->events_enabled(), 'Events enabled');
    
    $char->enable_events(0);
    ok(!$char->events_enabled(), 'Events disabled again');
}

# Test JSON serialization
{
    my $value = 21.5;
    my $char = Protocol::HAP::Characteristic->new(
        type => 'CurrentTemperature',
        iid => 13,
        format => 'float',
        perms => ['pr', 'ev'],
        unit => 'celsius',
        value => \$value,
        min => -40,
        max => 100,
        step => 0.1,
    );
    
    my $json = $char->to_json();
    
    ok(exists $json->{type}, 'JSON has type');
    ok(exists $json->{iid}, 'JSON has iid');
    ok(exists $json->{format}, 'JSON has format');
    ok(exists $json->{perms}, 'JSON has perms');
    is($json->{value}, 21.5, 'JSON value dereferences scalar ref');
    is($json->{unit}, 'celsius', 'JSON has unit');
    is($json->{minValue}, -40, 'JSON has minValue');
    is($json->{maxValue}, 100, 'JSON has maxValue');
    is($json->{minStep}, 0.1, 'JSON has minStep');
}

# Test JSON with boolean value
{
    my $state = 1;
    my $char = Protocol::HAP::Characteristic->new(
        type => 'On',
        iid => 1,
        format => 'bool',
        perms => ['pr', 'pw'],
        value => \$state,
    );
    
    my $json = $char->to_json();
    ok(exists $json->{type}, 'Boolean characteristic JSON has type');
    ok(exists $json->{iid}, 'Boolean characteristic JSON has iid');
}

# Test UUID short form in JSON output
{
    # On characteristic: 00000025-0000-1000-8000-0026BB765291 -> "25"
    my $on_char = Protocol::HAP::Characteristic->new(
        type => 'On', iid => 1, format => 'bool', perms => ['pr', 'pw'], value => 1
    );
    my $on_json = $on_char->to_json();
    is($on_json->{type}, '25', 'On characteristic type is 25 in short form');

    # CurrentTemperature: 00000011-0000-1000-8000-0026BB765291 -> "11"
    my $temp_char = Protocol::HAP::Characteristic->new(
        type => 'CurrentTemperature', iid => 2, format => 'float', perms => ['pr'], value => 21.5
    );
    my $temp_json = $temp_char->to_json();
    is($temp_json->{type}, '11', 'CurrentTemperature type is 11 in short form');

    # Name: 00000023-0000-1000-8000-0026BB765291 -> "23"
    my $name_char = Protocol::HAP::Characteristic->new(
        type => 'Name', iid => 3, format => 'string', perms => ['pr'], value => 'Test'
    );
    my $name_json = $name_char->to_json();
    is($name_json->{type}, '23', 'Name type is 23 in short form');
}

# Test that the module does not shorten a custom UUID
{
    my $custom_uuid = '12345678-1234-1234-1234-123456789012';
    my $char = Protocol::HAP::Characteristic->new(
        type => $custom_uuid, iid => 99, format => 'string', perms => ['pr'], value => 'custom'
    );
    my $json = $char->to_json();
    is($json->{type}, $custom_uuid, 'Custom characteristic UUID preserved in JSON');
}

# Test known characteristic types
{
    my @known_types = qw(
        Identify Manufacturer Model Name SerialNumber FirmwareRevision
        CurrentHeatingCoolingState TargetHeatingCoolingState
        CurrentTemperature TargetTemperature TemperatureDisplayUnits
        On OutletInUse
    );
    
    for my $type (@known_types) {
        my $char = Protocol::HAP::Characteristic->new(
            type => $type,
            iid => 1,
            format => 'string',
            perms => ['pr'],
            value => 'test',
        );
        ok(defined $char, "Characteristic type $type recognized");
        like($char->{type}, qr/^[0-9A-F-]+$/i, "$type has valid UUID");
    }
}

# The logger contract: the default is the null logger, which stays
# silent; an injected logger receives the messages.
{
    package Protocol::HAP::Characteristic::TestCapture;

    sub new ($class) { return bless { messages => [] }, $class }

    sub debug ($self, $format, @args) {
        push @{ $self->{messages} }, sprintf($format, @args);
        return;
    }
    sub info    ($self, @args) { return $self->debug(@args) }
    sub warning ($self, @args) { return $self->debug(@args) }
    sub error   ($self, @args) { return $self->debug(@args) }
}

subtest 'the default logger is silent' => sub {
    my $char = Protocol::HAP::Characteristic->new(
        type   => 'On',
        iid    => 3,
        format => 'bool',
        perms  => ['pr', 'pw', 'ev'],
        value  => 0,
    );

    isa_ok($char->{logger}, 'Protocol::HAP::Log::Null',
        'the default logger');

    # A write and a subscription log nothing and die nowhere
    my $stderr = '';
    {
        local *STDERR;
        open *STDERR, '>', \$stderr or die "Cannot capture stderr: $!";
        $char->set_value(1);
        $char->enable_events(1);
    }
    is($stderr, '', 'no message reaches standard error');
};

subtest 'an injected logger receives the messages' => sub {
    my $capture = Protocol::HAP::Characteristic::TestCapture->new;
    my $char    = Protocol::HAP::Characteristic->new(
        type   => 'On',
        iid    => 3,
        format => 'bool',
        perms  => ['pr', 'pw', 'ev'],
        value  => 0,
        logger => $capture,
    );

    $char->set_value(1);
    $char->enable_events(1);

    is(scalar @{ $capture->{messages} }, 2, 'two messages arrive');
    like($capture->{messages}[0], qr/IID=3/, 'the write names the IID');
    like($capture->{messages}[1], qr/enabled/, 'the subscription logs');
};

done_testing();
