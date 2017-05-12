# ************************************************************************* 
# Copyright (c) 2014-2015, SUSE LLC
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 
# 3. Neither the name of SUSE LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
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
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# ************************************************************************* 
#
# unit tests for Model/Schedule.pm
#

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::Dochazka::Common::Model::Schedule;
use Data::Dumper;
use Test::Fatal;
use Test::More; 

my $obj = App::Dochazka::Common::Model::Schedule->spawn(
    sid => 234,
    scode => 'Woofus',
    schedule => '{ "foobar" : "bazblat" }',
    remark => 'nothing of interest',
    disabled => 0,
);
is( ref $obj, 'App::Dochazka::Common::Model::Schedule' );
is( $obj->sid, 234 );
is( $obj->scode, 'Woofus' );
is( $obj->schedule, '{ "foobar" : "bazblat" }' );
is( $obj->remark, 'nothing of interest' );
is( $obj->disabled, 0 );

# use accessors to change the values
$obj->sid( 999 );
is( $obj->sid, 999 );
$obj->scode( 999 );
is( $obj->scode, 999 );
$obj->schedule( 999 );
is( $obj->schedule, 999 );
$obj->remark( 999 );
is( $obj->remark, 999 );
$obj->disabled( 999 );
is( $obj->disabled, 999 );

done_testing;
