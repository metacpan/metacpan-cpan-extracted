=pod

=encoding utf-8

=head1 PURPOSE

Tests L<Acme::Has::Tiny> a bit more.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Types::Standard -types;

BEGIN {
	package Person;
	use Acme::Has::Tiny qw(new has);
	
	has name => (isa => ::Str, predicate => 1);
	has age  => (isa => ::Num, predicate => 1, is => "rwp");
	
	$INC{'Person.pm'} = __FILE__;
};

BEGIN {
	package Employee;
	use Acme::Has::Tiny qw(new has);
	use base qw(Person);
	
	has name => (isa => ::Str, required => 1);
	has id   => (isa => ::Int, required => 1);
	
	Acme::Has::Tiny->create_constructor(
		"from_arrayref",
		buildargs => sub { shift; +{ name => $_[0][0], id => $_[0][1] } },
	);
	
	$INC{'Employee.pm'} = __FILE__;
};

my $alice = "Person"->new(name => "Alice", age => 32);
isa_ok($alice, "Person", '$alice');
can_ok($alice, $_) for qw(name age has_name has_age _set_age);

my $bob = "Employee"->new(name => "Bob", id => 123456);
isa_ok($bob, "Person", '$bob');
isa_ok($bob, "Employee", '$bob');
can_ok($bob, $_) for qw(name age has_name has_age _set_age id);
like(exception { $bob->_set_age("x") }, qr{^Value "x" did not pass type constraint "Num"}, 'type constraint');
ok(!$bob->has_age, 'not $bob->has_age');
is($bob->age, undef, '$bob->age undef');
is($bob->_set_age(42), 42, 'setter returns value');
ok($bob->has_age, '$bob->has_age');
is($bob->age, 42, 'getter returns value');

my $e = exception { "Employee"->new(name => undef) };
like($e, qr{^Attribute id is required by Employee}, 'required attribute exception');

done_testing;
