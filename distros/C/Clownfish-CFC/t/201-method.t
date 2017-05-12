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

use Test::More tests => 38;

BEGIN { use_ok('Clownfish::CFC::Model::Method') }
use Clownfish::CFC::Parser;

my $parser = Clownfish::CFC::Parser->new;
$parser->parse('parcel Neato;')
    or die "failed to process parcel_definition";

my %args = (
    return_type => $parser->parse('Obj*'),
    class_name  => 'Neato::Foo',
    param_list  => $parser->parse('(Foo *self, int32_t count = 0)'),
    name        => 'Return_An_Obj',
);

my $method = Clownfish::CFC::Model::Method->new(%args);
isa_ok( $method, "Clownfish::CFC::Model::Method" );

ok( $method->parcel, "parcel exposure by default" );

eval {
    my $death
        = Clownfish::CFC::Model::Method->new( %args, extra_arg => undef );
};
like( $@, qr/extra_arg/, "Extra arg kills constructor" );

eval {
    Clownfish::CFC::Model::Method->new( %args, name => 'return_an_obj' );
};
like( $@, qr/name/, "Invalid name kills constructor" );

for (qw( foo 1Foo Foo_Bar 1FOOBAR )) {
    eval {
        Clownfish::CFC::Model::Method->new(
            %args,
            class_name => $_,
        );
    };
    like( $@, qr/class_name/, "Reject invalid class name $_" );
    my $bogus_middle = "Foo::" . $_ . "::Bar";
    eval {
        Clownfish::CFC::Model::Method->new(
            %args,
            class_name => $bogus_middle,
        );
    };
    like( $@, qr/class_name/, "Reject invalid class name $bogus_middle" );
}

my $dupe = Clownfish::CFC::Model::Method->new(%args);
ok( $method->compatible($dupe), "compatible()" );

my $name_differs
    = Clownfish::CFC::Model::Method->new( %args, name => 'Eat' );
ok( !$method->compatible($name_differs),
    "different name spoils compatible()"
);
ok( !$name_differs->compatible($method), "... reversed" );

my $extra_param = Clownfish::CFC::Model::Method->new( %args,
    param_list => $parser->parse('(Foo *self, int32_t count = 0, int b)'), );
ok( !$method->compatible($name_differs),
    "extra param spoils compatible()"
);
ok( !$extra_param->compatible($method), "... reversed" );

my $default_differs = Clownfish::CFC::Model::Method->new( %args,
    param_list => $parser->parse('(Foo *self, int32_t count = 1)'), );
ok( !$method->compatible($default_differs),
    "different initial_value spoils compatible()"
);
ok( !$default_differs->compatible($method), "... reversed" );

my $missing_default = Clownfish::CFC::Model::Method->new( %args,
    param_list => $parser->parse('(Foo *self, int32_t count)'), );
ok( !$method->compatible($missing_default),
    "missing initial_value spoils compatible()"
);
ok( !$missing_default->compatible($method), "... reversed" );

my $param_name_differs = Clownfish::CFC::Model::Method->new( %args,
    param_list => $parser->parse('(Foo *self, int32_t countess = 0)'), );
ok( !$method->compatible($param_name_differs),
    "different param name spoils compatible()"
);
ok( !$param_name_differs->compatible($method), "... reversed" );

my $param_type_differs = Clownfish::CFC::Model::Method->new( %args,
    param_list => $parser->parse('(Foo *self, uint32_t count = 0)'), );
ok( !$method->compatible($param_type_differs),
    "different param type spoils compatible()"
);
ok( !$param_type_differs->compatible($method), "... reversed" );

my $self_type_differs = Clownfish::CFC::Model::Method->new(
    %args,
    class_name => 'Neato::Bar',
    param_list => $parser->parse('(Bar *self, int32_t count = 0)'),
);
ok( $method->compatible($self_type_differs),
    "different self type still compatible(), since can't test inheritance" );
ok( $self_type_differs->compatible($method), "... reversed" );

my $not_final = Clownfish::CFC::Model::Method->new(%args);
my $final     = $not_final->finalize;

eval { $method->override($final); };
like( $@, qr/final/i, "Can't override final method" );

ok( $not_final->compatible($final), "Finalize clones properly" );

for my $meth_meth (qw( short_method_sym full_method_sym full_offset_sym)) {
    eval { my $blah = $method->$meth_meth; };
    like( $@, qr/invoker/, "$meth_meth requires invoker" );
}

$parser->set_class_name("Neato::Obj");
isa_ok(
    $parser->parse($_),
    "Clownfish::CFC::Model::Method",
    "method declaration: $_"
    )
    for (
    'public int Do_Foo(Obj *self);',
    'Obj* Gimme_An_Obj(Obj *self);',
    'void Do_Whatever(Obj *self, uint32_t a_num, float real);',
    'Foo* Fetch_Foo(Obj *self, int num);',
    );

for ( 'public final void The_End(Obj *self);', ) {
    my $meth = $parser->parse($_);
    ok( $meth && $meth->final, "final method: $_" );
}

