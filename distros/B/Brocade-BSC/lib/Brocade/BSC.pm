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

Brocade::BSC - Configure and query the Brocade SDN controller.

=head1 VERSION

Version 1.0.4

=head1 DESCRIPTION

A I<Brocade::BSC> object is used to model, query, and configure Brocade's
OpenDaylight-based Software-Defined Networking controller.

Most API methods return a duple: a I<Brocade::BSC::Status> object, and a
reference to a data structure with the requested information.  Status
should always be verified before attempting to dereference the second
return value.

=cut

use version; our $VERSION = qv("v1.0.4");

use strict;
use warnings;

package Brocade::BSC;

use Brocade::BSC::Status qw(:constants);

use YAML;
use LWP;
use HTTP::Status qw(:constants :is status_message);
use JSON -convert_blessed_universally;
use XML::Parser;
use Carp::Assert;

=head1 METHODS

=cut

# Constructor ==========================================================
#
=over 4

=item B<new>

Creates a new I<Brocade::BSC> object and populates fields with values
from argument hash, if present, or YAML configuration file.

  ### parameters:
  #   + cfgfile       - path to YAML configuration file specifying controller attributes
  #   + ipAddr        - IP address of controller
  #   + portNum       - TCP port for controller's REST interface
  #   + adminName     - username
  #   + adminPassword - password
  #   + timeout       - for HTTP requests, in seconds
  #
  ### YAML configuration file labels and default values
  #
  #   parameter hash | YAML label  | default value
  #   -------------- | ----------- | -------------
  #   ipAddr         | ctrlIpAddr  | 127.0.0.1
  #   portNum        | ctrlPortNum | 8181
  #   adminName      | ctrlUname   | admin
  #   adminPassword  | ctrlPswd    | admin
  #   timeout        | timeout     | 5

Returns new I<Brocade::BSC> object.

=cut
sub new {
    my $caller = shift;
    my %params = @_;

    my $yamlcfg;
    if ($params{cfgfile} && ( -e $params{cfgfile})) {
        $yamlcfg = YAML::LoadFile($params{cfgfile});
    }
    my $self = {
        ipAddr        => '127.0.0.1',
        portNum       => '8181',
        adminName     => 'admin',
        adminPassword => 'admin',
        timeout       => 5
    };
    if ($yamlcfg) {
        $yamlcfg->{ctrlIpAddr}
            && ($self->{ipAddr} = $yamlcfg->{ctrlIpAddr});
        $yamlcfg->{ctrlPortNum}
            && ($self->{portNum} = $yamlcfg->{ctrlPortNum});
        $yamlcfg->{ctrlUname}
            && ($self->{adminName} = $yamlcfg->{ctrlUname});
        $yamlcfg->{ctrlPswd}
            && ($self->{adminPassword} = $yamlcfg->{ctrlPswd});
        $yamlcfg->{timeout}
            && ($self->{timeout} = $yamlcfg->{timeout});
    }
    map { $params{$_} && ($self->{$_} = $params{$_}) }
        qw(ipAddr portNum adminName adminPassword timeout);
    bless $self;
}    

# Method ===============================================================
# _http_req : semi-private; send HTTP request to BSC Controller
# Parameters: $method (string, req) HTTP verb
#           : $urlpath (string, req) path for REST request
#           : $data (string, opt)
#           : $headerref (hash ref, opt)
# Returns   : HTTP::Response
#
sub _http_req {
    my $self = shift;
    my ($method, $urlpath, $data, $headerref) = @_;
    my %headers = $headerref ? %$headerref : ();

    my $url = "http://$$self{ipAddr}:$$self{portNum}$urlpath";
    my $ua = LWP::UserAgent->new;
    $ua->timeout($self->{timeout});
    my $req = HTTP::Request->new($method => $url);
    while (my($header, $value) = each %headers) {
        $req->header($header => $value);
    }
    if ($data) {
        $req->content($data);
    }
    $req->authorization_basic($$self{adminName}, $$self{adminPassword});

    return $ua->request($req);
}

# Method ===============================================================
#
=item B<as_json>

  # Returns pretty-printed JSON string representing BSC object.

=cut
sub as_json {
    my $self = shift;
    my $json = new JSON->canonical->allow_blessed->convert_blessed;
    return $json->pretty->encode($self);
}

# Method ===============================================================
#
=item B<get_nodes_operational_list>

  # Returns   : BSC::Status
  #           : reference to an array of node names

=cut
sub get_nodes_operational_list {
    my $self = shift;
    my @nodeNames = ();
    my $status = new Brocade::BSC::Status;
    my $urlpath = "/restconf/operational/opendaylight-inventory:nodes";

    my $resp = $self->_http_req('GET', $urlpath);
    if ($resp->code == HTTP_OK) {
        if ($resp->content =~ /\"nodes\"/) {
            my $nodes = decode_json($resp->content)->{nodes}->{node};
            if (! $nodes) {
                $status->code($BSC_DATA_NOT_FOUND);
            }
            else {
                foreach (@$nodes) {
                    push @nodeNames, $_->{id};
                }
                $status->code($BSC_OK);
            }
        }
        else {
            $status->code($BSC_DATA_NOT_FOUND);
        }
    }
    else {
        $status->http_err($resp);
    }
    return ($status, \@nodeNames);
}

# Method ===============================================================
#
=item B<get_node_info>

  # Parameter : node name (string, required)
  # Returns   : BSC::Status
  #           : array reference containing node info

=cut
sub get_node_info {
    my $self = shift;
    my $node = shift;
    my $node_info = undef;
    my $status = new Brocade::BSC::Status;
    my $urlpath = "/restconf/operational/opendaylight-inventory:nodes/node/$node";

    my $resp = $self->_http_req('GET', $urlpath);
    if ($resp->code == HTTP_OK) {
        if ($resp->content =~ /\"node\"/) {
            $node_info = decode_json($resp->content)->{node};
            $status->code($node_info ? $BSC_OK : $BSC_DATA_NOT_FOUND);
        }
    }
    else {
        $status->http_err($resp);
    }
    return ($status, $node_info);
}

# Method ===============================================================
#
=item B<check_node_config_status>

  # Parameter : node name (string, required)
  # Returns   : BSC::Status - NODE_CONFIGURED or NODE_NOT_FOUND

=cut
sub check_node_config_status {
    my $self = shift;
    my $node = shift;
    my $status = new Brocade::BSC::Status;

    my $urlpath = "/restconf/config/opendaylight-inventory:nodes/node/$node";
    my $resp = $self->_http_req('GET', $urlpath);
    $status->code(($resp->code == HTTP_OK)
        ? $BSC_NODE_CONFIGURED : $BSC_NODE_NOT_FOUND);
    return $status;
}

# Method ===============================================================
#
=item B<check_node_conn_status>

  # Parameter : node name (string, required)
  # Returns   : BSC::Status - NODE_CONNECTED or NODE_DISCONNECTED

=cut
sub check_node_conn_status {
    my $self = shift;
    my $node = shift;
    my $status = new Brocade::BSC::Status;
    ($status, my $nodeStatus) = $self->get_all_nodes_conn_status();
    if ($status->ok) {
        $status->code($BSC_NODE_NOT_FOUND);
        foreach (@$nodeStatus) {
            if ($_->{id} eq $node) {
                $status->code($_->{connected} ? $BSC_NODE_CONNECTED
                                              : $BSC_NODE_DISCONNECTED);
                last;
            }
        }
    }
    return $status;
}

# Method ===============================================================
#
=item B<get_all_nodes_in_config>

  # Returns   : BSC::Status
  #           : array reference - list of node identifiers

=cut
sub get_all_nodes_in_config {
    my $self = shift;
    my @nodeNames = ();
    my $status = new Brocade::BSC::Status;
    my $urlpath = "/restconf/config/opendaylight-inventory:nodes";

    my $resp = $self->_http_req('GET', $urlpath);
    if ($resp->code == HTTP_OK) {
        if ($resp->content =~ /\"nodes\"/) {
            my $nodes = decode_json($resp->content)->{nodes}->{node};
            if (! $nodes) {
                $status->code($BSC_DATA_NOT_FOUND);
            }
            else {
                foreach (@$nodes) {
                    push @nodeNames, $_->{id};
                }
                $status->code($BSC_OK);
            }
        }
        else {
            $status->code($BSC_DATA_NOT_FOUND);
        }
    }
    else {
        $status->http_err($resp);
    }
    return ($status, \@nodeNames);
}

# Method ===============================================================
#
=item B<get_all_nodes_conn_status>

  # Returns   : BSC::Status
  #           : reference to array of hashes:
  #             { id        => nodename,
  #               connected => boolean }

=cut
#
# Openflow devices on the Controller are always prefixed with "openflow:"
# Since Openflow devices initiate communication with the Controller, and
# not vice versa as with NETCONF devices, any Openflow devices in the
# operational inventory are shown as connected.
#
sub get_all_nodes_conn_status {
    my $self = shift;
    my @nodeStatus = ();
    my $status = new Brocade::BSC::Status;
    my $connected = undef;
    my $urlpath = "/restconf/operational/opendaylight-inventory:nodes";

    my $resp = $self->_http_req('GET', $urlpath);
    if ($resp->code == HTTP_OK) {
        if ($resp->content =~ /\"nodes\"/) {
            my $nodes = decode_json($resp->content)->{nodes}->{node};
            if (! $nodes) {
                $status->code($BSC_DATA_NOT_FOUND);
            }
            else {
                foreach (@$nodes) {
                    if ($_->{id} =~ /^openflow:/) {
                        $connected = 1;
                    }
                    else {
                        $connected = $_->{"netconf-node-inventory:connected"};
                    }
                    push @nodeStatus, {'id' => $_->{id},
                                       'connected' => $connected}
                }
                $status->code($BSC_OK);
            }
        }
        else {
            $status->code($BSC_DATA_NOT_FOUND);
        }
    }
    else {
        $status->http_err($resp);
    }
    return ($status, \@nodeStatus);
}

# Method ===============================================================
#
=item B<get_netconf_nodes_in_config>

  # Returns   : BSC::Status
  #           : array reference - list of node identifiers

=cut
sub get_netconf_nodes_in_config {
    my $self = shift;
    my @netconf_nodes = undef;

    my ($status, $nodelist_ref) = $self->get_all_nodes_in_config();
    $status->ok and @netconf_nodes = grep !/^openflow:/, @$nodelist_ref;
    return ($status, \@netconf_nodes);
}

# Method ===============================================================
#
=item B<get_all_nodes_conn_status>

  # Returns   : BSC::Status
  #           : reference to array of hashes:
  #             { id        => nodename,
  #               connected => boolean }

=cut
sub get_netconf_nodes_conn_status {
    my $self = shift;
    my @netconf_nodes = undef;

    my ($status, $nodestatus_ref) = $self->get_all_nodes_conn_status();
    $status->ok and
        @netconf_nodes = grep { $_->{id} !~ /^openflow:/ } @$nodestatus_ref;
    return ($status, \@netconf_nodes);
}

# Method ===============================================================
#
=item B<get_schemas>

  # Parameters: node name (string, required)
  # Returns   : BSC::Status
  #           : array reference - supported schemas on node

=cut
sub get_schemas {
    my $self = shift;
    my $node = shift;
    my $schemas = undef;
    my $status = new Brocade::BSC::Status;
    my $urlpath = "/restconf/operational/opendaylight-inventory:nodes/node/"
        . "$node/yang-ext:mount/ietf-netconf-monitoring:netconf-state/schemas";

    my $resp = $self->_http_req('GET', $urlpath);
    if ($resp->code == HTTP_OK) {
        if ($resp->content =~ /\"schemas\"/) {
            $schemas = decode_json($resp->content)->{schemas}->{schema};
            $status->code($schemas ? $BSC_OK : $BSC_DATA_NOT_FOUND);
        }
        else {
            $status->code($BSC_DATA_NOT_FOUND);
        }
    }
    else {
        $status->http_err($resp);
    }
    return ($status, $schemas);
}

# Method ===============================================================
#
=item B<get_schema>

  # Parameters: node name
  #           : YANG schema ID
  #           : YANG schema version
  # Returns   : BSC::Status
  #           : requested YANG schema as formatted JSON

=cut
sub get_schema {
    my $self = shift;
    my ($node, $schemaId, $schemaVersion) = @_;
    my $status = new Brocade::BSC::Status;
    my $schema = undef;

    my $urlpath = "/restconf/operations/opendaylight-inventory:nodes"
        . "/node/$node/yang-ext:mount/ietf-netconf-monitoring:get-schema";
    my $payload = qq({"input":{"identifier":"$schemaId","version":)
        . qq("$schemaVersion","format":"yang"}});
    my %headers = ('content-type'=>'application/yang.data+json',
                   'accept'=>'text/json, text/html, application/xml, */*');

    my $resp = $self->_http_req('POST', $urlpath, $payload, \%headers);
    if ($resp->code == HTTP_OK) {
        my $xmltree_ref = new XML::Parser(Style => 'Tree')->parse($resp->content);
        assert   ($xmltree_ref->[0]          eq 'get-schema');
        assert   ($xmltree_ref->[1][1]       eq 'output');
        assert   ($xmltree_ref->[1][2][1]    eq 'data');
        assert   ($xmltree_ref->[1][2][2][1] == 0);
        $schema = $xmltree_ref->[1][2][2][2];
        $status->code($BSC_OK);
    }
    else {
        $status->http_err($resp);
    }
    return ($status, $schema);
}

# Method ===============================================================
#
=item B<get_netconf_operations>

  # Parameters: node name
  # Returns   : BSC::Status
  #           : hash reference - operations supported by specified node

=cut
sub get_netconf_operations {
    my $self = shift;
    my $node = shift;
    my $operations = undef;
    my $status = new Brocade::BSC::Status;
    my $urlpath = "/restconf/operations/opendaylight-inventory:nodes/node/$node/yang-ext:mount/";

    my $resp = $self->_http_req('GET', $urlpath);
    if ($resp->code == HTTP_OK) {
        if ($resp->content =~ /\"operations\"/) {
            $operations = decode_json($resp->content)->{operations};
            $status->code($BSC_OK);
        }
        else {
            $status->code($BSC_DATA_NOT_FOUND);
        }
    }
    else {
        $status->http_err($resp);
    }
    return ($status, $operations);
}

# Method ===============================================================
#
=item B<get_all_modules_operational_state>

  # Returns   : BSC::Status
  #           : array reference - hashes of module state

=cut
sub get_all_modules_operational_state {
    my $self = shift;
    my $modules = undef;
    my $status = new Brocade::BSC::Status;
    my $urlpath = "/restconf/operational/opendaylight-inventory:nodes/node/controller-config/yang-ext:mount/config:modules";
    
    my $resp = $self->_http_req('GET', $urlpath);
    if ($resp->code == HTTP_OK) {
        if ($resp->content =~ /\"modules\"/) {
            # BVC returns bad JSON on this REST call.  Sanitize.
            my $json = $resp->content;
            $json =~ s/\\\n//g;
            $modules = decode_json($json)->{modules}->{module};
            $status->code($modules ? $BSC_OK : $BSC_DATA_NOT_FOUND);
        }
        else {
            $status->code($BSC_DATA_NOT_FOUND);
        }
    }
    else {
        $status->http_err($resp);
    }
    return ($status, $modules);
}

# Method ===============================================================
# 
=item B<get_module_operational_state>

  # Parameter : module type
  #           : module name
  # Returns   : BSC::Status
  #           : array reference - hash of module state

=cut
sub get_module_operational_state {
    my $self = shift;
    my ($moduleType, $moduleName) = @_;
    my $module = undef;
    my $status = new Brocade::BSC::Status;
    my $urlpath = "/restconf/operational/opendaylight-inventory:nodes/node/controller-config/yang-ext:mount/config:modules/module/$moduleType/$moduleName";

    my $resp = $self->_http_req('GET', $urlpath);
    if ($resp->code == HTTP_OK ) {
        if ($resp->content =~ /\"module\"/) {
            $module = decode_json($resp->content)->{module};
            $status->code($module ? $BSC_OK : $BSC_DATA_NOT_FOUND);
        }
        else {
            $status->code($BSC_DATA_NOT_FOUND);
        }
    }
    else {
        $status->http_err($resp);
    }
    return ($status, $module);
}

# Method ===============================================================
# 
=item B<get_sessions_info>

  # Parameters: node name
  # Returns   : BSC::Status
  #           : hash reference - session listing on specified node

=cut
sub get_sessions_info {
    my $self = shift;
    my $node = shift;
    my $sessions = undef;
    my $status = new Brocade::BSC::Status;
    my $urlpath = "/restconf/operational/opendaylight-inventory:nodes/node/$node/yang-ext:mount/ietf-netconf-monitoring:netconf-state/sessions";

    my $resp = $self->_http_req('GET', $urlpath);
    if ($resp->code == HTTP_OK) {
        if ($resp->content =~ /\"sessions\"/) {
            $sessions = decode_json($resp->content)->{sessions};
            $status->code($sessions ? $BSC_OK : $BSC_DATA_NOT_FOUND);
        }
        else {
            $status->code($BSC_DATA_NOT_FOUND);
        }
    }
    else {
        $status->http_err($resp);
    }
    return ($status, $sessions);
}

# Method ===============================================================
# 
=item B<get_streams_info>

  # Parameters:
  # Returns   : BSC::Status
  #           : hash reference - streams info

=cut
sub get_streams_info {
    my $self = shift;
    my $streams = undef;
    my $status = new Brocade::BSC::Status;
    my $urlpath = "/restconf/streams";

    my $resp = $self->_http_req('GET', $urlpath);
    if ($resp->code == HTTP_OK) {
        if ($resp->content =~ /\"streams\"/) {
            $streams = decode_json($resp->content)->{streams};
            $status->code($streams ? $BSC_OK : $BSC_DATA_NOT_FOUND);
        }
        else {
            $status->code($BSC_DATA_NOT_FOUND);
        }
    }
    else {
        $status->http_err($resp);
    }
    return ($status, $streams);
}

# Method ===============================================================
# 
=item B<get_service_providers_info>

  # Parameters:
  # Returns   : BSC::Status
  #           : array reference ~ name/provider pairs

=cut
sub get_service_providers_info {
    my $self = shift;
    my $service = undef;
    my $status = new Brocade::BSC::Status;
    my $urlpath = "/restconf/config/opendaylight-inventory:nodes/node/controller-config/yang-ext:mount/config:services";

    my $resp = $self->_http_req('GET', $urlpath);
    if ($resp->code == HTTP_OK) {
        if ($resp->content =~ /\"services\"/) {
            $service = decode_json($resp->content)->{services}->{service};
            $status->code($service ? $BSC_OK : $BSC_DATA_NOT_FOUND);
        }
        else {
            $status->code($BSC_DATA_NOT_FOUND);
        }
    }
    else {
        $status->http_err($resp);
    }
    return ($status, $service);
}

# Method ===============================================================
#
=item B<get_service_provider_info>

  # Parameters: node name
  # Returns   : BSC::Status
  #           : array reference ~ name/provider pairs

=cut
sub get_service_provider_info {
    my $self = shift;
    my $name = shift;
    my $service = undef;
    my $status = new Brocade::BSC::Status;
    my $urlpath = "/restconf/config/opendaylight-inventory:nodes/node"
        . "/controller-config/yang-ext:mount/config:services/service/$name";

    my $resp = $self->_http_req('GET', $urlpath);
    if ($resp->code == HTTP_OK) {
        if ($resp->content =~ /\"service\"/) {
            $service = decode_json($resp->content)->{service};
            $status->code($BSC_OK);
        }
        else {
            $status->code($BSC_DATA_NOT_FOUND);
        }
    }
    else {
        $status->http_err($resp);
    }
    return ($status, $service);
}

# Method ===============================================================
#
=item B<add_netconf_node>

Add a mount point on controller for specified node.

  # Parameters: node name
  # Returns   : BSC::Status

=cut
sub add_netconf_node {
    my $self = shift;
    my $node = shift;
    my $status = new Brocade::BSC::Status($BSC_OK);

    my $urlpath = "/restconf/config/opendaylight-inventory:nodes/node/controller-config/yang-ext:mount/config:modules";
    my %headers = ('content-type' => 'application/xml',
                   'accept' => 'application/xml');
    my $xmlPayload = <<END_XML;
        <module xmlns="urn:opendaylight:params:xml:ns:yang:controller:config">
          <type xmlns:prefix="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">prefix:sal-netconf-connector</type>
          <name>$node->{name}</name>
          <address xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">$node->{ipAddr}</address>
          <port xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">$node->{portNum}</port>
          <username xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">$node->{adminName}</username>
          <password xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">$node->{adminPassword}</password>
          <tcp-only xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">$node->{tcpOnly}</tcp-only>
          <event-executor xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">
            <type xmlns:prefix="urn:opendaylight:params:xml:ns:yang:controller:netty">prefix:netty-event-executor</type>
            <name>global-event-executor</name>
          </event-executor>
          <binding-registry xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">
            <type xmlns:prefix="urn:opendaylight:params:xml:ns:yang:controller:md:sal:binding">prefix:binding-broker-osgi-registry</type>
            <name>binding-osgi-broker</name>
          </binding-registry>
          <dom-registry xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">
            <type xmlns:prefix="urn:opendaylight:params:xml:ns:yang:controller:md:sal:dom">prefix:dom-broker-osgi-registry</type>
            <name>dom-broker</name>
          </dom-registry>
          <client-dispatcher xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">
            <type xmlns:prefix="urn:opendaylight:params:xml:ns:yang:controller:config:netconf">prefix:netconf-client-dispatcher</type>
            <name>global-netconf-dispatcher</name>
          </client-dispatcher>
          <processing-executor xmlns="urn:opendaylight:params:xml:ns:yang:controller:md:sal:connector:netconf">
            <type xmlns:prefix="urn:opendaylight:params:xml:ns:yang:controller:threadpool">prefix:threadpool</type>
            <name>global-netconf-processing-executor</name>
          </processing-executor>
        </module>
END_XML

    my $resp = $self->_http_req('POST', $urlpath, $xmlPayload, \%headers);
    $resp->is_success or $status->http_err($resp);
    return $status;
}

# Method ===============================================================
#
=item B<delete_netconf_node>

  # Parameters: node name
  # Returns   : BSC::Status
  #           :

=cut
sub delete_netconf_node {
    my $self = shift;
    my $node = shift;
    my $status = new Brocade::BSC::Status($BSC_OK);
    my $urlpath = "/restconf/config/opendaylight-inventory:nodes/node"
        . "/controller-config/yang-ext:mount/config:modules/module"
        . "/odl-sal-netconf-connector-cfg:sal-netconf-connector/"
        . $node->{name};

    my $resp = $self->_http_req('DELETE', $urlpath);
    $resp->is_success or $status->http_err($resp);
    return $status;
}

# Method ===============================================================
#
# =item B<modify_netconf_node_in_config>
#
#   # Parameters:
#   # Returns   : BSC::Status
#   #           :
#
# =cut
sub modify_netconf_node_in_config {
    my $self = shift;
    my $node = shift;

    die "XXX";
}

# Method ===============================================================
#
=item B<get_ext_mount_config_urlpath>

  # Parameters: node name
  # Returns   : base restconf URL for configuration of mounted netconf node

=cut
sub get_ext_mount_config_urlpath {
    my $self = shift;
    my $node = shift;

    return "/restconf/config/opendaylight-inventory:nodes/node/"
        . "$node/yang-ext:mount/";
}

# Method ===============================================================
#
=item B<get_ext_mount_operational_urlpath>

  # Parameters: node name
  # Returns   : base restconf URL for operational status of mounted netconf node

=cut
sub get_ext_mount_operational_urlpath {
    my $self = shift;
    my $node = shift;

    return "/restconf/operational/opendaylight-inventory:nodes/node/"
        . "$node/yang-ext:mount/";
}

# Method ===============================================================
# 
=item B<get_node_operational_urlpath>

  # Parameters: node name
  # Returns   : base restconf URL for node, operational status

=cut
sub get_node_operational_urlpath {
    my $self = shift;
    my $node = shift;

    return "/restconf/operational/opendaylight-inventory:nodes/node/$node";
}

# Method ===============================================================
#
=item B<get_node_config_urlpath>

  # Parameters: node name
  # Returns   : base restconf URL for node, configuration

=cut
sub get_node_config_urlpath {
    my $self = shift;
    my $node = shift;

    return "/restconf/config/opendaylight-inventory:nodes/node/$node";
}

# Method ===============================================================
#
=item B<get_openflow_nodes_operational_list>

  # Returns   : BSC::Status
  #           : array reference - node names

=cut
sub get_openflow_nodes_operational_list {
    my $self = shift;
    my $status = new Brocade::BSC::Status;
    my @nodelist = ();

    my $urlpath = "/restconf/operational/opendaylight-inventory:nodes";
    my $resp = $self->_http_req('GET', $urlpath);
    if ($resp->code == HTTP_OK) {
        if ($resp->content =~ /\"nodes\"/) {
            my $nodes = decode_json($resp->content)->{nodes}->{node};
            if (! $nodes) {
                $status->code($BSC_DATA_NOT_FOUND);
            }
            else {
                $status->code($BSC_OK);
                foreach (@$nodes) {
                    $_->{id} =~ /^(openflow:[0-9]*)/ && push @nodelist, $1;
                }
            }
        }
    }
    else {
        $status->http_err($resp);
    }
    return ($status, \@nodelist);
}

# Module ===============================================================
1;

=back

=head1 AUTHOR

C<< <pruiklw at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-brocade-bsc at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Brocade-BSC>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Brocade::BSC


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Brocade-BSC>

=back


=head1 ACKNOWLEDGEMENTS

Brocade::BSC is entirely based on L<pybvc|https://github.com/BRCDCOMM/pybvc>
created by Sergei Garbuzov.


=head1 COPYRIGHT

Copyright (c) 2015,  BROCADE COMMUNICATIONS SYSTEMS, INC

All rights reserved.
