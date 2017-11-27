## no critic (Moose::RequireMakeImmutable)
package Chloro::Trait::Application::ToRole;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.07';

use Moose::Role;

use namespace::autoclean;

with 'Chloro::Trait::Application';

around apply => sub {
    my $orig  = shift;
    my $self  = shift;
    my $role1 = shift;
    my $role2 = shift;

    unless ( does_role( $role2, 'Chloro::Trait::Role' ) ) {
        $role2 = Moose::Util::MetaRole::apply_metaroles(
            for            => $role2,
            role_metaroles => {
                role => ['Chloro::Trait::Role'],
                application_to_class =>
                    ['Chloro::Trait::Application::ToClass'],
                application_to_role => ['Chloro::Trait::Application::ToRole'],
            },
        );
    }

    $self->$orig( $role1, $role2 );
};

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _apply_form_components {
    my $self  = shift;
    my $role1 = shift;
    my $role2 = shift;

    foreach my $field ( $role1->fields() ) {
        if ( $role2->has_field( $field->name() ) ) {

            require Moose;
            Moose->throw_error( q{Role '}
                    . $role1->name()
                    . q{' has encountered a field conflict }
                    . 'during composition. This is fatal error and cannot be disambiguated.'
            );
        }
        else {
            $role2->add_field($field);
        }
    }

    foreach my $group ( $role1->groups() ) {
        if ( $role2->has_group( $group->name() ) ) {

            require Moose;
            Moose->throw_error( q{Role '}
                    . $role1->name()
                    . q{' has encountered a group conflict }
                    . 'during composition. This is fatal error and cannot be disambiguated.'
            );
        }
        else {
            $role2->add_group($group);
        }
    }
}
## use critic

1;

# ABSTRACT: A trait that supports applying Chloro fields and groups to roles

__END__

=pod

=encoding UTF-8

=head1 NAME

Chloro::Trait::Application::ToRole - A trait that supports applying Chloro fields and groups to roles

=head1 VERSION

version 0.07

=head1 DESCRIPTION

This trait is used to allow the application of roles containing Chloro fields
and groups.

=head1 BUGS

See L<Chloro> for details.

Bugs may be submitted at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Chloro> or via email to L<bug-chloro@rt.cpan.org|mailto:bug-chloro@rt.cpan.org>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Chloro can be found at L<https://github.com/autarch/Chloro>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
