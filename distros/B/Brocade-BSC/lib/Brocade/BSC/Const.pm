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

Brocade::BSC::Const

=head1 SYNOPSIS

Symbolic constants used in BSC packages for well-known numbers
  (network protocols/header fields).

=head1 COPYRIGHT

Copyright (c) 2015,  BROCADE COMMUNICATIONS SYSTEMS, INC

All rights reserved.

=cut

package Brocade::BSC::Const;

use strict;
use warnings;

use Readonly;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw($ETH_TYPE_IPv4       $ETH_TYPE_IPv6       $ETH_TYPE_ARP
                    $ETH_TYPE_MPLS_UCAST $ETH_TYPE_MPLS_MCAST $ETH_TYPE_LLDP
                    $ETH_TYPE_QINQ       $ETH_TYPE_DOT1AD     $ETH_TYPE_STAG
                    $ETH_TYPE_DOT1Q      $ETH_TYPE_CTAG
                    $IP_PROTO_ICMP       $IP_PROTO_TCP        $IP_PROTO_UDP
                    $IP_PROTO_TLSP       $IP_PROTO_ICMPv6
                    $IP_DSCP_CS0  $IP_DSCP_CS1  $IP_DSCP_CS2  $IP_DSCP_CS3
                    $IP_DSCP_CS4  $IP_DSCP_CS5  $IP_DSCP_CS6  $IP_DSCP_CS7
                    $IP_DSCP_AF11 $IP_DSCP_AF12 $IP_DSCP_AF13
                    $IP_DSCP_AF21 $IP_DSCP_AF22 $IP_DSCP_AF23
                    $IP_DSCP_AF31 $IP_DSCP_AF32 $IP_DSCP_AF33
                    $IP_DSCP_AF41 $IP_DSCP_AF42 $IP_DSCP_AF43
                    $IP_DSCP_EF
                    $IP_ECN_NON_ECT  $IP_ECN_ECT0  $IP_ECN_ECT1  $IP_ECN_CE
                    $ARP_REQUEST     $ARP_REPLY
                    $PCP_BE          $PCP_BK       $PCP_EE       $PCP_CA
                    $PCP_VI          $PCP_VO       $PCP_IC       $PCP_NC
);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);


# Ethernet Types for some notable protocols
Readonly our $ETH_TYPE_IPv4       => 0x0800;    #  2048
Readonly our $ETH_TYPE_IPv6       => 0x86dd;    # 34525
Readonly our $ETH_TYPE_ARP        => 0x0806;    #  2054
Readonly our $ETH_TYPE_MPLS_UCAST => 0x8847;    # 34887
Readonly our $ETH_TYPE_MPLS_MCAST => 0x8848;    # 34888
Readonly our $ETH_TYPE_LLDP       => 0x88cc;    # 35020

Readonly our $ETH_TYPE_QINQ       => 0x88a8;    # 34984
Readonly our $ETH_TYPE_DOT1AD     => 0x88a8;    # 34984
Readonly our $ETH_TYPE_STAG       => 0x88a8;    # 34984

Readonly our $ETH_TYPE_DOT1Q      => 0x8100;    # 33024
Readonly our $ETH_TYPE_CTAG       => 0x8100;    # 33024

# IP protocol numbers
Readonly our $IP_PROTO_ICMP   => 0x01;  # ( 1) Internet Control Message Protocol
Readonly our $IP_PROTO_TCP    => 0x06;  # ( 6) Transmission Control Protocol
Readonly our $IP_PROTO_UDP    => 0x11;  # (17) User Datagram Protocol
Readonly our $IP_PROTO_TLSP   => 0x38;  # (56) Transport Layer Security Protocol
Readonly our $IP_PROTO_ICMPv6 => 0x3a;  # (58) ICMP for IPv6

# The IP Differentiated Services Code Points (DSCP)
# Class Selector (CS) are of the form 'xxx000'
# (higher value = higher priority)
#                                       | equiv IP precedence value
#                                       | -------------------------
Readonly our $IP_DSCP_CS0 => 0;         #  0   (Routine or Best Effort)
Readonly our $IP_DSCP_CS1 => 8;         #  1   (Priority)
Readonly our $IP_DSCP_CS2 => 16;        #  2   (Immediate)
Readonly our $IP_DSCP_CS3 => 24;        #  3   (Flash)
Readonly our $IP_DSCP_CS4 => 32;        #  4   (Flash Override)
Readonly our $IP_DSCP_CS5 => 40;        #  5   (Critical)
Readonly our $IP_DSCP_CS6 => 48;        #  6   (Internet)
Readonly our $IP_DSCP_CS7 => 56;        #  7   (Network)

# Assured Forwarding (AF) Per Hop Behavior (PHB) group
# The AF PHB group defines four separate classes
# Within each class, packets are given a drop precedence: high, medium or low
# Higher precedence means more dropping.
# AFxy (x=class, y=drop precedence)
# Class 1
Readonly our $IP_DSCP_AF11 => 10;
Readonly our $IP_DSCP_AF12 => 12;
Readonly our $IP_DSCP_AF13 => 14;
# Class 2
Readonly our $IP_DSCP_AF21 => 18;
Readonly our $IP_DSCP_AF22 => 20;
Readonly our $IP_DSCP_AF23 => 22;
# Class 3
Readonly our $IP_DSCP_AF31 => 26;
Readonly our $IP_DSCP_AF32 => 28;
Readonly our $IP_DSCP_AF33 => 30;
# Class 4
Readonly our $IP_DSCP_AF41 => 34;
Readonly our $IP_DSCP_AF42 => 36;
Readonly our $IP_DSCP_AF43 => 38;

# Expedited Forwarding
Readonly our $IP_DSCP_EF => 46;

# The Explicit Congestion Notification (ECN) 
# ECN uses the two least significant (right-most) bits of the DiffServ field
# in the IPv4 or IPv6 header to encode four different code points
Readonly our $IP_ECN_NON_ECT => 0;      # Non ECN-Capable Transport, NON-ECT
Readonly our $IP_ECN_ECT0    => 2;      # ECN Capable Transport, ECT(0)
Readonly our $IP_ECN_ECT1    => 1;      # ECN Capable Transport, ECT(1)
Readonly our $IP_ECN_CE      => 3;      # Congestion Encountered, CE

# ARP Operation Codes
Readonly our $ARP_REQUEST => 1;
Readonly our $ARP_REPLY   => 2;

# Ethernet frame Priority Code Points (PCP)
Readonly our $PCP_BE => 1;      # Best Effort            (priority 0, lowest)
Readonly our $PCP_BK => 0;      # Background             (priority 1)
Readonly our $PCP_EE => 2;      # Excellent Effort       (priority 2)
Readonly our $PCP_CA => 3;      # Critical Applications  (priority 3)
Readonly our $PCP_VI => 4;      # Video                  (priority 4)
Readonly our $PCP_VO => 5;      # Voice                  (priority 5)
Readonly our $PCP_IC => 6;      # Internetwork Control   (priority 6)
Readonly our $PCP_NC => 7;      # Network Control        (priority 7, highest)


# Module ===============================================================
1;
