#!perl -T

use strict;
use warnings;
use Test::More tests => 9;

use Algorithm::AhoCorasick qw(find_all);

my $found = find_all("To be or not to be", "be");
is_deeply($found, { 3 => [ "be" ], 16 => [ "be" ] });

my $mismatch = find_all("To be or not to be", "bet");
ok(!defined($mismatch));

sub test_fail {
    my $name = shift;

    eval {
	find_all(@_);
	fail($name);
    };
    if ($@) {
	ok(1, $name);
    }
}

test_fail("0 args");
test_fail("0 keywords", "To be or not to be");
test_fail("empty keyword", "To be or not to be", "be", "");

$found = find_all("To be or not to be", "be", "be");
is_deeply($found, { 3 => [ "be" ], 16 => [ "be" ] });

$mismatch = find_all("To be or not to be", 0);
ok(!defined($mismatch));

$found = find_all("Un chasseur qui sache chasser ne chase jamais sans son chien", "sa", "se", "si", "so", "su");
is_deeply($found, {
		   7 => [ "se" ],
		   16 => [ "sa" ],
		   26 => [ "se" ],
		   36 => [ "se" ],
		   46 => [ "sa" ],
		   51 => [ "so" ],
		  });

$found = find_all("Un chasseur qui sache chasser ne chase jamais sans son chien", "se", "seu");
is_deeply($found, {
		   7 => [ "se", "seu" ],
		   26 => [ "se" ],
		   36 => [ "se" ],
		  });
