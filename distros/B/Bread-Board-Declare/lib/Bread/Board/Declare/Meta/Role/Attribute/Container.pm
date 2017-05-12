package Bread::Board::Declare::Meta::Role::Attribute::Container;
BEGIN {
  $Bread::Board::Declare::Meta::Role::Attribute::Container::AUTHORITY = 'cpan:DOY';
}
{
  $Bread::Board::Declare::Meta::Role::Attribute::Container::VERSION = '0.16';
}
use Moose::Role;
Moose::Util::meta_attribute_alias('Container');
# ABSTRACT: attribute metarole for container attributes in Bread::Board::Declare

use Class::Load 'load_class';



has dependencies => (
    is        => 'ro',
    isa       => 'Bread::Board::Service::Dependencies',
    coerce    => 1,
    predicate => 'has_dependencies',
);

after attach_to_class => sub {
    my $self = shift;

    my $tc = $self->type_constraint;
    if ($tc && $tc->isa('Moose::Meta::TypeConstraint::Class')) {
        load_class($tc->class);
        confess "Subcontainers must inherit from Bread::Board::Container"
            unless $tc->class->isa('Bread::Board::Container');
    }
    else {
        confess "Attributes for subcontainers must specify a class type constraint";
    }
};

around get_value => sub {
    my $orig = shift;
    my $self = shift;
    my ($instance) = @_;

    return $self->$orig($instance)
        if $self->has_value($instance)
        || $self->has_default
        || $self->has_builder;

    my $val = $instance->get_sub_container($self->name);

    if ($self->has_type_constraint) {
        $val = $self->type_constraint->coerce($val)
            if $self->should_coerce;

        $self->verify_against_type_constraint($val, instance => $instance);
    }

    return $val;
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
                . '$val = ' . $instance . '->get_sub_container(\'' . $self->name . '\');' . "\n"
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

Bread::Board::Declare::Meta::Role::Attribute::Container - attribute metarole for container attributes in Bread::Board::Declare

=head1 VERSION

version 0.16

=head1 DESCRIPTION

This attribute trait indicates that the attribute (in a
L<Bread::Board::Declare> class) contains a subcontainer rather than a service.
It must be specified explicitly (or else a service that happens to return a
container will be created):

  has attr => (
      traits => ['Container'],
      is     => 'ro',
      isa    => 'Bread::Board::Container',
  );

Container attributes (unlike service attributes) can have defaults and
builders, allowing you to also define subcontainers inline when desired, as in:

  has attr => (
      traits  => ['Container'],
      is      => 'ro',
      isa     => 'Bread::Board::Container',
      default => sub {
          container Foo => as {
              service Bar => 'BAR';
          };
      }
  );

=head1 ATTRIBUTES

=head2 dependencies

If no default or builder is supplied, the type constraint will be used to
create a container instance automatically (using a temporary
L<ConstructorInjection|Bread::Board::ConstructorInjection> service). This is
the dependency specification to use for that temporary service.

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
