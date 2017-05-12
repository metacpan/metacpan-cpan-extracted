package Chloro::Result::Group;
BEGIN {
  $Chloro::Result::Group::VERSION = '0.06';
}

use Moose;
use MooseX::StrictConstructor;

use namespace::autoclean;

use Chloro::Error::Field;
use Chloro::Types qw( Bool NonEmptyStr );
use List::AllUtils qw( any );

with qw( Chloro::Role::Result Chloro::Role::ResultSet );

has group => (
    is       => 'ro',
    isa      => 'Chloro::Group',
    required => 1,
);

has key => (
    is       => 'ro',
    isa      => NonEmptyStr,
    required => 1,
);

has prefix => (
    is       => 'ro',
    isa      => NonEmptyStr,
    required => 1,
);

has is_valid => (
    is       => 'ro',
    isa      => Bool,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_is_valid',
);

sub _build_is_valid {
    my $self = shift;

    return 0 if any { ! $_->is_valid() } $self->_result_values();

    return 1;
}

sub key_value_pairs {
    my $self        = shift;
    my $skip_secure = shift;

    return map { $_->key_value_pairs() }
        grep { $skip_secure ? !$_->field()->is_secure() : 1 }
        $self->_result_values();
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: A result for a single group



=pod

=head1 NAME

Chloro::Result::Group - A result for a single group

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    my $group_result = $resultset->result_for('group');

    for my $field_result ( $group_result->results() ) {
        print $field_result->field()->name() . ' = ' . $field_result->value();
    }

=head1 DESCRIPTION

This class represents the result for a single repetition of a group after
processing user-submitted data.

A group result is like a miniature L<Chloro::ResultSet> object, and shares
some methods with that class, because it contains the results for more than
one field.

=head1 METHODS

This class has the following methods:

=head2 Chloro::Result::Group->new()

The constructor accepts the following arguments:

=over 4

=item * group

The L<Chloro::Group> object for this result.

=item * key

The key associated with this group. This is a single value from the values in
the associated L<Chloro::Group> object's C<repetition_key> field.

=item * prefix

The prefix for each field in this group. This will be the group name and key
separated by a period ("."), something like "phone_number.42".

=item * results

This should be a hash reference where the keys are field names and the values
are L<Chloro::Result::Field> objects.

=back

=head2 $result->results()

Returns a list of L<Chloro::Result::Field> objects for the fields associated
with this repetition of the group.

=head2 $result->result_for('field')

Given a field name, returns the L<Chloro::Result::Field> object for that
field. Note that for this API, you can simply pass the field's name without a
group prefix.

=head2 $result->key()

Returns the key associated with this group result.

=head2 $result->prefix()

Returns the field prefix for this group result.

=head2 $result->is_valid()

This returns true if none of the fields in this group's result have any
errors.

=head2 $result->key_value_pairs()

Returns the result as a key/value pair, where the keys are field names
(without prefixes).

=head1 ROLES

This class does the L<Chloro::Role::Result> and L<Chloro::Role::ResultSet>
role.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__

