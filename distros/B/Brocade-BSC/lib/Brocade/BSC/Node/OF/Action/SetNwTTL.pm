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

package Brocade::BSC::Node::OF::Action::SetNwTTL;
use parent qw(Brocade::BSC::Node::OF::Action);

use strict;
use warnings;


# Constructor ==========================================================
# Parameters: none
# Returns   : Brocade::BSC::Node::OF::Action::SetNwTTL object
# 
sub new {
    my $class = shift;
    my %params = @_;

    my $self = $class->SUPER::new(%params);
    $self->{set_nw_ttl_action}->{'nw-ttl'} = $params{ip_ttl};
    bless ($self, $class);
}


# Method ===============================================================
#             accessors
sub ip_ttl {
    my ($self, $nw_ttl) = @_;
    $self->{set_nw_ttl_action}->{'nw-ttl'} =
        (2 == @_) ? $ip_ttl : $self->{set_nw_ttl_action}->{'nw-ttl'};
}


# Module ===============================================================
1;
