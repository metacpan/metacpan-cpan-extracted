use strict;
use warnings;
use Benchmark qw( cmpthese );

{
	package Person::CT;
	use Class::Tiny
		{ name => sub { die "name is required" } },
		qw( age phone email );
#	sub BUILD { 1 }
}

{
	package Person::Moo;
	use Moo;
	has name => (is => 'rw', required => 1);
	has $_   => (is => 'rw', required => 0) for qw( age phone email );
#	sub BUILD { 1 }
}

{
	package Person::Mouse;
	use Mouse;
	has name => (is => 'rw', required => 1);
	has $_   => (is => 'rw', required => 0) for qw( age phone email );
#	sub BUILD { 1 }
}

{
	package Person::Moose;
	use Moose;
	has name => (is => 'rw', required => 1);
	has $_   => (is => 'rw', required => 0) for qw( age phone email );
#	sub BUILD { 1 }
}

{
	package Person::Moose::Immutable;
	use Moose;
	has name => (is => 'rw', required => 1);
	has $_   => (is => 'rw', required => 0) for qw( age phone email );
#	sub BUILD { 1 }
	__PACKAGE__->meta->make_immutable;
}

{
	package Person::XSCON;
	use Class::XSConstructor
		qw( name! age phone email );
	use Class::XSAccessor { accessors => [qw( name age phone email )] };
#	sub BUILD { 1 }
}

cmpthese(-1, {
	CT     => sub { Person::CT->new(name => "Alice", age => 40) for 1..1000 },
	Moo    => sub { Person::Moo->new(name => "Alice", age => 40) for 1..1000 },
	Mouse  => sub { Person::Mouse->new(name => "Alice", age => 40) for 1..1000 },
	Moose  => sub { Person::Moose->new(name => "Alice", age => 40) for 1..1000 },
	MooseI => sub { Person::Moose::Immutable->new(name => "Alice", age => 40) for 1..1000 },
	XSCON  => sub { Person::XSCON->new(name => "Alice", age => 40) for 1..1000 },
})

__END__

Results with BUILD method:

         Rate  Moose     CT MooseI    Moo  XSCON  Mouse
Moose  16.2/s     --   -95%   -96%   -97%   -97%   -98%
CT      305/s  1782%     --   -24%   -45%   -50%   -58%
MooseI  403/s  2391%    32%     --   -27%   -33%   -44%
Moo     550/s  3294%    80%    36%     --    -9%   -24%
XSCON   605/s  3634%    98%    50%    10%     --   -17%
Mouse   725/s  4377%   138%    80%    32%    20%     --

Results with the BUILD method commented out:

         Rate  Moose     CT MooseI    Moo  XSCON  Mouse
Moose  23.6/s     --   -93%   -95%   -96%   -96%   -97%
CT      336/s  1322%     --   -30%   -43%   -50%   -57%
MooseI  478/s  1921%    42%     --   -20%   -29%   -38%
Moo     594/s  2412%    77%    24%     --   -12%   -24%
XSCON   673/s  2749%   100%    41%    13%     --   -13%
Mouse   777/s  3187%   131%    63%    31%    15%     --
