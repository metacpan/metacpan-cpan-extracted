use Test::Simple;
use Test::More;
use Data::Filter::Abstract::Util qw/:all/;
use strict;

is( simple_sub({ "foo", "bar" }), '($_->{foo} eq "bar")', "string" );
is( simple_sub( "foo", "bar" ), '($_->{foo} eq "bar")', "string" );
is( simple_sub({ "foo", 1 }), '($_->{foo} == 1)', "number" );
is( simple_sub({ "foo", qr/12/ }), '($_->{foo} =~ qr/12/)', "regexp" );
is( simple_sub({ "foo", qr/[a-z]/i }), '($_->{foo} =~ qr/[a-z]/i)', "regexp" );

is( simple_hash({ bar => 1, baz => "wq", boo => qr/12/}), '($_->{bar} == 1) && ($_->{baz} eq "wq") && ($_->{boo} =~ qr/12/)', "and hash" );
is( simple_sub({ bar => 1, baz => "wq", boo => qr/12/}), '($_->{bar} == 1) && ($_->{baz} eq "wq") && ($_->{boo} =~ qr/12/)', "and hash via sub" );
is( simple_sub( bar => 1, baz => "wq", boo => qr/12/), '($_->{bar} == 1) && ($_->{baz} eq "wq") && ($_->{boo} =~ qr/12/)', "and hash via sub" );
is( simple_array("foo", [ 1, "wq", qr/12/ ]), '($_->{foo} == 1) || ($_->{foo} eq "wq") || ($_->{foo} =~ qr/12/)', "or array" );
is( simple_sub("foo", [ 1, "wq", qr/12/ ]), '($_->{foo} == 1) || ($_->{foo} eq "wq") || ($_->{foo} =~ qr/12/)', "or array via sub" );
# is( simple_sub({ "foo" => { ">" => 12 } }), '($_->{foo} > 12)', "or array via sub" );

is( simple_function_hash("foo" => { ">" => 12, "<" => 23 }), '($_->{foo} < 23) && ($_->{foo} > 12)', "function hash" );
is( simple_sub({ "foo" => { ">" => 12, "<" => 23 } }), '($_->{foo} < 23) && ($_->{foo} > 12)', "function hash via simple sub" );

is( simple_function_hash("foo" => { ">" => 12, "<" => 23 }), '($_->{foo} < 23) && ($_->{foo} > 12)', "function hash" );
is( simple_array("foo", [ { '==', 2 }, { '>', 5 } ]), '($_->{foo} == 2) || ($_->{foo} > 5)', "function array" );

is( logical_array("foo", [ -and => { '==', 2 }, { '>=', 5 } ]), '($_->{foo} == 2) && ($_->{foo} >= 5)', "logical array" );
is( simple_sub({ "foo", [ -and => { '==', 2 }, { '>=', 5 } ] }), '($_->{foo} == 2) && ($_->{foo} >= 5)', "logical array via sub" );
is( simple_sub( "foo", [ -and => { '==', 2 }, { '>=', 5 } ] ), '($_->{foo} == 2) && ($_->{foo} >= 5)', "logical array via sub" );

is( simple_sub({ "foo", [ -or => { '==', 2 }, { '>=', 5 } ] }), '($_->{foo} == 2) || ($_->{foo} >= 5)', "complex logic" );
is( simple_sub({ "foo", [ 1, "wq", qr/12/ ] }), '($_->{foo} == 1) || ($_->{foo} eq "wq") || ($_->{foo} =~ qr/12/)', "complex logic" );

is( simple_sub(sub { $_->{foo}->{bar} > 5 }), q((sub { use strict; $_->{'foo'}{'bar'} > 5; })), "simple sub" );
is( simple_sub("foo", sub { $_->{foo}->{bar} > 5 }), q((sub { use strict; $_->{'foo'}{'bar'} > 5; })), "simple sub" );

is( simple_sub({ "foo", \"bar" }), '((looks_like_number($_->{foo})) ? ($_->{foo} == $_->{bar}) : ($_->{foo} eq $_->{bar}))', "name" );
is( simple_sub({ "foo", [ -and => 1, \"bar" ] }), '($_->{foo} == 1) && ((looks_like_number($_->{foo})) ? ($_->{foo} == $_->{bar}) : ($_->{foo} eq $_->{bar}))', "name" );

is( simple_sub({ "foo", [ -or => 1, 12 ] }), '($_->{foo} == 1) || ($_->{foo} == 12)', "complex OR" );
is( simple_sub({"foo", [ 1, "wq", qr/12/, sub { shift()->{foo}->{bar} > 5 } ]}),
    q(($_->{foo} == 1) || ($_->{foo} eq "wq") || ($_->{foo} =~ qr/12/) || (sub { use strict; +(shift())->{'foo'}{'bar'} > 5; })), "complex or with mixed inputs" );

done_testing()
