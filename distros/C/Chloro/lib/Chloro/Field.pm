package Chloro::Field;
BEGIN {
  $Chloro::Field::VERSION = '0.06';
}

use Moose;
use MooseX::StrictConstructor;

use namespace::autoclean;

use Chloro::Types qw( Bool CodeRef NonEmptySimpleStr Str Value );
use Moose::Util::TypeConstraints;

with 'Chloro::Role::FormComponent';

has type => (
    is       => 'ro',
    isa      => 'Moose::Meta::TypeConstraint',
    required => 1,
    init_arg => 'isa',
);

has default => (
    is        => 'ro',
    isa       => Value | CodeRef,
    predicate => 'has_default',
);

has is_required => (
    is       => 'ro',
    isa      => Bool,
    init_arg => 'required',
    default  => 0,
);

has is_secure => (
    is       => 'ro',
    isa      => Bool,
    init_arg => 'secure',
    default  => 0,
);

has extractor => (
    is      => 'ro',
    isa     => NonEmptySimpleStr,
    default => '_extract_field_value',
);

has validator => (
    is      => 'ro',
    isa     => NonEmptySimpleStr,
    default => '_errors_for_field_value',
);

override BUILDARGS => sub {
    my $class = shift;

    my $p = super();

    $p->{isa}
        = Moose::Util::TypeConstraints::find_or_create_isa_type_constraint(
        $p->{isa} );

    return $p;
};

sub generate_default {
    my $self   = shift;
    my $params = shift;
    my $prefix = shift;

    my $default = $self->default();

    return ref $default
        ? $self->$default( $params, $prefix )
        : $default;
}

# The Storable hooks are needed because the Moose::Meta::TypeConstraint object
# contains a code reference, and Storable will just die if it tries to
# serialize it. So we save the type's _name_ and look that up when thawing.
#
# Unfortunately, this requires poking around in the object guts a little bit.
sub STORABLE_freeze {
    my $self = shift;

    my %copy = %{$self};

    my $type = delete $copy{type};

    return q{}, \%copy, \( $type->name() );
}

sub STORABLE_thaw {
    my $self = shift;
    shift;
    shift;
    my $obj  = shift;
    my $type = shift;

    %{$self} = %{$obj};

    $self->{type}
        = Moose::Util::TypeConstraints::find_or_create_type_constraint( ${$type} );

    return;
}

# This exists mostly to make testing easier
sub dump {
    my $self = shift;

    return (
        type     => $self->type(),
        required => $self->is_required(),
        secure   => $self->is_secure(),
        ( $self->has_default() ? ( default => $self->default() ) : () ),
    );
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: A field in a form



=pod

=head1 NAME

Chloro::Field - A field in a form

=head1 VERSION

version 0.06

=head1 SYNOPSIS

See L<Chloro>.

=head1 DESCRIPTION

This class represents a field in a form.

=head1 METHODS

This class has the following methods:

=head2 Chloro::Field->new()

You'll probably make fields by using the C<field()> subroutine exported by
L<Chloro>, but you can make one using this constructor.

The constructor accepts the following parameters:

=over 4

=item * name

The name of the field. This is required.

=item * human_name

A more friendly version of the name. This defaults to the same value as
C<name>. This value will be used when generating error messages for this
field.

=item * isa

This must be a Moose type constraint. You can pass a
L<Moose::Meta::TypeConstraint> object, a type name, or a type created with
L<MooseX::Types>.

Just like with L<Moose> attributes, an unknown name is treated as a class name.

=item * default

The default value for the field. Like Moose attributes, this can either be a
non-reference value of a subroutine reference.

A subroutine reference will be called as a method on the field object, and
will receive two additional arguments.

The first argument is the parameter passed to the C<< $form->process() >>
method.

The second is the prefix for the field, if it is part of a group.

=item * required

A boolean indicating whether the field is required. Defaults to false.

=item * secure

A boolean indicating whether the field contains sensitive data. Defaults to
false.

=item * extractor

This is an optional method I<on the field's form> that will be used to extract
this field's value.

The extractor is expected to return a two element list. The first should be
the name of the field in the form, the second is the value.

=item * validator

This is an optional method I<on the field's form> that will be used to
validate this field's value.

=back

=head2 $field->name()

The name as passed to the constructor.

=head2 $field->human_name()

A more friendly name, which defaults to the same value as C<< $field->name()
>>.

=head2 $field->type()

This returns a L<Moose::Meta::TypeConstraint> object, based on the value
passed to the constructor in the C<isa> parameter.

=head2 $field->default()

The default, as passed to the constructor, if any.

=head2 $field->is_required()

Returns a boolean indicating whether the field is required.

=head2 $field->is_secure()

Returns a boolean indicating whether the field contains sensitive data.

=head2 $field->extractor()

Returns the method used to extract the field's data from the user-submitted
parameters. This defaults to L<_extract_field_value>, a method provided by
L<Chloro::Role::Form>.

=head2 $field->validator()

Returns the method used to extract the field's data from the user-submitted
parameters. This defaults to L<_errors_for_field_value>, a method provided by
L<Chloro::Role::Form>.

=head2 $field->generate_default( $params, $prefix )

Given the user-submitted parameters and an optional prefix, this method
returns a default value for the field. If the default is a subroutine
reference, that reference will be called with the parameters passed to this
method.

=head2 $field->dump()

Returns a data structure representing the field definition. This exists
primarily for testing.

=head1 ROLES

This class consumes the L<Chloro::Role::FormComponent> role.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__

