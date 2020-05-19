use warnings;
use strict;
use lib '.';
use DBIx::Perlish qw/:all/;
use Test::More;
use t::test_utils;

# regression, $not_a_hash->{blah}, $not_a_hash->{blah}{bluh}
my $not_a_hash = undef;
my %not_a_hash;
if ( DBIx::Perlish->optree_version == 1 ) {
	test_select_sql {
		return $not_a_hash->{blah};
	} "not a hash 1",
	"select null",
	[];

	test_select_sql {
		return $not_a_hash->{blah}{bluh};
	} "not a hash 2",
	"select null",
	[];
	test_select_sql {
		return $not_a_hash{blah}{bluh};
	} "not a hash 3",
	"select null",
	[];
	test_select_sql {
	       my $t : tab;
	       return "abc$t->{name}xyz";
	} "concat, interp, hash syntax",
	"select (? || t01.name || ?) from tab t01",
	["abc", "xyz"];
} else {
	test_bad_select {
		return $not_a_hash->{blah};
	} "undefined hashref", qr/not supported/;
	test_bad_select {
		return $not_a_hash->{blah}{bluh};
	} "undefined hashref 2", qr/not supported/;
	test_bad_select {
		return $not_a_hash{blah}{bluh};
	} "undefined hashref 3", qr/not supported/;
	test_bad_select {
		my $t : tab;
		return "abc$t->{name}xyz";
	} "concat, interp, hash syntax", qr/not supported anymore/;
}

if ( DBIx::Perlish->optree_version == 1 ) {
	test_bad_select { join 1,2; } "bad join 1", qr/not a valid join/;
	test_bad_select { join 1,2,3; } "bad join 2", qr/not a valid join/;
	test_bad_select { join 1,2,3,4; } "bad join 3", qr/not a valid join/;
} else {
	test_bad_select { join $1,2,3; } "bad join 1", qr/not a valid join/;
	test_bad_select { join $1,2,3,4; } "bad join 2", qr/not a valid join/;
	test_bad_select { join $1,$2,$3,4,5; } "bad join 3", qr/not a valid join/;
}
done_testing;
