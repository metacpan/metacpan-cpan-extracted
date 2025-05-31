package Basic::Types::XS;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.11';

require XSLoader;
XSLoader::load("Basic::Types::XS", $VERSION);

1;

__END__

=head1 NAME

Basic::Types::XS - Fast but limited type constraints

=head1 VERSION

Version 0.11

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

=item * C<validate> - A value that may be used by the constraint to validate the input

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

=head3 StrMatch

Values that are valid strings and match a regex pattern.

	StrMatch(validate => qr/^[a-z]+$/)->("abc");

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

=head3 Enum

Values that contain a value found in the Enum array reference.

	Enum(validate => [qw/yes no/])->("yes");

=head1 METHODS

=head2 message

Sets a custom error message for the type constraint. This message will be used when validation fails.

	Str->message("This is a custom error message");

=head2 default

Sets a default value for the type constraint. This value will be returned when the input is undefined.

	Str->default(sub { return "default value" });

=head2 coerce

Sets a coercion function for the type constraint. This function will be used to convert input values before validation.

	Str->coerce(sub {
		my $value = shift;
		return join ",", @{$value} if ref $value eq "ARRAY";
		return $value;
	});

=head2 validate

This method maybe used to set the constaint validation option. What you set here will depend on the type you are using.
For example for the StrMatch type you would set a regex to match against.

	StrMatch->validate(qr/^[a-z]+$/);

=head2 constraint

Returns the validation function for the type constraint. This function can be used to validate values against the type constraint.

	Str->validate->("abc");

=head1 BENCHMARK

The following benchmark is between L<Types::Standard> with L<Type::Tiny::XS> installed and L<Basic::Types::XS>.

	use Benchmark qw(:all :hireswallclock);
	use Types::Standard;
	use Basic::Types::XS;

	my $r = timethese(1000000, {
		'Basic::Types::XS' => sub {
			my $Str = Basic::Types::XS::Definition::Str->('123');
			my $Num = Basic::Types::XS::Definition::Num->(123);
			my $Int = Basic::Types::XS::Definition::Int->(123);
			my $Array = Basic::Types::XS::Definition::ArrayRef->([qw/1 2 3/]);
			my $Hash = Basic::Types::XS::Definition::HashRef->({ a => 1, });
			my $Code = Basic::Types::XS::Definition::CodeRef->(sub { return 1 });
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
	Basic::Types::XS: 2.10176 wallclock secs ( 1.93 usr +  0.17 sys =  2.10 CPU) @ 476190.48/s (n=1000000)
	Types::Standard: 3.15881 wallclock secs ( 3.15 usr +  0.00 sys =  3.15 CPU) @ 317460.32/s (n=1000000)
			     Rate  Types::Standard Basic::Types::XS
	Types::Standard  317460/s               --             -33%
	Basic::Types::XS 476190/s              50%               --


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
