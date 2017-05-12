use strict;
use warnings qw(FATAL all);
use Test::More tests => 38;

use Data::Alias qw(alias);

our $x = 1;
our $y = 2;
our $z = 3;
our @x = (4, 5, 6);
our %x = (a => 7, b => 8);

alias my($a) = ($x);
ok \$a == \$x;
alias +($a) = ($y);
ok \$a == \$y;

alias my($b, $c) = ($x, $z);
ok \$b == \$x;
ok \$c == \$z;

alias our($j, $k) = ($b, $c);
ok \$j == \$x;
ok \$k == \$z;
ok \$b == \$x;
ok \$c == \$z;

alias my($d, @d) = @x;
ok \$d == \$x[0];
ok \@d != \@x;
ok scalar(@d) == 2;
ok \$d[0] == \$x[1];
ok \$d[1] == \$x[2];

alias my(@c) = @x;
ok \@c != \@x;
ok scalar(@c) == 3;
ok \$c[0] == \$x[0];
ok \$c[1] == \$x[1];
ok \$c[2] == \$x[2];

alias my @e = @x;
ok \@e == \@x;

alias my %e = %x;
ok \%e == \%x;

sub t0 {
	alias my($f, @f) = @_;
	ok \$f == \$x[0];
	ok \@f != \@x;
	ok \@f != \@_;
	ok scalar(@f) == 2;
	ok \$f[0] == \$x[1];
	ok \$f[1] == \$x[2];
}
t0(@x);

sub t1 {
	alias my(@g) = @_;
	ok \@g != \@_;
	ok \@g != \@x;
	ok scalar(@g) == 3;
	ok \$g[0] == \$x[0];
	ok \$g[1] == \$x[1];
	ok \$g[2] == \$x[2];
}
t1(@x);

sub t2 {
	alias my @g = @_;
	ok \@g == \@_;
	ok \@g != \@x;
	ok scalar(@g) == 3;
	ok \$g[0] == \$x[0];
	ok \$g[1] == \$x[1];
	ok \$g[2] == \$x[2];
}
t2(@x);

1;
