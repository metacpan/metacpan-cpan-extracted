use utf8;
use strict;
use warnings;

package DR::Tnt;
use base qw(Exporter);
our $VERSION = '0.20';
our @EXPORT = qw(tarantool);
use List::MoreUtils 'any';

use Carp;
$Carp::Internal{ (__PACKAGE__) }++;

sub tarantool {
    my (%opts) = @_;

    my $driver = delete($opts{driver}) || 'sync';
    
    unless (any { $driver eq $_ } 'sync', 'ae', 'async', 'coro') {
        goto usage;
    }


    goto $driver;
    sync:
        require DR::Tnt::Client::Sync;
        return DR::Tnt::Client::Sync->new(%opts);

    ae:
    async:
        require DR::Tnt::Client::AE;
        return DR::Tnt::Client::AE->new(%opts);

    coro:
        require DR::Tnt::Client::Coro;
        return DR::Tnt::Client::Coro->new(%opts);


    usage:
        croak "Too few information about tarantool connection";
}

1;

__END__

=head1 NAME

DR::Tnt - driver/connector for tarantool

=head1 SYNOPSIS

    use DR::Tnt;    # exports 'tarantool'

    my $tnt = tarantool
                    host                => '1.2.3.4',
                    port                => 567,
                    user                => 'my_tnt_user',
                    password            => '#1@#$JHJH',
                    hashify_tuples      => 1,
                    driver              => 'sync',  # default
                    lua_dir             => '/path/to/my/luas',
                    reconnect_interval  => 0.5
    ;

    my $tuple = $tnt->get(space => 'index', [ 'key' ]);
    my $tuples = $tnt->select(myspace => 'myindex', [ 'key' ], $limit, $offset);

    my $updated = $tnt->update('myspace', [ 'key' ], [ [ '=', 1, 'name' ]]);
    my $inserted = $tnt->insert(myspace => [ 1, 2, 3, 4 ]);
    my $replaced = $tnt->replace(myspace => [ 1, 3, 4, 5 ]);

    my $tuples = $tnt->call_lua('box.space.myspace:select', [ 'key' ]);
    my $hashified_tuples =
        $tnt->call_lua([ 'box.space.myspace:select' => 'myspace' ], ['key' ]);


    my $removed = $tnt->delete(myspace => [ 'key' ]);
   
    my $tuples = $tnt->eval_lua('return 123');
    my $hashify_tuples = $tnt->eval_lua(['return 123' => 'myspace' ]);

=head1 DESCRIPTION


This module provides a synchronous and asynchronous driver for
L<Tarantool|http://tarantool.org>.

The driver supports three work flow types:

=over

=item L<DR::Tnt::Client::AE>

The primary type, provides an asynchronous, callback-based 
API. Requires a running L<AnyEvent> machine.

=item L<DR::Tnt::Client::Sync>

Synchronous driver (based on L<IO::Socket::INET>/L<IO::Socket::UNIX>).

=item L<DR::Tnt::Client::Coro>

L<Coro>'s driver, uses L<DR::Tnt::Client::AE>.

=back

The module does L<require> and makes instance of 
selected driver.

=head1 METHODS

=head2 tarantool

Loads selected driver and returns connector.

You can choose one driver:

=over

=item sync

L<DR::Tnt::Client::Sync> will be loaded and created.

=item ae or async

L<DR::Tnt::Client::AE> will be loaded and created.

=item coro

L<DR::Tnt::Client::Coro> will be loaded and created.

=back


=head2 Attributes

=over

=item host, port

Connection point for tarantool instance. If host contains C<unix/>, port
have to contain valid unix path to opened socket.

=item user, password

Auth arguments.

=item lua_dir

Directory that contains some lua files. After connecting, the driver sends
L<$tnt->eval_lua> for each file in the directory. So You can use the mechanizm
to store some values to C<box.session.storage>.

=item hashify_tuples

If the option is set to C<TRUE>, then the driver will extract tuples
to hash by C<box.space._space> schema.

=item reconnect_interval

Internal to reconnect after disconnect or fatal errors. Undefined value
disables the mechanizm.

=item raise_error

The option is actual for C<coro> and C<sync> drivers
(L<DR::Tnt::Client::Coro> and L<DR::Tnt::Client::Sync>).

=item utf8

Default value is C<TRUE>. If C<TRUE>, driver will unpack all
strings as C<utf8>-decoded strings.

=back

=head2 Information attributes

=over

=item last_error

Contains array of last error.
If there was no errors, the attrubute contains C<undef>.

The array can contain two or three elements:

=over

=item *

String error identifier. Example: C<ER_SOCKET> or C<ER_REQUEST>.

=item *

Error message. Example: 'C<Connection timeout>'

=item *

Tarantool code. Optional parameter. Example C<0x806D>.
The code is present only for tarantool errors (like lua error, etc).

=back

=back

=head1 CONNECTORS METHODS

All connectors have the same API. AnyEvent's connector has the last
argument - callback for results.

If C<raise_error> is C<false>, C<coro> and C<sync> drivers will
return C<undef> and store C<last_error>. Any successfuly call clears
C<last_error> attribute.

=over
    
=item auth

    # auth by $tnt->user and $tnt->password
    if ($tnt->auth) {

    }

    if ($tnt->auth($user, $password) {

    }

Auth user in tarantool. Note: The driver uses
C<<$tnt->user>> and C<<$tnt->password>> attributes after reconnects.

=item select

    my $list = $tnt->select($space, $index, $key);
    my $list = $tnt->select($space, $index, $key, $limit, $offset, $iterator);

Select tuples from space. You can use space/index's names or numbers.

Default values for C<$iterator> is C<'EQ'>, for C<$limit> is C<2**32>,
for C<$offset> is C<0>.

=item get

    my $tuple = $tnt->get($space, $index, $key);

The same as C<select>, but forces C<$limit> to C<1>, C<$offset> to C<0>,
C<$iterator> to C<'EQ'> and returns the first tuple of result list.

=item update

    my $updated = $tnt->update($space, $key, [[ '=', 3, 'name' ]]);

Update tuple in database.


=item insert

    my $inserted = $tnt->insert($space, [ $name, $value ]);

=item replace

    my $replaced = $tnt->replace($space, [ $name, $value ]);

=item delete

    my $deleted = $tnt->delete($space, $key);

=item call_lua

    my $tuples = $tnt->call_lua('my.lua.name', $arg1, $arg2);
    
    my $hashified_tuples = $tnt->call_lua(['box.space.name:select' => 'name'], 123);


If C<proc_name> is C<ARRAYREF>, result tuples will be hashified as tuples
of selected space.

=item eval_lua

    my $tuples = $tnt->eval_lua('return {{1}}');
    my $hashified_tuples = $tnt->eval_lua(['return {{1}}' => 'name');

=item ping

    if ($tnt->ping) {
        # connection established.
    }

=back

=cut

