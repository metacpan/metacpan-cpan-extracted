package Catalyst::Plugin::Session::Manager;
use strict;
use warnings;

use base qw/Class::Data::Inheritable Class::Accessor::Fast/;

use NEXT;
use UNIVERSAL::require;
use Digest::MD5;
use Catalyst::Exception;

our $VERSION = '0.07';

__PACKAGE__->mk_classdata( '_session'        );
__PACKAGE__->mk_classdata( '_session_client' );
__PACKAGE__->mk_accessors( 'sessionid'       );

sub finalize {
    my $c = shift;
    $c->_session->set($c);
    $c->_session_client->set($c);
    return $c->NEXT::finalize(@_);
}

sub prepare_parameters {
   my $c = shift;
   $c->NEXT::prepare_parameters;
   if ( my $sid = $c->_session_client->get($c) ) {
       $c->sessionid($sid);
       $c->log->debug(qq/Found sessionid "$sid"/) if $c->debug;
   }
   return $c;
}

sub session {
    my $c = shift;
    return $c->{session} if $c->{session};
    my $sid = $c->sessionid;
    if (   $sid
        && $c->_session
        && ( $c->{session} = $c->_session->get($sid) ) )
    {
        $c->log->debug(qq/Found session "$sid"/) if $c->debug;
        return $c->{session};
    }
    else {
        my $sid = Digest::MD5::md5_hex( time, rand, $$, 'catalyst' );
        $c->sessionid($sid);
        $c->log->debug(qq/Created session "$sid"/) if $c->debug;
        return $c->{session} = {};
    }
}

sub setup {
    my $self    = shift;
    my $config  = $self->config->{session};
    my $storage = delete $config->{ storage } || 'FastMmap';
    my $client  = delete $config->{ client  } || 'Cookie';
    $storage = 'Catalyst::Plugin::Session::Manager::Storage::'.$storage;
    $client  = 'Catalyst::Plugin::Session::Manager::Client::'.$client;

    $storage->require;
    if ($@) {
        Catalyst::Exception->throw(
            qq/failed to load session storage class "$storage"/
        );
    }
    $self->_session($storage->new($config));

    $client->require;
    if ($@) {
        Catalyst::Exception->throw(
            qq/failed to load session client class "$client"/
        );
    }
    $self->_session_client($client->new($config));

    return $self->NEXT::setup(@_);
}

1;
__END__

=head1 NAME

Catalyst::Plugin::Session::Manager - session manager for Catalyst (deprecated on 5.5)

=head1 SYNOPSIS

    use Catalyst qw/Session::Manager/;

    MyApp->config->{session} = {
        storage => 'FastMmap',
        client  => 'Cookie',
        ...other configuration needed by storage and client class.
    }

=head1 ATTENTION

If you use Catalyst 5.5 or later, You should use L<Catalyst::Plugin::Session>.

I keep this on CPAN just for people still need Catalyst version 5.3.

=head1 DESCRIPTION

This module provides session handlers for separated two processes,
one is to store data on server-side, another is on client-side.

Set manager on server-side with 'storage' parameter in configuration.
And set client-side manager with 'client'.

If you don't set them, 'FastMmap' and 'Cookie' are set by default.

=head1 SERVER SIDE STORAGE

=over 4

=item FastMmap

See L<Catalyst::Plugin::Session::Manager::Storage::FastMmap>

=item File

See L<Catalyst::Plugin::Session::Manager::Storage::File>

=item CDBI

See L<Catalyst::Plugin::Session::Manager::Storage::CDBI>

=back

=head1 CLIENT SIDE HANDLER

=over 4

=item Cookie

See L<Catalyst::Plugin::Session::Manager::Client::Cookie>

=item StickyQuery

See L<Catalyst::Plugin::Session::Manager::Client::StickyQuery>

=item Rewrite

See L<Catalyst::Plugin::Session::Manager::Client::Rewrite>

=back

=head1 TODO

=over 4

=item more documentation

=item more tests

=back

=head1 SEE ALSO

L<Catalyst>,

L<Catalyst::Plugin::Session::FastMmap>

=head1 AUTHOR

Lyo Kato E<lt>lyo.kato@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Lyo Kato

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

