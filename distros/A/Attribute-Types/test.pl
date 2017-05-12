use Attribute::Types qw(INTEGER NUMBER);
use Attribute::Types qw(SCALAR ARRAY HASH CODE REGEX);
use Attribute::Types qw(GLOB REF Type);
use Attribute::Types qw(INTEGER NUMBER);

package My::Class;
sub new { bless {}, $_[0] }

package Der::Class;
use base 'My::Class';

package main;

my $n=0;
my $report;
sub report { $report .= join "", @_ }
#sub report { print @_ }
sub ok(&)  { $n++; eval { $_[0]->(); 1 } or report "not "; report "ok $n\n"}
sub nok(&) { $n++; !eval { $_[0]->(); 1 } or report "not "; report "ok $n\n" }
END { print "1..$n\n$report" }

{
	my $x : INTEGER;

	 ok { $x = 1 ; die unless $x==1 };
	 ok { $x = 0 ; die unless $x==0 };
	 ok { $x = -1 ; die unless $x==-1 };
	 ok { $x = 1.0 ; die unless $x==1 };
	nok { $x = 1.1 };
	 ok { $x = 1.1e2 ; die unless $x==110};
	nok { $x = 1.111e2 };
	nok { $x = 'a' };
	nok { $x = undef };
	nok { $x = \$x };		# SCALAR
	nok { $x = [] };		# ARRAY
	nok { $x = {} };		# HASH
	nok { $x = sub {} };		# CODE
	nok { $x = qr{} };		# REGEX
	nok { $x = \*x };		# GLOB
	nok { $x = \\$x };		# REF
}

{
	my $x : INTEGER(0..10);
	my @y : INTEGER(0..10);
	my %z : INTEGER(0..10);

	 ok { $x = 1 ; die unless $x==1 };
	 ok { $x = 0 ; die unless $x==0 };
	nok { $x = -1 };
	 ok { $x = 1.0 ; die unless $x==1 };
	nok { $x = 1.1 };
	nok { $x = 1.1 };
	nok { $x = 1.1e2 };
	nok { $x = 1.111e2 };
	nok { $x = 'a' };
	nok { $x = undef };
	nok { $x = \$x };		# SCALAR
	nok { $x = [] };		# ARRAY
	nok { $x = {} };		# HASH
	nok { $x = sub {} };		# CODE
	nok { $x = qr{} };		# REGEX
	nok { $x = \*x };		# GLOB
	nok { $x = \\$x };		# REF

	 ok { $y[1] = 1 ; die unless $y[1]==1 };
	 ok { $y[1] = 0 ; die unless $y[1]==0 };
	nok { $y[1] = -1 };
	 ok { $y[1] = 1.0 ; die unless $y[1]==1 };
	nok { $y[1] = 1.1 };
	nok { $y[1] = 1.1e2 };
	nok { $y[1] = 1.111e2 };
	nok { $y[1] = 'a' };
	nok { $y[1] = undef };
	nok { $y[1] = \$x };		# SCALAR
	nok { $y[1] = [] };		# ARRAY
	nok { $y[1] = {} };		# HASH
	nok { $y[1] = sub {} };		# CODE
	nok { $y[1] = qr{} };		# REGEX
	nok { $y[1] = \*x };		# GLOB
	nok { $y[1] = \\$x };		# REF

	 ok { $z{a} = 1 ; die unless $z{a}==1 };
	 ok { $z{a} = 0 ; die unless $z{a}==0 };
	nok { $z{a} = -1 };
	 ok { $z{a} = 1.0 ; die unless $z{a}==1 };
	nok { $z{a} = 1.1 };
	nok { $z{a} = 1.1e2 };
	nok { $z{a} = 1.111e2 };
	nok { $z{a} = 'a' };
	nok { $z{a} = undef };
	nok { $z{a} = \$x };		# SCALAR
	nok { $z{a} = [] };		# ARRAY
	nok { $z{a} = {} };		# HASH
	nok { $z{a} = sub {} };		# CODE
	nok { $z{a} = qr{} };		# REGEX
	nok { $z{a} = \*x };		# GLOB
	nok { $z{a} = \\$x };		# REF
}

{
	my $x : NUMBER;

	 ok { $x = 1 ; die unless $x==1 };
	 ok { $x = 0 ; die unless $x==0 };
	 ok { $x = -1 ; die unless $x==-1 };
	 ok { $x = 1.0 ; die unless $x==1.0 };
	 ok { $x = 1.1 ; die unless $x==1.1 };
	 ok { $x = 1.1e2 ; die unless $x==1.1e2 };
	 ok { $x = 1.111e2 ; die unless $x==1.111e2 };
	nok { $x = 'a' };
	nok { $x = undef };
	nok { $x = \$x };		# SCALAR
	nok { $x = [] };		# ARRAY
	nok { $x = {} };		# HASH
	nok { $x = sub {} };		# CODE
	nok { $x = qr{} };		# REGEX
	nok { $x = \*x };		# GLOB
	nok { $x = \\$x };		# REF
}

{
	my $x : INTEGER(0..);

	 ok { $x = 1 ; die unless $x==1 };
	 ok { $x = 0 ; die unless $x==0 };
	nok { $x = -1 };
	 ok { $x = 1.0 ; die unless $x==1 };
	nok { $x = 1.1 };
	nok { $x = 1.1 };
	 ok { $x = 1.1e2 };
	nok { $x = 1.111e2 };
	nok { $x = 'a' };
	nok { $x = undef };
	nok { $x = \$x };		# SCALAR
	nok { $x = [] };		# ARRAY
	nok { $x = {} };		# HASH
	nok { $x = sub {} };		# CODE
	nok { $x = qr{} };		# REGEX
	nok { $x = \*x };		# GLOB
	nok { $x = \\$x };		# REF
}

{
	my $x : INTEGER(..100);

	 ok { $x = 1 ; die unless $x==1 };
	 ok { $x = 0 ; die unless $x==0 };
	 ok { $x = -1 };
	 ok { $x = 1.0 ; die unless $x==1 };
	nok { $x = 1.1 };
	 ok { $x = 1.1e1 };
	nok { $x = 1.1e2 };
	nok { $x = 1.111e2 };
	nok { $x = 'a' };
	nok { $x = undef };
	nok { $x = \$x };		# SCALAR
	nok { $x = [] };		# ARRAY
	nok { $x = {} };		# HASH
	nok { $x = sub {} };		# CODE
	nok { $x = qr{} };		# REGEX
	nok { $x = \*x };		# GLOB
	nok { $x = \\$x };		# REF
}

{
	my $x : NUMBER(1.1..1.11e2);
	my @y : NUMBER(1.1..1.11e2);
	my %z : NUMBER(1.1..1.11e2);

	nok { $x = 1 };
	nok { $x = 0 };
	nok { $x = -1 };
	nok { $x = 1.0 };
	 ok { $x = 1.1 };
	 ok { $x = 1.1e2 };
	nok { $x = 1.111e2 };
	nok { $x = 'a' };
	 ok { $x = '1.1' };
	 ok { $x = '1.1'+0 };
	nok { $x = '1.1a' };
	nok { $x = '--1.1' };
	nok { $x = undef };
	nok { $x = \$x };		# SCALAR
	nok { $x = [] };		# ARRAY
	nok { $x = {} };		# HASH
	nok { $x = sub {} };		# CODE
	nok { $x = qr{} };		# REGEX
	nok { $x = \*x };		# GLOB
	nok { $x = \\$x };		# REF

	nok { $y[10] = 1 };
	nok { $y[10] = 0 };
	nok { $y[10] = -1 };
	nok { $y[10] = 1.0 };
	 ok { $y[10] = 1.1 ; die unless $y[10]==1.1 };
	 ok { $y[10] = 1.1e2 ; die unless $y[10]==1.1e2 };
	nok { $y[10] = 1.111e2 };
	nok { $y[10] = 'a' };
	nok { $y[10] = undef };
	nok { $y[10] = \$x };		# SCALAR
	nok { $y[10] = [] };		# ARRAY
	nok { $y[10] = {} };		# HASH
	nok { $y[10] = sub {} };	# CODE
	nok { $y[10] = qr{} };		# REGEX
	nok { $y[10] = \*x };		# GLOB
	nok { $y[10] = \\$x };		# REF

	nok { $z{ero} = 1 };
	nok { $z{ero} = 0 };
	nok { $z{ero} = -1 };
	nok { $z{ero} = 1.0 };
	 ok { $z{ero} = 1.1 ; die unless $z{ero}==1.1 };
	 ok { $z{ero} = 1.1e2 ; die unless $z{ero}==1.1e2 };
	nok { $z{ero} = 1.111e2 };
	nok { $z{ero} = 'a' };
	nok { $z{ero} = undef };
	nok { $z{ero} = \$x };		# SCALAR
	nok { $z{ero} = [] };		# ARRAY
	nok { $z{ero} = {} };		# HASH
	nok { $z{ero} = sub {} };	# CODE
	nok { $z{ero} = qr{} };		# REGEX
	nok { $z{ero} = \*x };		# GLOB
	nok { $z{ero} = \\$x };		# REF
}

{
	my $x : SCALAR;
	my @y : SCALAR;
	my %z : SCALAR;

	nok { $x = 1 };
	nok { $x = -1 };
	nok { $x = 'a' };
	nok { $x = undef };
	 ok { my $y; $x = \$y };	# SCALAR
	nok { $x = [] };		# ARRAY
	nok { $x = {} };		# HASH
	nok { $x = sub {} };		# CODE
	nok { $x = qr{} };		# REGEX
	nok { $x = \*x };		# GLOB
	nok { my $y; $x = \\$y };	# REF
	nok { $x = My::Class->new() };	# OBJECT
	nok { $x = Der::Class->new() };	# OBJECT

	nok { $y[3] = 1 };
	nok { $y[3] = -1 };
	nok { $y[3] = 'a' };
	nok { $y[3] = undef };
	 ok { my $y; $y[3] = \$y };	# SCALAR
	nok { $y[3] = [] };		# ARRAY
	nok { $y[3] = {} };		# HASH
	nok { $y[3] = sub {} };		# CODE
	nok { $y[3] = qr{} };		# REGEX
	nok { $y[3] = \*x };		# GLOB
	nok { my $y; $y[3] = \\$y };	# REF
	nok { $y[3] = My::Class->new() };	# OBJECT
	nok { $y[3] = Der::Class->new() };	# OBJECT

	nok { $z{a} = 1 };
	nok { $z{a} = -1 };
	nok { $z{a} = 'a' };
	nok { $z{a} = undef };
	 ok { my $y; $z{a} = \$y };	# SCALAR
	nok { $z{a} = [] };		# ARRAY
	nok { $z{a} = {} };		# HASH
	nok { $z{a} = sub {} };		# CODE
	nok { $z{a} = qr{} };		# REGEX
	nok { $z{a} = \*x };		# GLOB
	nok { my $y; $z{a} = \\$y };	# REF
	nok { $z{a} = My::Class->new() };	# OBJECT
	nok { $z{a} = Der::Class->new() };	# OBJECT
}

{
	my $x : ARRAY;

	nok { $x = 1 };
	nok { $x = -1 };
	nok { $x = 'a' };
	nok { $x = undef };
	nok { my $y; $x = \$y };	# SCALAR
	 ok { $x = [] };		# ARRAY
	nok { $x = {} };		# HASH
	nok { $x = sub {} };		# CODE
	nok { $x = qr{} };		# REGEX
	nok { $x = \*x };		# GLOB
	nok { my $y; $x = \\$y };	# REF
	nok { $x = My::Class->new() };	# OBJECT
	nok { $x = Der::Class->new() };	# OBJECT
}

{
	my $x : HASH;

	nok { $x = 1 };
	nok { $x = -1 };
	nok { $x = 'a' };
	nok { $x = undef };
	nok { my $y; $x = \$y };	# SCALAR
	nok { $x = [] };		# ARRAY
	 ok { $x = {} };			# HASH
	nok { $x = sub {} };		# CODE
	nok { $x = qr{} };		# REGEX
	nok { $x = \*x };		# GLOB
	nok { my $y; $x = \\$y };	# REF
	nok { $x = My::Class->new() };	# OBJECT
	nok { $x = Der::Class->new() };	# OBJECT
}

{
	my $x : CODE;

	nok { $x = 1 };
	nok { $x = -1 };
	nok { $x = 'a' };
	nok { $x = undef };
	nok { my $y; $x = \$y };	# SCALAR
	nok { $x = [] };		# ARRAY
	nok { $x = {} };		# HASH
	 ok { $x = sub {} };		# CODE
	nok { $x = qr{} };		# REGEX
	nok { $x = \*x };		# GLOB
	nok { my $y; $x = \\$y };	# REF
	nok { $x = My::Class->new() };	# OBJECT
	nok { $x = Der::Class->new() };	# OBJECT
}

{
	my $x : REGEX;

	nok { $x = 1 };
	nok { $x = -1 };
	nok { $x = 'a' };
	nok { $x = undef };
	nok { my $y; $x = \$y };	# SCALAR
	nok { $x = [] };		# ARRAY
	nok { $x = {} };		# HASH
	nok { $x = sub {} };		# CODE
	 ok { $x = qr{} };		# REGEX
	nok { $x = \*x };		# GLOB
	nok { my $y; $x = \\$y };	# REF
	nok { $x = My::Class->new() };	# OBJECT
	nok { $x = Der::Class->new() };	# OBJECT
}

{
	my $x : GLOB;

	nok { $x = 1 };
	nok { $x = -1 };
	nok { $x = 'a' };
	nok { $x = undef };
	nok { my $y; $x = \$y };	# SCALAR
	nok { $x = [] };		# ARRAY
	nok { $x = {} };		# HASH
	nok { $x = sub {} };		# CODE
	nok { $x = qr{} };		# REGEX
	 ok { $x = \*x };		# GLOB
	nok { my $y; $x = \\$y };	# REF
	nok { $x = My::Class->new() };	# OBJECT
	nok { $x = Der::Class->new() };	# OBJECT
}

{
	my $x : REF;

	nok { $x = 1 };
	nok { $x = -1 };
	nok { $x = 'a' };
	nok { $x = undef };
	nok { my $y; $x = \$y };	# SCALAR
	nok { $x = [] };		# ARRAY
	nok { $x = {} };		# HASH
	nok { $x = sub {} };		# CODE
	nok { $x = qr{} };		# REGEX
	nok { $x = \*x };		# GLOB
	 ok { my $y; $x = \\$y };	# REF
	nok { $x = My::Class->new() };	# OBJECT
	nok { $x = Der::Class->new() };	# OBJECT
}

{
	my $x : Type(My::Class);

	nok { $x = 1 };
	nok { $x = -1 };
	nok { $x = 'a' };
	nok { $x = undef };
	nok { my $y; $x = \$y };	# SCALAR
	nok { $x = [] };		# ARRAY
	nok { $x = {} };		# HASH
	nok { $x = sub {} };		# CODE
	nok { $x = qr{} };		# REGEX
	nok { $x = \*x };		# GLOB
	nok { my $y; $x = \\$y };	# REF
	 ok { $x = My::Class->new() };	# OBJECT
	 ok { $x = Der::Class->new() };	# OBJECT
}

{
	my $x : Type(Der::Class);

	nok { $x = 1 };
	nok { $x = -1 };
	nok { $x = 'a' };
	nok { $x = undef };
	nok { my $y; $x = \$y };	# SCALAR
	nok { $x = [] };		# ARRAY
	nok { $x = {} };		# HASH
	nok { $x = sub {} };		# CODE
	nok { $x = qr{} };		# REGEX
	nok { $x = \*x };		# GLOB
	nok { my $y; $x = \\$y };	# REF
	nok { $x = My::Class->new() };	# OBJECT
	 ok { $x = Der::Class->new() };	# OBJECT
}

{
	my $x : Type(/po*ny!?/);

	nok { $x = 1 };
	nok { $x = -1 };
	nok { $x = 'a' };
	 ok { $x = 'pony' };
	 ok { $x = 'pony pony pony pony pony!' };
	nok { $x = undef };
	nok { my $y; $x = \$y };	# SCALAR
	nok { $x = [] };		# ARRAY
	nok { $x = {} };		# HASH
	nok { $x = sub {} };		# CODE
	nok { $x = qr{} };		# REGEX
	nok { $x = \*x };		# GLOB
	nok { my $y; $x = \\$y };	# REF
	nok { $x = My::Class->new() };	# OBJECT
	nok { $x = Der::Class->new() };	# OBJECT
}

{
	sub odd { no warnings; $_[0] % 2 }
	my $x : Type(&odd);

	 ok { $x = 1 };
	nok { $x = 0 };
	 ok { $x = -1 };
	nok { $x = 'a' };
	nok { $x = 'pony' };
	nok { $x = 'pony pony pony pony pony!' };
	nok { $x = undef };
	nok { my $y; $x = \$y };	# SCALAR
	nok { $x = [] };		# ARRAY
	nok { $x = {} };		# HASH
	nok { $x = sub {} };		# CODE
	nok { $x = qr{} };		# REGEX
	nok { $x = \*x };		# GLOB
	nok { my $y; $x = \\$y };	# REF
	nok { $x = My::Class->new() };	# OBJECT
	nok { $x = Der::Class->new() };	# OBJECT
}

sub Positively::even {
	no warnings;
	!ref($_[0]) && $_[0] > 0 && $_[0] % 2 == 0
}

{
	my $x : Type(&Positively::even);

	nok { $x = 1 };
	 ok { $x = 2 };
	nok { $x = 0 };
	nok { $x = -1 };
	nok { $x = 'a' };
	nok { $x = 'pony' };
	nok { $x = 'pony pony pony pony pony!' };
	nok { $x = undef };
	nok { my $y; $x = \$y };	# SCALAR
	nok { $x = [] };		# ARRAY
	nok { $x = {} };		# HASH
	nok { $x = sub {} };		# CODE
	nok { $x = qr{} };		# REGEX
	nok { $x = \*x };		# GLOB
	nok { my $y; $x = \\$y };	# REF
	nok { $x = My::Class->new() };	# OBJECT
	nok { $x = Der::Class->new() };	# OBJECT
}

	eval 'my $x : Type("x"x2); 1'      and nok {die;} or ok {1;};
	eval 'my $x : Type(&missing); 1'   and nok {die;} or ok {1;};
	eval 'my $x : Type(&miss::ing); 1' and nok {die;} or ok {1;};
	eval 'use Attribute::Types qw(FRED BARNEY); 1'
					   and nok {die;} or ok {1;};
