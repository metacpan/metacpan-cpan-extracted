#!perl

use strict;
use warnings;
use Config::Validator;
use Test::More tests => 92;

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
    { type => "regexp" },
    [ qr/x/, qr/(a|b)/ix ],
    [ undef, "undef", "", 0, \0, \\0, -1, [], {}, "qr/x/", \&test_validator ],
);

############################################################################

test_validator(
    { type => "code" },
    [ \&test_validator, sub {} ],
    [ undef, "undef", "", 0, \0, \\0, -1, [], {}, qr/x/ ],
);

############################################################################

test_validator(
    { type => "ref(ARRAY)" },
    [ [], bless([], "dummy") ],
    [ undef, "undef", "", 0, \0, \\0, -1, {}, qr/x/, \&test_validator ],
);

############################################################################

test_validator(
    { type => "ref(HASH)" },
    [ {}, bless({}, "dummy") ],
    [ undef, "undef", "", 0, \0, \\0, -1, [], qr/x/, \&test_validator ],
);

############################################################################

test_validator(
    { type => "reference" },
    [ \0, \\0, [], bless([], "dummy"), {}, bless({}, "dummy"), \&test_validator ],
    [ undef, "undef", "", 0, -1 ],
);

############################################################################

test_validator(
    { type => "object" },
    [ bless([], "dummy"), bless({}, "dummy") ],
    [ undef, "undef", "", 0, \0, \\0, -1, [], {}, \&test_validator ],
);

############################################################################

test_validator(
    { type => "isa(dummy)" },
    [ bless([], "dummy"), bless({}, "dummy") ],
    [ undef, "undef", "", 0, \0, \\0, -1, [], {}, \&test_validator ],
);

############################################################################
