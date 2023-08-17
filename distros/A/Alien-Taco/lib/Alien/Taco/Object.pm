# Taco Perl object module.
# Copyright (C) 2013-2014 Graham Bell
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 NAME

Alien::Taco::Object - Taco Perl object module

=head1 SYNOPSIS

    my $obj = $taco->construct_object('ClassName', args => [...]);

    my $result = $obj->call_method('method_name', args => [...]);
    $obj->set_attribute('attribute_name', $value);
    my $value = $obj->get_attribute('attribute_name');

=head1 DESCRIPTION

This class is used to represent objects through by Taco actions.
Instances of this class will returned by methods of L<Alien::Taco>
objects and should not normally be constructed explicitly.

The objects reside on the server side and are referred to by instances
of this class by their object number.  When these instances are
destroyed the I<destroy_object> action is sent automatically.

=cut

package Alien::Taco::Object;

use strict;

our $VERSION = '0.003';

# new($taco_client, $object_number)
#
# Constructs a new instance of this class.  A reference to the Taco client
# is stored to allow actions to be sent via it.

sub new {
    my $class = shift;
    my $client = shift;
    my $number = shift;

    return bless {client => $client, number => $number}, $class;
}

# DESTROY
#
# Destructor method.  This invokes the _destroy_object method of
# the Taco client so that the object on the server side can be deleted.

sub DESTROY {
    my $self = shift;

    $self->{'client'}->_destroy_object($self->{'number'});
}

=head1 METHODS

=head2 Taco Methods

=over 4

=item call_method('method_name', [args => \@args], [kwargs => \%kwargs])

Invoke the given method on the object with the specified arguments
and keyword arguments.  The context (void / scalar / list) of this method
call is detected and sent as an action parameter.

=cut

sub call_method {
    my $self = shift;

    # Invoke this directly by the return command to
    # allow _call_method to detect the context.
    return $self->{'client'}->_call_method($self->{'number'}, @_);
}

=item get_attribute('attribute_name')

Retrieve the value of the given attribute.

=cut

sub get_attribute {
    my $self = shift;

    return $self->{'client'}->_get_attribute($self->{'number'}, @_);
}

# _number()
#
# Returns the object number identifying this object on the server side.
# This is an internal method for use by L<Alien::Taco> when sending
# a reference to this object as an action parameter.

sub _number {
    my $self = shift;

    return $self->{'number'};
}

=item set_attribute('attribute_name', $value)

Set the value of the given attribute.

=cut

sub set_attribute {
    my $self = shift;

    $self->{'client'}->_set_attribute($self->{'number'}, @_);
}

=back

=head2 Convenience Methods

=over 4

=item method('method_name')

Return a subroutine reference which calls the given function
with plain arguments only.  For example:

    my $ymd = $afd->method('ymd');
    print $ymd->('/'), "\n";

=cut

sub method {
    my $self = shift;
    my $name = shift;

    return sub {
        return $self->call_method($name, args => \@_);
    };
}

=back

=head2 JSON Methods

=over 4

=item TO_JSON

This method will be called by the JSON encoder to convert the object
to a hashref which is encodable as JSON.

=cut

sub TO_JSON {
    my $self = shift;
    return {_Taco_Object_ => $self->{'number'}};
}

1;

__END__

=back

=cut
