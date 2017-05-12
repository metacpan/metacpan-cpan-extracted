package Chloro::Trait::Role::Composite;
BEGIN {
  $Chloro::Trait::Role::Composite::VERSION = '0.06';
}

use Moose::Role;

use namespace::autoclean;

use Moose::Util::MetaRole;
use Moose::Util qw( does_role );

with 'Chloro::Trait::Role';

sub _merge_form_components {
    my $self = shift;

    $self->_merge('field');
    $self->_merge('group');
}

sub _merge {
    my $self = shift;
    my $thing = shift;

    my $pl_thing = $thing . 's';

    my @all;
    foreach my $role ( @{ $self->get_roles() } ) {
        if ( does_role( $role, 'Chloro::Trait::Role' ) ) {
            push @all, $role->$pl_thing();
        }
    }

    my %seen;

    foreach my $thing (@all) {
        my $name = $thing->name();

        if ( exists $seen{$name} ) {
            next if $seen{$name} == $thing;

            require Moose;
            Moose->throw_error( "Role '"
                    . $self->name()
                    . "' has encountered a Chloro $thing conflict "
                    . "during composition. This is a fatal error and "
                    . "cannot be disambiguated." );
        }

        $seen{$name} = $thing;
    }

    my $add_meth = 'add_' . $thing;

    foreach my $thing (@all) {
        $self->$add_meth($thing);
    }

    return keys %seen;
}

around apply_params => sub {
    my $orig = shift;
    my $self = shift;

    $self->$orig(@_);

    $self = Moose::Util::MetaRole::apply_metaroles(
        for            => $self,
        role_metaroles => {
            application_to_class =>
                ['Chloro::Trait::Application::ToClass'],
            application_to_role =>
                ['Chloro::Trait::Application::ToRole'],
        },
    );

    $self->_merge_form_components();

    return $self;
};

1;

# ABSTRACT: A trait that supports applying multiple roles at once



=pod

=head1 NAME

Chloro::Trait::Role::Composite - A trait that supports applying multiple roles at once

=head1 VERSION

version 0.06

=head1 DESCRIPTION

This trait is used to allow the application of multiple roles (one or more of
which contain Chloro fields or groups) to a class or role.

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

