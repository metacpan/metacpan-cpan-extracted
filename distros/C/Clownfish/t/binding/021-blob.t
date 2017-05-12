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

use Test::More tests => 8;
use Clownfish;

my $blob = Clownfish::Blob->new('abc');
isa_ok( $blob, 'Clownfish::Blob' );

is( $blob->to_perl, 'abc', 'to_perl' );
is( $blob->get_size, 3, 'get_size' );

my $other = Clownfish::Blob->new('abcd');
ok( $blob->equals($blob), 'equals true');
ok( !$blob->equals($other), 'equals false');
ok( $blob->compare_to($other) < 0, 'compare_to');

$blob = $other->clone_raw;
isa_ok( $blob, 'Clownfish::Blob', 'clone' );
ok( $blob->equals($other), 'equals after clone' );

