package Bolts::Meta::Attribute::Traits::Initializer;
$Bolts::Meta::Attribute::Traits::Initializer::VERSION = '0.143171';
# ABSTRACT: Build an attribute with an initializer

use Moose::Role;
use Safe::Isa;

Moose::Util::meta_attribute_alias('Bolts::Initializer');


# TODO Make this into a helper class so that other kinds of init can be added
# and customized later.
use Moose::Util::TypeConstraints;
has init_type => (
    is          => 'ro',
    isa         => enum([qw( Array Scalar )]),
    required    => 1,
    default     => 'Scalar',
);
no Moose::Util::TypeConstraints;


has special_initializer => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has _original_default => (
    is          => 'rw',
    predicate   => '_has_original_default',
);

before install_accessors => sub {
    my $self = shift;
    my $meta = $self->associated_class;

    $meta->add_attribute($self->special_initializer => (
        is       => 'ro',
        required => $self->is_required,
        init_arg => $self->name,
        ($self->_has_original_default ? (
            default  => $self->_original_default
        ) : ()),
    ));
};

before _process_options => sub {
    my ($self, $name, $options) = @_;

    # Having these here is probably a sign that we're doing this wrong.
    # Should probably just have the default call some predefined subroutine
    # instead and skip these bits here.
    $options->{special_initializer} //= '_' . $name . '_initializer';
    $options->{init_type}           //= 'Scalar';

    my $_initializer = $options->{special_initializer};

    $options->{_original_default} = delete $options->{default}
        if exists $options->{default};

    $options->{init_arg}  = undef;
    $options->{lazy}      = 1;

    if ($options->{init_type} eq 'Scalar') {
        $options->{default} = sub {
            my $self = shift;

            my $init = $self->$_initializer;
            if ($init->$_isa('Bolts::Meta::Initializer')) {
                return $self->initialize_value($init->get);
            }
            else {
                return $init;
            }
        };
    }
    else {
        $options->{default} = sub {
            my $self = shift;

            my @values;
            my $init_array = $self->$_initializer;
            for my $init (@$init_array) {
                if ($init->$_isa('Bolts::Meta::Initializer')) {
                    push @values, $self->initialize_value($init->get);
                }
                else {
                    push @values, $init;
                }
            }

            return \@values;
        };
    }
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bolts::Meta::Attribute::Traits::Initializer - Build an attribute with an initializer

=head1 VERSION

version 0.143171

=head1 DESCRIPTION

Sometimes it can be handy to partially break inversion of control to allow an object some control over it's own destiny. This attribute, given the short alias L<Bolts::Initializer>, can help you do that.

See L<Bolts::Role::Initializer> for details and a synopsis.

=head1 ATTRIBUTES

=head2 init_type

This is the type of initialization to perform on the intializer. It may be set to either "Array" or "Scalar" and defaults to "Scalar".

=over

=item Scalar

The initializer is given as a single value. Either the actual value to be passed through or a L<Bolts::Meta::Initializer> object.

=item Array

The initializer is given as an array reference of values. Each element of the array may be a L<Bolts::Meta::Initializer> object or a real object to place in the array as is.

=back

=head2 special_initializer

This is the name of the secondary attribute to use as the hidden initializer attribute. It defaults to C<<"_${name}_initializer">>, where C<<${name}>> is the name of this attribute.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
