package App::Controller::A;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }
with qw(
           CatalystX::Component::Traits
	   Catalyst::Component::ContextClosure
);


=head1 NAME

App::Controller::A - Catalyst Controller extended by TraitFor

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    #$c->response->body('Matched App::Controller::A in A.');
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
