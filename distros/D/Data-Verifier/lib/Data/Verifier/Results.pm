package Data::Verifier::Results;
$Data::Verifier::Results::VERSION = '0.63';
use Moose;
use MooseX::Storage;

with 'MooseX::Storage::Deferred';

# ABSTRACT: Results of a Data::Verifier verify


has 'fields' => (
    is  => 'rw',
    isa => 'HashRef',
    traits => [ 'Hash' ],
    default => sub { {} },
    handles => {
        get_field => 'get',
        set_field => 'set',
        has_field => 'exists'
    }
);


sub get_original_value {
    my ($self, $key) = @_;

    my $f = $self->get_field($key);
    return undef unless defined($f);
    return $f->original_value;
}


sub get_post_filter_value {
    my ($self, $key) = @_;

    my $f = $self->get_field($key);
    return undef unless defined($f);
    return $f->post_filter_value;
}


sub get_value {
    my ($self, $key) = @_;

    my $f = $self->get_field($key);
    return undef unless defined($f);
    return $f->value;
}


sub get_values {
    my ($self, @keys) = @_;

    return map { $self->get_value($_) } @keys;
}


sub is_invalid {
    my ($self, $field) = @_;

    my $f = $self->get_field($field);

    return 0 unless defined($f);
    return $f->valid ? 0 : 1;
}


sub is_missing {
    my ($self, $field) = @_;

	return 0 unless $self->has_field($field);

    my $f = $self->get_field($field);

    return 1 unless defined($f);
    return 0;
}


sub is_valid {
    my ($self, $field) = @_;

    my $f = $self->get_field($field);

    return 0 unless defined($f);
    return $f->valid ? 1 : 0;
}


sub is_wrong {
    my ($self, $field) = @_;

    # return true if it is missing
    return 1 if $self->is_missing($field);
    # return 0 if it's not present at all
    return 0 if !defined($self->get_field($field));
    # lastly, check that it's valid
    return 1 if $self->is_invalid($field);

    # Nope, must be fine
    return 0;
}


sub merge {
    my ($self, $other) = @_;

    foreach my $f (keys %{ $other->fields }) {
        $self->set_field($f, $other->get_field($f));
    }
}


sub invalid_count {
    my ($self) = @_;

    return scalar($self->invalids);
}


sub invalids {
    my ($self) = @_;

    return grep(
        { my $field = $self->get_field($_); defined($field) && !$field->valid; }
        keys %{ $self->fields }
    );
}


sub missing_count {
    my ($self) = @_;

    return scalar($self->missings);
}


sub missings {
    my ($self) = @_;

    return grep(
        { my $field = $self->get_field($_); !defined($field) }
        keys %{ $self->fields }
    );
}


sub success {
    my ($self) = @_;

    if($self->missing_count || $self->invalid_count) {
        return 0;
    }

    return 1;
}


sub valids {
    my ($self) = @_;

    return grep(
        { my $field = $self->get_field($_); defined($field) && $field->valid; }
        keys %{ $self->fields }
    );
}


sub valid_count {
    my ($self) = @_;

    return scalar($self->valids);
}


sub valid_values {
    my ($self) = @_;

    return map { $_ => $self->get_value($_) } $self->valids;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Data::Verifier::Results - Results of a Data::Verifier verify

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

    $results->success; # no

    $results->is_invalid('name'); # no
    $results->is_invalid('age'); # yes

    $results->is_missing('name'); # no
    $results->is_missing('sign'); # yes

=head1 SERIALIZATION

Data::Verifier uses L<MooseX::Storage::Deferred> to allow quick and easy
serialization. So a quick call to C<freeze> will serialize this object into
JSON and C<thaw> will inflate it.  The only caveat is that we don't serialize
the C<value> attribute.  Since coercion allows you to make the result any type
you want, it can't reliably be serialized.  Use original value if you are
serializing Result objects and using them to refill forms or something.

  my $json = $results->freeze({ format => 'JSON' });
  # ...
  my $results = Data::Verifier::Results->thaw($json, { format => 'JSON' });

=head1 INTERNALS

This module has a hashref attribute C<fields>.  The keys are the names of the
fields from the profile.  The corresponding values are either C<undef> or a
L<Data::Verifier::Field> object.

The B<only> keys that will be populated in the Result object are those that were
listed in the profile.  Any arbitrary fields I<will not> be part of the result
object, as they were not part of the profile.  You should not query the result
object for the state of any arbitrary fields.  This will not throw any
exceptions, but it may not return the results you want if you query for
arbitrary field names.

=head1 ATTRIBUTES

=head2 fields

HashRef of fields in this Results object.

=head1 METHODS

=head2 get_field ($name)

Gets the field object, if it exists, for the name provided.

=head2 has_field ($name)

Returns true if the name in question is part of this result object.  This
should be true for any field that was in the profile.

=head2 set_field ($name)

Sets the field object (you shouldn't be doing this directly) for the name
provided.

=head2 get_original_value ($name)

Get the original value for the specified field.

=head2 get_post_filter_value ($name)

Get the post-filter value for the specified field.

=head2 get_value ($name)

Returns the value for the specified field.  The value may be different from
the one originally supplied due to filtering or coercion.

=head2 get_values (@names)

Same concept as C<get_value> but will return a list of respective values in
the same order in which you provide the names.

=head2 is_invalid ($name)

Returns true if the specific field is invalid.

=head2 is_missing ($name)

Returns true if the specified field is missing.

=head2 is_valid ($name)

Returns true if the field is valid.

=head2 is_wrong ($name)

Returns true if the value was required and is missing or if the value did not
pass it's type constraint.  This is a one-stop method for determining if the
field in question is "wrong".

=head2 merge ($other_results_object)

Merge an existing Data::Verifier::Results object into this one.

=head2 invalid_count

Returns the count of invalid fields in this result.

=head2 invalids

Returns a list of invalid field names.

=head2 missing_count

Returns the count of missing fields in this result.

=head2 missings

Returns a list of missing field names.

=head2 success

Returns true or false based on if the verification's success.

=head2 valids

Returns a list of keys for which we have valid values.

=head2 valid_count

Returns the number of valid fields in this Results.

=head2 valid_values

Returns a hash of valid values in the form of C<name => value>.  This is a
convenient method for instantiating Moose objects from your verified data.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Cold Hard Code, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
