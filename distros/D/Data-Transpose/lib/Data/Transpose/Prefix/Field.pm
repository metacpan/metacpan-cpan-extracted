package Data::Transpose::Prefix::Field;

use strict;
use warnings;
use Moo;

=head1 NAME

Data::Transpose::Prefix::Field - Field class with prefix for Data::Transpose

=head1 SYNOPSIS

     $field = Data::Transpose::Prefix::Field->new(
        prefix => 'billing_',
        name => 'email',

=head1 DESCRIPTION

This is a subclass of L<Data::Transpose::Field>.

=head1 ATTRIBUTES

=over 4

=item prefix

Prefix for the field name.

=back

=head1 METHODS

=head2 target

Sets or get the target.

     $field->target('email');

The return value includes the prefix, e.g.
C<billing_email>.

=cut

extends 'Data::Transpose::Field';

has prefix => (
    is => 'ro',
    required => 1,
);

has _target => (
    is => 'rwp',
);

sub target {
    my ($self, $target) = @_;

    if ($target) {
        # setter
        $self->_set__target($target);
    }

    if ($self->_target) {
        return $self->prefix . $self->_target;
    }
    else {
        return $self->prefix . $self->name;
    }
};

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2016 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
