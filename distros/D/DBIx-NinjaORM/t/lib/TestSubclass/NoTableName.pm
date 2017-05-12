package TestSubclass::NoTableName;

use strict;
use warnings;

use base 'DBIx::NinjaORM';


=head1 NAME

TestSubclass::NoTableName - Test subclass without a table name.


=head1 VERSION

Version 3.1.0

=cut

our $VERSION = '3.1.0';


=head1 SYNOPSIS

	use lib 't/lib';
	use TestSubclass::NoTableName;


=head1 DESCRIPTION

Test subclass without a table name defined, which should not allow ORM
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
			primary_key_name => 'test_id',
		}
	);

	return $info;
}

1;
