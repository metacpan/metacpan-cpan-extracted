package Data::Verifier::Field;
$Data::Verifier::Field::VERSION = '0.63';
use Moose;
use MooseX::Storage;

with 'MooseX::Storage::Deferred';

# ABSTRACT: Field from a Data::Verifier profile


has original_value => (
    is => 'rw',
    isa => 'Maybe[Str|ArrayRef|HashRef]',
    predicate => 'has_original_value'
);


has post_filter_value => (
    is => 'rw',
    isa => 'Maybe[Str|ArrayRef|HashRef]',
    predicate => 'has_post_filter_value'
);


has reason => (
    is => 'rw',
    isa => 'Str',
    predicate => 'has_reason'
);


has valid => (
    is => 'rw',
    isa => 'Bool',
    default => 1
);


has value => (
    traits => [ 'DoNotSerialize' ],
    is => 'rw',
    isa => 'Any',
    clearer => 'clear_value'
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Data::Verifier::Field - Field from a Data::Verifier profile

=head1 VERSION

version 0.63

=head1 SYNOPSIS

    use Data::Verifier;

    my $dv = Data::Verifier->new(profile => {
        name => {
            required    => 1,
            type        => 'Str',
            filters     => [ qw(collapse trim) ]
        },
        age  => {
            type        => 'Int'
        },
        sign => {
            required    => 1,
            type        => 'Str'
        }
    });

    my $results = $dv->verify({
        name => 'Cory', age => 'foobar'
    });


    my $field = $results->get_field('name');
    print $field->value;

=head1 DESCRIPTION

Data::Verifier::Field provides all post-verification information on a given
field.

=head1 ATTRIBUTES

=head2 original_value

The string value of the field before any filters or coercion.  This will
survive serialization whereas value will not.

=head2 post_filter_value

The string value of the field before after filters but before coercion. This
will survive serialization whereas value will not.

=head2 reason

If this field is invalid then this attribute should contain a "reason".  Out
of the box it will always contain a string.  One of:

=over 4

=item B<dependent>

A dependent check failed.

=item B<has_coerced_value>

Predicate for the C<coerced_value> attribute.

=item B<max_length>

The value was larger than the field's max length.

=item B<min_length>

The value was shorter than the field's min length.

=item B<post_check>

The post check failed.

=item B<type_constraint>

The value did not pass the type constraint.

=item B<derived>

The value failed because a value derived from it failed.

=back

=head2 valid

Boolean value representing this fields validity.

=head2 value

The value of this field.  This will not be present if serialized, as it could
be any value, some of which we may not know how to Serialize.  See
C<original_value>.

=head1 METHODS

=head2 has_original_value

Predicate that returns true if this field has an original value.

=head2 has_post_filter_value

Predicate that returns true if this field has a post filter value.

=head2 has_reason

Predicate that returns true if this field has a reason.

=head2 clear_value

Clears the value attribute.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Cold Hard Code, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
