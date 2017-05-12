package TestSubclass::TestTable;

use strict;
use warnings;

use base 'DBIx::NinjaORM';

use LocalTest;


=head1 NAME

TestSubclass::TestTable - Interface to the 'tests' table.


=head1 VERSION

Version 3.1.0

=cut

our $VERSION = '3.1.0';


=head1 SYNOPSIS

	use lib 't/lib';
	use TestSubclass::TestTable;


=head1 DESCRIPTION

Test subclass with the basic information required to use the 'tests' table.


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
			table_name       => 'tests',
			primary_key_name => 'test_id',
		}
	);

	return $info;
}

1;
