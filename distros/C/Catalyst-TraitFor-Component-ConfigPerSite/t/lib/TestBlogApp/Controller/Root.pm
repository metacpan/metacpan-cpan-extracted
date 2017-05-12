package TestBlogApp::Controller::Root;

use base 'Catalyst::Controller';


# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
__PACKAGE__->config->{namespace} = '';


=head1 NAME

TestBlogApp::Controller::Root

=head1 DESCRIPTION

Root Controller for TestBlogApp.

=head1 METHODS

=cut


=head2 index

Forward to the Blog

=cut

sub index : Path : Args(0) {
	my ( $self, $c ) = @_;
	
	# Redirect to Blog
	$c->detach( 'Blog', 'index' );
}

=head2 default

404 handler

=cut

sub default : Path {
    my ( $self, $c ) = @_;
    
	$c->forward( 'Root', 'build_menu' );
	
    $c->stash->{ template } = '404.tt';
    
    $c->response->status(404);
}


=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass( 'RenderView' ) {}

1;

