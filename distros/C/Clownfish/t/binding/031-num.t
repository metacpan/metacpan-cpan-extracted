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

use Test::More tests => 25;
use Clownfish;
use Clownfish::Boolean qw( $true_singleton $false_singleton );

my $float     = Clownfish::Float->new(0.5);
my $neg_float = Clownfish::Float->new(-0.5);
isa_ok( $float, 'Clownfish::Float' );

is ( $float->get_value, 0.5, 'Float get_value' );
is ( $float->to_i64, 0, 'Float to_i64' );
is ( $float->to_string, '0.5', 'Float to_string' );
ok ( $float->equals($float), 'Float equals true' );
ok ( !$float->equals($neg_float), 'Float equals false' );
ok ( $float->compare_to($neg_float) > 0, 'Float compare_to' );

my $float_clone = $float->clone_raw;
isa_ok( $float_clone, 'Clownfish::Float', 'Float clone' );
ok ( $float->equals($float_clone), 'Float clone is equal' );

my $int     = Clownfish::Integer->new(12345);
my $neg_int = Clownfish::Integer->new(-12345);
isa_ok( $int, 'Clownfish::Integer' );

is ( $int->get_value, 12345, 'Integer get_value' );
is ( $int->to_string, '12345', 'Integer to_string' );
ok ( $int->equals($int), 'Integer equals true' );
ok ( !$int->equals($neg_int), 'Integer equals false' );
ok ( $int->compare_to($neg_int) > 0, 'Integer compare_to' );

my $int_clone = $int->clone_raw;
isa_ok( $int_clone, 'Clownfish::Integer', 'Integer clone' );
ok ( $int->equals($int_clone), 'Integer clone is equal' );

my $bool  = Clownfish::Boolean->singleton(1);
isa_ok( $bool, 'Clownfish::Boolean' );

ok ( $bool->get_value, 'Boolean get_value true' );
ok ( !$false_singleton->get_value, 'Boolean get_value false' );
is ( $bool->to_string, 'true', 'Boolean to_string' );
ok ( $bool->equals($true_singleton), 'Boolean equals true' );
ok ( !$bool->equals($false_singleton), 'Boolean equals false' );

my $bool_clone = $bool->clone_raw;
isa_ok( $bool_clone, 'Clownfish::Boolean', 'Boolean clone' );
ok ( $bool->equals($bool_clone), 'Boolean clone is equal' );

