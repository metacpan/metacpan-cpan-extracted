# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use warnings;

use Test::More tests => 4;
use Clownfish qw( to_clownfish );

my ( $vector, $twin );

$vector = Clownfish::Vector->new;
$vector->push( Clownfish::String->new($_) ) for 1 .. 5;
$vector->delete(3);
$vector->push('abc');
$vector->insert(
    tick    => 0,
    element => 'elem',
);
$twin = $vector->clone_raw;
is_deeply( $twin->to_perl, $vector->to_perl, "clone" );

use Data::Dumper;

my $hashref  = { foo => 'Foo', bar => 'Bar' };
$hashref->{baz} = [ { circular => [ undef, $hashref ], one => 'One' } ];

my $arrayref = [];
push( @$arrayref, [] ) for 1..5000;
push( @$arrayref, $arrayref, { key => $arrayref }, 42, $hashref, 'string' );

$vector = to_clownfish($arrayref);
is( $$vector, ${ $vector->fetch_raw(5000) },
    'to_clownfish($arrayref) handles circular references' );

my $hash = $vector->fetch_raw(5003);
is(
    $$hash,
    ${
        $hash->fetch_raw('baz')
             ->fetch_raw(0)
             ->fetch_raw('circular')
             ->fetch_raw(1)
    },
    'to_clownfish($arrayref) handles deep circular references'
);

my $roundtripped = $vector->to_perl;
is_deeply( $roundtripped, $arrayref, 'to_perl handles circular references');

# During global destruction, Clownfish destructors can be invoked forcefully
# in a random order. Circular references in Clownfish objects must be broken
# to avoid segfaults.

$hash->clear();
$vector->clear();

