package Basic::Types::XS;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.07';

require XSLoader;
XSLoader::load("Basic::Types::XS", $VERSION);

1;

__END__

=head1 NAME

Basic::Types::XS - Fast but limited type constraints

=head1 VERSION

Version 0.07

=cut

=head1 SYNOPSIS

	package Test;

	use Moo;
	use Basic::Types::XS qw/Str Num Int ArrayRef HashRef/;

	has string => (
		is       => 'ro',
		isa      => Str,
		required => 1,
	);

	has num => (
		is       => 'ro',
		isa      => Num,
	);

	has int => (
		is       => 'rw',
		isa      => Int,
	);

	has array => (
		is       => 'ro',
		isa      => ArrayRef,
		default  => sub { return [] },
	);

	has hash => (
		is       => 'ro',
		isa      => HashRef,
		default  => sub { return {} },
	);

	1;


=head1 EXPORT

This module exports type constraints that can be used to validate and coerce values in your Perl code.
You can import the types you need by specifying them in the C<use> statement:

	use Basic::Types::XS qw/Str Num Int ArrayRef HashRef/;

=head2 Type Options

Each type constraint can be used directly as a function to validate values, or you can create a type constraint with options.
For example, to create a type constraint for a string with custom options:

	use Basic::Types::XS qw/Str/; 

	my $Str = Str(
		default => sub { return "default value" },
		coerce  => sub {
			my $value = shift;
			return join ",", @{$value} if ref $value eq "ARRAY";
			return $value;
		},
		message => "This is a custom error message",
	);

	$Str->("abc"); # Validates and returns "abc"
	$Str->(undef); # Returns "default value"
	$Str->([qw/a b c/]); # Coerces array to string "a,b,c"
	$Str->({}); # Throws an error with custom message

=over 4

=item * C<default> - A coderef to provide a default value if the input is undefined

=item * C<coerce> - A coderef to coerce the input value before validation

=item * C<message> - A custom error message string

=back

=head3 Any

Absolutely any value passes this type constraint (even undef).

	Any->("abc");

=head3 Defined

Only undef fails this type constraint.

	Defined->("abc");

=head3 Bool

Values that are reasonable booleans. Accepts 1, 0, "", undef, \1, \0, \"", \undef

	Bool->(1);

=head3 Str

Values that are valid strings, this includes numbers.

	Str->("abc");

=head3 Num

Values that are valid numbers, this incldues floats/doubles.

	Num->(123.456);

=head3 Int

Values that are valide integers.

	Int->(123);

=head3 Ref

Values that contain any reference

	Ref->({ ... });

=head3 ScalarRef

Values that contain a scalar reference.

	ScalarRef->(\"abc");

=head3 ArrayRef

Values that contain array references.

	ArrayRef->([qw/a b c/]);

=head3 HashRef

Values that contain hash references

	HashRef->({ a => 1, b => 2, c => 3 });

=head3 CodeRef

Values that contain code references

	CodeRef->(sub { return 'abc' });

=head3 RegexpRef

Value that contain regexp references

	RegexpRef->(qr/abc/);

=head3 GlobRef

Value that contain glob references

	my $open, '>', 'abc.txt';
	GlobRef->($open);

=cut

=head3 Object

Values that contain blessed references (objects).

	Object->(My::Class->new());

=head3 ClassName

Values that contain valid class names (strings).

	ClassName->("My::Class");

=head1 METHODS

=head2 validate

Returns the validation function for the type constraint. This function can be used to validate values against the type constraint.

	Str->validate->("abc");

=head1 BENCHMARK

The following benchmark is between L<Types::Standard> with L<Type::Tiny::XS> installed and L<Basic::Types::XS>.

	use Benchmark qw(:all :hireswallclock);
	use Types::Standard;
	use Basic::Types::XS;

	my $r = timethese(1000000, {
		'Basic::Types::XS' => sub {
			my $Str = Basic::Types::XS::Str->('123');
			my $Num = Basic::Types::XS::Num->(123);
			my $Int = Basic::Types::XS::Int->(123);
			my $Array = Basic::Types::XS::ArrayRef->([qw/1 2 3/]);
			my $Hash = Basic::Types::XS::HashRef->({ a => 1, });
			my $Code = Basic::Types::XS::CodeRef->(sub { return 1 });
		},
		'Types::Standard' => sub {
			my $Str = Types::Standard::Str->('123');
			my $Num = Types::Standard::Num->(123);
			my $Int = Types::Standard::Int->(123);
			my $Array = Types::Standard::ArrayRef->([qw/1 2 3/]);
			my $Hash = Types::Standard::HashRef->({ a => 1, });
			my $Code = Types::Standard::CodeRef->(sub { return 1 });
		},
	});

	Benchmark: timing 1000000 iterations of Basic::Types::XS, Types::Standard...
	Basic::Types::XS: 2.22538 wallclock secs ( 2.20 usr +  0.04 sys =  2.24 CPU) @ 446428.57/s (n=1000000)
	Types::Standard: 3.23532 wallclock secs ( 3.23 usr +  0.00 sys =  3.23 CPU) @ 309597.52/s (n=1000000)
			     Rate  Types::Standard Basic::Types::XS
	Types::Standard  309598/s               --             -31%
	Basic::Types::XS 446429/s              44%               --

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-basic-types-xs at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Basic-Types-XS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Basic::Types::XS


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Basic-Types-XS>

=item * Search CPAN

L<https://metacpan.org/release/Basic-Types-XS>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Basic::Types::XS
