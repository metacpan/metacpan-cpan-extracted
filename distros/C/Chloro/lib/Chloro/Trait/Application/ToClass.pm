package Chloro::Trait::Application::ToClass;
BEGIN {
  $Chloro::Trait::Application::ToClass::VERSION = '0.06';
}

use Moose::Role;

use namespace::autoclean;

use Moose::Util qw( does_role );

with 'Chloro::Trait::Application';

around apply => sub {
    my $orig  = shift;
    my $self  = shift;
    my $role  = shift;
    my $class = shift;

    unless ( does_role( $class, 'Chloro::Trait::Class' ) ) {
        $class = Moose::Util::MetaRole::apply_metaroles(
            for             => $class,
            class_metaroles => {
                class => ['Chloro::Trait::Class'],
            },
        );
    }

    unless ( $class->does_role('Chloro::Role::Form') ) {
        Moose::Util::MetaRole::apply_base_class_roles(
            for   => $class,
            roles => ['Chloro::Role::Form'],
        );
    }

    $self->$orig( $role, $class );
};

sub _apply_form_components {
    my $self  = shift;
    my $role  = shift;
    my $class = shift;

    foreach my $field ( $role->fields() ) {
        next if $class->has_field( $field->name() );

        $class->add_field($field);
    }

    foreach my $group ( $role->groups() ) {
        next if $class->has_group( $group->name() );

        $class->add_group($group);
    }
}

1;

# ABSTRACT: A trait that supports applying Chloro fields and groups to classes



=pod

=head1 NAME

Chloro::Trait::Application::ToClass - A trait that supports applying Chloro fields and groups to classes

=head1 VERSION

version 0.06

=head1 DESCRIPTION

This trait is used to allow the application of roles containing Chloro fields
and groups.

=head1 BUGS

See L<Chloro> for details.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__

