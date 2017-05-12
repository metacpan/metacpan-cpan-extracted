package Catalyst::Plugin::Session::Manager::Client::Cookie;
use strict;
use warnings;
use base qw/Catalyst::Plugin::Session::Manager::Client/;

our $EXPIRES = 60 * 60;

sub set {
    my ( $self, $c ) = @_;
    my $sid = $c->sessionid or return;
    my $set = 1;
    if ( my $cookie = $c->request->cookies->{session} ) {
        $set = 0 if $cookie->value eq $sid;
    }
    if ( $set ) {
        $c->response->cookies->{session} = {
            value   => $sid,
            expires => '+'. $self->expires .'s',
        };
    }
}

sub get {
    my ( $self, $c ) = @_;
    if ( my $cookie = $c->request->cookies->{session} ) {
        return $cookie->value;
    }
}

sub expires {
    my $self = shift;
    $self->{config}{expires} || $EXPIRES;
}

1;
__END__

=head1 NAME

Catalyst::Plugin::Session::Manager::Client::Cookie - stores session id with cookie

=head1 SYNOPSIS

    use Catalyst qw/Session::Manager/;

    MyApp->config->{session} = {
        client  => 'Cookie',
        expires => 3600,
    };

=head1 DESCRIPTION

This module allows you to store session id in your browser's cookie.

=head1 CONFIGURATION

=over 4

=item expires

3600 is set by default.

=item domain

Override the domain for the cookie

=back

=head1 SEE ALSO

L<Catalyst>

L<Catalyst::Plugin::Session::Manager>

=head1 AUTHOR

Lyo Kato E<lt>lyo.kato@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

