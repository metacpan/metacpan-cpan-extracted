# Copyright (c) 2015,  BROCADE COMMUNICATIONS SYSTEMS, INC
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from this
# software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
# THE POSSIBILITY OF SUCH DAMAGE.

=head1 NAME

Brocade::BSC::Node::OF::Action

=head1 DESCRIPTION

Create openflow action to apply to openflow node.  All Actions may have
an I<order> parameter passed in the constructor to specify the order in
which Actions are evaluated.  Action-specific methods and parameters are
described under each Action, below.

=cut

package Brocade::BSC::Node::OF::Action;

use strict;
use warnings;

# Constructor ==========================================================
# Parameters: order (optional)
# Returns   : Brocade::BSC::Node::OF::Action object
# 
sub new {
    my ($class, %params) = @_;

    my $self = {};
    $self->{order} = $params{order} ? $params{order} : 0;
    bless ($self, $class);
}


# Method ===============================================================
#             order
# Parameters: retrieve or set the 'order' attribute
# Returns   : 'order' value
#
sub order {
    my ($self, $order) = @_;
    $self->{order} = (@_ == 2) ? $order : $self->{order};
}


# Module ===============================================================
1;

=head1 SUBCLASSES

Subclasses are listed relative to Brocade::BSC::Node::OF::Action.


=head2 ::CopyTTLIn

Copy the TTL from the outermost to the second outermost header with TTL.
Copy can be IP->IP, MPLS->MPLS, or MPLS->IP.


=head2 ::CopyTTLOut

Copy the TTL from the second outermost header to the outermost header
with TTL.  Copy can be IP->IP, MPLS->MPLS, or IP->MPLS.


=head2 ::DecMplsTTL

Decrement the MPLS TTL.  Only applies to packets with an existing MPLS shim header.


=head2 ::DecNwTTL

Decrement the IPv4 TTL or the IPv6 hop limit field and update the IP checksum.
Only applies to IPv4 and IPv6 packets.


=head2 ::Drop

Implicit action if no output action encountered.


=head2 ::FloodAll

Send the packet out all interfaces, excluding the interface on which it arrived.


=head2 ::Flood

Send the packet out all interfaces, excluding the interface on which it arrived
and all ports disabled by the spanning tree protocol.


=head2 ::Group

Process the packet through the specified group.  The exact interpretation
depends on the group type.

=over 4

=item B<new>

  # Parameters: group
  #           : group_id

=item B<group>

Set or retrieve the group for this action.

=item B<group_id>

Set or retrieve the group ID for this action.

=back


=head2 ::HwPath

DOC TBD


=head2 ::Loopback

DOC TBD


=head2 ::Output

Forward a packet to the specified OpenFlow port.  OpenFlow switches must
support forwarding to physical ports, switch-defined logical ports, and
the required reserved ports.

=over 4

=item B<new>

  # Parameters: port    - out which to send packet
  #           : max_len - maximum packet length

=item B<outport>

Set or retrieve the output port for this action.

=item B<max_len>

Set or retrieve the maximum packet length for this action.

=back


=head2 ::PopMplsHeader

Pop the outermost MPLS tag or shim header from the packet.  The specified
ethernet type is used as the ethernet type of the resulting packet.

=over 4

=item B<new>

  # Parameters: eth_type - for ethernet packet after MPLS header removed.

=item B<eth_type>

Set or retrive the ethernet type for this action.

=back


=head2 ::PopPBBHeader

Pop the outermost PBB (802.1ah Provider Backbone Bridge) service instance
header from the packet.


=head2 ::PopVlanHeader

Pop the outermost VLAN header from the packet.


=head2 ::PushMplsHeader

Push a new MPLS shim header onto the packet.  The ethernet type for the tag
should be either 0x8847 (unicast) or 0x8848 (multicast).

=over 4

=item B<new>

  # Parameters: eth_type - for the MPLS tag.

=item B<eth_type>

Set or retrieve the ethernet type for this action.

=back


=head2 ::PushPBBHeader

Push a new PBB service instance header onto the packet.  The ethernet type
for the tag should be 0x88e7.

=over 4

=item B<new>

  # Parameters: eth_type - for the PBB tag.

=item B<eth_type>

Set or retrieve the ethernet type for this action.

=back


=head2 ::PushVlanHeader

Push a new VLAN header onto the packet.  The ethernet type for the VLAN tag
should be 0x8100 (802.1q) or 0x88a8 (802.1ad).

=over 4

=item B<new>

  # Parameters: eth_type - ethernet type
  #           : tag      -
  #           : pcp      - priority code point
  #           : cfi      - canonical format indicator
  #           : vid      - vlan identifier

=item B<eth_type>

Set or retrieve the ethernet type for this action.

=item B<tag>

Set or retrieve the vlan tag for this action.

=item B<pcp>

Set or retrieve the priority code point for this action.

=item B<cfi>

Set or retrieve the canonical format indicator for this action.

=item B<vid>

Set or retrieve the vlan identifier for this action.

=back


=head2 ::SetDlDst

Set Ethernet destination address.

=over 4

=item B<new>

  # Parameters: mac_addr - destination ethernet address

=item B<mac_addr>

Set or retrieve the destination ethernet address for this action.

=back


=head2 ::SetDlSrc

Set Ethernet source address.

=over 4

=item B<new>

  # Parameters: mac_addr - source ethernet address

=item B<mac_addr>

Set or retrieve the source ethernet address for this action.

=back


=head2 ::SetField

DOC TBD


=head2 ::SetMplsTTL

Replace the existing MPLS TTL.  Only applies to packets with an existing
MPLS shim header.

=over 4

=item B<new>

  # Parameters: mpls_ttl - TTL to set

=item B<mpls_ttl>

Set or retrieve the MPLS TTL for this action.

=back


=head2 ::SetNwDst

Set the destination IP address.

=over 4

=item B<new>

  # Parameters: ip_addr

=item B<ip_addr>

Set or retrieve the [destination] IP address for this action.

=back


=head2 ::SetNwSrc

Set the source IP address.

=over 4

=item B<new>

  # Parameters: ip_addr

=item B<ip_addr>

Set or retrieve the [source] IP address for this action.

=back


=head2 ::SetNwTTL

Replace the existing IPv4 TTL or IPv6 hop limit and update the IP checksum.
Only applies to IPv4 and IPv6 packets.

=over 4

=item B<new>

  # Parameters: ip_ttl

=item B<ip_ttl>

Set or retrieve the TTL for this action.

=back


=head2 ::SetQueue

The set-queue action sets the queue id for a packet.  When the packet is
forwarded to a port using the output action, the queue id determines
which queue attached to this port is used for scheduling and forwarding
the packet.  Forwarding behavior is dictated by the configuration of the
queue and is used to provide basic Quality-of-Service (QoS) support.

=over 4

=item B<new>

  # Parameters: queue
  #           : queue_id

=item B<queue>

Set or retrieve the queue for this action.

=item B<queue_id>

Set or retrieve the queue ID for this action.

=back


=head2 ::SetTcpUdpDst

Set the TCP or UDP destination port.

=over 4

=item B<new>

  # Parameters: port

=item B<port>

Set or retrieve the TCP or UDP destination port for this action.

=back


=head2 ::SetTcpUdpSrc

Set the TCP or UDP source port.

=over 4

=item B<new>

  # Parameters: port

=item B<port>

Set or retrieve the TCP or UDP source port for this action.

=back


=head2 ::SetVlanCfi

The Drop Eligible Indicator (formerly Canonical Format Indicator) may be
used alone or in conjunction with the PCP to indicate frames which may
be dropped in the presence of congestion.

=over 4

=item B<new>

  # Parameters: vlan_cfi

=item B<vlan_cfi>

Set or retrieve the VLAN DEI (CFI) for this action.

=back


=head2 ::SetVlanId

Set the 802.1q VLAN ID.

=over 4

=item B<new>

  # Parameters: vid

=item B<vid>

Set or retrieve the VLAN ID for this action.

=back


=head2 ::SetVlanPCP

Set the 802.1q VLAN priority.

=over 4

=item B<new>

#  Parameters: vlan_pcp

=item B<vlan_pcp>

Set or retrieve the VLAN priority code point for this action.

=back


=head2 ::StripVlan

Remove the 802.1q VLAN header from the packet.


=head2 ::SwPath

DOC TBD


=head1 COPYRIGHT

Copyright (c) 2015,  BROCADE COMMUNICATIONS SYSTEMS, INC

All rights reserved.
