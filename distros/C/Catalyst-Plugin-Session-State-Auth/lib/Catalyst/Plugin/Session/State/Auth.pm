package Catalyst::Plugin::Session::State::Auth;
use Moose;
use MRO::Compat;
use HTTP::Headers::Util qw(split_header_words);

use namespace::clean -except => 'meta';

our $VERSION = '0.0005';

extends 'Catalyst::Plugin::Session::State';
with 'MooseX::Emulate::Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw/_sessionid_from_auth_signature/);

sub get_session_id {
    my ( $c, @args ) = @_;
    return $c->_sessionid_from_auth_signature || $c->maybe::next::method(@args);
}

sub delete_session_id {
    my ( $c, @args ) = @_;
    $c->_sessionid_from_auth_signature(undef);
    $c->maybe::next::method(@args);
}

sub finalize {
    my $c = shift;
    return $c->maybe::next::method(@_);
}

sub prepare_path {
    my $c = shift;

    $c->maybe::next::method(@_);

    if ( $c->request->header('authorization') ){
        my @values     = split_header_words( $c->request->header('authorization') );
        my $signature  = $values[-1][-1];
        $c->_sessionid_from_auth_signature($signature);
        $c->_tried_loading_session_id(0);
        $c->log->debug(qq/Found sessionid "$signature" in MAC authentication/)
          if $c->debug;
    }
}

__PACKAGE__

__END__

1;

=head1 NAME

Catalyst::Plugin::Session::State::Auth -
Use signature in HTTP MAC authentication scheme to pass the session id between requests

=head1 SYNOPSIS
    In MyApp.pm
    use Catalyst qw/
      Session
      Session::State::Auth
      Session::Store::Foo
      /;

=head1 DESCRIPTION

In your HTTP request
Authorization: MAC token="h480djs93hd8",
                   timestamp="137131200",
                   nonce="dj83hs9s",
                   signature="kDZvddkndxvhGRXZhvuDjEWhGeE="

In order for L<Catalyst::Plugin::Session> to work,
Use the mac signature to pass your sessionid,
and the session data needs to be stored on the server.

Note that this pre-alpha version has no way to rewrite outgoing data.

=head1 METHODS

=head1 BUGS

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Plugin::Session>,L<Catalyst::Plugin::Session::State::URI>.

=head1 AUTHOR

Warachet Samtalee (zdk)

This module is derived from L<Catalyst::Plugin::Session::State::URI> code.

=head1 COPYRIGHT & LICENSE

Copyright 2011 the above author(s).

This sofware is free software, and is licensed under the same terms as perl itself.

=cut
