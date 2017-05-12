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

package Brocade::BSC::Node::OF::Action::Output;
use parent qw(Brocade::BSC::Node::OF::Action);

use Carp::Assert;

use strict;
use warnings;


# Constructor ==========================================================
# Parameters: none
# Returns   : Brocade::BSC::Node::OF::Action::Output object
# 
sub new {
    my ($class, %params) = @_;

    my $self = $class->SUPER::new(%params);
    $self->{output_action}->{'output_node_connector'} = $params{port};
    $self->{output_action}->{'max_length'} = $params{max_len};
    bless ($self, $class);
    if ($params{href}) {
        while (my ($key, $value) = each %{$params{href}}) {
            $key =~ s/-/_/g;
            $self->{output_action}->{"$key"} = $value;
        }
    }
    return $self;
}


# Method ===============================================================
#             as_oxm
# Parameters: none
# Returns   : this, as formatted for transmission to controller
#
sub as_oxm {
    my $self = shift;

    my $port = $self->outport();
    assert ($port);
    my $maxlen = $self->max_len();
    my $oxm = "output=$port";
    $oxm .= ":$maxlen" if defined($maxlen);
    return $oxm;
}


# Method ===============================================================
#             accessors
sub outport {
    my ($self, $port) = @_;
    $self->{output_action}->{'output_node_connector'} =
        (2 == @_) ? $port : $self->{output_action}->{'output_node_connector'};
}
sub max_len {
    my ($self, $max_len) = @_;
    $self->{output_action}->{'max_length'} =
        (2 == @_) ? $max_len : $self->{output_action}->{'max_length'};
}


# Module ===============================================================
1;
