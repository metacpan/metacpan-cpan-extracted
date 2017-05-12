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
# unit tests for Model/Employee.pm

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::Dochazka::Common::Model::Employee;
use Test::Fatal;
use Test::More;

# spawn badness
like( exception { App::Dochazka::Common::Model::Employee->spawn( 'bogus' ); }, 
    qr/Odd number of parameters/ );
like( exception { App::Dochazka::Common::Model::Employee->spawn( 'bogus' => 1 ); }, 
    qr/not listed in the validation options: bogus/ );

# spawn goodness
my $obj = App::Dochazka::Common::Model::Employee->spawn;
is( ref $obj, 'App::Dochazka::Common::Model::Employee' );
$obj = App::Dochazka::Common::Model::Employee->spawn(
    'eid' => 234,
    'sec_id' => 96609,
    'fullname' => "Friedrich Handel",
    'nick' => "Freedie", 
    'email' => 'handel@composers.org', 
    'passhash' => 'asdf', 
    'salt' => 'tastes good', 
    'remark' => 'too many notes'
);
is( ref $obj, 'App::Dochazka::Common::Model::Employee' );
is( $obj->eid, 234 );
is( $obj->sec_id, 96609 );
is( $obj->fullname, "Friedrich Handel" );
is( $obj->nick, "Freedie" ); 
is( $obj->email, 'handel@composers.org' ); 
is( $obj->passhash, 'asdf' ); 
is( $obj->salt, 'tastes good' ); 
is( $obj->supervisor, undef );
is( $obj->remark, 'too many notes' );

# reset badness
like( exception { $obj->reset( 'bogus' ); }, 
    qr/Odd number of parameters/ );
like( exception { $obj->reset( 'bogus' => 1 ); }, 
    qr/not listed in the validation options: bogus/ );

# reset goodness
my %props = (
    'eid' => 99,
    'sec_id' => 15334,
    'fullname' => "Luft Balons",
    'nick' => "Needle", 
    'email' => 'needle@composers.org', 
    'passhash' => '', 
    'salt' => undef,
    'supervisor' => 'trdelnik',
    'remark' => 'go away'
);
$obj->reset( %props );
my $obj2 = App::Dochazka::Common::Model::Employee->spawn( %props );
is_deeply( $obj, $obj2 );

# set goodness
my $desired_value = 'Please don\'t go!';
$obj2->set( 'remark' => $desired_value );
is( $obj2->remark, $desired_value );

# get goodness
is( $obj2->get( 'remark' ), $desired_value );

done_testing;
