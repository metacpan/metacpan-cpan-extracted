use v5.14;
use warnings;
use Encode;
use utf8;

use Test::More;
use Data::Dumper;

sub import {
    my($pkg, @sub) = @_;
    eval "require $pkg";
    for my $sub (@sub) {
	no strict 'refs';
	*$sub = \&{"$pkg\::$sub"};
    }
}

import "App::Greple::xlate", qw(strip);

sub label {
    local $_ = shift;
    s/\n/\\n/g;
    qq(\"$_\");
}

for my $t ([ "a", "a", "a" ],
	   [ " a", "a", "a" ],
	   [ "a ", "a", "a" ],
	   [ " ab \n", "ab\n", "ab\n" ],
	   [ " a\nb \n", "a\nb\n", "a\nb\n" ],
	   [ " a\n b \n", "a\nb\n", "a\n b\n" ],
	   [ " a\n b\n ", "a\nb\n", "a\n b\n", { TODO => "impossible" } ],
	   [ " a\n b \n ", "a\nb\n", "a\n b \n", { TODO => "impossible" } ],
       ) {
    my $opt = ref $t->[-1] ? pop @$t : {};
    my($s, @a) = @$t;
    my $save = $s;
    for my $p (0, 1) {
	local $TODO = $opt->{TODO};
	my $unstrip = strip($s, $p);
	my $l = label($save);
	is($s, $a[$p], "  strip: " . $l);
	$unstrip->($s);
	is($s, $save, "unstrip: " . $l);
    }
}

done_testing;
