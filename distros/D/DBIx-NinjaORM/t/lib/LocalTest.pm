package LocalTest;

use strict;
use warnings;

use Carp;
use Data::Validate::Type;
use DBI;
use Test::More;
use Try::Tiny;


=head1 NAME

LocalTest - Test functions for L<DBIx::NinjaORM>.


=head1 VERSION

Version 3.1.0

=cut

our $VERSION = '3.1.0';


=head1 SYNOPSIS

	use lib 't/lib';
	use LocalTest;

	my $dbh = LocalTest::ok_database_handle();


=head1 FUNCTIONS

=head2 get_database_handle()

Create a database handle.

	my $dbh = LocalTest::get_database_handle();

=cut

sub get_database_handle
{
	$ENV{'NINJAORM_DATABASE'} ||= 'dbi:SQLite:dbname=t/test_database||';

	my ( $database_dsn, $database_user, $database_password ) = split( /\|/, $ENV{'NINJAORM_DATABASE'} );

	my $database_handle = DBI->connect(
		$database_dsn,
		$database_user,
		$database_password,
		{
			RaiseError => 1,
		}
	);

	# If it's SQLite, we need to turn on foreign keys support.
	if ( defined( $database_handle ) )
	{
		my $database_type = get_database_type( $database_handle );
		if ( defined( $database_type ) && ( $database_type eq 'SQLite' ) )
		{
			$database_handle->do( 'PRAGMA foreign_keys = ON' );
		}
	}

	return $database_handle
}


=head2 ok_database_handle()

Verify that a database handle can be created, and return it.

	my $dbh = LocalTest::ok_database_handle();

=cut

sub ok_database_handle
{
	ok(
		defined(
			my $database_handle = get_database_handle()
		),
		'Create connection to a database.',
	);

	my $database_type = $database_handle->{'Driver'}->{'Name'} || '';
	note( "Testing $database_type database." );

	return $database_handle;
}


=head2 get_database_type()

Return the name of the driver used by the database handle.

	my $database_type = LocalTest::get_database_type( $database_handle );

=cut

sub get_database_type
{
	my ( $dbh ) = @_;

	croak 'The first argument of get_database_type() must be a database handle'
		if ! Data::Validate::Type::is_instance( $dbh, class => 'DBI::db' );

	return $dbh->{'Driver'}->{'Name'};
}


=head2 ok_database_type()

Verify that the database type is supported, and return it.

	my $database_type = LocalTest::ok_database_type( $database_handle );

=cut

sub ok_database_type
{
	my ( $dbh ) = @_;

	my $type = get_database_type( $dbh ) || '';

	like(
		$type,
		qr/^(?:mysql|SQLite|Pg)$/,
		"Database type '$type' is supported.",
	);

	return $type;
}


=head2 get_memcache()

Get a memcache object.

	my $memcache = LocalTest::get_memcache();

=cut

sub get_memcache
{
	return
		try
		{
			eval 'use Cache::Memcached::Fast';
			die 'Cache::Memcached::Fast is not installed on this system'
				if $@;

			return Cache::Memcached::Fast->new(
				{
					servers =>
					[
						'localhost:11211',
					],
				}
			);
		}
		catch
		{
			return undef;
		};
}


=head2 ok_memcache()

Verify that memcache is running, and skip all tests if it isn't.

	my $memcache = LocalTest::ok_memcache();

=cut

sub ok_memcache
{
	# Verify if Cache::Memcached::Fast is installed.
	eval 'use Cache::Memcached::Fast';
	plan( skip_all => 'Cache::Memcached::Fast required to test cache-related features.' ) && exit
		if $@;

	my $memcache = LocalTest::get_memcache();

	# Verify that memcache is configured and running.
	plan( skip_all => 'Memcache is not running or configured on this machine, cannot test.' ) && exit
		if !defined( $memcache) || !$memcache->set( 'test_ninja_orm', 1, time() + 10 );

	return $memcache;
}


=head1 AUTHOR

Guillaume Aubert, C<< <aubertg at cpan.org> >>.


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/DBIx-NinjaORM/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc LocalTest


You can also look for information at:

=over 4

=item * GitHub's request tracker

L<https://github.com/guillaumeaubert/DBIx-NinjaORM/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-NinjaORM>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-NinjaORM>

=item * MetaCPAN

L<https://metacpan.org/release/DBIx-NinjaORM>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2009-2017 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.

=cut

1;
