package MyApp::Controller::A;
use Moose;
use namespace::autoclean;
use MyLib qw(ping);

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

MyApp::Controller::A - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body( ping() );
}



=encoding utf8

=head1 AUTHOR

dab,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
