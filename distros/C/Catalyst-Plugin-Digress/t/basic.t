use Test::More tests => 4;

{
	package Catalyst::Action::Null;
	$INC{'Catalyst/Action/Null.pm'} = __FILE__;
	use base 'Catalyst::Action';

	sub execute {
		my ( $self, $controller, $c ) = ( shift, @_ );
		$c->response->body( 'Carpe diem' );
	}

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

	sub null : ActionClass('Null') { die 'Condolences' }

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

	sub null : Local {
		my ( $self, $c ) = ( shift, @_ );
		$c->digress( '/entry/null' );
	}

	package MyApp;
	use Catalyst 'Digress';

	# throw away the unreadable standard error response wall of markup
	sub finalize_error {
		my $c = shift;
		$c->SUPER::finalize_error;
		$c->response->body( join '', @{ $c->error } );
	}

	__PACKAGE__->setup;
}

use Catalyst::Test 'MyApp';

{
	my $res = request '/';
	is $res->code, 200, 'Exception averted';
	is $res->content, 'Congrats to myself', 'Response received';
}

{ # check whether action class/role overriding execute() works
	my $res = request '/null';
	is $res->code, 200, 'Exception averted via ActionClass';
	is $res->content, 'Carpe diem', 'Response received via ActionClass';
}
