package Catalyst::Plugin::Session::Store::Memcached::Fast;

use strict;
use base qw/
    Class::Accessor::Fast 
    Class::Data::Inheritable 
    Catalyst::Plugin::Session::Store/;

use NEXT;

use Cache::Memcached::Fast;
use Catalyst::Utils;

our $VERSION = '0.02';

__PACKAGE__->mk_classdata(qw/_session_memcached_storage/);
__PACKAGE__->mk_classdata(qw/_session_memcached_expires/);

=head1 NAME

Catalyst::Plugin::Session::Store::Memcached::Fast - Memcached session storage backend.

=head1 SYNOPSIS

    use Catalyst qw/Session Session::Store::Memcached::Fast Session::State::Foo/;
    
    MyApp->config->{session} = {
        expires => 3600,
        servers => ['127.0.0.1:11210'],
        # another Cache::Memcached::Fast params
    };

    # ... in an action:
    $c->session->{foo} = 'bar'; # will be saved

=head1 DESCRIPTION

C<Catalyst::Plugin::Session::Store::Memcached::Fast> is a fast session storage plugin
for Catalyst that uses memcached cache. It is based on L<Cache::Memcached::Fast>.

=head2 METHODS

=over 4

=item get_session_data

=item store_session_data

=item delete_session_data

=item delete_expired_sessions

These are implementations of the required methods for a store. See
L<Catalyst::Plugin::Session::Store>.

=item get_and_set_session_data

This is the optional method for atomic write semantics. See
L<Catalyst::Plugin::Session::AtomicWrite>.

=cut

sub get_session_data {
    my ( $c, $sid ) = @_;
    $c->_session_memcached_storage->get($sid);
}

sub store_session_data {
    my ( $c, $sid, $data, $expires ) = @_;
    $c->_session_memcached_storage->set( $sid, $data, $expires || $c->_session_memcached_expires );
}

sub delete_session_data {
    my ( $c, $sid ) = @_;
    $c->_session_memcached_storage->remove($sid);
}

sub delete_expired_sessions { } # unsupported

sub get_and_set_session_data {
    my ( $c, $sid, $sub, $try ) = @_;

    return if ($try > 10);

    my $val = $c->_session_memcached_storage->gets($sid);
    $$val[1] = $sub->($sid, $$val[1]);
    if ($c->_session_memcached_storage->cas($sid, @$val)) {
        return $$val[1];
    } else {
        return $c->get_and_set_session_data($sid, $sub, $try++);
    }
}

=item setup_session

Sets up the session connection.

=cut

sub setup_session {
    my $c = shift;

    $c->NEXT::setup_session(@_);

    my $cfg = $c->config->{session};

    $c->_session_memcached_expires($cfg->{expires} || 86400);

    $c->_session_memcached_storage(
        Cache::Memcached::Fast->new(
{                map { $_ => $cfg->{$_} }
                  grep { exists $cfg->{$_} } qw/
			servers
			namespace
			hash_namespace
			nowait
			connect_timeout
			io_timeout
			close_on_error
			compress_threshold
			compress_ratio
			compress_methods
			max_failures
			failure_timeout
			ketama_points
			serialize_methods
			utf8
			check_args
                  /
}
        )
    );
}

=back

=head1 CAVEATS

=head1 CONFIGURATION

=over 4

=back

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Plugin::Session>, L<Cache::Memcached::Fast>.

=head1 AUTHORS

Denis Arapov, C<bwizard@blackwizard.pp.ru>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
