=pod

=encoding utf-8

=head1 PURPOSE

Check you can inherit from a Class::XSConstructor class without using
Class::XSConstructor in the child class.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

{
	package Local::Person;
	use Class::XSConstructor qw( name! !! );
	sub name { $_[0]{name} }
}

{
	package Local::Employee;
	our @ISA = 'Local::Person';
}

my $bob = Local::Employee->new( name => 'Bob' );
is( $bob->name, 'Bob' );

done_testing;