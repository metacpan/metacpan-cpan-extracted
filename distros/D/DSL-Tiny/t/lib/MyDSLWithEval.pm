#!perl

package MyDSLWithEval;

use Moo;

extends qw(MyDSL);

with qw(DSL::Tiny::InstanceEval);

1;
