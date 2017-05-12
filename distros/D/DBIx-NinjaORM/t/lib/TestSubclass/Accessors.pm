package TestSubclass::Accessors;

use strict;
use warnings;

use base 'DBIx::NinjaORM';


=head1 NAME

TestSubclass::Accessors - Test subclass without a primary key.


=head1 VERSION

Version 3.1.0

=cut

our $VERSION = '3.1.0';


=head1 SYNOPSIS

	use lib 't/lib';
	use TestSubclass::Accessors;


=head1 DESCRIPTION

Test subclass with specific static_class_info() values designed to make easy
the testing of the static class info accessors.


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
			'default_dbh'       => "TESTDBH",
			'memcache'          => "TESTMEMCACHE",
			'table_name'        => "TEST_TABLE_NAME",
			'primary_key_name'  => "TEST_PRIMARY_KEY_NAME",
			'list_cache_time'   => 20,
			'object_cache_time' => 20,
			'unique_fields'     => [ 'test' ],
			'filtering_fields'  => [ 'test' ],
			'readonly_fields'   => [ 'test' ],
			'has_created_field' => 0,
			'cache_key_field'   => 'TEST_CACHE_KEY_FIELD',
		}
	);

	return $info;
}

1;
