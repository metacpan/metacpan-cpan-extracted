package Bread::Board::Declare::Role::Object;
BEGIN {
  $Bread::Board::Declare::Role::Object::AUTHORITY = 'cpan:DOY';
}
{
  $Bread::Board::Declare::Role::Object::VERSION = '0.16';
}
use Moose::Role;

use Moose::Util 'does_role';

has name => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { shift->meta->name },
);

sub BUILD { }
after BUILD => sub {
    my $self = shift;

    my $meta = Class::MOP::class_of($self);

    my %seen = (
        map { $_->class => $_->name }
            grep { $_->does('Bread::Board::Service::WithClass') && $_->has_class }
                 $meta->get_all_services
    );
    for my $service ($meta->get_all_services) {
        if ($service->isa('Bread::Board::Declare::BlockInjection')) {
            Scalar::Util::weaken(my $weakself = $self);
            my $block = $service->block;
            $self->add_service(
                $service->clone(
                    block => sub {
                        $block->(@_, $weakself)
                    },
                )
            );
        }
        elsif ($service->isa('Bread::Board::Declare::ConstructorInjection')
            && $service->associated_attribute->infer
            && (my $meta = Class::MOP::class_of($service->class))) {
            my $inferred = Bread::Board::Service::Inferred->new(
                current_container => $self,
                service           => $service->clone,
                infer_params      => 1,
            )->infer_service($service->class, \%seen);

            $self->add_service($inferred);
            $self->add_type_mapping_for($service->class, $inferred);
        }
        else {
            $self->add_service($service->clone);
        }
    }

    for my $attr (grep { does_role($_, 'Bread::Board::Declare::Meta::Role::Attribute::Container') } $meta->get_all_attributes) {
        my $container;
        if ($attr->has_value($self) || $attr->has_default || $attr->has_builder) {
            $container = $attr->get_value($self);
            $container->name($attr->name);
        }
        else {
            my $dependencies = $attr->has_dependencies
                ? $attr->dependencies
                : {};

            if (!exists $dependencies->{name}) {
                my $name_dep = Bread::Board::Dependency->new(
                    service => Bread::Board::Literal->new(
                        name  => '__ANON__',
                        value => $attr->name,
                    ),
                );
                $dependencies->{name} = $name_dep;
            }

            my $s = Bread::Board::ConstructorInjection->new(
                name         => '__ANON__',
                parent       => $self,
                class        => $attr->type_constraint->class,
                dependencies => $dependencies,
            );
            # need to clone this here to ensure the dependencies are also
            # cloned
            $container = $s->clone->get;
        }
        $self->add_sub_container($container);
    }
};

no Moose::Role;


1;

__END__

=pod

=head1 NAME

Bread::Board::Declare::Role::Object

=head1 VERSION

version 0.16

=for Pod::Coverage BUILD

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
