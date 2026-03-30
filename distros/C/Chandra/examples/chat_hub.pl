#!/usr/bin/env perl
#
# Chat Hub - Run this first, then open chat_window.pl instances
#
# Usage:
#   perl examples/chat_hub.pl
#

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Chandra::Socket::Hub;

my $hub = Chandra::Socket::Hub->new(name => 'chat');
print "Chat hub running (name: 'chat')\n";
print "Open windows with: perl examples/chat_window.pl <name>\n\n";

$hub->on_connect(sub {
    my ($client) = @_;
    my $name = $client->name;
    print "[+] $name joined\n";
    $hub->broadcast('system', { text => "$name joined the chat" });
    $hub->broadcast('users', { list => [sort $hub->clients] });
});

$hub->on_disconnect(sub {
    my ($client) = @_;
    my $name = $client->name;
    print "[-] $name left\n";
    $hub->broadcast('system', { text => "$name left the chat" });
    $hub->broadcast('users', { list => [sort $hub->clients] });
});

$hub->on('msg', sub {
    my ($data, $sender) = @_;
    print "<${\$sender->name}> $data->{text}\n";
    $hub->broadcast('msg', { from => $sender->name, text => $data->{text} });
});

$hub->run;
