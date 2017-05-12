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

use Test::More tests => 39;
use Clownfish qw( to_clownfish );
use Clownfish::Test;

my %complex_data_structure = (
    a => [ 1, 2, 3, { ooga => 'booga' } ],
    b => { foo => 'foofoo', bar => 'barbar' },
);
my $kobj = to_clownfish( \%complex_data_structure );
isa_ok( $kobj, 'Clownfish::Obj' );
my $transformed = $kobj->to_perl;
is_deeply( $transformed, \%complex_data_structure,
    "transform from Perl to Clownfish data structures and back" );

my $bread_and_butter = Clownfish::Hash->new;
$bread_and_butter->store( 'bread', Clownfish::Blob->new('butter') );
my $salt_and_pepper = Clownfish::Hash->new;
$salt_and_pepper->store( 'salt', Clownfish::ByteBuf->new('pepper') );
$complex_data_structure{c} = $bread_and_butter;
$complex_data_structure{d} = $salt_and_pepper;
$transformed = to_clownfish( \%complex_data_structure )->to_perl;
$complex_data_structure{c} = { bread => 'butter' };
$complex_data_structure{d} = { salt  => 'pepper' };
is_deeply( $transformed, \%complex_data_structure,
    "handle mixed data structure correctly" );

my $string = Clownfish::String->new("string");
eval { $string->substring(offset => 0, length => 1, foo => 1) };
like( $@, qr/Invalid parameter/, "Die on invalid parameter" );

eval { $string->length(undef) };
like( $@, qr/Usage: length/, "Die on extra parameter" );

my $th = Clownfish::Test::TestHost->new;
$string = Clownfish::String->new("string");
my $retval;

$retval = $th->test_obj_pos_arg($string);
is( $retval, 'string', "positional object arg" );
eval { $th->test_obj_pos_arg(undef) };
like( $@, qr/undef/, "die on undef positional object arg" );

$retval = $th->test_obj_pos_arg_def($string);
is( $retval, 'string', "positional object arg w/default" );
$retval = $th->test_obj_pos_arg_def(undef);
ok( !defined($retval), "undef positional object arg w/default" );
$retval = $th->test_obj_pos_arg_def();
ok( !defined($retval), "empty positional object arg w/default" );

$retval = $th->test_obj_label_arg(arg => $string);
is( $retval, 'string', "labeled object arg" );
eval { $th->test_obj_label_arg(arg => undef) };
like( $@, qr/undef/, "die on undef labeled object arg" );

$retval = $th->test_obj_label_arg_def(arg => $string);
is( $retval, 'string', "labeled object arg w/default" );
$retval = $th->test_obj_label_arg_def(arg => undef);
ok( !defined($retval), "undef labeled object arg w/default" );
$retval = $th->test_obj_label_arg_def();
ok( !defined($retval), "empty labeled object arg w/default" );

$retval = $th->test_int32_pos_arg(102);
is( $retval, 102, "positional int32 arg" );
eval { $th->test_int32_pos_arg(undef) };
like( $@, qr/undef/, "die on undef positional int32 arg" );

$retval = $th->test_int32_pos_arg_def(102);
is( $retval, 102, "positional int32 arg w/default" );
$retval = $th->test_int32_pos_arg_def(undef);
is( $retval, 101, "undef positional int32 arg w/default" );
$retval = $th->test_int32_pos_arg_def();
is( $retval, 101, "empty positional int32 arg w/default" );

$retval = $th->test_int32_label_arg(arg => 102);
is( $retval, 102, "labeled int32 arg" );
eval { $th->test_int32_label_arg(arg => undef) };
like( $@, qr/undef/, "die on undef labeled int32 arg" );

$retval = $th->test_int32_label_arg_def(arg => 102);
is( $retval, 102, "labeled int32 arg w/default" );
$retval = $th->test_int32_label_arg_def(arg => undef);
is( $retval, 101, "undef labeled int32 arg w/default" );
$retval = $th->test_int32_label_arg_def();
is( $retval, 101, "empty labeled int32 arg w/default" );

$retval = $th->test_bool_pos_arg(1);
ok( $retval, "true positional bool arg" );
$retval = $th->test_bool_pos_arg(0);
ok( !$retval, "false positional bool arg" );
eval { $th->test_bool_pos_arg(undef) };
like( $@, qr/undef/, "die on undef positional bool arg" );

$retval = $th->test_bool_pos_arg_def(1);
ok( $retval, "true positional bool arg w/default" );
$retval = $th->test_bool_pos_arg_def(0);
ok( !$retval, "false positional bool arg w/default" );
$retval = $th->test_bool_pos_arg_def(undef);
ok( $retval, "undef positional bool arg w/default" );
$retval = $th->test_bool_pos_arg_def();
ok( $retval, "empty positional bool arg w/default" );

$retval = $th->test_bool_label_arg(arg => 1);
ok( $retval, "true labeled bool arg" );
$retval = $th->test_bool_label_arg(arg => 0);
ok( !$retval, "false labeled bool arg" );
eval { $th->test_bool_label_arg(arg => undef) };
like( $@, qr/undef/, "die on undef labeled bool arg" );

$retval = $th->test_bool_label_arg_def(arg => 1);
ok( $retval, "true labeled bool arg w/default" );
$retval = $th->test_bool_label_arg_def(arg => 0);
ok( !$retval, "false labeled bool arg w/default" );
$retval = $th->test_bool_label_arg_def(arg => undef);
ok( $retval, "undef labeled bool arg w/default" );
$retval = $th->test_bool_label_arg_def();
ok( $retval, "empty labeled bool arg w/default" );

