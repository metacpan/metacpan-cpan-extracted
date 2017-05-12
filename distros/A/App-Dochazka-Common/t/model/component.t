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
# unit tests for Model/Component.pm
#

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::Dochazka::Common::Model::Component;
use Test::Fatal;
use Test::More;

note( 'spawn badness' );
like( exception { App::Dochazka::Common::Model::Component->spawn( 'bogus' ); }, 
    qr/Odd number of parameters/ );
like( exception { App::Dochazka::Common::Model::Component->spawn( 'bogus' => 1 ); }, 
    qr/not listed in the validation options: bogus/ );

note( 'spawn goodness' );
my $object = App::Dochazka::Common::Model::Component->spawn(
    cid => 14,
    path => 'path/to/bubba/component',
    source => 'Bunchofcharacters',
    acl => 'admin',
);
is( ref $object, 'App::Dochazka::Common::Model::Component' );
is( $object->cid, 14 );
is( $object->path, 'path/to/bubba/component' );
is( $object->source, 'Bunchofcharacters' );
is( $object->acl, 'admin' );

note( 'reset badness' );
like( exception { $object->reset( 'bogus' ); }, 
    qr/Odd number of parameters/ );
like( exception { $object->reset( 'bogus' => 1 ); }, 
    qr/not listed in the validation options: bogus/ );

note( 'reset goodness' );
my %props = (
    cid => 55, 
    path => 'prd', 
    source => 'dont wanna live like a a refugee',
    acl => 'inactive',
    validations => {},
);
$object->reset( %props );
my $obj2 = App::Dochazka::Common::Model::Component->spawn( %props );
is( ref $object, 'App::Dochazka::Common::Model::Component' );
is( ref $obj2, 'App::Dochazka::Common::Model::Component' );
is_deeply( $object, $obj2 );
map { is( $object->{$_}, $props{$_} ); } keys( %props );
is( $object->cid, $object->{'cid'} );
is( $object->path, $object->{'path'} ); 
is( $object->source, $object->{'source'} );
is( $object->acl, $object->{'acl'} );
is( $object->validations, $object->{'validations'} );

note( 'TO_JSON' );
my $u_obj = $object->TO_JSON;
is( ref $u_obj, 'HASH' );
is_deeply( $u_obj, {
    'cid' => 55,
    'path' => 'prd', 
    'source' => 'dont wanna live like a a refugee',
    'acl' => 'inactive',
    'validations' => {},
});

note( 'clone, compare' );
$obj2 = $object->clone;
isnt( $object, $obj2 );
is_deeply( $object, $obj2 );
ok( $object->compare( $obj2 ) );
$obj2->cid( 27 );
ok( ! $object->compare( $obj2 ) );

note( 'accessors already tested above' );

done_testing;

