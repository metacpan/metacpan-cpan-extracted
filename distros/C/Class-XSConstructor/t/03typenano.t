=pod

=encoding utf-8

=head1 PURPOSE

Test that Class::XSConstructor supports Type::Nano type constraints.
(MooseX::Types and MouseX::Types should pretty much just work too,
but are not tested.)

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Requires { 'Type::Nano' => '0.013' };

{
	package Person;
	use Type::Nano qw(Int);
	use Class::XSConstructor qw( name! ), age => Int, qw( email phone );
}

{
	package Employee;
	use parent -norequire, qw(Person);
	use Class::XSConstructor qw( employee_id! );
}

my $alice0 = bless {
	name         => "Alice",
	employee_id  => "001",
	age          => "40",
	email        => "alice\@example.net",
	phone        => "01273 123 456",
} => "Employee";

my $alice1 = Employee->new(
	name         => "Alice",
	employee_id  => "001",
	age          => "40",
	email        => "alice\@example.net",
	phone        => "01273 123 456",
	ignoreme     => 999,
);

my $alice2 = Employee->new(
	name         => "Alice",
	employee_id  => "001",
	age          => "40",
	email        => "alice\@example.net",
	phone        => "01273 123 456",
	ignoreme     => 999,
);

is_deeply($alice1, $alice0, 'constructor works given list of key-value pairs');
is_deeply($alice2, $alice0, 'constructor works given hashref');

is_deeply(
	Employee->new(name => "Alice", employee_id => "001"),
	bless({ name => "Alice", employee_id => "001" } => "Employee"),
	"optional arguments don't autovivify given list of key-value pairs",
);

is_deeply(
	Employee->new({ name => "Alice", employee_id => "001" }),
	bless({ name => "Alice", employee_id => "001" } => "Employee"),
	"optional arguments don't autovivify given hashref",
);

my $e1 = exception { Employee->new(  name        => "Alice"   ) };
my $e2 = exception { Employee->new(  exployee_id => "001"     ) };
my $e3 = exception { Employee->new({ name        => "Alice"  }) };
my $e4 = exception { Employee->new({ exployee_id => "001"    }) };
my $e5 = exception { Employee->new(  name => "Alice", employee_id => "001"  ) };
my $e6 = exception { Employee->new({ name => "Alice", employee_id => "001" }) };

like($_, qr/\AAttribute 'employee_id' is required/, 'exception') for $e1, $e3;
like($_, qr/\AAttribute 'name' is required/       , 'exception') for $e2, $e4;
is($_, undef, 'no exception') for $e5, $e6;

my $e7 = exception { Employee->new(  name => "Alice", employee_id => "001", age => "xyz"  ) };
my $e8 = exception { Employee->new({ name => "Alice", employee_id => "001", age => "xyz" }) };

like($_, qr/failed type constraint/, 'exception') for $e7, $e8;

done_testing;

