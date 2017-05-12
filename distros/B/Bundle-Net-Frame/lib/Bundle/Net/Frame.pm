#
# $Id: Frame.pm 9 2015-01-13 18:13:54Z gomor $
#
package Bundle::Net::Frame;
use strict;
use warnings;

our $VERSION = '1.03';

1;

__END__

=head1 NAME

Bundle::Net::Frame - A bundle to install various Net::Frame related modules

=head1 SYNOPSIS

  perl -MCPAN -e 'install Bundle::Net::Frame'

=head1 CONTENTS

Net::Write - a portable interface to open and send raw data to network

Net::Frame - the base framework for frame crafting

Net::Frame::Device - get network device information and gateway

Net::Frame::Dump - tcpdump like implementation

Net::Frame::Layer::8021Q - 802.1Q layer object

Net::Frame::Layer::GRE - Generic Route Encapsulation layer object

Net::Frame::Layer::ICMPv4 - Internet Control Message Protocol v4 layer object

Net::Frame::Layer::ICMPv6 - Internet Control Message Protocol v6 layer object

Net::Frame::Layer::IPv6 - Internet Protocol v6 layer object

Net::Frame::Layer::LLC - Logical-Link Control layer object

Net::Frame::Layer::LLTD - Link Layer Topology Discovery layer object

Net::Frame::Layer::LOOP - LOOP layer object

Net::Frame::Layer::OSPF - Open Shortest Path First layer object

Net::Frame::Layer::PPPLCP - PPP Link Control Protocol layer object

Net::Frame::Layer::PPPoES - PPP-over-Ethernet layer object

Net::Frame::Layer::STP - Spanning Tree Protocol layer object

Net::Frame::Layer::UDPLite - UDPLite layer object

Net::Frame::Simple - frame crafting made easy

Net::Frame::Tools - useful network utilities created using Net::Frame

=head1 DESCRIPTION

This is a bundle of Net::Frame related modules.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
