package Catalyst::Plugin::Session::Manager::Client::Rewrite;
use strict;
use warnings;

use base qw/Catalyst::Plugin::Session::Manager::Client/;

use URI::Find;

our $SESSIONID = "SESSIONID";

sub set {
    my ( $self, $c ) = @_;
    my $redirect = $c->response->redirect;
    $c->response->redirect( $self->uri($c, $redirect) ) if $redirect;
    my $sid = $c->sessionid or return;
    my $finder = URI::Find->new(
        sub {
            my ( $uri, $orig ) = @_;
            my $base = $c->request->base;
            return $orig unless $orig =~ /^$base/;
            return $orig if $uri->path =~ /\/-\//;
            return $self->uri($c, $orig);
        }
    );
    $finder->find( \$c->res->{body} ) if $c->res->body;
}

sub get {
    my ( $self, $c ) = @_;
    $c->request->param( $self->sessionid_name ) || undef;
}

sub sessionid_name {
    my $self = shift;
    return $self->{config}{name} || $SESSIONID;
}

sub uri {
    my ( $self, $c, $uri ) = @_;
    if ( my $sid = $c->sessionid ) {
        $uri = URI->new($uri);
        $uri->query_form($uri->query_form, $self->sessionid_name, $sid);
        return $uri->as_string;
    }
    return $uri;
}

1;
__END__

=head1 NAME

Catalyst::Plugin::Session::Manager::Client::Rewrite - handle sessonid with rewriting URL

=head1 SYNOPSIS

    use Catalyst qw/Session::Manager/;

    MyApp->config->{session} = {
        client => 'Rewrite',
        name   => 'SESSIONID',
    };

=head1 DESCRIPTION

This module allows you to handle sessionid with rewriting URL.

=head1 CONFIGURATION

=over 4

=item name

'SESSIONID' is set by default.

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

