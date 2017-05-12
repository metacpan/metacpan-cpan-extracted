package Dancer2::Session::CGISession;

use strict;
use 5.008_005;
our $VERSION = '0.04';

use Moo;
use Carp;
use Dancer2::Core::Types;
use CGI::Session;

with 'Dancer2::Core::Role::SessionFactory';

#------------------------------------#
# Attributes
#------------------------------------#

has driver_params => (
    is => 'ro',
    default => sub { {}; }
);

has driver => (
    is => 'ro',
    default => sub { 'driver:File'; }
);

has name => (
    is => 'ro',
    default => sub { 'CGISESSID'; }
);

#------------------------------------#
# Role composition
#------------------------------------#

#might be possible to do something with CGI::Session find method here
sub _sessions {
    my ($self) = @_;
    return [];
}

sub generate_id {
    my ( $class ) = @_;

    #creation of the cgi session when generating the id, as it using dancer2 id to create CGI session seems not to be working
    my $cgi_session = CGI::Session->new(
        $class->driver,
        undef,
        $class->driver_params
    ) or die CGI::Session->errstr();;
    $cgi_session->expire( $class->session_duration );
    $cgi_session->name( $class->cookie_name );

    #Return the newly created CGI::Session id
    return $cgi_session->id();
}

sub _change_id {
    my ( $self, $old_id, $new_id ) = @_;
    my $data = $self->_retrieve($old_id);
    $self->_destroy($old_id);
    $self->_flush($new_id, $data);
}

sub _retrieve {
    my ( $class, $id ) = @_;

    my $cgi_session = $class->get_cgi_session( $id );
    if( $cgi_session->is_empty or $cgi_session->is_expired ) {
        # CGI Session has been removed from the server, die here, Dancer2::Core::Role::Session
        # knows how to deal with that, warn Caller by dying
        die "CGI Session has disappeared";
    }

    return $cgi_session->dataref();
}

sub _destroy {
    my ( $class, $id ) = @_;

    my $cgi_session = $class->get_cgi_session( $id );
    if( defined $cgi_session->id ) {
        $cgi_session->delete;
        $cgi_session->flush;
    }
}

sub _flush {
    my ( $class, $id, $data ) = @_;

    my $cgi_session = $class->get_cgi_session( $id );
    foreach my $key (keys %{$data} ){
        delete $$data{$key} if ($key =~ m/^_SESSION_/);
    }
    $cgi_session->param( %{$data} );
    $cgi_session->flush;
}

sub get_cgi_session {
    my ( $class, $id ) = @_;

    my $cgi_session = CGI::Session->load( $class->driver, $id, $class->driver_params )
        or die CGI::Session->errstr();

    return $cgi_session;
}

1;
__END__

=encoding utf-8

=head1 NAME

Dancer2::Session::CGISession - Share Dancer Session with CGI::Session

=head1 SYNOPSIS

  use Dancer2::Session::CGISession;

=head1 DESCRIPTION

Dancer2::Session::CGISession is a session engine for Dancer2 to interact with CGI::Session;
Mostly usefull if you need to share sessions created by non-Dancer apps which are already using CGI::Session.
That Plugin is heavily inspired from Dancer::Session::CGISession

This module is a work in progress

You can set CGI::Session drivers and parameters using Dancer2 configuration

    session: "CGISession"

    engines:
      session:
        CGISession:
          driver: "driver:file:
          driver_params:
            "Directory": "/tmp
          name: "session name"

=head1 AUTHOR

Pierre VIGIER E<lt>pierre.vigier@gmail.comE<gt>

=head2 Contributors

jwilliams99 E<lt>https://github.com/jwilliams99E<gt>

Peter Mottram (SysPete) E<lt>peter@sysnix.comE<gt>

=head1 COPYRIGHT

Copyright 2015- Pierre VIGIER

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut

