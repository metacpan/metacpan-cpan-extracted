use strict; use warnings; use utf8;

package MyApp::Controller::Root;

use Catalyst::Controller ();
BEGIN { our @ISA = 'Catalyst::Controller' }

__PACKAGE__->config( namespace => '' );

sub test : Local {
	my ( $self, $c ) = ( shift, @_ );
	$c->stash->{'message'}  = $c->request->param('message') || $c->config->{'default_message'};
	$c->stash->{'template'} = $c->request->param('template');
}

sub test_render : Local {
	my ( $self, $c ) = ( shift, @_ );
	my $view = $c->view('AppConfig');
	if ( $view->render( $c, $c->req->param('template'), { name => $c->config->{'name'}, param => $c->req->param('param') || '' }, \$c->stash->{'message'} ) ) {
		$c->stash->{'template'} = 'test';
	}
	else {
		$c->response->body( $view->template->error );
		$c->response->status(403);
	}
}

sub test_msg : Local {
	my ( $self, $c ) = ( shift, @_ );
	$c->view('AppConfig')->render( $c, \$c->req->param('msg'), {}, \$c->stash->{'message'} )
		? $c->stash->{'template'} = 'test'
		: die;
}

sub test_alt_content_type : Local {
	my ( $self, $c ) = ( shift, @_ );
	$c->stash(
		current_view => 'AltContentType',
		template     => 'test',
		message      => $c->action->name,
	);
}

sub heart : Path('♥') {
	my ( $self, $c ) = ( shift, @_ );
	$c->stash( hearts => '♥♥♥' );
}

sub test_dynamic_path : Local {
	my ( $self, $c ) = ( shift, @_ );
	$c->stash( additional_template_paths => [ $c->path_to( 'alt_root' ) ] );
}

sub test_args : Local Args {}

sub end : Private {
	my ( $self, $c ) = ( shift, @_ );
	return 1 if $c->response->status =~ /^3\d\d$/;
	return 1 if $c->response->body;
	my $p_view = $c->request->param('view');
	$c->forward( $c->view( $p_view || () ) );
}

1;
