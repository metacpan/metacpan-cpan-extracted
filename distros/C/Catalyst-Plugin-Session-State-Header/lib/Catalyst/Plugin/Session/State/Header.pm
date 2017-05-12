package Catalyst::Plugin::Session::State::Header;
use Moose;
use namespace::autoclean;
extends 'Catalyst::Plugin::Session::State';

use MRO::Compat;
use Catalyst::Utils ();

our $VERSION = '0.02';

sub extend_session_id {
    my ( $c, $sid, $expires ) = @_;

    $c->maybe::next::method( $sid, $expires );
}

sub set_session_id {
    my ( $c, $sid ) = @_;

    return $c->maybe::next::method($sid);
}

sub get_session_id {
    my $c = shift;

    my $path = uni_path($c->request->path());

    my $cfg = $c->_session_plugin_config();
    if ($cfg->{allowed_uri} && $path !~ m/$cfg->{allowed_uri}/s) {
        $c->log->debug("URI $path is not allowed for header authentication");
        return $c->maybe::next::method(@_);
    }

    if ($cfg->{auth_header} and  my $sid = $c->request->header($cfg->{auth_header})) {
        $c->log->debug("Header was found: $sid");
        if (!$c->validate_session_id($sid)) {
            $c->log->debug("Session id, that was provided in header, is invalid");
            return $c->maybe::next::method(@_);
        }
        return $sid;
    }
    return $c->maybe::next::method(@_);
}

sub delete_session_id {
    my ( $c, $sid ) = @_;

    $c->maybe::next::method($sid);
}


sub uni_path {
    my ($path) = @_;

    return '/' unless $path;
    $path =~ s|\/{2,}|/|gs;
    $path =~ s|^\/+||s;
    $path =~ s|\/+$||s;
    return '/' unless $path;
    $path = '/' . $path . '/';
    return $path;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Catalyst::Plugin::Session::State::Header - Manipulate session IDs by auth headers.

=head1 SYNOPSIS

    use Catalyst qw/Session Session::State::Header Session::Store::Foo/;
    ...;
    __PACKAGE__->config('Plugin::Session' => {
        auth_header => 'x-auth',
        allowed_uri => '^/api/',
    });

=head1 DESCRIPTION

In order for L<Catalyst::Plugin::Session> to work the session data needs to be stored on the server. To link session on server with client we need to pass somehow session_id to the server, and server should accept it.

This plugin accepts session_id using headers. It is usable for APIs, when we need to path auth information in the headers, for example, in x-auth header.

=head1 CONFIGURATION

=over 4

=item auth_header

Header name, in which authentication info should be passed. For example, x-auth.

=item allowed_uri

Regexp for URI validation. If specified, this plugin will be enabled only for paths matched by regexp that was provided. Otherwise, all URIs will be affected.

=back

=head1 METHODS

=over 4

=item extend_session_id

=item set_session_id

=item get_session_id

=item delete_session_id

=item uni_path

Returns unified catalyst path with heading and ending slashes and withoud slash repetitions.
Catalyst path ($c->request->path()) returns controller path as is, so, it path could be:
api///login/
api/login
api/login///

But for catalyst these paths are the same, so, this method will return /api/login/ for each of them.

=back

=head1 SEE ALSO

L<Catalyst>
L<Catalyst::Plugin::Session>
L<Catalyst::Plugin::Session::State::Cookie>
L<Catalyst::Plugin::Session::State::URI>

=head1 LICENSE

This program is free software, you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

