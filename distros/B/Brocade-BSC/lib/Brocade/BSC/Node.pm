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

Brocade::BSC::Node

=head1 DESCRIPTION

A I<Brocade::BSC::Node> object is used to model, query, and configure
network devices via Brocade's OpenDaylight-based Software-Defined
Networking controller.

=cut

package Brocade::BSC::Node;

use strict;
use warnings;

use YAML;
use JSON -convert_blessed_universally;

=head1 METHODS

=cut

# Constructor ==========================================================
#
=over 4

=item B<new>

Creates a new I<Brocade::BSC::Node> object and populates fields with
values from argument hash, if present, or YAML configuration file.

  ### parameters:
  #   + cfgfile       - path to YAML configuration file specifying node attributes
  #   + ctrl          - reference to Brocade::BSC controller object (required)
  #   + name          - name of controlled node
  #
  ### YAML configuration file labels and default values
  #
  #   parameter hash | YAML label  | default value
  #   -------------- | ----------- | -------------
  #   name           | nodeName    |

Returns new I<Brocade::BSC::Node> object.
=cut
sub new {
    my $class = shift;
    my %params = @_;

    my $yamlcfg;
    if ($params{cfgfile} && ( -e $params{cfgfile})) {
        $yamlcfg = YAML::LoadFile($params{cfgfile});
    }
    my $self = {
        ctrl          => $params{ctrl},
        name          => ''
    };
    if ($yamlcfg) {
        $yamlcfg->{nodeName}
            && ($self->{name} = $yamlcfg->{nodeName});
    }
    $params{name} && ($self->{name} = $params{name});

    bless ($self, $class);
}

# Method ===============================================================
#
=item B<as_json>

  # Returns   : Returns pretty-printed JSON string representing netconf node.

=cut
sub as_json {
    my $self = shift;
    my $json = new JSON->canonical->allow_blessed->convert_blessed;
    return $json->pretty->encode($self);
}


# Method ===============================================================
#
=item B<ctrl_req>

  # Parameters: $method (string, req) HTTP verb
  #           : $urlpath (string, req) path for REST request
  #           : $data (string, opt)
  #           : $headerref (hash ref, opt)
  # Returns   : HTTP::Response

=cut
sub ctrl_req {
    my $self = shift;

    return $self->{ctrl}->_http_req(@_);
}

# Module ===============================================================
1;

=back

=head1 COPYRIGHT

Copyright (c) 2015,  BROCADE COMMUNICATIONS SYSTEMS, INC

All rights reserved.
