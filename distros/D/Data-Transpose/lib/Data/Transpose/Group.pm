package Data::Transpose::Group;

use strict;
use warnings;

=head1 NAME

Data::Transpose::Group - Group class for Data::Transpose

=head1 SYNOPSIS

    $group = $tp->group('fullname', $tp->field('firstname'),
                                    $tp->field('lastname'));
    
=head1 METHODS

=head2 new

    $group = Data::Transpose::Group->new(name => 'mygroup',
        objects => [$field_one, $field_two]);

=cut

use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use namespace::clean;

has name => (is => 'rw',
             required => 1,
             isa => Str);

has objects => (is => 'ro',
                isa => ArrayRef[Object],
                required => 1);

has join => (is => 'rw',
             default => sub { ' ' },
             isa => Str);

has _output => (is => 'rwp',
               isa => Str,
              );

has target => (is => 'rw');

=head2 name

Set name of the group:

    $group->name('fullname');

Get name of the group:

    $group->name;

=head2 objects

Passed only to the constructor. Arrayref with the field objects.

=cut

sub _return_object_on_set {
    my ($orig, $self, $name) = @_;
    if (defined $name) {
        $orig->($self, $name);
        return $self;
    }
    return $orig->($self);
}

around name => \&_return_object_on_set;


=head2 fields

Returns field objects for this group:

    $group->fields;

=cut

sub fields {
    return shift->objects;
}

=head2 join

Set string for joining field values:

    $group->join(',');

Get string for joining field values:

    $group->join;

The default string is a single blank character.

=cut

around join => \&_return_object_on_set;
around target => \&_return_object_on_set;

=head2 value

Returns value for output:
    
    $output = $group->value;

With undefined argument, does not set the output to undef (because a
group always output a string), but apply the joining.

With a defined argument, does not perform the joining, but set the
output value.

=cut

sub value {
    my $self = shift;
    my $token;
    
    if (@_ and defined($_[0])) {
        $self->_set__output(shift);
    }
    else {
        # combine field values
        $self->_set__output(CORE::join($self->join,
                                     map {my $value = $_->value;
                                          defined $value ? $value : '';
                                     } @{$self->objects}));
    }
    
    return $self->_output;
}

=head2 target

Set target name for target operation:

    $group->target('name');

Get target name:

    $group->target;

=cut


=head1 LICENSE AND COPYRIGHT

Copyright 2012-2016 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
