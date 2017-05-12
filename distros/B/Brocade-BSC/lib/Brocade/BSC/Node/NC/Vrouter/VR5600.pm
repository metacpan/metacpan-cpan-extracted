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

Brocade::BSC::Node::NC::Vrouter::VR5600

=head1 DESCRIPTION

The I<::Vrouter::VR5600> object models a Vyatta 5600 Virtual router
controlled via netconf by a I<Brocade::BSC> instance.

=cut

use strict;
use warnings;

# Package ==============================================================
# DataplaneInterfaceFirewall
#
#
# ======================================================================
package Brocade::BSC::Node::NC::Vrouter::VR5600::DataplaneInterfaceFirewall;

# Constructor ==========================================================
# Parameters: interface name
# Returns   :
#
sub new {
    my $class = shift;
    my $tagnode = shift;

    my $self = {
        tagnode => $tagnode,
        firewall => {
            inlist  => [],
            outlist => []
        }
    };
    bless ($self, $class);
}

# Method ===============================================================
#             add_in_item : append firewall rule to inbound rules list
# Parameters: firewall rule name
# Returns   :
#
sub add_in_item {
    my ($self, $item) = @_;

    push @{$self->{firewall}->{inlist}}, $item;
}
# Method ===============================================================
#             add_out_item : append firewall rule to outbound rules list
# Parameters: firewall rule name
# Returns   :
#
sub add_out_item {
    my ($self, $item) = @_;

    push @{$self->{firewall}->{outlist}}, $item;
}

# Method ===============================================================
#             get_url_extenstion: provide suffix for configuring *this*
#                                 firewall; must be appended to config urlpath
# Parameters: none
# Returns   : url suffix
#
sub get_url_extension {
    my $self = shift;

    return "vyatta-interfaces:interfaces/vyatta-interfaces-dataplane:"
        . "dataplane/$self->{tagnode}";
}

# Method ===============================================================
#             get_payload:
# Parameters: none
# Returns   : self as JSON formatted for BSC REST call
#
sub get_payload {
    my $self = shift;

    my $json = new JSON->canonical->allow_blessed->convert_blessed;
    my $payload = '{"vyatta-interfaces-dataplane:dataplane":'
        . $json->encode($self)
        . '}';
    $payload =~ s/firewall/vyatta-security-firewall:firewall/g;
    $payload =~ s/inlist/in/g;
    $payload =~ s/outlist/out/g;

    return $payload;
}



# Package ==============================================================
# Brocade::BSC::Node::NC::Vrouter::5600
#    model and interact with Vyatta Virtual Router 5600 via BSC
#
# ======================================================================

package Brocade::BSC::Node::NC::Vrouter::VR5600;

use base qw(Brocade::BSC::Node::NC);
use HTTP::Status qw(:constants :is status_message);
use URI::Escape qw(uri_escape);
use JSON -convert_blessed_universally;
use Brocade::BSC;
use Brocade::BSC::Status qw(:constants);

=head1 METHODS

=over 4

=cut

# Method ===============================================================
#
=item B<get_schemas>

  # Returns   : array ref - YANG schemas supported by node

=cut ===================================================================
sub get_schemas {
    my $self = shift;

    return $self->{ctrl}->get_schemas($self->{name});
}

# Method ===============================================================
#
=item B<get_schema>

  # Returns   : requested YANG schema as formatted JSON

=cut ===================================================================
sub get_schema {
    my $self = shift;
    my ($yangId, $yangVersion) = @_;

    return $self->{ctrl}->get_schema($self->{name}, $yangId, $yangVersion);
}

# Method ===============================================================
#
=item B<get_cfg>

  # Returns   : BSC::Status
  #           : hash ref - VR5600 node configuration

=cut ===================================================================
sub get_cfg {
    my $self = shift;
    my $status = new Brocade::BSC::Status;
    my $config = undef;

    my $url = $self->{ctrl}->get_ext_mount_config_urlpath($self->{name});
    my $resp = $self->ctrl_req('GET', $url);
    if ($resp->code == HTTP_OK) {
        $config = decode_json($resp->content);
        $status->code($BSC_OK);
    }
    else {
        $status->http_err($resp);
    }
    return ($status, $config);
}

# Method ===============================================================
#
=item B<get_firewalls_cfg>

  # Returns   : BSC::Status
  #           : firewall configuration of VR5600 as a JSON string

=cut ===================================================================
sub get_firewalls_cfg {
    my $self = shift;
    my $status = new Brocade::BSC::Status;
    my $config = undef;

    my $url = $self->{ctrl}->get_ext_mount_config_urlpath($self->{name});
    $url .= "vyatta-security:security/vyatta-security-firewall:firewall";
    my $resp = $self->ctrl_req('GET', $url);
    if ($resp->code == HTTP_OK) {
        $config = $resp->content;
        $status->code($BSC_OK);
    }
    elsif ($resp->code == HTTP_NOT_FOUND) {
	$status->code($BSC_DATA_NOT_FOUND)
    }
    else {
        $status->http_err($resp);
    }
    return ($status, $config);
}

# Method ===============================================================
#
=item B<get_firewall_instance_cfg>

  # Parameters: name of firewall instance
  # Returns   : BSC::Status
  #           : specified ruleset from VR5600 firewall configuration
  #               as JSON string

=cut ===================================================================
sub get_firewall_instance_cfg {
    my $self = shift;
    my $instance = shift;
    my $status = new Brocade::BSC::Status;
    my $config = undef;

    my $url = $self->{ctrl}->get_ext_mount_config_urlpath($self->{name});
    $url .= "vyatta-security:security/vyatta-security-firewall:firewall/name/"
        . $instance;
    my $resp = $self->ctrl_req('GET', $url);
    if ($resp->code == HTTP_OK) {
        $config = $resp->content;
        $status->code($BSC_OK);
    }
    else {
        $status->http_err($resp);
    }
    return ($status, $config);
}

# Method ===============================================================
#
=item B<create_firewall_instance>

Create empty firewall instance on VR5600

  # Returns   : BSC::Status - success of operation

=cut ===================================================================
sub create_firewall_instance {
    my $self = shift;
    my $fwInstance = shift;
    my $status = new Brocade::BSC::Status($BSC_OK);

    my $urlpath = $self->{ctrl}->get_ext_mount_config_urlpath($self->{name});
    my %headers = ('content-type'=>'application/yang.data+json');
    my $payload = $fwInstance->get_payload();

    my $resp = $self->ctrl_req('POST', $urlpath, $payload, \%headers);
    $resp->is_success or $status->http_err($resp);

    return $status;
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub add_firewall_instance_rule {
    die "XXX";
}

# Method ===============================================================
# 
# Parameters: 
# Returns   : 
#
sub update_firewall_instance_rule {
    die "XXX";
}

# Method ===============================================================
#
=item B<delete_firewall_instance>

  # Parameters: name of instance to delete
  # Returns   : BSC::Status - success of operation

=cut ===================================================================
sub delete_firewall_instance {
    my $self = shift;
    my $fwInstance = shift;
    my $status = new Brocade::BSC::Status;

    my $urlpath = $self->{ctrl}->get_ext_mount_config_urlpath($self->{name})
        . $fwInstance->get_url_extension()
        . "/name/";
    my @rules = $fwInstance->get_rules();

    foreach my $rule (@rules) {
        my $rule_url = $urlpath . $rule->get_name();
        my $resp = $self->ctrl_req('DELETE', $rule_url);
        if ($resp->code != HTTP_OK) {
            $status->http_err($resp);
            last;
        }
        else {
            $status->code($BSC_OK);
        }
    }
    return $status;
}

# Method ===============================================================
#
=item B<set_dataplane_interface_firewall>

  # Parameters: ifName (required) - dataplane interface to which to apply
  #                                   firewall rules
  #           : inFw              - name of firewall instance for inbound traffic
  #           : outFw             - name of firewall instance for outbound traffic
  # Returns   : BSC::Status       - success of operation

=cut ===================================================================
sub set_dataplane_interface_firewall {
    my ($self, %params) = @_;
    my $status = new Brocade::BSC::Status($BSC_OK);

    my %headers = ('content-type' => 'application/yang.data+json');
    my $urlpath = $self->{ctrl}->get_ext_mount_config_urlpath($self->{name});

    $params{ifName} or die "missing req'd parameter \$ifName";
    my $fw = new Brocade::BSC::Node::NC::Vrouter::VR5600::DataplaneInterfaceFirewall($params{ifName});

    $params{inFw}  and $fw->add_in_item($params{inFw});
    $params{outFw} and $fw->add_out_item($params{outFw});

    my $payload = $fw->get_payload();
    $urlpath .= $fw->get_url_extension();

    my $resp = $self->ctrl_req('PUT', $urlpath, $payload, \%headers);
    $resp->code == HTTP_OK or $status->http_err($resp);
    return $status;
}

# Method ===============================================================
#
=item B<delete_dataplane_interface_firewall>

  # Parameters: ifName (required) - interface from which to clear firewall rules
  # Returns   : BSC::Status       - success of operation

=cut ===================================================================
sub delete_dataplane_interface_firewall {
    my ($self, $ifName) = @_;

    my $status = new Brocade::BSC::Status($BSC_OK);

    my $urlpath = $self->{ctrl}->get_ext_mount_config_urlpath($self->{name})
        . "vyatta-interfaces:interfaces/vyatta-interfaces-dataplane:dataplane"
        . "/$ifName/vyatta-security-firewall:firewall/";
    my $resp = $self->ctrl_req('DELETE', $urlpath);
    $resp->code == HTTP_OK or $status->http_err($resp);
    return $status;
}

# Method ===============================================================
#
=item B<get_interfaces_list>

  # Returns   : BSC::Status
  #           : array ref - interface names

=cut ===================================================================
sub get_interfaces_list {
    my $self = shift;
    my $status = new Brocade::BSC::Status;
    my $ifcfg = undef;
    my @iflist = ();

    ($status, $ifcfg) = $self->get_interfaces_cfg();
    if ($status->ok) {
        while ($ifcfg =~ m/"tagnode":"([^"]*)"/g) {
            push @iflist, $1;
        }
    }
    return ($status, \@iflist);
}

# Method ===============================================================
#
=item B<get_interfaces_cfg>

  # Returns   : BSC::Status
  #           : VR5600 network interface configuration as JSON string

=cut ===================================================================
sub get_interfaces_cfg {
    my $self = shift;
    my $status = new Brocade::BSC::Status;
    my $config = undef;

    my $urlpath = $self->{ctrl}->get_ext_mount_config_urlpath($self->{name});
    $urlpath .= "vyatta-interfaces:interfaces";

    my $resp = $self->ctrl_req('GET', $urlpath);
    if ($resp->code == HTTP_OK) {
        $config = $resp->content;
        $status->code($BSC_OK);
    }
    else {
        $status->http_err($resp);
    }
    return ($status, $config);
}

# Method ===============================================================
#
=item B<get_dataplane_interfaces_list>

  # Returns   : BSC::Status
  #           : array - dataplane interface names

=cut ===================================================================
sub get_dataplane_interfaces_list {
    my $self = shift;
    my $status = new Brocade::BSC::Status;
    my $dpifcfg = undef;
    my $iflist = undef;
    my @dpiflist;

    ($status, $dpifcfg) = $self->get_interfaces_cfg();
    if (! $dpifcfg) {
        $status->code($BSC_DATA_NOT_FOUND);
    }
    else {
        $iflist = decode_json($dpifcfg)->{interfaces}->{'vyatta-interfaces-dataplane:dataplane'};
        foreach my $interface (@$iflist) {
            push @dpiflist, $interface->{tagnode};
        }
        $status->code($BSC_OK);
    }
    return ($status, @dpiflist);
}

# Method ===============================================================
#
=item B<get_dataplane_interfaces_cfg>

  # Returns   : BSC::Status
  #           : array ref - configuration of all dataplane interfaces

=cut ===================================================================
sub get_dataplane_interfaces_cfg {
    my $self = shift;
    my $dpifcfg = undef;

    my ($status, $config) = $self->get_interfaces_cfg();
    if ($status->ok) {
        my $str1 = 'interfaces';
        my $str2 = 'vyatta-interfaces-dataplane:dataplane';
        if ($config =~ /$str2/) {
            $dpifcfg = decode_json($config)->{$str1}->{$str2};
        }
    }
    return ($status, $dpifcfg);
}

# Method ===============================================================
#
=item B<get_dataplane_interface_cfg>

  # Parameters: name of interface
  # Returns   : BSC::Status
  #           : configuration of specified interface as JSON string

=cut ===================================================================
sub get_dataplane_interface_cfg {
    my $self = shift;
    my $ifname = shift;
    my $status = new Brocade::BSC::Status;
    my $cfg = undef;

    my $urlpath = $self->{ctrl}->get_ext_mount_config_urlpath($self->{name})
        . "vyatta-interfaces:interfaces/vyatta-interfaces-dataplane:dataplane/"
        . $ifname;
    my $resp = $self->ctrl_req('GET', $urlpath);
    if ($resp->code == HTTP_OK) {
        $cfg = $resp->content;
        $status->code($BSC_OK);
    }
    else {
        $status->http_err($resp);
    }
    return ($status, $cfg);
}

# Method ===============================================================
#
=item B<get_loopback_interfaces_list>

  # Returns   : BSC::Status
  #           : array ref - loopback interface names

=cut ===================================================================
sub get_loopback_interfaces_list {
    my $self = shift;
    my @lbiflist = ();

    my ($status, $lbifcfg) = $self->get_loopback_interfaces_cfg();
    if (! $lbifcfg) {
        $status->code($BSC_DATA_NOT_FOUND);
    }
    else {
        foreach (@$lbifcfg) {
            push @lbiflist, $_->{tagnode};
        }
        $status->code($BSC_OK);
    }
    return ($status, \@lbiflist);
}

# Method ===============================================================
#
=item B<get_loopback_interfaces_cfg>

  # Returns   : BSC::Status
  #           : array ref - configuration of loopback interfaces

=cut ===================================================================
sub get_loopback_interfaces_cfg {
    my $self = shift;
    my $lbifcfg = undef;

    my ($status, $config) = $self->get_interfaces_cfg();
    if ($status->ok) {
        my $str1 = 'interfaces';
        my $str2 = 'vyatta-interfaces-loopback:loopback';
        if (($config =~ /$str1/) && ($config =~ /$str2/)) {
            $lbifcfg = decode_json($config)->{$str1}->{$str2};
        }
    }
    return ($status, $lbifcfg);
}

# Method ===============================================================
#
=item B<get_loopback_interface_cfg>

  # Parameters: name of interface
  # Returns   : BSC::Status
  #           : requested loopback configuration as JSON string

=cut ===================================================================
sub get_loopback_interface_cfg {
    my $self = shift;
    my $ifName = shift;
    my $status = new Brocade::BSC::Status($BSC_OK);
    my $config = undef;

    my $urlpath = $self->{ctrl}->get_ext_mount_config_urlpath($self->{name})
        . "vyatta-interfaces:interfaces/vyatta-interfaces-loopback:loopback/"
        . $ifName;
    my $resp = $self->ctrl_req('GET', $urlpath);
    if ($resp->code == HTTP_OK) {
        $config = $resp->content;
        $status->code($BSC_OK);
    }
    else {
        $status->http_err($resp);
    }

    return ($status, $config);
}


# Method ===============================================================
#
=item B<set_vpn_cfg>

  # Parameters: BSC::Node::NC::Vrouter::VPN
  # Returns   : BSC::Status

=cut ===================================================================
sub set_vpn_cfg {
    my ($self, $vpn) = @_;
    my $status = new Brocade::BSC::Status($BSC_OK);

    my $urlpath = $self->{ctrl}->get_ext_mount_config_urlpath($self->{name});
    my %headers = ('content-type' => 'application/yang.data+json');

    my $resp = $self->ctrl_req('POST', $urlpath, $vpn->get_payload(), \%headers);
    $resp->is_success or $status->http_err($resp);
    return $status;
}


# Method ===============================================================
#
=item B<get_vpn_cfg>

  # Returns   : BSC::Status
  #           : VPN configuration as JSON string

=cut ===================================================================
sub get_vpn_cfg {
    my $self = shift;
    my $status = new Brocade::BSC::Status;
    my $config = undef;
    
    my $urlpath = $self->{ctrl}->get_ext_mount_config_urlpath($self->{name})
	. "vyatta-security:security/vyatta-security-vpn-ipsec:vpn";
    my $resp = $self->ctrl_req('GET', $urlpath);
    if ($resp->code == HTTP_OK) {
	$config = $resp->content;
	$status->code($BSC_OK);
    }
    elsif ($resp->code == HTTP_NOT_FOUND) {
	$status->code($BSC_DATA_NOT_FOUND);
    }
    else {
	$status->http_err($resp);
    }

    return ($status, $config);
}


# Method ===============================================================
#
=item B<delete_vpn_cfg>

  # Parameters: none - deletes all vpn configuration
  # Returns   : BSC::Status

=cut ===================================================================
sub delete_vpn_cfg {
    my $self = shift;
    my $status = new Brocade::BSC::Status($BSC_OK);

    my $urlpath = $self->{ctrl}->get_ext_mount_config_urlpath($self->{name})
	. "vyatta-security:security/vyatta-security-vpn-ipsec:vpn";
    my $resp = $self->ctrl_req('DELETE', $urlpath);
    $resp->is_success() or $status->http_err($resp);
    return $status;
}


# Method ===============================================================
#
=item B<set_openvpn_interface_cfg>

  # Parameters:
  # Returns   :

=cut ===================================================================
sub set_openvpn_interface_cfg {
    my ($self, $ovpn_ifcfg) = @_;
    my $status = new Brocade::BSC::Status($BSC_OK);
    my %headers = ('content-type' => 'application/yang.data+json');
    my $urlpath = $self->{ctrl}->get_ext_mount_config_urlpath($self->{name});

    my $resp = $self->ctrl_req('POST', $urlpath,
                               $ovpn_ifcfg->get_payload, \%headers);
    $resp->is_success or $status->http_err($resp);
    return $status;
}


# Method ===============================================================
#
=item B<get_openvpn_interface_cfg>

  # Parameters:
  # Returns   :

=cut ===================================================================
sub get_openvpn_interface_cfg {
    my ($self, $ovpn_ifname) = @_;
    my $status = new Brocade::BSC::Status;
    my $config = undef;
    my $urlpath = $self->{ctrl}->get_ext_mount_config_urlpath($self->{name})
        . "vyatta-interfaces:interfaces/"
        . "vyatta-interfaces-openvpn:openvpn/$ovpn_ifname";

    my $resp = $self->ctrl_req('GET', $urlpath);
    if ($resp->code == HTTP_OK) {
	$config = $resp->content;
	$status->code($BSC_OK);
    }
    elsif ($resp->code == HTTP_NOT_FOUND) {
	$status->code($BSC_DATA_NOT_FOUND);
    }
    else {
	$status->http_err($resp);
    }
    return ($status, $config);
}


# Method ===============================================================
#
=item B<get_openvpn_interfaces_cfg>

  # Parameters:
  # Returns   : BSC::Status
  #           : array ref - configuration of openvpn interface(s)

=cut ===================================================================
sub get_openvpn_interfaces_cfg {
    my $self = shift;
    my $ovpn_ifcfg = undef;
    my $ovpn_tag = 'vyatta-interfaces-openvpn:openvpn';

    my ($status, $config) = $self->get_interfaces_cfg();
    if ($status->ok) {
        ($config =~ /$ovpn_tag/) and
            $ovpn_ifcfg = decode_json($config)->{'interfaces'}->{$ovpn_tag} or
            $status->code($BSC_DATA_NOT_FOUND);
    }
    return ($status, $ovpn_ifcfg);
}


# Method ===============================================================
#
=item B<delete_openvpn_interface_cfg>

  # Parameters: interface name for openvpn if; e.g. vtun0
  # Returns   : BSC::Status

=cut ===================================================================
sub delete_openvpn_interface_cfg {
    my ($self, $ovpn_ifname) = @_;
    my $status = new Brocade::BSC::Status($BSC_OK);
    my $urlpath = $self->{ctrl}->get_ext_mount_config_urlpath($self->{name})
        . "vyatta-interfaces:interfaces/"
        . "vyatta-interfaces-openvpn:openvpn/$ovpn_ifname";

    my $resp = $self->ctrl_req('DELETE', $urlpath);
    $resp->is_success() or $status->http_err($resp);
    return $status;
}


# Method ===============================================================
#
=item B<set_protocols_static_route_cfg>

  # Parameters: BSC::Node::NC::Vrouter::StaticRoute to set
  # Returns   : BSC::Status

Configure static route on vRouter

=cut ===================================================================
sub set_protocols_static_route_cfg {
    my ($self, $route) = @_;
    my $status = new Brocade::BSC::Status($BSC_OK);
    my %headers = ('content-type' => 'application/yang.data+json');
    my $urlpath = $self->{ctrl}->get_ext_mount_config_urlpath($self->{name});

    my $resp = $self->ctrl_req('POST', $urlpath,
                               $route->get_payload, \%headers);
    $resp->is_success() or $status->http_err($resp);
    return $status;
}


# Method ===============================================================
#
=item B<get_protocols_cfg>

  # Parameters: model, opt, on which to filter
  # Returns   : BSC::Status
  #           : routing protocol configuation as JSON

=cut ===================================================================
sub get_protocols_cfg {
    my ($self, $model) = @_;
    my $status = new Brocade::BSC::Status;
    my $config = undef;
    my $urlpath = $self->{ctrl}->get_ext_mount_config_urlpath($self->{name})
        . "vyatta-protocols:protocols";
    defined $model and $urlpath .= "/$model";

    my $resp = $self->ctrl_req('GET', $urlpath);
    if ($resp->code == HTTP_OK) {
	$config = $resp->content;
	$status->code($BSC_OK);
    }
    elsif ($resp->code == HTTP_NOT_FOUND) {
	$status->code($BSC_DATA_NOT_FOUND);
    }
    else {
	$status->http_err($resp);
    }
    return ($status, $config);
}


# Method ===============================================================
#
=item B<delete_protocols_cfg>

  # Parameters: model, opt, on which to filter for deletion
  # Returns   : BSC::Status

=cut ===================================================================
sub delete_protocols_cfg {
    my ($self, $model) = @_;
    my $status = new Brocade::BSC::Status($BSC_OK);
    my $urlpath = $self->{ctrl}->get_ext_mount_config_urlpath($self->{name})
        . "vyatta-protocols:protocols";
    defined $model and $urlpath .= "/$model";

    my $resp = $self->ctrl_req('DELETE', $urlpath);
    $resp->is_success() or $status->http_err($resp);
    return $status;
}


# Method ===============================================================
#
=item B<get_protocols_static_cfg>

  # Returns   : BSC::Status
  #           : static route configuration as JSON

=cut ===================================================================
sub get_protocols_static_cfg {
    my $self = shift;
    return $self->get_protocols_cfg('vyatta-protocols-static:static');
}


# Method ===============================================================
#
=item B<delete_protocols_static_cfg>

  # Returns   : BSC::Status

=cut ===================================================================
sub delete_protocols_static_cfg {
    my $self = shift;
    return $self->delete_protocols_cfg('vyatta-protocols-static:static');
}


# Method ===============================================================
#
=item B<get_protocols_static_interface_route_cfg>

  # Parameters: subnet for which to get route
  # Returns   : BSC::Status
  #           : requested route as JSON

=cut ===================================================================
sub get_protocols_static_interface_route_cfg {
    my ($self, $subnet) = @_;
    return $self->get_protocols_cfg("vyatta-protocols-static:static"
                                    . "/interface-route/"
                                    . uri_escape($subnet));
}


# Method ===============================================================
#
=item B<delete_protocols_static_interface_route_cfg>

  # Parameters: subnet for route to delete
  # Returns   : BSC::Status

=cut ===================================================================
sub delete_protocols_static_interface_route_cfg {
    my ($self, $subnet) = @_;
    return $self->delete_protocols_cfg("vyatta-protocols-static:static"
                                       . "/interface-route/"
                                       . uri_escape($subnet));
}


# Module ===============================================================
1;

=back

=head1 COPYRIGHT

Copyright (c) 2015,  BROCADE COMMUNICATIONS SYSTEMS, INC

All rights reserved.
