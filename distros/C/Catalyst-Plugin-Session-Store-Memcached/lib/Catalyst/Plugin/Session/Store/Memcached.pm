package Catalyst::Plugin::Session::Store::Memcached;

use Moose;

extends 'Catalyst::Plugin::Session::Store';

with 'MooseX::Emulate::Class::Accessor::Fast';
with 'Catalyst::ClassData';

use MRO::Compat;
use namespace::clean -except => 'meta';
use Cache::Memcached::Managed;
use Catalyst::Exception;

our $VERSION = '0.05';

__PACKAGE__->mk_classdata($_)
  for qw/_session_memcached_storage _session_memcached_arg_fudge/;

=head1 NAME

Catalyst::Plugin::Session::Store::Memcached - Memcached storage backend for
session data.

=head1 SYNOPSIS

    use Catalyst qw/ Session Session::Store::Memcached Session::State::Foo /;

    MyApp->config(
        'Plugin::Session' => {
            memcached_new_args => {
                # L<Cache::Memcached::Managed/new>
                'data' => [ "10.0.0.15:11211", "10.0.0.15:11212" ],
            },
            memcached_item_args => {
                # L<Cache::Memcached::Managed/set>, get, delete
                # ...
            },
        },
    );

    # ... in an action:
    $c->session->{foo} = 'bar';    # will be saved

=head1 DESCRIPTION

C<Catalyst::Plugin::Session::Store::Memcached> is a session storage plugin for
Catalyst that uses the L<Cache::Memcached::Managed> module to connect to
memcached, a fast data caching server.

=head2 METHODS

=over 4

=item get_session_data

=item store_session_data

=item delete_session_data

=item delete_expired_sessions

These are implementations of the required methods for a store. See
L<Catalyst::Plugin::Session::Store>.

=cut

sub get_session_data {
    my ( $c, $key ) = @_;
    $c->_session_memcached_storage->get( @{ $c->_session_memcached_arg_fudge },
        id => $key, );
}

sub store_session_data {
    my ( $c, $key, $data ) = @_;

    $c->_session_memcached_storage->set(
        @{ $c->_session_memcached_arg_fudge },
        (
            $key =~ /^(?:expires|session|flash)/
              ? ( expiration => $c->session_expires )
              : ()
        ),
        id    => $key,
        value => $data,
      )
      or Catalyst::Exception->throw(
        "Couldn't save $key / $data in memcached storage");
}

sub delete_session_data {
    my ( $c, $sid ) = @_;
    $c->_session_memcached_storage->delete(
        @{ $c->_session_memcached_arg_fudge },
        id => $sid, );
}

sub delete_expired_sessions { }

=item setup_session

Sets up the session cache file.

=cut

sub setup_session {
    my $c = shift;

    $c->maybe::next::method(@_);

    my $cfg = $c->_session_plugin_config;

    my $appname = "$c";

    $c->_session_memcached_storage(
        my $storage = $cfg->{memcached_obj} || Cache::Memcached::Managed->new(
            data      => "localhost:11211",
            namespace => "catalyst_session",
            %{ $cfg->{memcached_new_args} || {} },
        ),
    );

    $c->_session_memcached_arg_fudge(
        [
            version => $appname->VERSION,
            key     => $appname,
            %{ $cfg->{memcached_item_args} || {} },
        ]
    );
}

=back

=head1 CONFIGURATION

These parameters are placed in the hash under the C<Plugin::Session> key in the
configuration hash.

=over 4

=item memcached_obj

If this key is a true value it will be used as the storage driver. It is
assumed that it adheres to the same interface as L<Cache::Memcached::Managed>.

=item memcached_new_args

This parameter is a hash reference which will be flattenned as the argument
list to L<Cache::Memcached::Managed/new>.

Some default values will be used:

=over 4

=item data

The data server to use defaults to C<localhost:11211>.

=item namespace

C<"catalyst_session">

=back

=item memcached_item_args

Extra arguments to be passed into C<set>, C<get>, and C<delete>. These are
discussed in L<Cache::Memcached::Managed>.

Some default values will be used:

=over 4

=item version

C<< YourApp->VERSION >>

=item key

C<"YourApp">

=back

=back

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Plugin::Session>, L<Cache::Memcached>.

=head1 AUTHORS

This module is derived from L<Catalyst::Plugin::Session::FastMmap> code, and
has been heavily modified since.

Tomas Doran, (t0m) C<bobtfish@bobtfish.net> - current maintainer.

Andrew Ford

Andy Grundman

Christian Hansen

Yuval Kogman, C<nothingmuch@woobling.org>

Marcus Ramberg

Sebastian Riedel

head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;
