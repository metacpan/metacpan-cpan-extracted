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

use Test::More tests => 14;
use Clownfish qw( to_clownfish );

my $hash = Clownfish::Hash->new( capacity => 10 );
$hash->store( "foo", Clownfish::String->new("bar") );
$hash->store( "baz", Clownfish::String->new("banana") );

my $iter = Clownfish::HashIterator->new($hash);
isa_ok( $iter, 'Clownfish::HashIterator' );
for (my $i = 0; $i < 2; $i++) {
    ok( $iter->next, "iter next $i" );
    my $key = $iter->get_key;
    is( $iter->get_value, $hash->fetch($key), "iter get $i" );
}
ok( !$iter->next, 'iter next final');

ok( !defined( $hash->fetch("blah") ),
    "fetch for a non-existent key returns undef" );

$hash->clear();
$hash->store( "nada", undef );
ok( !defined($hash->fetch("nada")), "store/fetch undef value" );
is( $hash->get_size, 1, "size after storing undef value" );

my %hash_with_utf8_keys = ( "\x{263a}" => "foo" );
my $round_tripped = to_clownfish( \%hash_with_utf8_keys )->to_perl;
is_deeply( $round_tripped, \%hash_with_utf8_keys,
    "Round trip conversion of hash with UTF-8 keys" );

my $hashref = {};
$hashref->{foo} = $hashref;
$hashref->{bar} = [ $hashref ];

$hash = to_clownfish($hashref);
is( $$hash, ${ $hash->fetch_raw('foo') },
    'to_clownfish($hashref) handles circular references' );

my $roundtripped = $hash->to_perl;
is_deeply( $roundtripped, $hashref, 'to_perl handles circular references' );

my $deep_hashref = { key => $hashref };
my $deep_hash = to_clownfish($deep_hashref);
my $val = $deep_hash->fetch_raw('key');
is( $$val, ${ $val->fetch_raw('bar')->fetch_raw(0) },
    'to_clownfish($hashref) handles deep circular references' );

$roundtripped = $deep_hash->to_perl;
is_deeply( $roundtripped, $deep_hashref,
           'to_perl handles deep circular references' );

# During global destruction, Clownfish destructors can be invoked forcefully
# in a random order. Circular references in Clownfish objects must be broken
# to avoid segfaults.

$hash->clear();
$val->clear();

