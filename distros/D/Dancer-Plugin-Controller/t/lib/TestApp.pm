package TestApp;

use strict;
use warnings;
use utf8;

use Dancer ':syntax';

use FindBin;
use lib $FindBin::Bin. '/../lib';

use Dancer::Plugin::Controller '0.15';

use TestApp::Action::Test;
use TestApp::Action::Test_404;
use TestApp::Action::Test_Inherit;
use TestApp::Action::TestCustomMethod;

get '/' => sub { 
	my $res = controller(action => 'Test');
	if (ref $res) {
		return $res->{result};
	}
};

get '/404_redirect_test' => sub { 
	controller(
		action => 'Test_404',
		redirect_404 => '/404'
	);
};

get '/404' => sub {
	'404 redirect success';
};

get '/inherit' => sub {
	var x => 'x_value';
	my $res = controller(action => 'Test_Inherit');
	if (ref $res) {
		return $res->{result};
	}
};

get '/custom_action_method' => sub { 
	my $res = controller(action => 'TestCustomMethod');
	if (ref $res) {
		return $res->{result};
	}
};

1;
