#############################################################################
#
# Small little class representing a changelog entry
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
#
# Copyright (c) 2009,2010 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Archive::RPM::ChangeLogEntry;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
use MooseX::Types::DateTimeX ':all';

use overload '""' => sub { shift->as_string };

use DateTime;

our $VERSION = '0.07';

has text => (is => 'ro', isa => 'Str', required => 1);
has time => (is => 'ro', isa => DateTime, coerce => 1, required => 1);
has name => (is => 'ro', isa => 'Str', required => 1);

sub as_string {
    my $self = shift @_;

    my ($name, $time) = ($self->name, $self->time);

    return "* $time $name\n" . $self->text;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Archive::RPM::ChangeLogEntry - A RPM %changelog entry

=head1 DESCRIPTION

Basic bits representing an RPM changelog entry.

=head1 SUBROUTINES/METHODS

=over 4

=item B<text>

The text of the changelog entry.

=item B<time>

The time of the entry.

=item B<name>

The "name" part of the changelog entry.  Note that this is ovten overloaded
with the version/rel of the package it applies to.

=item B<as_string>

Returns the properly laid-out changelog; this is also the function called when
this object is used in a string context (aka "stringified").

=back

=head1 SEE ALSO

L<Archive::RPM>

=head1 AUTHOR

Chris Weyl  <cweyl@alumni.drew.edu>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, 2010 Chris Weyl <cweyl@alumni.drew.edu>

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the 

    Free Software Foundation, Inc.
    59 Temple Place, Suite 330
    Boston, MA  02111-1307  USA

=cut

# fin...
