package DR::Tarantool;

=head1 NAME

DR::Tarantool - a Perl driver for L<Tarantool|http://tarantool.org>


=head1 SYNOPSIS

    use DR::Tarantool ':constant', 'tarantool';
    use DR::Tarantool ':all';

    my $tnt = tarantool
        host    => '127.0.0.1',
        port    => 123,
        spaces  => {
            ...
        }
    ;

    $tnt->update( ... );

    my $tnt = coro_tarantool
        host    => '127.0.0.1',
        port    => 123,
        spaces  => {
            ...
        }
    ;

    use DR::Tarantool ':constant', 'async_tarantool';

    async_tarantool
        host    => '127.0.0.1',
        port    => 123,
        spaces  => {
            ...
        },
        sub {
            ...
        }
    ;

    $tnt->update(...);

=head1 DESCRIPTION

This module provides a synchronous and asynchronous driver for
L<Tarantool|http://tarantool.org>.

The driver does not have external dependencies, but includes the
official light-weight Tarantool C client (a single C header which
implements all protocol formatting) for packing requests and unpacking
server responses.

This driver implements "iproto" protocol described in
https://github.com/mailru/tarantool/blob/master/doc/box-protocol.txt

It is built on top of L<AnyEvent> - an asynchronous event
framework, and is therefore easiest to integrate into a program
which is already based on L<AnyEvent>. A synchronous version of
the driver exists as well, it starts L<AnyEvent> event machine for
every request. 

The driver supports three work flow types:

=over

=item L<DR::Tarantool::AsyncClient>

The primary type, provides an asynchronous, callback-based 
API. Requires a running L<AnyEvent> machine.

=item L<DR::Tarantool::SyncClient>

Is built on top of L<DR::Tarantool::AsyncClient>. Starts 
L<AnyEvent> machine for every request. After a request is
served, the event loop is stopped, and the results
are returned to the caller, or, in case of an error, an
exception is thrown.

=item L<DR::Tarantool::CoroClient>

Is also built on top of L<DR::Tarantool::AsyncClient>, but is
designed to work in cooperative multitasking environment provided
by L<Coro>. Is fully syntax-compatible with
L<DR::Tarantool::SyncClient>, but requires a running event loop to
operate, like L<DR::Tarantool::AsyncClient>. Requests from
different coroutines are served concurrently.

=back

L<Tarantool|http://tarantool.org> binary protocol
contains no representation of database schema or tuple field types.
Due to this deficiency, to easily integrate with Perl and automatically
convert tuple fields to Perl values, the driver needs to know field names
and types. To tell the driver about them, an instance of a dedicated class
must be used.
L<DR::Tarantool::Spaces> is essentially a Perl hash which
describes field types and names for each space used in the program.
It can hardly be useful on its own, but once a connection is
"enlightened" with an instance of this class, access to all tuple
fields by a field name becomes possible. Type conversion, as
well as packing/unpacking from Tarantool binary format is
performed automatically.

Please follow the docs for L<DR::Tarantool::Spaces> to learn
how to describe a schema.

=head2 Establishing a connection

=head3 L<DR::Tarantool::AsyncClient>

	DR::Tarantool::AsyncClient->connect(
		host 	=> $host,
		port 	=> $port,
		spaces 	=> { ... },
		sub {
			my ($tnt) = @_;
			...

		}
	);

The callback passed to connect() gets invoked after a connection
is established. The only argument of the callback is the newly
established connection handle. The handle's type is
L<DR::Tarantool::AsyncClient>.

=head3 L<DR::Tarantool::CoroClient> and L<DR::Tarantool::SyncClient>

	my $tnt = DR::Tarantool::SyncClient->connect(
		host 	=> $host,
		port 	=> $port,
		spaces 	=> { ... }
	);

	my $tnt = DR::Tarantool::CoroClient->connect(
		host 	=> $host,
		port 	=> $port,
		spaces 	=> { ... }
	);

The only difference of synchronous versions from the asynchronous
one is absence of a callback. The created connection handle
is returned directly from connect().
In this spirit, the only difference of any synchronous API all
from the asynchronous counterpart is also in absence of the callback.

=head2 Working with tuples

=head3 Querying 

	my $user123 = $tnt->select('users' => 123);

	my $users_by_roles = $tnt->select('users' => 'admins' => 'role_index');
	

It is possible to select data by a primary key (expects a Perl scalar),
secondary, multi-part key (expects an array).

The default index used for selection is the primary one, a non-default index
can be set by providing index name.

The contents of the result set is interpreted in accordance with 
schema description provided in L<DR::Tarantool::Spaces>.
Supported data types are numbers, Unicode strings, JSON,
fixed-point decimals.

=head3 Insertion 

	$tnt->insert('users' => [ 123, 'vasya', 'admin' ]);

Insert a tuple into space 'users', defined in B<spaces> hash on
connect. 

=head3 Deletion

	$tnt->delete(users => 123);

Delete a tuple from space 'users'. The deletion is always
performed by the primary key.


=head3 Update

	$tnt->update(users => 123 => [[ role => set => 'not_admin' ]]);

It is possible to modify any field in a tuple. A field can be
accessed by field name or number. A set of modifications can be
provided in a Perl array.

The following update operations are supported:

=over

=item set

Assign a field

=item add, and, or, xor

Arithmetic and bitwise operations for integers.

=item substr

Replace a substring with a paste (similar to Perl splice).

=item insert

Insert a field before the given field.

=item delete

Delete a field.

=item push

Append a field at the tail of the tuple.

=item pop

Pop a field from the tail of the tuple.

=back

=head3 Lua

	$tnt->call_lua(my_proc_name => [ arguments, ...]);

Invoke a Lua stored procedure by name.

=head2 Supported data types

The driver supports all Tarantool types (B<NUM>, B<NUM64>, B<STR>),
as well as some client-only types, which are converted to the
above server types automatically on the client:

=over

=item UTF8STR

A unicode string. 

=item MONEY

Fixed decimal currency. Stores the value on the server in B<NUM> type,
by multiplying the given amount by 100. The largest amount
that can be stored in this type is, therefore, around 20 000 000.
Can store negative values.

=item BIGMONEY

The same as above, but uses B<NUM64> as the underlying storage.

=item JSON

An arbitrary Perl object is automatically serialized to JSON with
L<JSON::XS> on insertion, and deserialized on selection.

=back

The basic data transfer unit in Tarantool protocol is a single
tuple. A selected tuple is automatically wrapped into an instance
of class L<DR::Tarantool::Tuple>. An object of this class can be
used as an associative container, in which any field can be
accessed by field name:

	my $user = $tnt->select(users => 123);

	printf("user: %s, role: %s\n", $user->name, $user->role);



To run driver tests, the following Perl modules are also necessary:
L<AnyEvent>, L<Coro>, L<Test::Pod>, L<Test::Spelling>,
L<Devel::GlobalDestruction>, L<JSON::XS>.

To run tests, do:
    perl Makefile.PL
    make
    make test

The test suite attempts to find the server and start it, thus
make sure L<tarantool_box> is available in the path, or export
TARANTOOL_BOX=/path/to/tarantool_box.

=cut

use 5.008008;
use strict;
use warnings;
use Carp;
$Carp::Internal{ (__PACKAGE__) }++;

use base qw(Exporter);


our %EXPORT_TAGS = (
    client      => [ qw( tarantool async_tarantool coro_tarantool) ],
    constant    => [
        qw(
            TNT_INSERT TNT_SELECT TNT_UPDATE TNT_DELETE TNT_CALL TNT_PING
            TNT_FLAG_RETURN TNT_FLAG_ADD TNT_FLAG_REPLACE
        )
    ],
);

our @EXPORT_OK = ( map { @$_ } values %EXPORT_TAGS );
$EXPORT_TAGS{all} = \@EXPORT_OK;
our @EXPORT = @{ $EXPORT_TAGS{client} };
our $VERSION = '0.44';

=head1 EXPORT

=head2 tarantool

connects to L<Tarantool|http://tarantool.org> in synchronous mode
using L<DR::Tarantool::SyncClient>.

=cut

sub tarantool {
    require DR::Tarantool::SyncClient;
    no warnings 'redefine';
    *tarantool = sub {
        DR::Tarantool::SyncClient->connect(@_);
    };
    goto \&tarantool;
}


=head2 rsync_tarantool

connects to L<Tarantool|http://tarantool.org> in synchronous mode
using L<DR::Tarantool::RealSyncClient>.

=cut

sub rsync_tarantool {
    require DR::Tarantool::RealSyncClient;
    no warnings 'redefine';
    *rsync_tarantool = sub {
        DR::Tarantool::RealSyncClient->connect(@_);
    };
    goto \&rsync_tarantool;
}


=head2 async_tarantool

connects to L<tarantool|http://tarantool.org> in async mode using
L<DR::Tarantool::AsyncClient>.

=cut

sub async_tarantool {
    require DR::Tarantool::AsyncClient;
    no warnings 'redefine';
    *async_tarantool = sub {
        DR::Tarantool::AsyncClient->connect(@_);
    };
    goto \&async_tarantool;
}


=head2 coro_tarantol

connects to L<tarantool|http://tarantool.org> in async mode using
L<DR::Tarantool::CoroClient>.


=cut

sub coro_tarantool {
    require DR::Tarantool::CoroClient;
    no warnings 'redefine';
    *coro_tarantool = sub {
        DR::Tarantool::CoroClient->connect(@_);
    };
    goto \&coro_tarantool;
}


=head2 :constant

Exports constants to use in a client request as flags:

=over

=item TNT_FLAG_RETURN

With this flag on, each INSERT/UPDATE request
returns the new value of the tuple. DELETE returns the deleted
tuple, if it is found.

=item TNT_FLAG_ADD

With this flag on, INSERT returns an error if an old tuple
with the same primary key already exists. No tuple is inserted
in this case.

=item TNT_FLAG_REPLACE

With this flag on, INSERT returns an error if an old
tuple for the primary key does not exist.
Without either of the flags, INSERT replaces the old
tuple if it doesn't exist.

=back

=cut

require XSLoader;
XSLoader::load('DR::Tarantool', $VERSION);



=head2 :all

Exports all functions and constants.

=head1 TODO

=over

=item *

Support push, pop in UPDATE.

=item *

Make it possible to construct B<select>, B<delete> keys from Perl
hashes, not just Perl arrays.

=item *

Support L<DR::Tarantool::Tuple> as an argument to B<insert>.

=back

=head1 COPYRIGHT AND LICENSE

 Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>
 Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

 This program is free software, you can redistribute it and/or
 modify it under the terms of the Artistic License.

=head1 VCS

The project is hosted on github in the following git repository:
L<https://github.com/dr-co/dr-tarantool/>.

=cut

1;
