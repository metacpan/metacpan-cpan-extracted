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

Brocade::BSC::Node::NC::Vrouter::VPN

=head1 DESCRIPTION

Create and modify vpn configuration on a Vyatta virtual router controlled
by a Brocade::BSC controller.

=cut

use strict;
use warnings;

use Data::Walk;
use JSON -convert_blessed_universally;

package Brocade::BSC::Node::NC::Vrouter::VPN;

use parent qw(Clone);
use Scalar::Util qw(reftype);

# Constructor ==========================================================
#
=over 4

=item B<new>

Creates and returns a new I<Brocade::BSC::Node::NC::Vrouter::VPN> object.

=cut
sub new {
    my $class = shift;

    my $self = {
        ipsec => {
            auto_update        => undef,
            disable_uniqreqids => undef,
            esp_group          => [],
            ike_group          => [],
            logging            => undef,
            nat_networks       => {
                allowed_network => [],
            },
            nat_traversal      => undef,
            profile            => [],
            site_to_site       => undef
        },
        l2tp  => {
            remote_access => {
                authentication => {
                    local_users => {
                        username => [],
                    },
                    mode => undef,
                },
                client_ip_pool => undef,
                description    => undef,
                dhcp_interface => undef,
                dns_servers => {
                    server_1 => undef,
                    server_2 => undef,
                },
                wins_servers => {
                    server_1 => undef,
                    server_2 => undef,
                },
                ipsec_settings => {
                    authentication => {
                        mode => undef,
                        pre_shared_secret => undef,
                        x509 => {
                            ca_cert_file        => undef,
                            crl_file            => undef,
                            server_cert_file    => undef,
                            server_key_file     => undef,
                            server_key_password => undef,
                        },
                    },
                },
                mtu => undef,
                outside_address => undef,
                outside_nexthop => undef,
                server_ip_pool  => undef,
            },
        },
        rsa_keys => {
            local_key => {
                file => undef,
            },
            rsa_key_name => [],
        },
    };
    
    bless ($self, $class);
}


# Method ===============================================================
#
=item B<as_json>

  # Returns   : VPN as formatted JSON string.

=cut ===================================================================
sub as_json {
    my $self = shift;
    my $json = new JSON->canonical->allow_blessed->convert_blessed;
    return $json->pretty->encode($self);
}


# Subroutine ===========================================================
#             _strip_undef: remove all keys with undefined value from hash,
#                           and any empty subtrees
# Parameters: none.  use as arg to Data::Walk::walk
# Returns   : irrelevant
#
sub _strip_undef {
    if ((defined reftype $_) and (reftype $_ eq ref {})) {
        while (my ($key, $value) = each %$_) {
            defined $value or delete $_->{$key};
            if( ref $_->{$key} eq ref {} ) {
                delete $_->{$key} if keys %{$_->{$key}} == 0;
            }
            elsif( ref $_->{$key} eq ref [] ) {
                delete $_->{$key} if @{$_->{$key}} == 0;
            }
        }
    }
}


# Method ===============================================================
#
=item B<get_payload>

  # Returns   : VPN configuration as JSON for posting to controller.

=cut ===================================================================
sub get_payload {
    my $self = shift;

    my $json = new JSON->canonical->allow_blessed->convert_blessed;
    my $clone = $self->clone();

    Data::Walk::walkdepth(\&_strip_undef, $clone);

    my $payload = '{"vyatta-security:security":{"vyatta-security-vpn-ipsec:vpn":'
        . $json->encode($clone)
        . '}}';
    $payload =~ s/_/-/g;

    return $payload;
}


# Method ===============================================================
#
#item B<_find_ike_group>

  # Parameters: group  => name of IKE group to find (or create)
  #           : create => (boolean) - whether or not to create new group
  #                                   if no matching group exists
  # Returns   : group reference; undef if not found and no create

#cut ===================================================================
sub _find_ike_group {
    my ($self, %params) = @_;
    my $group = undef;
    foreach my $grp (@{$self->{ipsec}->{ike_group}}) {
        $group = $grp;
        last if ($group->{tagnode} eq $params{grouptag});
    }
    if ($params{create} and not defined $group) {
        $group = {tagnode => $params{grouptag}};
        push @{$self->{ipsec}->{ike_group}}, $group;
    }
    return $group;
}


# Method ===============================================================
#
=item B<set_ipsec_ike_group_proposal>

  # Parameters: group      => name of IKE group to modify
  #           : tagnode    => proposal identifier
  #           : encryption => one of 'aes128', 'aes256', '3des'
  #           : hash       => 'sha1' or 'md5'
  #           : dh_group   =>
  # Returns   : list of proposals

=cut ===================================================================
sub set_ipsec_ike_group_proposal {
    my ($self, %params) = @_;

    defined $params{group} or die "required parameter 'group'\n";
    my $group = $self->_find_ike_group(grouptag => $params{group}, create => 1);
    my $proposal = {};
    map { $params{$_} && ($proposal->{$_} = $params{$_}) }
        qw(tagnode encryption hash dh_group);
    push @{$group->{proposal}}, $proposal;
}


# Method ===============================================================
#
=item B<set_ipsec_ike_group_lifetime>

  # Parameters: group    => name of IKE group to modify
  #           : lifetime => to apply to group
  # Returns   : lifetime

=cut ===================================================================
sub set_ipsec_ike_group_lifetime {
    my ($self, %params) = @_;

    defined $params{group} or die "required parameter 'group'\n";
    my $group = $self->_find_ike_group(grouptag => $params{group}, create => 1);
    $group->{lifetime} = $params{lifetime};
}


# Method ===============================================================
#
#item B<_find_esp_group>

  # Parameters: group  => name of ESP group to find (or create)
  #           : create => (boolean) - whether or not to create new group
  #                                   if no matching group exists
  # Returns   : group reference; undef if not found and no create

#cut ===================================================================
sub _find_esp_group {
    my ($self, %params) = @_;
    my $group = undef;
    foreach my $grp (@{$self->{ipsec}->{esp_group}}) {
        $group = $grp;
        last if ($group->{tagnode} eq $params{grouptag});
    }
    if ($params{create} and not defined $group) {
        $group = {tagnode => $params{grouptag}};
        push @{$self->{ipsec}->{esp_group}}, $group;
    }
    return $group;
}


# Method ===============================================================
#
=item B<set_ipsec_esp_group_proposal>

  # Parameters: group      => name of ESP group to modify
  #           : tagnode    => proposal identifier
  #           : encryption => one of 'aes128', 'aes256', '3des'
  #           : hash       => 'sha1' or 'md5'
  # Returns   : list of proposals

=cut ===================================================================
sub set_ipsec_esp_group_proposal {
    my ($self, %params) = @_;

    defined $params{group} or die "required parameter 'group'\n";
    my $group = $self->_find_esp_group(grouptag => $params{group}, create => 1);
    my $proposal = {};
    map { $params{$_} && ($proposal->{$_} = $params{$_}) }
        qw(tagnode encryption hash);
    push @{$group->{proposal}}, $proposal;
}


# Method ===============================================================
#
=item B<set_ipsec_esp_group_lifetime>

  # Parameters: group    => name of ESP group to modify
  #           : lifetime => to apply to group
  # Returns   : lifetime

=cut ===================================================================
sub set_ipsec_esp_group_lifetime {
    my ($self, %params) = @_;

    defined $params{group} or die "required parameter 'group'\n";
    my $group = $self->_find_esp_group(grouptag => $params{group}, create => 1);
    $group->{lifetime} = $params{lifetime};
}


# Method ===============================================================
#
#item B<_find_site_site_peer>

  # Parameters: peer  => identifier for vpn peer
  #           : create => (boolean) - whether or not to create new peer
  #                                   hash if no matching peer exists
  # Returns   : peer reference; undef if not found and no create

#cut ===================================================================
sub _find_site_site_peer {
    my ($self, %params) = @_;
    my $peer = undef;
    $self->{ipsec}->{site_to_site}->{peer} = []
        if not defined ($self->{ipsec}->{site_to_site});
    foreach my $peernode (@{$self->{ipsec}->{site_to_site}->{peer}}) {
        $peer = $peernode;
        last if ($peer->{tagnode} eq $params{peertag});
    }
    if ($params{create} and not defined $peer) {
        $peer = {tagnode => $params{peertag}};
        push @{$self->{ipsec}->{site_to_site}->{peer}}, $peer;
    }
    return $peer;
}


# Method ===============================================================
#
=item B<ipsec_site_site_peer_description>

  # Parameters: peertag => identifier for peer entry to modify
  #           : description

=cut ===================================================================
sub ipsec_site_site_peer_description {
    my ($self, $peertag, $description) = @_;
    my $peer = $self->_find_site_site_peer(peertag => $peertag, create => 1);
    $peer->{description} = $description;
}


# Method ===============================================================
#
=item B<ipsec_site_site_peer_auth_mode>

  # Parameters: peertag => identifier for peer entry to modify
  #           : auth_mode

=cut ===================================================================
sub ipsec_site_site_peer_auth_mode {
    my ($self, $peertag, $auth_mode) = @_;
    my $peer = $self->_find_site_site_peer(peertag => $peertag, create => 1);
    $peer->{authentication}->{mode} = $auth_mode;
}


# Method ===============================================================
#
=item B<ipsec_site_site_peer_auth_psk>

  # Parameters: peertag => identifier for peer entry to modify
  #           : psk     => pre-shared secret key

=cut ===================================================================
sub ipsec_site_site_peer_auth_psk {
    my ($self, $peertag, $psk) = @_;
    my $peer = $self->_find_site_site_peer(peertag => $peertag, create => 1);
    $peer->{authentication}->{pre_shared_secret} = $psk;
}


# Method ==============================================================
#
=item B<ipsec_site_site_peer_auth_rsa_key_name>

  # Parameters: peertag => identifier for peer entry to modify
  #           : rsa_key_name

=cut ==================================================================
sub ipsec_site_site_peer_auth_rsa_key_name {
    my ($self, $peertag, $rsa_key_name) = @_;
    my $peer = $self->_find_site_site_peer(peertag => $peertag, create => 1);
    $peer->{authentication}->{rsa_key_name} = $rsa_key_name;
}


# Method ==============================================================
#
=item B<ipsec_site_site_peer_auth_remote_id>

  # Parameters: peertag => identifer for peer entry to modify
  #           : remote_id

=cut ==================================================================
sub ipsec_site_site_peer_auth_remote_id {
    my ($self, $peertag, $remote_id) = @_;
    my $peer = $self->_find_site_site_peer(peertag => $peertag, create => 1);
    $peer->{authentication}->{remote_id} = $remote_id;
}


# Method ==============================================================
#
=item B<ipsec_site_site_peer_auth_ca_cert_file>

  # Parameters: peertag => identifier for peer entry to modify
  #           : path to certificate authority certificate

=cut ==================================================================
sub ipsec_site_site_peer_auth_ca_cert_file {
    my ($self, $peertag, $ca_cert_file) = @_;
    my $peer = $self->_find_site_site_peer(peertag => $peertag, create => 1);
    $peer->{authentication}->{x509}->{ca_cert_file} = $ca_cert_file;
}
# Method ==============================================================
#
=item B<ipsec_site_site_peer_auth_srv_cert_file>

  # Parameters: peertag => identifier for peer entry to modify
  #           : path to server certificate

=cut ==================================================================
sub ipsec_site_site_peer_auth_srv_cert_file {
    my ($self, $peertag, $cert_file) = @_;
    my $peer = $self->_find_site_site_peer(peertag => $peertag, create => 1);
    $peer->{authentication}->{x509}->{cert_file} = $cert_file;
}
# Method ==============================================================
#
=item B<ipsec_site_site_peer_auth_srv_key_file>

  # Parameters: peertag => identifier for peer entry to modify
  #           : path to key file for server certificate

=cut ==================================================================
sub ipsec_site_site_peer_auth_srv_key_file {
    my ($self, $peertag, $srv_key_file) = @_;
    my $peer = $self->_find_site_site_peer(peertag => $peertag, create => 1);
    $peer->{authentication}->{x509}->{key}->{file} = $srv_key_file;
}
# Method ==============================================================
#
=item B<ipsec_site_site_peer_auth_srv_key_pswd>

  # Parameters: peertag => identifier for peer entry to modify
  #           : password for server cert key file

=cut ==================================================================
sub ipsec_site_site_peer_auth_srv_key_pswd {
    my ($self, $peertag, $srv_key_pswd) = @_;
    my $peer = $self->_find_site_site_peer(peertag => $peertag, create => 1);
    $peer->{authentication}->{x509}->{key}->{password} = $srv_key_pswd;
}


# Method ===============================================================
#
=item B<ipsec_site_site_peer_dflt_esp_grp>

  # Parameters: peertag => identifier for peer entry to modify
  #           : esp_group => identifier for ESP group to use with this peer

=cut ===================================================================
sub ipsec_site_site_peer_dflt_esp_grp {
    my ($self, $peertag, $esp_group) = @_;
    my $peer = $self->_find_site_site_peer(peertag => $peertag, create => 1);
    $peer->{default_esp_group} = $esp_group;
}


# Method ===============================================================
#
=item B<ipsec_site_site_peer_ike_grp>

  # Parameters: peertag => identifier for peer entry to modify
  #             ike_group => identifier for IKE group to use with this peer

=cut ===================================================================
sub ipsec_site_site_peer_ike_grp {
    my ($self, $peertag, $ike_group) = @_;
    my $peer = $self->_find_site_site_peer(peertag => $peertag, create => 1);
    $peer->{ike_group} = $ike_group;
}


# Method ===============================================================
#
=item B<ipsec_site_site_peer_local_addr>

  # Parameters: peertag => identifier for peer entry to modify
  #           : local_address => IP address on this vrouter for
  #                              ipsec connection

=cut ===================================================================
sub ipsec_site_site_peer_local_addr {
    my ($self, $peertag, $local_address) = @_;
    my $peer = $self->_find_site_site_peer(peertag => $peertag, create => 1);
    $peer->{local_address} = $local_address;
}


# Method ===============================================================
#
#item B<_find_create_tunnel>

  # Parameters: peer  => identifier for vpn peer
  #           : tunnel_id => identifier for tunnel
  # Returns   : tunnel reference; undef if not found and no create

#cut ===================================================================
sub _find_create_tunnel {
    my ($peer, $tunnel_id) = @_;
    my $tunnel = undef;
    $peer->{tunnel} = [] if not defined $peer->{tunnel};
    foreach my $tun (@{$peer->{tunnel}}) {
        $tunnel = $tun;
        last if ($tunnel->{tagnode} == $tunnel_id);
    }
    if (not defined $tunnel) {
        $tunnel = {tagnode => $tunnel_id};
        push @{$peer->{tunnel}}, $tunnel;
    }
    return $tunnel;
}


# Method ===============================================================
#
=item B<ipsec_site_site_peer_tunnel_local_pfx>

  # Parameters: peer   => identifier for peer entry to modify
  #             tunnel => identifier for tunnel to modify
  #             subnet => local subnet routed via tunnel

=cut ===================================================================
sub ipsec_site_site_peer_tunnel_local_pfx {
    my ($self, %params) = @_;
    my $peer = $self->_find_site_site_peer(peertag => $params{peer},
                                           create => 1);
    my $tunnel = _find_create_tunnel($peer, $params{tunnel});
    $tunnel->{local}->{prefix} = $params{subnet};
}


# Method ===============================================================
#
=item B<ipsec_site_site_peer_tunnel_remote_pfx>

  # Parameters: peer   => identifier for peer entry to modify
  #             tunnel => identifier for tunnel to modify
  #             subnet => remote subnet routed via tunnel

=cut ===================================================================
sub ipsec_site_site_peer_tunnel_remote_pfx {
    my ($self, %params) = @_;
    my $peer = $self->_find_site_site_peer(peertag => $params{peer},
                                           create => 1);
    my $tunnel = _find_create_tunnel($peer, $params{tunnel});
    $tunnel->{remote}->{prefix} = $params{subnet};
}


# Method ===============================================================
#
=item B<nat_allow_network>

  # Parameters: subnet to be allowed through NAT, CIDR notation (w.x.y.z/d)
  # Returns   : allowed network list

Append a permitted IP subnet to list of permitted subnets.

=cut ===================================================================
sub nat_allow_network {
    my ($self, $subnet) = @_;

    (2 == @_) and
        push @{$self->{ipsec}->{nat_networks}->{allowed_network}}, {'tagnode' => $subnet};
    return $self->{ipsec}->{nat_networks};
}

# Method ===============================================================
#
=item B<nat_traversal>

  # Parameters: boolean: enable/disable NAT traversal
  # Returns   : current setting

Set or retrieve the NAT traversal flag.

=cut ===================================================================
sub nat_traversal {
    my ($self, $enable) = @_;
    (1 == @_) and return $self->{ipsec}->{nat_traversal};
    $self->{ipsec}->{nat_traversal} = $enable ? "enable" : "disable";
}





# Method ===============================================================
#
=item B<l2tp_remote_access_user>

  # Parameters: hash {'name' => ..., 'pswd' => ...}
  # Returns   : current list of user/password entries

Append a user to list of authorized users.

=cut ===================================================================
sub l2tp_remote_access_user {
    my ($self, %params) = @_;
    if (defined $params{name} and defined $params{pswd}) {
        push @{$self->{l2tp}->{remote_access}->{authentication}->{local_users}->{username}},
            {'tagnode' => $params{name}, 'password' => $params{pswd}};
    }
    return $self->{l2tp}->{remote_access}->{authentication}->{local_users};
}

# Method ===============================================================
#
=item B<l2tp_remote_access_user_auth_mode>

  # Parameters: mode
  # Returns   : current mode

Set or retrieve authentication mode.

=cut ===================================================================
sub l2tp_remote_access_user_auth_mode {
    my ($self, $mode) = @_;
    $self->{l2tp}->{remote_access}->{authentication}->{mode} =
        (2 == @_) ? $mode : $self->{l2tp}->{remote_access}->{authentication}->{mode};
}

# Method ===============================================================
#
=item B<l2tp_remote_access_client_ip_pool>

  # Parameters: 'start' => IPADDR, 'end' => IPADDR
  # Returns   : current cilent IP pool

Set or retrieve the IP address range that will be used for assigning
addresses to remote VPN connected nodes.

=cut ===================================================================
sub l2tp_remote_access_client_ip_pool {
    my ($self, %params) = @_;

    (defined $params{start} and defined $params{end})
        or return $self->{l2tp}->{remote_access}->{client_ip_pool};
    $self->{l2tp}->{remote_access}->{client_ip_pool} =
        { 'start' => $params{start}, 'stop' => $params{end} };
}

# Method ===============================================================
#
=item B<l2tp_remote_access_description>

  # Parameters: description string
  # Returns   : description string

Set or retrieve the VPN description.

=cut ===================================================================
sub l2tp_remote_access_description {
    my ($self, $description) = @_;
    $self->{l2tp}->{remote_access}->{description} =
        (2 == @_) ? $description : $self->{l2tp}->{remote_access}->{description};
}

# Method ===============================================================
#
=item B<l2tp_remote_access_dhcp_interface>

  # Parameters:
  # Returns   :

=cut ===================================================================
sub l2tp_remote_access_dhcp_interface {
    my ($self, $if) = @_;
    $self->{l2tp}->{remote_access}->{dhcp_interface} =
        (2 == @_) ? $if : $self->{l2tp}->{remote_access}->{dhcp_interface};
}

# Method ===============================================================
#
=item B<l2tp_remote_access_primary_dns_server>

  # Parameters: IP address of DNS server
  # Returns   : current primary DNS server

Set or retrieve primary DNS server IP address.

=cut ===================================================================
sub l2tp_remote_access_primary_dns_server {
    my ($self, $ipaddr) = @_;
    $self->{l2tp}->{remote_access}->{dns_servers}->{server_1} =
        (2 == @_) ? $ipaddr : $self->{l2tp}->{remote_access}->{dns_servers}->{server_1};
}

# Method ===============================================================
#
=item B<l2tp_remote_access_secondary_dns_server>

  # Parameters: IP address of DNS server
  # Returns   : current secondary DNS server

Set or retrieve secondary DNS server IP address.

=cut ===================================================================
sub l2tp_remote_access_secondary_dns_server {
    my ($self, $ipaddr) = @_;
    $self->{l2tp}->{remote_access}->{dns_servers}->{server_2} =
        (2 == @_) ? $ipaddr : $self->{l2tp}->{remote_access}->{dns_servers}->{server_2};
}

# Method ===============================================================
#
=item B<l2tp_remote_access_primary_wins_server>

  # Parameters: IP address of WINS server
  # Returns   : current primary WINS server

Set or retrieve primary WINS server IP address.

=cut ===================================================================
sub l2tp_remote_access_primary_wins_server {
    my ($self, $ipaddr) = @_;
    $self->{l2tp}->{remote_access}->{wins_servers}->{server_1} =
        (2 == @_) ? $ipaddr : $self->{l2tp}->{remote_access}->{wins_servers}->{server_1};
}

# Method ===============================================================
#
=item B<l2tp_remote_access_secondary_wins_server>

  # Parameters: IP address of WINS server
  # Returns   : current secondary WINS server

Set or retrieve secondary WINS server IP address.

=cut ===================================================================
sub l2tp_remote_access_secondary_wins_server {
    my ($self, $ipaddr) = @_;
    $self->{l2tp}->{remote_access}->{wins_servers}->{server_2} =
        (2 == @_) ? $ipaddr : $self->{l2tp}->{remote_access}->{wins_servers}->{server_2};
}


# Method ==============================================================
#
=item B<ipsec_auth_mode>

  # Parameters: ipsec authentication mode
  # Returns   : current mode

=cut ==================================================================
sub l2tp_remote_access_ipsec_auth_mode {
    my ($self, $mode) = @_;
    $self->{l2tp}->{remote_access}->{ipsec_settings}->{authentication}->{mode} =
        (2 == @_) ? $mode :
                    $self->{l2tp}->{remote_access}->{ipsec_settings}->{authentication}->{mode};
}


# Method ==============================================================
#
=item B<auth_psk>

  # Parameters: pre-shared secret key for ipsec vpn
  # Returns   : psk

=cut ==================================================================
sub l2tp_remote_access_ipsec_auth_psk {
    my ($self, $psk) = @_;
    $self->{l2tp}->{remote_access}->{ipsec_settings}->{authentication}->{pre_shared_secret} =
        (2 == @_) ? $psk :
                    $self->{l2tp}->{remote_access}->{ipsec_settings}->{authentication}->{pre_shared_secret};
}


# Method ==============================================================
#
=item B<auth_ca_cert_file>

  # Parameters: path to file on vrouter containing x509 certificate
  #             of trusted certificate authority
  # Returns   : file path

=cut ==================================================================
sub l2tp_remote_access_ipsec_auth_ca_cert_file {
    my ($self, $path) = @_;
    my $x509 = $self->{l2tp}->{remote_access}->{ipsec_settings}->{authentication}->{x509};
    $x509->{ca_cert_file} = (2 == @_) ? $path : $x509->{ca_cert_file};
}


# Method ==============================================================
#
=item B<auth_crl_file>

  # Parameters: path to file on vrouter containing x509 certificate
  #             revocation list
  # Returns   : file path

=cut ==================================================================
sub l2tp_remote_access_ipsec_auth_crl_file {
    my ($self, $path) = @_;
    my $x509 = $self->{l2tp}->{remote_access}->{ipsec_settings}->{authentication}->{x509};
    $x509->{crl_file} = (2 == @_) ? $path : $x509->{crl_file};
}


# Method ==============================================================
#
=item B<auth_srv_cert_file>

  # Parameters: path to file on vrouter containing x509 server certificate
  # Returns   : file path

=cut ==================================================================
sub l2tp_remote_access_ipsec_auth_srv_cert_file {
    my ($self, $path) = @_;
    my $x509 = $self->{l2tp}->{remote_access}->{ipsec_settings}->{authentication}->{x509};
    $x509->{server_cert_file} = (2 == @_) ? $path : $x509->{server_cert_file};
}


# Method ==============================================================
#
=item B<auth_srv_key_file>

  # Parameters: path to file on vrouter containing x509 key
  # Returns   : file path

=cut ==================================================================
sub l2tp_remote_access_ipsec_auth_srv_key_file {
    my ($self, $path) = @_;
    my $x509 = $self->{l2tp}->{remote_access}->{ipsec_settings}->{authentication}->{x509};
    $x509->{server_key_file} = (2 == @_) ? $path : $x509->{server_key_file};
}


# Method ==============================================================
#
=item B<l2tp_remote_access_ipsec_auth_srv_key_pswd>

  # Parameters: path to file on vrouter containing x509 key password
  # Returns   : file path

=cut ==================================================================
sub l2tp_remote_access_ipsec_auth_srv_key_pswd {
    my ($self, $path) = @_;
    my $x509 = $self->{l2tp}->{remote_access}->{ipsec_settings}->{authentication}->{x509};
    $x509->{server_key_password} = (2 == @_) ? $path : $x509->{server_key_password};
}


# Method ===============================================================
#
=item B<l2tp_remote_access_mtu>

  # Parameters: maximum transmission unit to apply [128..16384]
  # Returns   : current MTU

=cut ===================================================================
sub l2tp_remote_access_mtu {
    my ($self, $mtu) = @_;
    $self->{l2tp}->{remote_access}->{mtu} =
        (2 == @_) ? $mtu : $self->{l2tp}->{remote_access}->{mtu};
}

# Method ===============================================================
#
=item B<l2tp_remote_access_outside_address>

  # Parameters: IP address
  # Returns   : current l2tp external IP address

=cut ===================================================================
sub l2tp_remote_access_outside_address {
    my ($self, $ipaddr) = @_;
    $self->{l2tp}->{remote_access}->{outside_address} =
        (2 == @_) ? $ipaddr : $self->{l2tp}->{remote_access}->{outside_address};
}

# Method ===============================================================
#
=item B<l2tp_remote_access_outside_nexthop>

  # Parameters: IP address
  # Returns   : current l2tp gateway address

=cut ===================================================================
sub l2tp_remote_access_outside_nexthop {
    my ($self, $ipaddr) = @_;
    $self->{l2tp}->{remote_access}->{outside_nexthop} =
        (2 == @_) ? $ipaddr : $self->{l2tp}->{remote_access}->{outside_nexthop};
}

# Method ===============================================================
#
=item B<l2tp_remote_access_server_ip_pool>

  # Parameters: start => IP_ADDRESS
  #           : end   => IP_ADDRESS
  # Returns   :

=cut ===================================================================
sub l2tp_remote_access_server_ip_pool {
    my ($self, %params) = @_;

    (defined $params{start} and defined $params{end})
        or return $self->{l2tp}->{remote_access}->{server_ip_pool};
    $self->{l2tp}->{remote_access}->{server_ip_pool} =
        { 'start' => $params{start}, 'stop' => $params{end} };
}





# Method ===============================================================
#
=item B<local_key>

  # Parameters: path to file on local system containing RSA key
  # Returns   : current path

=cut ===================================================================
sub local_key {
    my ($self, $keyfile) = @_;
    $self->{rsa_keys}->{local_key}->{file} =
        (2 == @_) ? $keyfile : $self->{rsa_keys}->{local_key}->{file};
}

# Method ===============================================================
#
=item B<rsa_key>

  # Parameters:
  # Returns   :

=cut ===================================================================
sub rsa_key {
    my ($self, %params) = @_;

    if (defined $params{name} and defined $params{value}) {
        push @{$self->{rsa_keys}->{rsa_key_name}},
            {'tagnode' => $params{name}, 'rsa_key' => $params{value}};
    }
    return $self->{rsa_keys}->{rsa_key_name};
}

# Module ===============================================================
1;

=back

=head1 COPYRIGHT

Copyright (c) 2015,  BROCADE COMMUNICATIONS SYSTEMS, INC

All rights reserved.
