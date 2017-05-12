package Cocoa::NetworkChange;
use 5.008005;
use strict;
use warnings;
use parent qw/Exporter/;

our $VERSION = "0.01";

our @EXPORT = qw/on_network_change is_network_connected current_interface/;

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

1;
__END__

=encoding utf-8

=head1 NAME

Cocoa::NetworkChange - Checking network connection for OS X

=head1 SYNOPSIS

  use Cocoa::EventLoop;
  use Cocoa::NetworkChange;

  on_network_change(sub {
      my $wlan = shift;
      # on connected
      if ($wlan->{ssid} && $wlan->{ssid} =~ /aterm/) {
          # ...
      }
  }, sub {
      # on disconnected
  });

  Cocoa::EventLoop->run;

=head1 DESCRIPTION

Cocoa::NetworkChange checks network connection in real time. You can do something when you connected to a certain Wi-Fi network.

Note that if you disconnected with PPPoE authentication, Cocoa::NetworkChange guesses that it's connected to the network.

=head1 FUNCTIONS

=over 4

=item C<< on_network_change($connect_cb, [$disconnect_cb]) >>

Call the callback on network connected or disconnected.

  on_network_change(sub {
      my $wlan = shift;
      # on connected
  }, sub {
      # on disconnected
  });

=over 4

=item C<< $wlan->{ssid} >>

Service set identifier (SSID)

=item C<< $wlan->{interface} >>

The BSD name of the interface (such as en0, en1)

=item C<< $wlan->{mac_address} >>

The hardware media access control (MAC) address

=item C<< $wlan->{bssid} >>

Basic service set identifier (BSSID)

=back

=item C<< is_network_connected() >>

(immediately) Return 1, when you are connected to the network and 0 otherwise.

=item C<< current_interface() >>

See above.

=back

=head1 LICENSE

Copyright (C) Takumi Akiyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Takumi Akiyama E<lt>t.akiym@gmail.comE<gt>

=cut

