#!perl

use strict;
use warnings;
use Config::Validator;
use Test::More tests => 7;

############################################################################

#
# helper
#

sub test ($$@) {
    my($ok, $name, @options) = @_;
    my($validator);

    $@ = "";
    eval { $validator = Config::Validator->new(@options) };
    if ($ok) {
	is($@, "", $name);
    } else {
	ok($@, $name);
    }

}

############################################################################

#
# valid schemas
#

test(1, "default");
test(1, "simple", { type => "integer" });

############################################################################

#
# invalid schemas
#

test(0, "odd", 1, 2, 3);
test(0, "empty", {}); # type is mandatory
test(0, "typo", { type => "itneger" });
test(0, "unknown", { type => "valid(foobar)" });
test(0, "code+min", { type => "code", min => 1 });

############################################################################
