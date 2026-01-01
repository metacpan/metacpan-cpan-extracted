use Test::Simple;
use Test::More;
use Data::Filter::Abstract::Util qw/:all/;
use strict;

$\ = "\n"; $, = "\t";

# print STDERR Data::Filter::Abstract::Util::key_q("foo-bar");
# print STDERR Data::Filter::Abstract::Util::key_q("foo bar");

is( simple_sub({ "foo-bar" => 12 }), '($_->{"foo-bar"} == 12)', "multiple regexp" );
is( simple_sub({ "foo-bar" => { "=~" => 12, } }), '($_->{"foo-bar"} =~ qr/12/)', "multiple regexp" );


is( simple_sub({ "foo-bar" => { "=~" => 12, "!~" => qr/23/i } }), '($_->{"foo-bar"} !~ qr/23/i) && ($_->{"foo-bar"} =~ qr/12/)', "multiple regexp" );

is( simple_sub({ "foo bar" => { "=~" => [ qr/12/i, qr/23/i ] } }), '($_->{"foo bar"} =~ qr/12/i) || ($_->{"foo bar"} =~ qr/23/i)', "multiple regexp" );
is( simple_sub({ "foo-bar" => { "=~" => [ qr/12/i, qr/23/i ] } }), '($_->{"foo-bar"} =~ qr/12/i) || ($_->{"foo-bar"} =~ qr/23/i)', "multiple regexp" );


is( simple_sub({ "foo bar", "bar" }), '($_->{"foo bar"} eq "bar")', "string" );
is( simple_sub( "foo bar", "bar" ), '($_->{"foo bar"} eq "bar")', "string" );
is( simple_sub({ "foo bar", 1 }), '($_->{"foo bar"} == 1)', "number" );
is( simple_sub({ "foo bar", qr/12/ }), '($_->{"foo bar"} =~ qr/12/)', "regexp" );
is( simple_sub({ "foo bar", qr/[a-z]/i }), '($_->{"foo bar"} =~ qr/[a-z]/i)', "regexp" );

is( simple_hash({ bar => 1, baz => "wq", boo => qr/12/}), '($_->{bar} == 1) && ($_->{baz} eq "wq") && ($_->{boo} =~ qr/12/)', "and hash" );
is( simple_sub({ bar => 1, baz => "wq", boo => qr/12/}), '($_->{bar} == 1) && ($_->{baz} eq "wq") && ($_->{boo} =~ qr/12/)', "and hash via sub" );
is( simple_sub( bar => 1, baz => "wq", boo => qr/12/), '($_->{bar} == 1) && ($_->{baz} eq "wq") && ($_->{boo} =~ qr/12/)', "and hash via sub" );
is( simple_array("foo bar", [ 1, "wq", qr/12/ ]), '($_->{"foo bar"} == 1) || ($_->{"foo bar"} eq "wq") || ($_->{"foo bar"} =~ qr/12/)', "or array" );
is( simple_sub("foo bar", [ 1, "wq", qr/12/ ]), '($_->{"foo bar"} == 1) || ($_->{"foo bar"} eq "wq") || ($_->{"foo bar"} =~ qr/12/)', "or array via sub" );
# is( simple_sub({ "foo bar" => { ">" => 12 } }), '($_->{"foo bar"} > 12)', "or array via sub" );

is( simple_function_hash("foo bar" => { ">" => 12, "<" => 23 }), '($_->{"foo bar"} < 23) && ($_->{"foo bar"} > 12)', "function hash" );
is( simple_sub({ "foo bar" => { ">" => 12, "<" => 23 } }), '($_->{"foo bar"} < 23) && ($_->{"foo bar"} > 12)', "function hash via simple sub" );

is( simple_function_hash("foo bar" => { ">" => 12, "<" => 23 }), '($_->{"foo bar"} < 23) && ($_->{"foo bar"} > 12)', "function hash" );
is( simple_array("foo bar", [ { '==', 2 }, { '>', 5 } ]), '($_->{"foo bar"} == 2) || ($_->{"foo bar"} > 5)', "function array" );

is( logical_array("foo bar", [ -and => { '==', 2 }, { '>=', 5 } ]), '($_->{"foo bar"} == 2) && ($_->{"foo bar"} >= 5)', "logical array" );
is( simple_sub({ "foo bar", [ -and => { '==', 2 }, { '>=', 5 } ] }), '($_->{"foo bar"} == 2) && ($_->{"foo bar"} >= 5)', "logical array via sub" );
is( simple_sub( "foo bar", [ -and => { '==', 2 }, { '>=', 5 } ] ), '($_->{"foo bar"} == 2) && ($_->{"foo bar"} >= 5)', "logical array via sub" );

is( simple_sub({ "foo bar", [ -or => { '==', 2 }, { '>=', 5 } ] }), '($_->{"foo bar"} == 2) || ($_->{"foo bar"} >= 5)', "complex logic" );
is( simple_sub({ "foo bar", [ 1, "wq", qr/12/ ] }), '($_->{"foo bar"} == 1) || ($_->{"foo bar"} eq "wq") || ($_->{"foo bar"} =~ qr/12/)', "complex logic" );

is( simple_sub(sub { $_->{"foo bar"}->{bar} > 5 }), q((sub { use strict; $_->{'foo bar'}{'bar'} > 5; })), "simple sub" );
is( simple_sub("foo bar", sub { $_->{"foo bar"}->{bar} > 5 }), q((sub { use strict; $_->{'foo bar'}{'bar'} > 5; })), "simple sub" );

is( simple_sub({ "foo bar", \"bar" }), '((looks_like_number($_->{"foo bar"})) ? ($_->{"foo bar"} == $_->{bar}) : ($_->{"foo bar"} eq $_->{bar}))', "name" );
is( simple_sub({ "foo bar", [ -and => 1, \"bar" ] }), '($_->{"foo bar"} == 1) && ((looks_like_number($_->{"foo bar"})) ? ($_->{"foo bar"} == $_->{bar}) : ($_->{"foo bar"} eq $_->{bar}))', "name" );

is( simple_sub({ "foo bar", [ -or => 1, 12 ] }), '($_->{"foo bar"} == 1) || ($_->{"foo bar"} == 12)', "complex OR" );
is( simple_sub({"foo bar", [ 1, "wq", qr/12/, sub { shift()->{"foo bar"}->{bar} > 5 } ]}),
    q(($_->{"foo bar"} == 1) || ($_->{"foo bar"} eq "wq") || ($_->{"foo bar"} =~ qr/12/) || (sub { use strict; +(shift())->{'foo bar'}{'bar'} > 5; })), "complex or with mixed inputs" );


done_testing()
