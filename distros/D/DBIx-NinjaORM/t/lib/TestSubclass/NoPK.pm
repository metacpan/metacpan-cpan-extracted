package TestSubclass::NoPK;

use strict;
use warnings;

use base 'DBIx::NinjaORM';


=head1 NAME

TestSubclass::NoPK - Test subclass without a primary key.


=head1 VERSION

Version 3.1.0

=cut

our $VERSION = '3.1.0';


=head1 SYNOPSIS

	use lib 't/lib';
	use TestSubclass::NoPK;


=head1 DESCRIPTION

Test subclass without a primary key name defined, which should not allow ORM
operations.


=head1 FUNCTIONS

=head2 static_class_info()

Configure static class information.

=cut

sub static_class_info
{
	my ( $class ) = @_;

	my $info = $class->SUPER::static_class_info();

	$info->set(
		{
			table_name => 'tests',
		}
	);

	return $info;
}

1;
