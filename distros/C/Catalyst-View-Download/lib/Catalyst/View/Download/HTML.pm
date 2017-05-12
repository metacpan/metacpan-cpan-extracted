package Catalyst::View::Download::HTML;

use Moose;
use namespace::autoclean;

extends 'Catalyst::View';

=head1 NAME

Catalyst::View::Download::HTML

=head1 VERSION

0.05

=cut

our $VERSION = "0.05";
$VERSION = eval $VERSION;

__PACKAGE__->config( 'stash_key' => 'html' );

sub process {
    my $self = shift;
    my ( $c ) = @_;

    my $template = $c->stash->{ 'template' };
    my $content = $self->render( $c, $template, $c->stash );

    $c->res->headers->header( "Content-Type" => "text/html" )
      if ( $c->res->headers->header( "Content-Type" ) eq "" );
    $c->res->body( $content );
}

sub render {
    my $self = shift;
    my ( $c, $template, $args ) = @_;

    my $stash_key = $self->config->{ 'stash_key' };
    my $content   = $c->stash->{ $stash_key } || $c->response->body;

    return $content;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

    # lib/MyApp/View/Download/HTML.pm
    package MyApp::View::Download::HTML;
    use base qw( Catalyst::View::Download::HTML );
    1;

    # lib/MyApp/Controller/SomeController.pm
    sub example_action_1 : Local {
        my ($self, $c) = @_;

        my $content = "Some Text";

        # To output your data just pass your content into the 'html' key of the stash
        $c->stash->{'html'} = $content;

        # Or into the body of the response for this action
        $c->response->body($content);

        # Finally forward processing to the HTML View
        $c->forward('MyApp::View::Download::HTML');
    }

=head1 DESCRIPTION

Takes content and outputs the content as html text.

=head1 SUBROUTINES

=head2 process

This method will be called by Catalyst if it is asked to forward to a component
without a specified action.

=head2 render

Allows others to use this view for much more fine-grained content generation.

=head1 CONFIG

=over 4

=item stash_key

Determines the key in the stash this view will look for when attempting to
retrieve content to process. If this key isn't found it will then look at
$c->response->body for content.

  $c->view('MyApp::View::Download::HTML')->config->{'stash_key'} = 'content';

=back

=head1 AUTHOR

Travis Chase, C<< <gaudeon at cpan dot org> >>

=head1 SEE ALSO

L<Catalyst> L<Catalyst::View> L<Catalyst::View::Download>

=head1 LICENSE

Copyright 2011 Travis Chase.

This program is free software. You can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
