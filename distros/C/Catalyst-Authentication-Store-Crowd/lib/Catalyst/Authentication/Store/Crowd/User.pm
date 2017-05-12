package Catalyst::Authentication::Store::Crowd::User;

use Moose;
extends 'Catalyst::Authentication::User';

has 'info' => (is => 'ro', isa => 'HashRef');

sub id { shift->get('name'); }

sub supported_features { return { session => 1 }; }

sub get {
    my ($self, $field) = @_;
    return $self->info->{$field};
}

1;

__END__

=pod

=head1 NAME

Catalyst::Authentication::Store::Crowd::User - A user object representing a Crowd user account

=head1 METHODS

=head2 supported_features

Method using for enabling session

=head2 get

Get user info attributes
Ex. $user->get('display-name')

=head1 AUTHOR

Keerati Thiwanruk, E<lt>keerati.th@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Keerati Thiwanruk

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
