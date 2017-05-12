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
# unit tests for Model/Activity.pm
#

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::Dochazka::Common::Model::Activity;
use Test::Fatal;
use Test::More;

# spawn badness
like( exception { App::Dochazka::Common::Model::Activity->spawn( 'bogus' ); }, 
    qr/Odd number of parameters/ );
like( exception { App::Dochazka::Common::Model::Activity->spawn( 'bogus' => 1 ); }, 
    qr/not listed in the validation options: bogus/ );

# spawn goodness
my $obj = App::Dochazka::Common::Model::Activity->spawn;
is( ref $obj, 'App::Dochazka::Common::Model::Activity' );
$obj = App::Dochazka::Common::Model::Activity->spawn(
    aid => 112, 
    code => 'BUBBA', 
    long_desc => 'A wrestling referee', 
    remark => 'cool dude' 
);
is( $obj->aid, 112 );
is( $obj->code, 'BUBBA' );
is( $obj->long_desc, 'A wrestling referee' );
is( $obj->remark, 'cool dude' );

# reset badness
like( exception { $obj->reset( 'bogus' ); }, 
    qr/Odd number of parameters/ );
like( exception { $obj->reset( 'bogus' => 1 ); }, 
    qr/not listed in the validation options: bogus/ );

# reset goodness
my %props = (
    aid => 55, 
    code => 'Robert', 
    long_desc => 'a refugee',
    remark => 'smokes too much',
    disabled => undef,
);
$obj->reset( %props );
my $obj2 = App::Dochazka::Common::Model::Activity->spawn( %props );
is( ref $obj, 'App::Dochazka::Common::Model::Activity' );
is( ref $obj2, 'App::Dochazka::Common::Model::Activity' );
is_deeply( $obj, $obj2 );
map { is( $obj->{$_}, $props{$_} ); } keys( %props );
is( $obj->aid, $obj->{'aid'} );
is( $obj->code, $obj->{'code'} ); 
is( $obj->long_desc, $obj->{'long_desc'} );
is( $obj->remark, $obj->{'remark'} );
is( $obj->disabled, $obj->{'disabled'} );
ok( ! $obj->disabled );
is( $obj->disabled, undef );

# TO_JSON
my $u_obj = $obj->TO_JSON;
is( ref $u_obj, 'HASH' );
is_deeply( $u_obj, {
    'aid' => 55,
    'code' => 'Robert', 
    'long_desc' => 'a refugee',
    'remark' => 'smokes too much',
    'disabled' => undef,
});

# clone, compare, compare_disabled
$obj2 = $obj->clone;
isnt( $obj, $obj2 );
is_deeply( $obj, $obj2 );
ok( $obj->compare( $obj2 ) );
ok( $obj->compare_disabled( $obj2 ) );
is( $obj->disabled, undef );
$obj->disabled( 0 );
is( $obj->disabled, 0 );
is( $obj2->disabled, undef );
ok( ! $obj->compare( $obj2 ) );
ok( $obj->compare_disabled( $obj2 ) );

# accessors already tested above

done_testing;

