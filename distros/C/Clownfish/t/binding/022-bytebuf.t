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
use lib 'buildlib';

use Test::More tests => 10;
use Clownfish;

my $buf = Clownfish::ByteBuf->new('abc');
isa_ok( $buf, 'Clownfish::ByteBuf' );

is( $buf->to_perl, 'abc', 'to_perl' );
is( $buf->get_size, 3, 'get_size' );

$buf->set_size(2);
is( $buf->to_perl, 'ab', 'set_size' );
$buf->cat(Clownfish::Blob->new('c'));
is( $buf->to_perl, 'abc', 'cat' );

my $other = Clownfish::ByteBuf->new('abcd');
ok( $buf->equals($buf), 'equals true');
ok( !$buf->equals($other), 'equals false');
ok( $buf->compare_to($other) < 0, 'compare_to');

$buf = $other->clone_raw;
isa_ok( $buf, 'Clownfish::ByteBuf', 'clone' );
ok( $buf->equals($other), 'equals after clone' );

