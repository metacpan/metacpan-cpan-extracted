#!perl

use strict;
use warnings;
use Config::Validator qw();
use Test::More tests => 52;

our($validator, $count);

$validator = Config::Validator->new(
    octet => {
        type => "integer",
        min  => 0,
        max  => 255,
    },
    color => {
        type   => "struct",
        fields => {
            red   => { type => "valid(octet)" },
            green => { type => "valid(octet)" },
            blue  => { type => "valid(octet)" },
        },
    },
    list_of_colors  => { type => "list(valid(color))" },
    table_of_colors => { type => "table(valid(color))" },
);

sub callback () {
    my($valid, $schema, $type, $data, @path) = @_;

    $count++;
    if (@path == 0 and ref($data) eq "ARRAY") {
        is($type, "list(valid(color))", "0 type <@path>");
    } elsif (@path == 0 and ref($data) eq "HASH") {
        is($type, "table(valid(color))", "0 type <@path>");
    } elsif (@path == 1) {
        like($type, qr/^(valid\(color\)|struct)$/, "1 type <@path>");
        is(ref($data), "HASH", "1 data <@path>");
        like("@path", qr/^(0|foo)$/, "1 path <@path>");
    } elsif (@path == 2) {
        like($type, qr/^(valid\(octet\)|integer)$/, "2 type <@path>");
        is(ref($data), "", "2 data <@path>");
        like("@path", qr/^(0|foo) (red|green|blue)$/, "1 path <@path>");
    } else {
        fail("unexpected path: @path");
    }
}

$count = 0;
$validator->traverse(\&callback, [
    { red => 1, green => 2, blue => 3 },
], "list_of_colors");
is($count, 9, "count");

$count = 0;
$validator->traverse(\&callback, {
    foo => { red => 1, green => 2, blue => 3 },
}, "table_of_colors");
is($count, 9, "count");
