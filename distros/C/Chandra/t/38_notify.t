#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Chandra::Notify');

# Test is_supported - should return 0 or 1
{
    my $supported = Chandra::Notify->is_supported();
    ok(defined $supported, 'is_supported returns a defined value');
    like($supported, qr/^[01]$/, 'is_supported returns 0 or 1');
}

# Test parameter validation
{
    my $warned = 0;
    local $SIG{__WARN__} = sub { $warned++ if $_[0] =~ /title is required/ };
    
    my $result = Chandra::Notify->send();
    is($result, 0, 'send without title returns 0');
    is($warned, 1, 'send without title warns');
}

{
    my $warned = 0;
    local $SIG{__WARN__} = sub { $warned++ if $_[0] =~ /title is required/ };
    
    my $result = Chandra::Notify->send(body => 'No title');
    is($result, 0, 'send with only body returns 0');
    is($warned, 1, 'send with only body warns');
}

{
    my $warned = 0;
    local $SIG{__WARN__} = sub { $warned++ if $_[0] =~ /title is required/ };
    
    my $result = Chandra::Notify->send(title => '');
    is($result, 0, 'send with empty title returns 0');
    is($warned, 1, 'send with empty title warns');
}

# Test OO interface
{
    my $notifier = Chandra::Notify->new(sound => 1, timeout => 5000);
    isa_ok($notifier, 'Chandra::Notify', 'new returns blessed object');
    is($notifier->{sound}, 1, 'default sound stored');
    is($notifier->{timeout}, 5000, 'default timeout stored');
}

# Test hashref argument style
SKIP: {
    skip "Notifications crash without app bundle on macOS", 2
        unless $ENV{CHANDRA_TEST_NOTIFY};
    
    my $warned = 0;
    local $SIG{__WARN__} = sub { $warned++ };
    
    # Should not warn with valid title
    my $result = Chandra::Notify->send({ title => 'Test', body => 'Body' });
    # Result depends on platform support
    ok(defined $result, 'send with hashref returns defined value');
    is($warned, 0, 'send with valid args does not warn');
}

# Skip actual notification tests unless we can send them
SKIP: {
    skip "Notifications not supported on this platform", 2
        unless Chandra::Notify->is_supported();
    
    # These tests would actually show notifications
    # Only run in interactive mode or CI with display
    skip "Skipping visual notification tests", 2
        unless $ENV{CHANDRA_TEST_NOTIFY};
    
    my $result1 = Chandra::Notify->send(
        title => 'Chandra Test',
        body  => 'Basic notification test',
    );
    ok($result1, 'basic notification sent');
    
    my $result2 = Chandra::Notify->send(
        title   => 'Chandra Test 2',
        body    => 'Notification with options',
        sound   => 1,
        timeout => 3000,
    );
    ok($result2, 'notification with options sent');
}

# Test App integration (mock)
{
    # Create a minimal mock app
    package MockApp;
    sub new { bless { _webview => undef }, shift }
    
    package main;
    
    use_ok('Chandra');
    
    # App->notify is defined in XS, test via Chandra::App if available
    can_ok('Chandra::App', 'notify') if $INC{'Chandra/App.pm'};
}

done_testing();
