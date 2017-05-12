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

use Test::More tests => 6;
use Encode qw( _utf8_off );
use Clownfish;

# Return 3 strings useful for verifying UTF-8 integrity.
sub utf8_test_strings {
    my $smiley       = "\x{263a}";
    my $not_a_smiley = $smiley;
    _utf8_off($not_a_smiley);
    my $frowny = $not_a_smiley;
    utf8::upgrade($frowny);
    return ( $smiley, $not_a_smiley, $frowny );
}

my ( $smiley, $not_a_smiley, $frowny ) = utf8_test_strings();

my $string = Clownfish::String->new($smiley);
isa_ok( $string, "Clownfish::String" );
is( $string->to_perl, $smiley, "round trip UTF-8" );

$string = Clownfish::String->new($smiley);
my $clone = $string->clone_raw;
is( $clone->to_perl, Clownfish::String->new($smiley)->to_perl, "clone" );

my $wanted = "abc\x00de";
$string = Clownfish::String->new($wanted);
my $iter = $string->top;
isa_ok( $iter, "Clownfish::StringIterator" );
my $buf = '';
while (my $cp = $iter->next) {
    $buf .= chr($cp);
}
is( $buf, $wanted, 'iter next' );

{
    package MyStringCallbackTest;
    use Clownfish::Test;
    use base qw(Clownfish::Test::StringCallbackTest);

    our $string_ref;

    sub new {
        $string_ref = \$_[1];
        return $_[0]->SUPER::new;
    }

    sub callback {
        my $self = shift;
        $$string_ref = 'bar';
    }
}

SKIP: {
    skip( "Known issue CLOWNFISH-44", 1 );
    my $string = 'foo';
    my $callback_test = MyStringCallbackTest->new($string);
    ok( $callback_test->unchanged_by_callback($string),
        "String unchanged by callback" );
}

