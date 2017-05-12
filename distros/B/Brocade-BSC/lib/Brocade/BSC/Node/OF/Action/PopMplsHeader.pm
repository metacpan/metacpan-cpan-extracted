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

package Brocade::BSC::Node::OF::Action::PopMplsHeader;
use parent qw(Brocade::BSC::Node::OF::Action);

use strict;
use warnings;


# Constructor ==========================================================
# Parameters: none
# Returns   : Brocade::BSC::Node::OF::Action::PopMplsHeader object
# 
sub new {
    my ($class, %params) = @_;

    my $self = $class->SUPER::new(%params);
    $self->{pop_mpls_action}->{'ethernet-type'} = $params{eth_type};
    bless ($self, $class);
    if ($params{href}) {
        while (my ($key, $value) = each %{$params{href}}) {
            $key =~ s/-/_/g;
            $self->{pop_mpls_action}->{$key} = $value;
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

    return "pop_mpls";
}


# Method ===============================================================
#             accessors
sub eth_type {
    my ($self, $eth_type) = @_;
    $self->{pop_mpls_action}->{'ethernet-type'} =
        (2 == @_) ? $eth_type : $self->{pop_mpls_action}->{'ethernet-type'};
}


# Module ===============================================================
1;
