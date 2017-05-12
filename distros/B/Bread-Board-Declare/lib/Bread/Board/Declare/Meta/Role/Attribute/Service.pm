package Bread::Board::Declare::Meta::Role::Attribute::Service;
BEGIN {
  $Bread::Board::Declare::Meta::Role::Attribute::Service::AUTHORITY = 'cpan:DOY';
}
{
  $Bread::Board::Declare::Meta::Role::Attribute::Service::VERSION = '0.16';
}
use Moose::Role;
Moose::Util::meta_attribute_alias('Service');
# ABSTRACT: attribute metarole for service attributes in Bread::Board::Declare

use Bread::Board::Types;
use Class::Load qw(load_class);

use Bread::Board::Declare::BlockInjection;
use Bread::Board::Declare::ConstructorInjection;
use Bread::Board::Declare::Literal;



has block => (
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => 'has_block',
);


# has_value is already a method
has literal_value => (
    is        => 'ro',
    isa       => 'Value',
    init_arg  => 'value',
    predicate => 'has_literal_value',
);


has lifecycle => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_lifecycle',
);


has dependencies => (
    is        => 'ro',
    isa       => 'Bread::Board::Service::Dependencies',
    coerce    => 1,
    predicate => 'has_dependencies',
);


has parameters => (
    is        => 'ro',
    isa       => 'Bread::Board::Service::Parameters',
    coerce    => 1,
    predicate => 'has_parameters',
);


has infer => (
    is  => 'ro',
    isa => 'Bool',
);


has constructor_name => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_constructor_name',
);


has associated_service => (
    is   => 'rw',
    does => 'Bread::Board::Service',
);

after attach_to_class => sub {
    my $self = shift;

    my %params = (
        associated_attribute => $self,
        name                 => $self->name,
        ($self->has_lifecycle
            ? (lifecycle => $self->lifecycle)
            : ()),
        ($self->has_dependencies
            ? (dependencies => $self->dependencies)
            : ()),
        ($self->has_parameters
            ? (parameters => $self->parameters)
            : ()),
        ($self->has_constructor_name
            ? (constructor_name => $self->constructor_name)
            : ()),
    );

    my $tc = $self->has_type_constraint ? $self->type_constraint : undef;

    my $service;
    if ($self->has_block) {
        if ($tc && $tc->isa('Moose::Meta::TypeConstraint::Class')) {
            %params = (%params, class => $tc->class);
            load_class($tc->class);
        }
        $service = Bread::Board::Declare::BlockInjection->new(
            %params,
            block => $self->block,
        );
    }
    elsif ($self->has_literal_value) {
        $service = Bread::Board::Declare::Literal->new(
            %params,
            value => $self->literal_value,
        );
    }
    elsif ($tc && $tc->isa('Moose::Meta::TypeConstraint::Class')) {
        load_class($tc->class);
        $service = Bread::Board::Declare::ConstructorInjection->new(
            %params,
            class => $tc->class,
        );
    }
    else {
        my $name = $self->name;
        $service = Bread::Board::Declare::BlockInjection->new(
            %params,
            block => sub {
                die "Attribute $name did not specify a service."
                  . " It must be given a value through the constructor or"
                  . " writer method before it can be resolved."
            },
        );
    }

    $self->associated_service($service);
};

after _process_options => sub {
    my $class = shift;
    my ($name, $opts) = @_;

    return unless exists $opts->{default}
               || exists $opts->{builder};
    return unless exists $opts->{class}
               || exists $opts->{block}
               || exists $opts->{value};

    # XXX: uggggh
    return if grep { $_ eq 'Moose::Meta::Attribute::Native::Trait::String'
                  || $_ eq 'Moose::Meta::Attribute::Native::Trait::Counter' }
              @{ $opts->{traits} };

    my $exists = exists($opts->{default}) ? 'default' : 'builder';
    die "$exists is not valid when Bread::Board service options are set";
};

around get_value => sub {
    my $orig = shift;
    my $self = shift;
    my ($instance) = @_;

    return $self->$orig($instance)
        if $self->has_value($instance);

    my $val = $instance->get_service($self->name)->get;

    if ($self->has_type_constraint) {
        $val = $self->type_constraint->coerce($val)
            if $self->should_coerce;

        $self->verify_against_type_constraint($val, instance => $instance);
    }

    if ($self->should_auto_deref) {
        if (ref($val) eq 'ARRAY') {
            return wantarray ? @$val : $val;
        }
        elsif (ref($val) eq 'HASH') {
            return wantarray ? %$val : $val;
        }
        else {
            die "Can't auto_deref $val.";
        }
    }
    else {
        return $val;
    }
};

around _inline_instance_get => sub {
    my $orig = shift;
    my $self = shift;
    my ($instance) = @_;
    return 'do {' . "\n"
            . 'my $val;' . "\n"
            . 'if (' . $self->_inline_instance_has($instance) . ') {' . "\n"
                . '$val = ' . $self->$orig($instance) . ';' . "\n"
            . '}' . "\n"
            . 'else {' . "\n"
                . '$val = ' . $instance . '->get_service(\'' . $self->name . '\')->get;' . "\n"
                . join("\n", $self->_inline_check_constraint(
                    '$val',
                    '$type_constraint',
                    '$type_message',
                )) . "\n"
            . '}' . "\n"
            . '$val' . "\n"
        . '}';
};

no Moose::Role;

1;

__END__

=pod

=head1 NAME

Bread::Board::Declare::Meta::Role::Attribute::Service - attribute metarole for service attributes in Bread::Board::Declare

=head1 VERSION

version 0.16

=head1 DESCRIPTION

This role adds functionality to the attribute metaclass for
L<Bread::Board::Declare> objects.

=head1 ATTRIBUTES

=head2 block

The block to use when creating a L<Bread::Board::BlockInjection> service.

=head2 literal_value

The value to use when creating a L<Bread::Board::Literal> service. Note that
the parameter that should be passed to C<has> is C<value>.

=head2 lifecycle

The lifecycle to use when creating the service. See L<Bread::Board::Service>
and L<Bread::Board::LifeCycle>.

=head2 dependencies

The dependency specification to use when creating the service. See
L<Bread::Board::Service::WithDependencies>.

=head2 parameters

The parameter specification to use when creating the service. See L<Bread::Board::Service::WithParameters>.

=head2 infer

If true, the dependency list will be inferred as much as possible from the
attributes in the class. See L<Bread::Board::Manual::Concepts::Typemap> for
more information. Note that this is only valid for constructor injection
services.

=head2 constructor_name

The constructor name to use when creating L<Bread::Board::ConstructorInjection>
services. Defaults to C<new>.

=head2 associated_service

The service object that is associated with this attribute.

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
