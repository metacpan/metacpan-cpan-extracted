use Test::Simple;
use Test::More;
use Data::Filter::Abstract::Util qw/:all/;
use strict;

is( simple_sub({ "foo" => { ">" => 12, "<" => 23 } }), '(((($_->{foo} < 23)) && (($_->{foo} > 12))))', "function hash via simple sub" );

is( simple_sub({ "status" => { 'eq', [ 'assigned', 'in-progress', 'pending'] } }),
    '((($_->{status} eq "assigned") || ($_->{status} eq "in-progress") || ($_->{status} eq "pending")))',
    "simple op and arrayref");

is( simple_sub({ "status" => ["-or" => { 'eq', 'assigned' }, { "eq" => 'in-progress' }, { "eq" => 'pending' } ] } ),
    '(((($_->{status} eq "assigned")) || (($_->{status} eq "in-progress")) || (($_->{status} eq "pending"))))',
    "simple op and arrayref");


done_testing()
