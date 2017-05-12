package App::Mimosa::View::Mason;
use Moose;
extends 'Catalyst::View::HTML::Mason';
#with 'Catalyst::Component::ApplicationAttribute';

__PACKAGE__->config(
    globals            => ['$c'],
    template_extension => '.mason',
);

# must late-compute our interp_args
sub interp_args {
    my $self = shift;
    return {
        comp_root => [
            [ main => App::Mimosa->path_to('views') ],
           ],
    };
}

=head1 NAME

App::Mimosa::View::Mason - Mason View Component

=head1 DESCRIPTION

Mason View Component. This extends Catalyst::View::HTML::Mason.

=head1 FUNCTIONS

=head2 $self->component_exists($component)

Check if a Mason component exists. Returns 1 if the component exists, otherwise 0.


=cut

sub component_exists {
    my ( $self, $component ) = @_;

    return $self->interp->comp_exists( $component ) ? 1 : 0;
}

=head1 SEE ALSO

L<HTML::Mason>, L<Catalyst::View::HTML::Mason>

=head1 AUTHORS

Robert Buels, Jonathan "Duke" Leto

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=cut

__PACKAGE__->meta->make_immutable;
1;
