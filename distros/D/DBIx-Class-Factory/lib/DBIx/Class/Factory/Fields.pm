package DBIx::Class::Factory::Fields;

use strict;
use warnings;

=encoding utf8

=head1 NAME

DBIx::Class::Factory::Fields - fields for DBIx::Class::Factory class

=head1 DESCRIPTION

Every callback used in L<DBIx::Class::Factory> gets a C<DBIx::Class::Factory::Fields> instance as an argument.

=cut

=head1 METHODS

=over

=item B<new>

Constructor. You shouldn't call it explicitly.

=cut

sub new {
    my ($class, @params) = @_;

    my $instance = bless({}, $class);
    $instance->_init(@params);

    return $instance;
}

=item B<all>

Returns hashref with all fields that are not excluded

=cut

sub all {
    my ($self) = @_;

    my %result;
    foreach my $field (keys %{$self->{init_fields}}) {
        unless (defined $self->{exclude_set}->{$field}) {
            $result{$field} = $self->get($field);
        }
    }

    return \%result;
}

=item B<get>

Get the value of the field.

    $fields->get('name');

=cut

sub get {
    my ($self, $field) = @_;

    unless (exists $self->{processed_fields}->{$field}) {
        my $value = $self->{init_fields}->{$field};

        if (ref($value) eq 'CODE') {
            $value = $value->($self);
        }

        $self->{processed_fields}->{$field} = $value;
    }

    return $self->{processed_fields}->{$field};
}

=back

=cut

# PRIVATE METHODS

sub _init {
    my ($self, $fields, $exclude_set) = @_;

    $self->{init_fields} = $fields;
    $self->{processed_fields} = {};
    $self->{exclude_set} = $exclude_set;

    return;
}

=head1 AUTHOR

Vadim Pushtaev, C<pushtaev@cpan.org>

=head1 BUGS AND FEATURES

Bugs are possible, feature requests are welcome. Write me as soon as possible.

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Vadim Pushtaev.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
