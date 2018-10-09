package Catapulse::Web::Controller::Test;
$Catapulse::Web::Controller::Test::VERSION = '0.01';
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Catapulse::Module::Test - Catalyst Controller

=head1 VERSION

version 0.01

=head1 DESCRIPTION

Catalyst Controller to test Catapulse

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

}


__PACKAGE__->meta->make_immutable;

=encoding utf8

=head1 SEE ALSO

L<Catapulse>

=head1 AUTHOR

Daniel Brosseau, 2018, <dab@catapulse.org>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
