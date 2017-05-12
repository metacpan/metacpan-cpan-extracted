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

Brocade::BSC::Node::OF::Match

=head1 DESCRIPTION

Model Match field of FlowEntry.

=cut

package Brocade::BSC::Node::OF::Match;

use strict;
use warnings;

#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
package Brocade::BSC::Node::OF::Match::Ethernet;

# Constructor ==========================================================
sub new {
    my ($class, %params) = @_;

    my $self = {
        ethernet_type        => undef,
        ethernet_source      => undef,
        ethernet_destination => undef
    };
    bless ($self, $class);
    if ($params{href}) {
        while (my ($key, $value) = each %{$params{href}}) {
            $key =~ s/-/_/g;
            $self->{$key} = $value;
        }
    }
    return $self;
}

# Method ===============================================================
#             accessors
sub type {
    my ($self, $eth_type) = @_;
    (@_ == 2) and $self->{ethernet_type}->{type} = $eth_type;
    return $self->{ethernet_type}->{type};
}
sub src {
    my ($self, $eth_src) = @_;
    (@_ == 2) and $self->{ethernet_source}->{address} = $eth_src;
    return $self->{ethernet_source}->{address};
}
sub dst {
    my ($self, $eth_dst) = @_;
    (@_ == 2) and $self->{ethernet_destination}->{address} = $eth_dst;
    return $self->{ethernet_destination}->{address};
}


#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
package Brocade::BSC::Node::OF::Match::Vlan;

use Carp::Assert;

# Constructor ==========================================================
sub new {
    my ($class, %params) = @_;

    my $self = {
        vlan_id => undef,
        vlan_pcp => undef,
    };
    bless ($self, $class);
    if ($params{href}) {
        while (my ($key, $value) = each %{$params{href}}) {
            $key =~ s/-/_/g;
            if ($key eq 'vlan_id') {
                assert (ref $value eq "HASH");
                $self->{vlan_id}->{vlan_id} = $value->{'vlan-id'};
                $self->{vlan_id}->{vlan_id_present} =
                    $value->{'vlan-id-present'};
            }
            else {
                $self->{$key} = $value;
            }
        }
    }
    return $self;
}

# Method ===============================================================
#             accessors
sub vid {
    my ($self, $vid) = @_;
    if (2 == @_) {
        $self->{vlan_id}->{vlan_id} = $vid;
        $self->{vlan_id}->{vlan_id_present} = JSON::true;
    }
    return $self->{vlan_id}->{vlan_id};
}
sub pcp {
    my ($self, $pcp) = @_;
    $self->{vlan_pcp} = (2 == @_) ? $pcp : $self->{vlan_pcp};
}


#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
package Brocade::BSC::Node::OF::Match::Icmp;

# Constructor ==========================================================
sub new {
    my ($class, %params) = @_;

    my $self = {
        icmpv4_type => undef,
        icmpv4_code => undef
    };
    bless ($self, $class);
    if ($params{href}) {
        while (my ($key, $value) = each %{$params{href}}) {
            $key =~ s/-/_/g;
            $self->{$key} = $value;
        }
    }
    return $self;
}

# Method ===============================================================
#             accessors
sub type {
    my ($self, $icmp_type) = @_;
    $self->{icmpv4_type} = (2 == @_) ? $icmp_type : $self->{icmpv4_type};
}
sub code {
    my ($self, $icmp_code) = @_;
    $self->{icmpv4_code} = (2 == @_) ? $icmp_code : $self->{icmpv4_code};
}


#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
package Brocade::BSC::Node::OF::Match::IcmpV6;

# Constructor ==========================================================
sub new {
    my ($class, %params) = @_;

    my $self = {
        icmpv6_type => undef,
        icmpv6_code => undef
    };
    bless ($self, $class);
    if ($params{href}) {
        while (my ($key, $value) = each %{$params{href}}) {
            $key =~ s/-/_/g;
            $self->{$key} = $value;
        }
    }
    return $self;
}

# Method ===============================================================
#             accessors
sub type {
    my ($self, $icmp6_type) = @_;
    $self->{icmpv6_type} = (2 == @_) ? $icmp6_type : $self->{icmpv6_type};
}
sub code {
    my ($self, $icmp6_code) = @_;
    $self->{icmpv6_code} = (2 == @_) ? $icmp6_code : $self->{icmpv6_code};
}


#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
package Brocade::BSC::Node::OF::Match::Ip;

# Constructor ==========================================================
sub new {
    my ($class, %params) = @_;

    my $self = {
        ip_dscp  => undef,     # ip_hdr[1] 7:2
        ip_ecn   => undef,     # ip_hdr[1] 1:0
        ip_protocol => undef   # ip_hdr[0] 7:4
    };
    bless ($self, $class);
    if ($params{href}) {
        while (my ($key, $value) = each %{$params{href}}) {
            $key =~ s/-/_/g;
            $self->{$key} = $value;
        }
    }
    return $self;
}

# Method ===============================================================
#             accessors
sub dscp {
    my ($self, $dscp) = @_;
    $self->{ip_dscp} = (2 == @_) ? $dscp : $self->{ip_dscp};
}
sub ecn {
    my ($self, $ecn) = @_;
    $self->{ip_ecn} = (2 == @_) ? $ecn : $self->{ip_ecn};
}
sub proto {
    my ($self, $proto) = @_;
    $self->{ip_protocol} = (2 == @_) ? $proto : $self->{ip_protocol};
}


#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
package Brocade::BSC::Node::OF::Match::IPv6Label;

# Constructor ==========================================================
sub new {
    my ($class, %params) = @_;

    my $self = {
        ipv6_flabel => undef,
        ipv6_flabel_mask => undef
    };
    bless ($self, $class);
    if ($params{href}) {
        while (my ($key, $value) = each %{$params{href}}) {
            $key =~ s/-/_/g;
            $self->{$key} = $value;
        }
    }
    return $self;
}

# Method ===============================================================
#             accessors
sub flabel {
    my ($self, $flabel) = @_;
    $self->{ipv6_flabel} = (2 == @_) ? $flabel : $self->{ipv6_flabel};
}
sub flabel_mask {
    my ($self, $mask) = @_;
    $self->{flabel_mask} = (2 == @_) ? $mask : $self->{flabel_mask};
}


#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
package Brocade::BSC::Node::OF::Match::IPv6ExtHdr;

# Constructor ==========================================================
sub new {
    my ($class, %params) = @_;

    my $self = {
        ipv6_exthdr => undef,
        ipv6_exthdr_mask => undef
    };
    bless ($self, $class);
    if ($params{href}) {
        while (my ($key, $value) = each %{$params{href}}) {
            $key =~ s/-/_/g;
            $self->{$key} = $value;
        }
    }
    return $self;
}

# Method ===============================================================
#             accessors
sub exthdr {
    my ($self, $exthdr) = @_;
    $self->{ipv6_exthdr} = (2 == @_) ? $exthdr : $self->{ipv6_exthdr};
}
sub exthdr_mask {
    my ($self, $mask) = @_;
    $self->{exthdr_mask} = (2 == @_) ? $mask : $self->{exthdr_mask};
}


#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
package Brocade::BSC::Node::OF::Match::Pbb;

# Constructor ==========================================================
sub new {
    my ($class, %params) = @_;

    my $self = {
        pbb_isid => undef,
        pbb_mask => undef
    };
    bless ($self, $class);
    if ($params{href}) {
        while (my ($key, $value) = each %{$params{href}}) {
            $key =~ s/-/_/g;
            $self->{$key} = $value;
        }
    }
    return $self;
}

# Method ===============================================================
#             accessors
sub isid {
    my ($self, $isid) = @_;
    $self->{pbb_isid} = (2 == @_) ? $isid : $self->{pbb_isid};
}
sub mask {
    my ($self, $mask) = @_;
    $self->{pbb_mask} = (2 == @_) ? $mask : $self->{pbb_mask};
}


#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
package Brocade::BSC::Node::OF::Match::ProtocolMatchFields;

# Constructor ==========================================================
sub new {
    my ($class, %params) = @_;

    my $self = {
        mpls_label => undef,
        mpls_tc    => undef,
        mpls_bos   => undef,
        pbb        => undef
    };
    bless ($self, $class);
    if ($params{href}) {
        while (my ($key, $value) = each %{$params{href}}) {
            $key =~ s/-/_/g;
            $self->{$key} = $value;
        }
    }
    return $self;
}
        
# Method ===============================================================
#             accessors
sub mpls_label {
    my ($self, $mpls_label) = @_;
    $self->{mpls_label} = (2 == @_) ? $mpls_label : $self->{mpls_label};
}
sub mpls_tc {
    my ($self, $mpls_tc) = @_;
    $self->{mpls_tc} = (2 == @_) ? $mpls_tc : $self->{mpls_tc};
}
sub mpls_bos {
    my ($self, $mpls_bos) = @_;
    $self->{mpls_bos} = (2 == @_) ? $mpls_bos : $self->{mpls_bos};
}


#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
package Brocade::BSC::Node::OF::Match::Metadata;

# Constructor ==========================================================
sub new {
    my ($class, %params) = @_;

    my $self = {
        metadata => undef,
        metadata_mask => undef
    };
    bless ($self, $class);
    if ($params{href}) {
        while (my ($key, $value) = each %{$params{href}}) {
            $key =~ s/-/_/g;
            $self->{$key} = $value;
        }
    }
    return $self;
}

# Method ===============================================================
#             accessors
sub metadata {
    my ($self, $metadata) = @_;
    $self->{metadata} = (2 == @_) ? $metadata : $self->{metadata};
}
sub metadata_mask {
    my ($self, $mask) = @_;
    $self->{metadata_mask} = (2 == @_) ? $mask : $self->{metadata_mask};
}


#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
package Brocade::BSC::Node::OF::Match;

# Constructor ==========================================================
# Parameters: hash ref of values with which to instantiate Match (optional)
# Returns   : Brocade::BSC::Node::OF::Match object
# 
=head1 METHODS

=cut

# Constructor ==========================================================
#
=over 4

=item B<new>

Creates and returns a new Match object.  Use accessor functions to
modify Match after creation, or provide hash of values to B<new()>
to set values in constructor call.

=cut ===================================================================
sub new {
    my ($class, %params) = @_;
    my $self = {
        in_port => undef,
        in_phy_port => undef,
        ethernet_match => undef,
        ipv4_source => undef,
        ipv4_destination => undef,
        ip_match => undef,
        ipv6_source => undef,
        ipv6_destination => undef,
        ipv6_nd_target => undef,
        ipv6_nd_sll => undef,
        ipv6_nd_tll => undef,
        ipv6_label => undef,
        ipv6_ext_header => undef,
        protocol_match_fields => undef,
        udp_source_port => undef,
        udp_destination_port => undef,
        tcp_source_port => undef,
        tcp_destination_port => undef,
        sctp_source_port => undef,
        sctp_destination_port => undef,
        icmpv4_match => undef,
        icmpv6_match => undef,
        vlan_match => undef,
        arp_op => undef,
        arp_source_transport_address => undef,
        arp_target_transport_address => undef,
        arp_source_hardware_address => undef,
        arp_target_hardware_address => undef,
        tunnel => undef,
        metadata => undef
    };
    bless ($self, $class);
    if ($params{href}) {
        while (my ($key, $value) = each %{$params{href}}) {
            $key =~ s/-/_/g;
            if ($key eq 'ethernet_match') {
                $self->{$key} = new Brocade::BSC::Node::OF::Match::Ethernet(href => $value);
            }
            elsif ($key eq 'ip_match') {
                $self->{$key} = new Brocade::BSC::Node::OF::Match::Ip(href => $value);
            }
            elsif ($key eq 'protocol_match_fields') {
                $self->{$key} = new Brocade::BSC::Node::OF::Match::ProtocolMatchFields(href => $value);
            }
            elsif ($key eq 'icmpv4_match') {
                $self->{$key} = new Brocade::BSC::Node::OF::Match::Icmp(href => $value);
            }
            elsif ($key eq 'icmpv6_match') {
                $self->{$key} = new Brocade::BSC::Node::OF::Match::IcmpV6(href => $value);
            }
            elsif ($key eq 'vlan_match') {
                $self->{$key} = new Brocade::BSC::Node::OF::Match::Vlan(href => $value);
            }
            else {
                $self->{$key} = $value;
            }
        }
    }
    return $self;
}


# Method ===============================================================
#             as_oxm
# Parameters: none
# Returns   : FlowEntry formatted as Node::OF eXtensible Match
#
no strict 'refs';
sub as_oxm {
    my $self = shift;

    my $oxm = "";
    #              accessor  => format
    my @xlate = (['in_port'  => 'in_port=%d'],
                 ['eth_type' => 'eth_type=0x%x'],
                 ['eth_src'  => 'eth_src=%s'],
                 ['eth_dst'  => 'eth_dst=%s'],
                 ['vlan_id'  => 'vlan_vid=%d'],
                 ['vlan_pcp' => 'vlan_pcp=%d'],
                 ['ip_proto' => 'ip_proto=%d'],
                 ['ip_dscp'  => 'ip_dscp=%d'],
                 ['ip_ecn'   => 'ip_ecn=%d'],
                 ['icmpv4_type'     => 'icmpv4_type=%d'],
                 ['icmpv4_code'     => 'icmpv4_code=%d'],
                 ['icmpv6_type'     => 'icmpv6_type=%d'],
                 ['icmpv6_code'     => 'icmpv6_code=%d'],
                 ['ipv4_src'        => 'ipv4_src=%s'],
                 ['ipv4_dst'        => 'ipv4_dst=%s'],
                 ['ipv6_src'        => 'ipv6_src=%s'],
                 ['ipv6_dst'        => 'ipv6_dst=%s'],
                 ['ipv6_flabel'     => 'ipv6_flabel=%d'],
                 ['ipv6_ext_header' => 'ipv6_exthdr=%d'],
                 ['udp_src_port'    => 'udp_src=%d'],
                 ['udp_dst_port'    => 'udp_dst=%d'],
                 ['tcp_src_port'    => 'tcp_src=%d'],
                 ['tcp_dst_port'    => 'tcp_dst=%d'],
                 ['sctp_src_port'   => 'sctp_src=%d'],
                 ['sctp_dst_port'   => 'sctp_dst=%d'],
                 ['arp_opcode'      => 'arp_op=%s'],
                 ['arp_src_transport_address' => 'arp_spa=%s'],
                 ['arp_tgt_transport_address' => 'arp_tpa=%s'],
                 ['arp_src_hw_address'        => 'arp_sha=%s'],
                 ['arp_tgt_hw_address'        => 'arp_tha=%s'],
                 ['mpls_label'      => 'mpls_label=%s'],
                 ['mpls_tc'         => 'mpls_tc=%s'],
                 ['mpls_bos'        => 'mpls_bos=%s'],
                 ['tunnel_id'       => 'tunnel_id=%d'],
                 ['metadata'        => 'metadata=%s']
        );
    foreach (@xlate) {
        my ($value, $format) = ($_->[0]($self), $_->[1]);
        if (defined $value) {
            $oxm .= q(,) if length ($oxm);
            $oxm .= sprintf ($format, $value);
        }
    }
    return $oxm;
}
use strict 'refs';

# Method ===============================================================
#             accessors
# Parameters: none for gets; value to set for sets
# Returns   : Match value
#
=item B<eth_type>

Set or retrieve the FlowEntry ethernet type match field.

=cut
sub eth_type {
    my ($self, $eth_type) = @_;
    my $value = undef;
    my $match_exists = defined $self->{ethernet_match};

    if (@_ == 2) {
        $match_exists or $self->{ethernet_match} = new Brocade::BSC::Node::OF::Match::Ethernet;
        $self->{ethernet_match}->type($eth_type);
    }
    $match_exists and $value = $self->{ethernet_match}->type();
    return $value;
}
=item B<eth_src>

Set or retrieve the FlowEntry ethernet source address match field.

=cut
sub eth_src {
    my ($self, $eth_src) = @_;
    my $value = undef;
    my $match_exists = defined $self->{ethernet_match};

    if (@_ == 2) {
        $match_exists or $self->{ethernet_match} = new Brocade::BSC::Node::OF::Match::Ethernet;
        $self->{ethernet_match}->src($eth_src);
    }
    $match_exists and $value = $self->{ethernet_match}->src();
    return $value;
}
=item B<eth_dst>

Set or retrieve the FlowEntry ethernet destination address match field.

=cut
sub eth_dst {
    my ($self, $eth_dst) = @_;
    my $value = undef;
    my $match_exists = defined $self->{ethernet_match};

    if (@_ == 2) {
        $match_exists or $self->{ethernet_match} = new Brocade::BSC::Node::OF::Match::Ethernet;
        $self->{ethernet_match}->dst($eth_dst);
    }
    $match_exists and $value = $self->{ethernet_match}->dst();
    return $value;
}
=item B<vlan_id>

Set or retrieve the FlowEntry vlan ID match field.

=cut
sub vlan_id {
    my ($self, $vid) = @_;
    my $value = undef;
    my $match_exists = defined $self->{vlan_match};

    if (@_ == 2) {
        $match_exists or $self->{vlan_match} = new Brocade::BSC::Node::OF::Match::Vlan;
        $self->{vlan_match}->vid($vid);
    }
    $match_exists and $value = $self->{vlan_match}->vid();
    return $value;
}
=item B<vlan_pcp>

Set or retrieve the FlowEntry VLAN Priority Code Point match field.

=cut
sub vlan_pcp {
    my ($self, $pcp) = @_;
    my $value = undef;
    my $match_exists = defined $self->{vlan_match};

    if (@_ == 2) {
        $match_exists or $self->{vlan_match} = new Brocade::BSC::Node::OF::Match::Vlan;
        $self->{vlan_match}->pcp($pcp);
    }
    $match_exists and $value = $self->{vlan_match}->pcp();
    return $value;
}
=item B<ipv4_src>

Set or retrieve the FlowEntry IPv4 source address match field.

=cut
sub ipv4_src {
    my ($self, $ipv4_src) = @_;
    $self->{ipv4_source} = (@_ == 2) ? $ipv4_src : $self->{ipv4_source};
}
=item B<ipv4_dst>

Set or retrieve the FlowEntry IPv4 destination address match field.

=cut
sub ipv4_dst {
    my ($self, $ipv4_dst) = @_;
    $self->{ipv4_destination}
        = (@_ == 2) ? $ipv4_dst : $self->{ipv4_destination};
}
=item B<ipv6_src>

Set or retrieve the FlowEntry IPv6 source address match field.

=cut
sub ipv6_src {
    my ($self, $ipv6_src) = @_;
    $self->{ipv6_source} = (@_ == 2) ? $ipv6_src : $self->{ipv6_source};
}
=item B<ipv6_dst>

Set or retrieve the FlowEntry IPv6 destination address match field.

=cut
sub ipv6_dst {
    my ($self, $ipv6_dst) = @_;
    $self->{ipv6_destination}
        = (@_ == 2) ? $ipv6_dst : $self->{ipv6_destination};
}
=item B<ipv6_flabel>

Set or retrieve the FlowEntry IPv6 flow label.

=cut
sub ipv6_flabel {
    my ($self, $ipv6_label) = @_;
    my $value = undef;
    my $match_exists = defined $self->{ipv6_label};

    if (@_ == 2) {
        $match_exists or $self->{ipv6_label} = new Brocade::BSC::Node::OF::Match::IPv6Label;
        $self->{ipv6_label}->flabel($ipv6_label);
    }
    $match_exists and $value = $self->{ipv6_label}->flabel();
    return $value;
}
=item B<ipv6_ext_header>

Set or retrieve the FlowEntry IPv6 extension header match field.

=cut
sub ipv6_ext_header {
    my ($self, $ipv6_ext_header) = @_;
    my $value = undef;
    my $match_exists = defined $self->{ipv6_ext_header};

    if (@_ == 2) {
        $match_exists or $self->{ipv6_ext_header} = new Brocade::BSC::Node::OF::Match::IPv6ExtHdr;
        $self->{ipv6_ext_header}->exthdr($ipv6_ext_header);
    }
    $match_exists and $value = $self->{ipv6_ext_header}->exthdr();
    return $value;
}
=item B<ip_dscp>

Set or retrieve the FlowEntry IP Differentiated Services Code Point match field.

=cut
sub ip_dscp {
    my ($self, $dscp) = @_;
    my $value = undef;
    my $match_exists = defined $self->{ip_match};

    if (@_== 2) {
        $match_exists or $self->{ip_match} = new Brocade::BSC::Node::OF::Match::Ip;
        $self->{ip_match}->dscp($dscp);
    }
    $match_exists and $value = $self->{ip_match}->dscp();
    return $value;
}
=item B<ip_ecn>

Set or retrieve the FlowEntry Explicit Congestion Notification match field.

=cut
sub ip_ecn {
    my ($self, $ecn) = @_;
    my $value = undef;
    my $match_exists = defined $self->{ip_match};

    if (@_== 2) {
        $match_exists or $self->{ip_match} = new Brocade::BSC::Node::OF::Match::Ip;
        $self->{ip_match}->ecn($ecn);
    }
    $match_exists and $value = $self->{ip_match}->ecn();
    return $value;
}
=item B<ip_proto>

Set or retrieve the FlowEntry IP Protocol match field.

=cut
sub ip_proto {
    my ($self, $proto) = @_;
    my $value = undef;
    my $match_exists = defined $self->{ip_match};

    if (@_== 2) {
        $match_exists or $self->{ip_match} = new Brocade::BSC::Node::OF::Match::Ip;
        $self->{ip_match}->proto($proto);
    }
    $match_exists and $value = $self->{ip_match}->proto();
    return $value;
}
sub ip_proto_version {
    die "XXX IpMatch";
}
=item B<udp_src_port>

Set or retrieve the FlowEntry UDP source port match field.

=cut
sub udp_src_port {
    my ($self, $udp_src_port) = @_;
    $self->{udp_source_port}
        = (@_ == 2) ? $udp_src_port : $self->{udp_source_port};
}
=item B<udp_dst_port>

Set or retrieve the FlowEntry UDP destination port match field.

=cut
sub udp_dst_port {
    my ($self, $udp_dst_port) = @_;
    $self->{udp_destination_port}
        = (@_ == 2) ? $udp_dst_port : $self->{udp_destination_port};
}
=item B<tcp_src_port>

Set or retrieve the FlowEntry TCP source port match field.

=cut
sub tcp_src_port {
    my ($self, $tcp_src_port) = @_;
    $self->{tcp_source_port}
        = (@_ == 2) ? $tcp_src_port : $self->{tcp_source_port};
}
=item B<tcp_dst_port>

Set or retrieve the FlowEntry TCP destination port match field.

=cut
sub tcp_dst_port {
    my ($self, $tcp_dst_port) = @_;
    $self->{tcp_destination_port}
        = (@_ == 2) ? $tcp_dst_port : $self->{tcp_destination_port};
}
=item B<sctp_src_port>

Set or retrieve the FlowEntry SCTP source port match field.

=cut
sub sctp_src_port {
    my ($self, $sctp_src_port) = @_;
    $self->{sctp_source_port}
        = (@_ == 2) ? $sctp_src_port : $self->{sctp_source_port};
}
=item B<sctp_dst_port>

Set or retrieve the FlowEntry SCTP destination port match field.

=cut
sub sctp_dst_port {
    my ($self, $sctp_dst_port) = @_;
    $self->{sctp_destination_port}
        = (@_ == 2) ? $sctp_dst_port : $self->{sctp_destination_port};
}
=item B<icmpv4_type>

Set or retrieve the FlowEntry ICMPv4 type match field.

=cut
sub icmpv4_type {
    my ($self, $icmpv4_type) = @_;
    my $value = undef;
    my $match_exists = defined $self->{icmpv4_match};

    if (@_ == 2) {
        $match_exists or $self->{icmpv4_match} = new Brocade::BSC::Node::OF::Match::Icmp;
        $self->{icmpv4_match}->type($icmpv4_type);
    }
    $match_exists and $value = $self->{icmpv4_match}->type();
    return $value;
}
=item B<icmpv4_code>

Set or retrieve the FlowEntry ICMPv4 code match field.

=cut
sub icmpv4_code {
    my ($self, $icmpv4_code) = @_;
    my $value = undef;
    my $match_exists = defined $self->{icmpv4_match};

    if (@_ == 2) {
        $match_exists or $self->{icmpv4_match} = new Brocade::BSC::Node::OF::Match::Icmp;
        $self->{icmpv4_match}->code($icmpv4_code);
    }
    $match_exists and $value = $self->{icmpv4_match}->code();
    return $value;
}
=item B<icmpv6_type>

Set or retrieve the FlowEntry ICMPv6 type match field.

=cut
sub icmpv6_type {
    my ($self, $icmpv6_type) = @_;
    my $value = undef;
    my $match_exists = defined $self->{icmpv6_match};

    if (@_ == 2) {
        $match_exists or $self->{icmpv6_match} = new Brocade::BSC::Node::OF::Match::IcmpV6;
        $self->{icmpv6_match}->type($icmpv6_type);
    }
    $match_exists and $value = $self->{icmpv6_match}->type();
    return $value;
}
=item B<icmpv6_code>

Set or retrieve the FlowEntry ICMPv6 code match field.

=cut
sub icmpv6_code {
    my ($self, $icmpv6_code) = @_;
    my $value = undef;
    my $match_exists = defined $self->{icmpv6_match};

    if (@_ == 2) {
        $match_exists or $self->{icmpv6_match} = new Brocade::BSC::Node::OF::Match::IcmpV6;
        $self->{icmpv6_match}->code($icmpv6_code);
    }
    $match_exists and $value = $self->{icmpv6_match}->code();
    return $value;
}
=item B<in_port>

Set or retrieve the FlowEntry port match field.

=cut
sub in_port {
    my ($self, $in_port) = @_;
    $self->{in_port} = (@_ == 2) ? $in_port : $self->{in_port};
}
=item B<in_phy_port>

Set or retrieve the FlowEntry physical port match field.

=cut
sub in_phy_port {
    my ($self, $in_phy_port) = @_;
    $self->{in_phy_port} = (@_ == 2) ? $in_phy_port : $self->{in_phy_port};
}
=item B<arp_opcode>

Set or retrieve the FlowEntry ARP code match field.

=cut
sub arp_opcode {
    my ($self, $arp_opcode) = @_;
    $self->{arp_op} = (@_ == 2) ? $arp_opcode : $self->{arp_op};
}
=item B<arp_src_transport_address>

Set or retrieve the FlowEntry ARP source transport address match field.

=cut
sub arp_src_transport_address {
    my ($self, $arp_src_transport_address) = @_;
    $self->{arp_source_transport_address}
        = (@_ == 2) ? $arp_src_transport_address
                    : $self->{arp_source_transport_address};
}
=item B<arp_tgt_transport_address>

Set or retrieve the FlowEntry ARP target transport address match field.

=cut
sub arp_tgt_transport_address {
    my ($self, $arp_tgt_transport_address) = @_;
    $self->{arp_target_transport_address}
        = (@_ == 2) ? $arp_tgt_transport_address
                    : $self->{arp_target_transport_address};
}
=item B<arp_src_hw_address>

Set or retrieve the FlowEntry ARP source hardware address match field.

=cut
sub arp_src_hw_address {
    my ($self, $arp_src_hw_address) = @_;
    my $value = undef;

    (@_ == 2) and
        $self->{arp_source_hardware_address}->{address} = $arp_src_hw_address;
    defined $self->{arp_source_hardware_address} and
        $value = $self->{arp_source_hardware_address}->{address};
    return $value;
}
=item B<arp_tgt_hw_address>

Set or retrieve the FlowEntry ARP target hardware address match field.

=cut
sub arp_tgt_hw_address {
    my ($self, $arp_tgt_hw_address) = @_;
    my $value = undef;

    (@_ == 2) and
        $self->{arp_target_hardware_address}->{address} = $arp_tgt_hw_address;
    defined $self->{arp_target_hardware_address} and
        $value = $self->{arp_target_hardware_address}->{address};
    return $value;
}
=item B<mpls_label>

Set or retrieve the FlowEntry MPLS label match field.

=cut
sub mpls_label {
    my ($self, $mpls_label) = @_;
    my $value = undef;
    my $match_exists = defined $self->{protocol_match_fields};

    if (@_ == 2) {
        $match_exists or
            $self->{protocol_match_fields} = new Brocade::BSC::Node::OF::Match::ProtocolMatchFields;
        $self->{protocol_match_fields}->mpls_label($mpls_label);
    }
    $match_exists and $value = $self->{protocol_match_fields}->mpls_label();
    return $value;
}
=item B<mpls_tc>

Set or retrieve the FlowEntry MPLS TC match field.

=cut
sub mpls_tc {
    my ($self, $mpls_tc) = @_;
    my $value = undef;
    my $match_exists = defined $self->{protocol_match_fields};

    if (@_ == 2) {
        $match_exists or
            $self->{protocol_match_fields} = new Brocade::BSC::Node::OF::Match::ProtocolMatchFields;
        $self->{protocol_match_fields}->mpls_tc($mpls_tc);
    }
    $match_exists and $value = $self->{protocol_match_fields}->mpls_tc();
    return $value;
}
=item B<mpls_bos>

Set or retrieve the FlowEntry MPLS BOS match field.

=cut
sub mpls_bos {
    my ($self, $mpls_bos) = @_;
    my $value = undef;
    my $match_exists = defined $self->{protocol_match_fields};

    if (@_ == 2) {
        $match_exists or
            $self->{protocol_match_fields} = new Brocade::BSC::Node::OF::Match::ProtocolMatchFields;
        $self->{protocol_match_fields}->mpls_bos($mpls_bos);
    }
    $match_exists and $value = $self->{protocol_match_fields}->mpls_bos();
    return $value;
}
=item B<tunnel_id>

Set or retrieve the FlowEntry tunnel ID match field.

=cut
sub tunnel_id {
    my ($self, $tunnel_id) = @_;
    my $value = undef;

    (@_ == 2) and $self->{tunnel}->{tunnel_id} = $tunnel_id;
    defined $self->{tunnel} and $value = $self->{tunnel}->{tunnel_id};
    return $value;
}
=item B<metadata>

Set or retrieve the FlowEntry metadata match field.

=cut
sub metadata {
    my ($self, $metadata) = @_;
    my $value = undef;
    my $match_exists = defined $self->{metadata};

    if (@_ == 2) {
        $match_exists or $self->{metadata} = new Brocade::BSC::Node::OF::Match::Metadata;
        $self->{metadata}->metadata($metadata);
    }
    $match_exists and $self->{metadata}->metadata();
    return $value;
}
=item B<metadata_mask>

Set or retrieve the FlowEntry metadata mask match field.

=cut
sub metadata_mask {
    my ($self, $mask) = @_; 
    my $value = undef;
    my $match_exists = defined $self->{metadata};

    if (@_ == 2) {
        $match_exists or $self->{metadata} = new Brocade::BSC::Node::OF::Match::Metadata;
        $self->{metadata}->metadata_mask($mask);
    }
    $match_exists and $self->{metadata}->metadata_mask();
    return $value;
}


# Module ===============================================================
1;

=back

=head1 COPYRIGHT

Copyright (c) 2015,  BROCADE COMMUNICATIONS SYSTEMS, INC

All rights reserved.
