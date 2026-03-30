#!/usr/bin/env perl
#
# Example: Socket IPC between Chandra instances
#
# Demonstrates Hub/Client communication for multi-window apps.
# Run this script to see a Hub coordinate two Clients exchanging
# messages over Unix domain sockets.
#
# Usage:
#   perl examples/socket_ipc_example.pl
#

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch",
        "$FindBin::Bin/../lib";
use Chandra::Socket::Hub;
use Chandra::Socket::Client;

my $hub_name = "example-$$";

# --- Start the Hub (central message broker) ---
my $hub = Chandra::Socket::Hub->new(name => $hub_name);
print "[Hub] Listening as '$hub_name'\n";

$hub->on_connect(sub {
    my ($client) = @_;
    print "[Hub] Client connected: " . $client->name . "\n";
    $hub->broadcast('system', { event => 'join', who => $client->name });
});

$hub->on_disconnect(sub {
    my ($client) = @_;
    print "[Hub] Client disconnected: " . $client->name . "\n";
});

# Hub listens for 'chat' messages and broadcasts them
$hub->on('chat', sub {
    my ($data, $sender) = @_;
    print "[Hub] Relaying chat from " . $sender->name . ": $data->{text}\n";
    $hub->broadcast('chat', { from => $sender->name, text => $data->{text} });
});

# Hub handles 'ping' with a direct reply
$hub->on('ping', sub {
    my ($data, $sender) = @_;
    print "[Hub] Ping from " . $sender->name . "\n";
    $hub->send_to($sender->name, 'pong', { ts => time() });
});

# --- Create two Clients (simulating two windows) ---
my $client_a = Chandra::Socket::Client->new(name => 'window-A', hub => $hub_name);
my $client_b = Chandra::Socket::Client->new(name => 'window-B', hub => $hub_name);

print "[Client A] Connected: " . ($client_a->is_connected ? "yes" : "no") . "\n";
print "[Client B] Connected: " . ($client_b->is_connected ? "yes" : "no") . "\n";

# Register handlers on spokes
my @a_inbox;
$client_a->on('chat', sub {
    my ($data) = @_;
    push @a_inbox, $data;
    print "[Client A] Received chat from $data->{from}: $data->{text}\n";
});

$client_a->on('system', sub {
    my ($data) = @_;
    print "[Client A] System: $data->{who} $data->{event}\n";
});

my @b_inbox;
$client_b->on('chat', sub {
    my ($data) = @_;
    push @b_inbox, $data;
    print "[Client B] Received chat from $data->{from}: $data->{text}\n";
});

$client_b->on('pong', sub {
    my ($data) = @_;
    print "[Client B] Pong received! Server time: $data->{ts}\n";
});

# --- Let the Hub accept both connections ---
select(undef, undef, undef, 0.05);
$hub->poll for 1..3;

# --- Exchange messages ---
print "\n--- Client A sends a chat message ---\n";
$client_a->send('chat', { text => 'Hello from window A!' });
select(undef, undef, undef, 0.05);
$hub->poll;      # Hub receives and broadcasts
select(undef, undef, undef, 0.05);
$client_a->poll;  # A gets the broadcast
$client_b->poll;  # B gets the broadcast

print "\n--- Client B sends a chat message ---\n";
$client_b->send('chat', { text => 'Hey A, window B here!' });
select(undef, undef, undef, 0.05);
$hub->poll;
select(undef, undef, undef, 0.05);
$client_a->poll;
$client_b->poll;

print "\n--- Client B pings the Hub ---\n";
$client_b->send('ping', {});
select(undef, undef, undef, 0.05);
$hub->poll;
select(undef, undef, undef, 0.05);
$client_b->poll;

# --- Hub broadcasts to all ---
print "\n--- Hub broadcasts an announcement ---\n";
$hub->broadcast('system', { event => 'shutdown', who => 'hub' });
select(undef, undef, undef, 0.05);
$client_a->poll;
$client_b->poll;

# --- Cleanup ---
print "\n--- Shutting down ---\n";
$client_a->close;
$client_b->close;
$hub->close;

print "Done. Socket cleaned up.\n";
