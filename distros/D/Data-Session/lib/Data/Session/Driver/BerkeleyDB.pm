package Data::Session::Driver::BerkeleyDB;

use parent 'Data::Session::Base';
no autovivification;
use strict;
use warnings;

use BerkeleyDB;

use Hash::FieldHash ':all';

use Try::Tiny;

our $VERSION = '1.17';

# -----------------------------------------------

sub init
{
	my($self, $arg) = @_;
	$$arg{cache}    ||= '';
	$$arg{verbose}  ||= 0;

} # End of init.

# -----------------------------------------------

sub new
{
	my($class, %arg) = @_;

	$class -> init(\%arg);

	(! $arg{cache}) && die __PACKAGE__ . '. No cache supplied to new(...)';

	return from_hash(bless({}, $class), \%arg);

} # End of new.

# -----------------------------------------------

sub remove
{
	my($self, $id) = @_;
	my($lock)      = $self -> cache -> cds_lock;
	my($status)    = $self -> cache -> db_del($id);

	$lock -> cds_unlock;

	# Return '' for failure.

	return $status ? '' : 1;

} # End of remove.

# -----------------------------------------------

sub retrieve
{
	my($self, $id) = @_;
	my($lock)      = $self -> cache -> cds_lock;
	my($data)      = '';
	my($status)    = $self -> cache -> db_get($id => $data);

	$lock -> cds_unlock;

	# Return '' for failure.

	return $status ? '' : $data;

} # End of retrieve.

# -----------------------------------------------

sub store
{
	my($self, $id, $data) = @_;
	my($lock)   = $self -> cache -> cds_lock;
	my($status) = $self -> cache -> db_put($id => $data);

	$lock -> cds_unlock;

	return $status ? '' : 1;

} # End of store.

# -----------------------------------------------

sub traverse
{
	my($self, $sub) = @_;
	my($id, $data)  = ('', '');
	my($cursor)     = $self -> cache -> db_cursor;

	while ($cursor -> c_get($id, $data, DB_NEXT) == 0)
	{
		$sub -> ($id);
	}

	undef $cursor;

	return 1;

} # End of traverse.

# -----------------------------------------------

1;

=pod

=head1 NAME

L<Data::Session::Driver::BerkeleyDB> - A persistent session manager

=head1 Synopsis

See L<Data::Session> for details.

=head1 Description

L<Data::Session::Driver::BerkeleyDB> allows L<Data::Session> to manipulate sessions via
L<BerkeleyDB>.

To use this module do both of these:

=over 4

=item o Specify a driver of type BerkeleyDB, as
Data::Session -> new(type => 'driver:BerkeleyDB ...')

=item o Specify a cache object of type L<BerkeleyDB> as Data::Session -> new(cache => $object)

Also, $object must have been created with a Env parameter of type L<BerkeleyDB::Env>. See below.

=back

See scripts/berkeleydb.pl.

=head1 Case-sensitive Options

See L<Data::Session/Case-sensitive Options> for important information.

=head1 Method: new()

Creates a new object of type L<Data::Session::Driver::BerkeleyDB>.

C<new()> takes a hash of key/value pairs, some of which might mandatory. Further, some combinations
might be mandatory.

The keys are listed here in alphabetical order.

They are lower-case because they are (also) method names, meaning they can be called to set or get
the value at any time.

=over 4

=item o cache => $object

Specifies the object of type L<BerkeleyDB> to use for session storage.

This key is normally passed in as Data::Session -> new(cache => $object).

Warning: This cache object must have been set up both as an object of type L<BerkeleyDB>, and with
that object having an Env parameter of type L<Berkeley::Env>, because this module -
L<Data::Session::Driver::BerkeleyDB> - uses the L<BerkeleyDB> method cds_lock().

This key is mandatory.

=item o verbose => $integer

Print to STDERR more or less information.

Typical values are 0, 1 and 2.

This key is normally passed in as Data::Session -> new(verbose => $integer).

This key is optional.

=back

=head1 Method: remove($id)

Deletes from storage the session identified by $id.

Returns the result of calling the L<BerkeleyDB> method delete($id).

This result is a Boolean value indicating 1 => success or 0 => failure.

=head1 Method: retrieve($id)

Retrieve from storage the session identified by $id.

Returns the result of calling the L<BerkeleyDB> method get($id).

This result is a frozen session. This value must be thawed by calling the appropriate serialization
driver's thaw() method.

L<Data::Session> calls the right thaw() automatically.

=head1 Method: store($id => $data)

Writes to storage the session identified by $id, together with its data $data.

Returns the result of calling the L<BerkeleyDB> method set($id => $data).

This result is a Boolean value indicating 1 => success or 0 => failure.

=head1 Method: traverse()

Retrieves all ids via a cursor, and for each id calls the supplied subroutine with the id as the
only parameter.

The database is not locked during this process.

Returns 1.

=head1 Installing BerkeleyDB

	Get Oracle's BerkeleyDB from
	http://www.oracle.com/technetwork/database/berkeleydb/overview/index.html
	I used V 5.1.19
	tar xvzf db-5.1.19.tar.gz
	cd db-5.1.19/build_unix
	../dist/configure
	make
	sudo make install
	It installs into /usr/local/BerkeleyDB.5.1

	Get Perl's BerkeleyDB from http://search.cpan.org
	I used V 0.43
	tar xvzf BerkeleyDB-0.43.tar.gz
	cd BerkeleyDB-0.43
	Edit 2 lines in config.in:
	INCLUDE = /usr/local/BerkeleyDB.5.1/include
	LIB     = /usr/local/BerkeleyDB.5.1/lib
	perl Makefile.PL
	make && make test
	sudo make install

=head1 Support

Log a bug on RT: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Session>.

=head1 Author

L<Data::Session> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2010.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2010, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
