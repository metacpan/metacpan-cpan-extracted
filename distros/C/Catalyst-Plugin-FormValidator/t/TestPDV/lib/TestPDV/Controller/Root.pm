package TestPDV::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }
#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config( namespace => '' );

=head1 NAME

TestPDV::Controller::Root - Root Controller for TestPDV

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

=head2 default

Standard 404 error page

=cut

sub form_test : Local {
    my ( $self, $c ) = @_;
    $c->stash( template => TestPDV->path_to( 'root', 'form_test.tt' ) );
    $c->form( required => ['testinput'] );

    my $result = $c->form->valid('testinput');
    $c->res->body($result);

}

=head2 end

Attempt to render a view, if needed.

=cut

=head1 AUTHOR

Devin Austin

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
