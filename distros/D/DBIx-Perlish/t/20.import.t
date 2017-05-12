use warnings;
use strict;
use Test::More;
BEGIN {
	plan tests => 15;
}
BEGIN {
	ok(!main->can("x_fetch"), "no x_fetch");
	ok(!main->can("x_select"), "no x_select");
	ok(!main->can("x_update"), "no x_update");
	ok(!main->can("x_delete"), "no x_delete");
	ok(!main->can("x_insert"), "no x_insert");
}
my $dx;
use DBIx::Perlish prefix => "x", dbh => \$dx;
BEGIN {
	ok(main->can("x_fetch"), "with x_fetch");
	ok(main->can("x_select"), "with x_select");
	ok(main->can("x_update"), "with x_update");
	ok(main->can("x_delete"), "with x_delete");
	ok(main->can("x_insert"), "with x_insert");
}
BEGIN {
	$main::dy = {};
}
use DBIx::Perlish prefix => "y", dbh => \$main::dy; # REF
BEGIN {
	ok(main->can("y_fetch"), "with y_fetch");
	ok(main->can("y_select"), "with y_select");
	ok(main->can("y_update"), "with y_update");
	ok(main->can("y_delete"), "with y_delete");
	ok(main->can("y_insert"), "with y_insert");
}
