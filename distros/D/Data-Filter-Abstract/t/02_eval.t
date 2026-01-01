use Test::Simple;
use Test::More;
use Data::Filter::Abstract::Util qw/:all/;
# use strict;

is ( ref eval(sprintf "sub { %s }", simple_sub("foo", "bar")), "CODE");
is ( ref eval(sprintf "sub { %s }", simple_sub("foo", 1)), "CODE");
is ( ref eval(sprintf "sub { %s }", simple_sub("foo", qr/12/)), "CODE");
is ( ref eval(sprintf "sub { %s }", simple_sub("foo", qr/[a-z]/i)), "CODE");

is ( ref eval(sprintf "sub { %s }", simple_hash({ bar => 1, baz => "wq", boo => qr/12/})), "CODE");
is ( ref eval(sprintf "sub { %s }", simple_sub({ bar => 1, baz => "wq", boo => qr/12/})), "CODE");
is ( ref eval(sprintf "sub { %s }", simple_array("foo", [ 1, "wq", qr/12/ ])), "CODE");
is ( ref eval(sprintf "sub { %s }", simple_sub("foo" => { ">" => 12 })), "CODE");


is ( ref eval(sprintf "sub { %s }", simple_function_hash("foo" => { ">" => 12, "<" => 23 })), "CODE");
is ( ref eval(sprintf "sub { %s }", simple_array("foo", [ { '==', 2 }, { '>', 5 } ])), "CODE");


is ( ref eval(sprintf "sub { %s }", logical_array("foo", [ -and => { '==', 2 }, { '>=', 5 } ])), "CODE");
is ( ref eval(sprintf "sub { %s }", simple_sub("foo", [ -and => { '==', 2 }, { '>=', 5 } ])), "CODE");

is ( ref eval(sprintf "sub { %s }", simple_sub("foo", [ -or => { '==', 2 }, { '>=', 5 } ])), "CODE");
is ( ref eval(sprintf "sub { %s }", simple_sub("foo", [ 1, "wq", qr/12/ ])), "CODE");

is ( ref eval(sprintf "sub { %s }", simple_sub(sub { $_->{foo}->{bar} > 5 })), "CODE");
is ( ref eval(sprintf "sub { %s }", simple_sub("foo", sub { $_->{foo}->{bar} > 5 })), "CODE");

is ( ref eval(sprintf "sub { %s }", simple_sub("foo", \"bar")), "CODE");
is ( ref eval(sprintf "sub { %s }", simple_sub("foo", [ -and => 1, \"bar" ])), "CODE");

is ( ref eval(sprintf "sub { %s }", simple_sub("foo", [ -and => 1, 12 ])), "CODE");
is ( ref eval(sprintf "sub { %s }", simple_sub("foo", [ 1, "wq", qr/12/, sub { shift()->{foo}->{bar} > 5 } ])), "CODE");

done_testing()
