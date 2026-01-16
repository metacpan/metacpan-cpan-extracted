use Test::Simple;
use Test::More;
use Data::Filter::Abstract::Util qw/:all/;
use strict;

is( simple_sub({ "foo" => { "=~" => 12, "!~" => qr/23/i } }), '((($_->{foo} !~ qr/23/i) && ($_->{foo} =~ qr/12/)))', "multiple regexp" );

is( simple_sub({ "foo" => { "=~" => [ qr/12/, qr/23/i ] } }), '((($_->{foo} =~ qr/12/) || ($_->{foo} =~ qr/23/i)))', "multiple regexp" );

is( simple_sub({ "foo" => { "=~" => [ "12", qr/23/i ] } }), '((($_->{foo} =~ qr/12/) || ($_->{foo} =~ qr/23/i)))', "multiple regexp" );

done_testing()
