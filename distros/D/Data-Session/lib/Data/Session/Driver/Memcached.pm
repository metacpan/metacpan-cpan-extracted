package Data::Session::Driver::Memcached;

use parent 'Data::Session::Base';
no autovivification;
use strict;
use warnings;

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

	return $self -> cache -> delete($id);

} # End of remove.

# -----------------------------------------------

sub retrieve
{
	my($self, $id) = @_;

	# Return undef for failure.

	return $self -> cache -> get($id);

} # End of retrieve.

# -----------------------------------------------

sub store
{
	my($self, $id, $data, $time) = @_;

	return $self -> cache -> set($id, $data, $time);

} # End of store.

# -----------------------------------------------

sub traverse
{
	my($self, $sub) = @_;

	return 1;

} # End of traverse.

# -----------------------------------------------

1;

=pod

=head1 NAME

L<Data::Session::Driver::Memcached> - A persistent session manager

=head1 Synopsis

See L<Data::Session> for details.

=head1 Description

L<Data::Session::Driver::Memcached> allows L<Data::Session> to manipulate sessions
L<Cache::Memcached>.

To use this module do both of these:

=over 4

=item o Specify a driver of type Memcached, as Data::Session -> new(type => 'driver:Memcached ...')

=item o Specify a cache object of type L<Cache::Memcached> as Data::Session -> new(cache => $object)

=back

See scripts/memcached.pl.

=head1 Case-sensitive Options

See L<Data::Session/Case-sensitive Options> for important information.

=head1 Method: new()

Creates a new object of type L<Data::Session::Driver::Memcached>.

C<new()> takes a hash of key/value pairs, some of which might mandatory. Further, some combinations
might be mandatory.

The keys are listed here in alphabetical order.

They are lower-case because they are (also) method names, meaning they can be called to set or get
the value at any time.

=over 4

=item o cache => $object

Specifies the object of type L<Cache::Memcached> to use for session storage.

This key is normally passed in as Data::Session -> new(cache => $object).

This key is mandatory.

=item o verbose => $integer

Print to STDERR more or less information.

Typical values are 0, 1 and 2.

This key is normally passed in as Data::Session -> new(verbose => $integer).

This key is optional.

=back

=head1 Method: remove($id)

Deletes from storage the session identified by $id.

Returns the result of calling the L<Cache::Memcached> method delete($id).

This result is a Boolean value indicating 1 => success or 0 => failure.

=head1 Method: retrieve($id)

Retrieve from storage the session identified by $id.

Returns the result of calling the L<Cache::Memcached> method get($id).

This result is a frozen session. This value must be thawed by calling the appropriate serialization
driver's thaw() method.

L<Data::Session> calls the right thaw() automatically.

=head1 Method: store($id, $data, $time)

Writes to storage the session identified by $id, together with its data $data. The expiry time of
the object is passed into the set() method of L<Cache::Memcached>, too.

Returns the result of calling the L<Cache::Memcached> method set($id, $data, $time).

This result is a Boolean value indicating 1 => success or 0 => failure.

Note: $time is 0 for sessions which don't expire. If you wish to pass undef or 'never', as per the
L<Cache::Memcached> documentation, you will have to subclass L<Cache::Memcached> and override the
set() method to change 0 to 'never'.

=head1 Method: traverse()

There is no mechanism (apart from memcached's debug code) to get a list of all keys in a cache
managed by memcached, so there is no way to traverse them via this module.

Returns 1.

=head1 Installing memcached

	Get libevent from http://www.monkey.org/~provos/libevent/
	I used V 2.0.8-rc
	./configure
	make && make verify
	sudo make install
	It installs into /usr/local/lib, so tell memcached where to look:
	LD_LIBRARY_PATH=/usr/local/lib
	export LD_LIBRARY_PATH

	Get memcached from http://memcached.org/
	I used V 1.4.5
	./configure --with-libevent=/usr/local/lib
	make && make test
	sudo make install

	Running memcached:
	memcached -m 5 &

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
