#!perl

use strict;
use warnings;
use Config::Validator;
use Test::More tests => 34;

############################################################################

#
# helpers
#

sub test_data ($$$;$) {
    my($ok, $val, $data, $name) = @_;

    $@ = "";
    if (defined($name)) {
	eval { $val->validate($data, $name) };
    } else {
	eval { $val->validate($data) };
    }
    $data = "<undef>" unless defined($data);
    if ($ok) {
	is($@, "", "test good $data");
    } else {
	ok($@, "test bad  $data");
    }
}

sub test_validator ($$$) {
    my($schema, $ok, $bad) = @_;
    my($val, $data);

    $val = Config::Validator->new($schema);
    ok($val, "new(" . join(", ", map("$_=$schema->{$_}", sort(keys(%$schema)))). ")");
    foreach $data (@$ok) {
	test_data(1, $val, $data);
    }
    foreach $data (@$bad) {
	test_data(0, $val, $data);
    }
}

############################################################################

test_validator(
    { type => "list", subtype => { type => "boolean" } },
    [ [], [ "true", "false" ] ],
    [ "true", [ "true", [ "false" ]] ],
);

############################################################################

test_validator(
    { type => "list(integer)", min => 1, max => 2 },
    [ [ 1 ], [ 1, 2] ],
    [ [], [ "xx" ], [ 1, 2, 3], 1 ],
);

test_validator(
    { type => "list?(integer)", min => 1, max => 2 },
    [ [ 1 ], [ 1, 2], 1 ],
    [ [], [ "xx" ], [ 1, 2, 3] ],
);

############################################################################

test_validator(
    { type => "table(integer)", match => qr/abc/, max => 2 },
    [ {}, { "xabcx" => 123 }, { "xabcx" => 123, "yabcy" => 456 } ],
    [ [], { "xacbx" => 123 }, { "xabcx" => 12.3 }, { "xabcx" => 123, "yabcy" => 456, "zabcz" => 789 } ],
);

############################################################################

test_validator(
    { type => "struct", fields => { abc => { type => "integer" }, def => { type => "boolean", optional => "true" } } },
    [ { abc => 1 }, { abc => 2, def => "false" } ],
    [ {}, { acb => 1 }, { abc => 2, def => "flase" }, { abc => 3, dfe => "false" } ],
);

############################################################################
