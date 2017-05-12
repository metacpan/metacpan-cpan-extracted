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

#!/usr/bin/perl -T

use Test::More tests => 15;

# check module load 1
use_ok( 'Brocade::BSC::Node::NC::Vrouter::VR5600' );
use Brocade::BSC;

# create object with specified values 10
my $bsc = new Brocade::BSC;
my $vRouter = new Brocade::BSC::Node::NC::Vrouter::VR5600(ctrl => $bsc,
                                                          name => 'vr5600',
                                                          ipAddr => '192.168.99.4',
                                                          adminName => 'vyatta',
                                                          adminPassword => 'Vy@tt@');

ok( defined($vRouter),                            "created VR5600 object");
ok( $vRouter->isa(Brocade::BSC::Node::NC::Vrouter::VR5600), "...and its a VR5600");
is( scalar keys %$vRouter, 7,                     "   a HASH with seven keys");
ok( $vRouter->{ctrl}->isa(Brocade::BSC),          "controller object (specified)");
is( $vRouter->{name}, 'vr5600',                   "name (specified)");
is( $vRouter->{ipAddr}, '192.168.99.4',           "ipAddr (specified)");
is( $vRouter->{portNum}, 830,                     "portNum (default)");
is( $vRouter->{tcpOnly}, 0,                       "tcpOnly (default)");
is( $vRouter->{adminName}, 'vyatta',              "adminName (specified)");
is( $vRouter->{adminPassword}, 'Vy@tt@',          "adminPassword (specified)");

# verify methods accessible 4
# inherited
can_ok( $vRouter, as_json );
# self
can_ok( $vRouter, get_schema );
can_ok( $vRouter, get_cfg );
can_ok( $vRouter, get_interfaces_list );
