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

Brocade::BSC::Node::NC

=head1 DESCRIPTION

A I<Brocade::BSC::NetconfNode> object is used to model, query, and configure
netconf devices via Brocade's OpenDaylight-based Software-Defined Networking
controller.

=cut

package Brocade::BSC::Node::NC;

use strict;
use warnings;

use parent qw(Brocade::BSC::Node);
use YAML;

=head1 METHODS

=cut

# Constructor ==========================================================
#
=over 4

=item B<new>

Creates a new I<Brocade::BSC::Node::NC> object and populates fields with
values from argument hash, if present, or YAML configuration file.

  ### parameters:
  #   + cfgfile       - path to YAML configuration file specifying node attributes
  #   + ctrl          - reference to Brocade::BSC controller object (required)
  #   + name          - name of controlled netconf node
  #   + ipAddr        - IP address of netconf node
  #   + portNum       - TCP port for node's NETCONF interface
  #   + tcpOnly       - boolean
  #   + adminName     - username
  #   + adminPassword - password
  #
  ### YAML configuration file labels and default values
  #
  #   parameter hash | YAML label  | default value
  #   -------------- | ----------- | -------------
  #   name           | nodeName    |
  #   ipAddr         | nodeIpAddr  |
  #   portNum        | nodePortNum | 830
  #   tcpOnly        |             | 0
  #   adminName      | nodeUname   | admin
  #   adminPassword  | nodePswd    | admin

Returns new I<Brocade::BSC::Node::NC> object.
=cut
sub new {
    my ($class, %params) = @_;

    my $self = $class->SUPER::new(%params);

    my $yamlcfg = undef;
    if ($params{cfgfile} && ( -e $params{cfgfile})) {
        $yamlcfg = YAML::LoadFile($params{cfgfile});
    }
    # Netconf-specific defaults
    $self->{ipAddr} = '';
    $self->{portNum} = 830;
    $self->{tcpOnly} = 0;
    $self->{adminName} = 'admin';
    $self->{adminPassword} = 'admin';

    if ($yamlcfg) {
        $yamlcfg->{nodeIpAddr}
            && ($self->{ipAddr} = $yamlcfg->{nodeIpAddr});
        $yamlcfg->{nodePortNum}
            && ($self->{portNum} = $yamlcfg->{nodePortNum});
        $yamlcfg->{nodeUname}
            && ($self->{adminName} = $yamlcfg->{nodeUname});
        $yamlcfg->{nodePswd}
            && ($self->{adminPassword} = $yamlcfg->{nodePswd});
    }
    map { $params{$_} && ($self->{$_} = $params{$_}) }
        qw(ipAddr portNum tcpOnly adminName adminPassword);

    return $self;
}

# Module ===============================================================
1;

=back

=head1 COPYRIGHT

Copyright (c) 2015,  BROCADE COMMUNICATIONS SYSTEMS, INC

All rights reserved.
