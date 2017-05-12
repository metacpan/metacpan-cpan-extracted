#!perl

use strict;
use warnings;
use Config::Validator;
use Test::More tests => 119;

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
    { type => "anything" },
    [ undef, "undef", "", 0, \0, \\0, -1, [], {}, qr/x/, \&test_validator ],
    [],
);

############################################################################

test_validator(
    { type => "undef" },
    [ undef ],
    [ "undef", "", 0, \0, \\0, -1, [], {}, qr/x/, \&test_validator ],
);

############################################################################

test_validator(
    { type => "defined" },
    [ "undef", "", 0, \0, \\0, -1, [], {}, qr/x/, \&test_validator ],
    [ undef ],
);

############################################################################

test_validator(
    { type => "string" },
    [ "undef", "", 0, -1 ],
    [ undef, \0, \\0, [], {}, qr/x/, \&test_validator ],
);

test_validator(
    { type => "string", min => 3, max => 5 },
    [ "abc", "abcd", "abcde" ],
    [ "", "a", "ab", "abcdef", {} ],
);

test_validator(
    { type => "string", match => qr/abc/ },
    [ "abc", "abcd" ],
    [ "ab", "abdc" ],
);

############################################################################

test_validator(
    { type => "boolean" },
    [ "true", "false" ],
    [ undef, [], "", 0, 1, "TRUE" ],
);

############################################################################

test_validator(
    { type => "number" },
    [ sin(1), .1, -1.1e+2, +1.1e-2, 0, -1, 123456, 0x123456 ],
    [ undef, [], "", "1.2.3" ],
);

test_validator(
    { type => "number", min => 0.1, max => 5e-1 },
    [ .11, .44 ],
    [ undef, [], "", "0.1.2", 0, 1 ],
);

############################################################################

test_validator(
    { type => "integer" },
    [ 0, -1, 123456, 0x123456 ],
    [ undef, [], "", "1.2.3", sin(1), .1, +1.1e-2 ],
);

test_validator(
    { type => "integer", min => 0, max => 255 },
    [ 0, 1, 127, 255 ],
    [ undef, [], "", "1.2.3", sin(1), .1, +1.1e-2, -1, 123456 ],
);

############################################################################
