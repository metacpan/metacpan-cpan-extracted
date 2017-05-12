package TestSubclass::DateTable;

use strict;
use warnings;

use base 'DBIx::NinjaORM';

use LocalTest;


=head1 NAME

TestSubclass::DateTable - Interface to the 'date_tests' table.


=head1 VERSION

Version 3.1.0

=cut

our $VERSION = '3.1.0';


=head1 SYNOPSIS

	use lib 't/lib';
	use TestSubclass::DateTable;


=head1 DESCRIPTION

Test subclass with the basic information required to use the 'date_tests'
table.


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
			default_dbh      => LocalTest::get_database_handle(),
			table_name       => 'date_tests',
			primary_key_name => 'test_id',
		}
	);

	return $info;
}


=head2 get_current_time()

Return the current date.

	my $current_date = $class->get_current_time();

=cut

sub get_current_time
{
	my ( $self, $field ) = @_;

	my $database_handle = $self->assert_dbh();
	my $database_type = $database_handle->{'Driver'}->{'Name'} || '';

	if ( $database_type eq 'mysql' )
	{
		return 'NOW()';
	}
	elsif ( $database_type eq 'Pg' )
	{
		return 'now()';
	}
	else
	{
		return "DATETIME('NOW')";
	}
}

1;
