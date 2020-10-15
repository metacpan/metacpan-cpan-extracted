use Test::More tests => 2;

{
	package MyApp::Controller::Entry;
	$INC{'MyApp/Controller/Entry.pm'} = __FILE__;
	use base 'Catalyst::Controller';

	sub target : Private {
		my ( $self, $c, $who ) = ( shift, @_ );
		$c->response->body( "Congrats to $who" );
		$c->detach;
	}

	sub bounce : Private {
		my ( $self, $c, $who ) = ( shift, @_ );
		$c->digress( 'target', $who );
	}

	package MyApp::Controller::Root;
	$INC{'MyApp/Controller/Root.pm'} = __FILE__;
	use base 'Catalyst::Controller';

	__PACKAGE__->config( namespace => '' );

	sub target : Private {}

	sub default : Private {
		my ( $self, $c ) = ( shift, @_ );
		$c->digress( '/entry/bounce', 'myself' );
		die 'Condolences';
	}

	package MyApp;
	use Catalyst 'Digress';
	__PACKAGE__->setup;
}

use Catalyst::Test 'MyApp';

{
  my $res = request '/';
  is $res->code, 200, 'Exception averted';
  is $res->content, 'Congrats to myself', 'Response received';
}
