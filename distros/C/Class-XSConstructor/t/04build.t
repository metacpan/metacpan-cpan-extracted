=pod

=encoding utf-8

=head1 PURPOSE

Test that Class::XSConstructor supports C<BUILD>

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018-2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

my $x = "";

{
	package Person;
	use Class::XSConstructor qw( name! age email phone );
	sub BUILD { $x .= __PACKAGE__ }
}

{
	package Employee;
	use parent -norequire, qw(Person);
	use Class::XSConstructor qw( employee_id! );
	sub BUILD { $x .= __PACKAGE__ . $_[1]{slug} }
}

Employee->new(name => "Alice", employee_id => "001", slug => "Yeah");

is($x, "PersonEmployeeYeah", "BUILD");

$x = "";

Employee->new(name => "Alice", employee_id => "001", slug => "Yeah", "__no_BUILD__" => 1);

is($x, "", "__no_BUILD__ => 1");

$x = "";

Employee->new(name => "Alice", employee_id => "001", slug => "Baby", "__no_BUILD__" => 0);

is($x, "PersonEmployeeBaby", "__no_BUILD__ => 0");

done_testing;

