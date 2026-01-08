use strict;
use warnings;
use Benchmark qw( cmpthese );

{
	package Person::CT;
	use Class::Tiny
		{ name => sub { die "name is required" } },
		qw( age phone email );
	sub BUILD { 1 }
}

{
	package Person::Moo;
	use Moo;
	has name => (is => 'rw', required => 1);
	has $_   => (is => 'rw', required => 0) for qw( age phone email );
	sub BUILD { 1 }
}

{
	package Person::Mouse;
	use Mouse;
	has name => (is => 'rw', required => 1);
	has $_   => (is => 'rw', required => 0) for qw( age phone email );
	sub BUILD { 1 }
}

{
	package Person::Moose;
	use Moose;
	has name => (is => 'rw', required => 1);
	has $_   => (is => 'rw', required => 0) for qw( age phone email );
	sub BUILD { 1 }
}

{
	package Person::Moose::Immutable;
	use Moose;
	has name => (is => 'rw', required => 1);
	has $_   => (is => 'rw', required => 0) for qw( age phone email );
	sub BUILD { 1 }
	__PACKAGE__->meta->make_immutable;
}

{
	package Person::XSCON;
	use Class::XSConstructor
		qw( name! age phone email );
	use Class::XSAccessor { accessors => [qw( name age phone email )] };
	sub BUILD { 1 }
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
         Rate  Moose     CT MooseI    Moo  Mouse  XSCON
Moose  34.3/s     --   -94%   -96%   -96%   -97%   -98%
CT      550/s  1504%     --   -29%   -44%   -52%   -65%
MooseI  770/s  2147%    40%     --   -21%   -32%   -51%
Moo     974/s  2743%    77%    27%     --   -14%   -38%
Mouse  1139/s  3224%   107%    48%    17%     --   -27%
XSCON  1570/s  4483%   186%   104%    61%    38%     --