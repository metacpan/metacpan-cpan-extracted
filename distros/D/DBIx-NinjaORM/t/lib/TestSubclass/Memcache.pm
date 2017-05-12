package TestSubclass::Memcache;

use strict;
use warnings;

use base 'DBIx::NinjaORM';

use lib 't/lib';
use LocalTest;


=head1 NAME

TestSubclass::Memcache - Test subclass with a memcache object.


=head1 VERSION

Version 3.1.0

=cut

our $VERSION = '3.1.0';


=head1 SYNOPSIS

	use lib 't/lib';
	use TestSubclass::Memcache;


=head1 DESCRIPTION

Test subclass with a valid memcache object, to test cache-related features.


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
			'memcache' => LocalTest::get_memcache(),
		}
	);

	return $info;
}

1;
