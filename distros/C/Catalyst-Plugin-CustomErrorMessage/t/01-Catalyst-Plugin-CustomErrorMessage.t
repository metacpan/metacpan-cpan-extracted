#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More 'tests' => 24;

use English;

BEGIN { use_ok('Catalyst::Plugin::CustomErrorMessage') or exit };

exit main();

sub main {
	can_ok('Catalyst::Plugin::CustomErrorMessage', 'finalize_error');
	
	SKIP: {
		eval "use base 'Class::Accessor::Fast'";	
		skip 'no "Class::Accessor::Fast" installed skipping fake Catalyst tests.', 22 if $EVAL_ERROR;
	
		my $c;
		
		diag '> in debug mode';
		$c = MyCatalyst->new(
			'debug' => 1,
			'error' => [
				'error message1',
				'error message2',
			],
		);
		$c->finalize_error();
		ok($c->finalize_error_called, 'check if finalize_error() was really called');
		ok(!$c->finalize_error_called, 'check internal finalize_error()');
		is($c->flash->{'finalize_error'}, undef, 'flash empty');
		is($c->response->body, undef, 'response body empty');
		
		diag '> no action set tests';
		$c = MyCatalyst->new(
			'error' => [
				'error message1',
				'error message2',
			],
		);
		$c->finalize_error();
		ok($c->finalize_error_called, 'check if it was really called');
		is($c->response->redirect, '/', 'default redirect is "/"');
		is($c->flash->{'finalize_error'}, 'error message1<br/> error message2', 'check error message in flash');
		
		# setting non defaults
		$c->config->{'custom-error-message'}->{'uri-for-not-found'} = '/custom';
		$c->finalize_error();
		ok($c->finalize_error_called, 'check if it was really called');
		is($c->response->redirect, '/custom', 'config redirect is "/custom"');
		
		
		
		diag '> action set tests';
		$c = MyCatalyst->new(
			'action' => MyCatalyst::Action->new(),
			'error'  => [
				'error message1',
				'error message2',
			],
		);
		$c->finalize_error();
		ok($c->finalize_error_called, 'check if it was really called');
		is($c->view_name, 'TT', 'default view is TT');
		is($c->view->template_name, 'error.tt2', 'default template is error.tt2');
		is($c->response->content_type, 'text/html; charset=utf-8', 'default content type is "text/html; charset=utf-8"');
	
		# setting non defaults
		my $view_name       = 'View';
		my $content_type    = 'text/plain; charset=utf-8';
		my $error_template  = 'my_error.tt2';
		my $response_status = 0;
		$c->config->{'custom-error-message'}->{'error-template'}    = $error_template;
		$c->config->{'custom-error-message'}->{'content-type'}      = $content_type;
		$c->config->{'custom-error-message'}->{'view-name'}         = $view_name;
		$c->config->{'custom-error-message'}->{'response-status'}   = $response_status;
	
		$c->finalize_error();
		ok($c->finalize_error_called, 'check if it was really called');
		
		is($c->view_name, $view_name, 'now view is "'.$view_name.'"');
		is($c->view->template_name, 'my_error.tt2', 'now template is my_error.tt2');
		is($c->response->content_type, $content_type, 'now content type is "'.$content_type.'"');
		is($c->response->status, $response_status, 'now response status is "'.$response_status.'"');
		
		
		# catching errors in the view
		$c->config({});
		$c->config->{'custom-error-message'}->{'view-name'} = 'BrokenView';
		$c->flash->{'finalize_error'} = undef;
		$c->response->body(undef);
		
		$c->finalize_error();
		ok($c->finalize_error_called, 'check if it was really called');
		
		is($c->flash->{'finalize_error'}, undef, 'flash empty');
		is($c->response->body, undef, 'response body empty');
		like($c->log->error, qr{non_existing_function}, 'error is logged');
	}
	
	return 0;
}


=head1 MyCatalyst

Pseudo Catalyst object for testing.

=cut

package MyCatalyst;

use strict;
use warnings;

use English;
use Carp::Clan;
use MRO::Compat;

use base 'Catalyst::Plugin::CustomErrorMessage';

BEGIN {
	eval "use base 'Class::Accessor::Fast'";
	
	if (not $EVAL_ERROR) {
		__PACKAGE__->mk_accessors(qw{
			view_name
			config
			debug
			error
			action
			response
			flash
			stash
			_save_flash
		});
	}
}

sub new {
	my $class = shift;
	my %args  = @_;
	
	my $self = $class->next::method(\%args);
	
	$self->response(MyCatalyst::Response->new());
	$self->flash({})  if not defined $self->flash;
	$self->stash({})  if not defined $self->stash;
	$self->config({}) if not defined $self->config;
	
	return $self;
}

sub finalize_error {
	my $self = shift;
	
	$self->next::method;
	
	$self->finalize_error_called(1);
}

sub finalize_error_called {
	my $self = shift;
	
	# get
	if (@_ == 0) {
		if ($self->{'finalize_error_called'}) {
			$self->{'finalize_error_called'} = 0;
			return 1;
		}
		else {
			return 0;
		}
	}
	#set
	else {
		$self->{'finalize_error_called'} = shift;
		return; 
	}
}

sub view {
	my $self      = shift;
	my $view_name = shift;

	if (defined $view_name) {
		$self->view_name($view_name);
		$view_name = 'MyCatalyst::'.$view_name;
		$self->{'last_view_object'} = $view_name->new();
	}
	
	return $self->{'last_view_object'};
}

sub uri_for {
	my $self = shift;
	my $path = shift;
	
	return $path;
}

sub log {
	my $self = shift;
	return $self->logger;
}

sub logger {
	my $self = shift;
	
	$self->{'logger'} = MyCatalyst::Logger->new()
		if (not $self->{'logger'});
	
	return $self->{'logger'};
}

1;


=head1 MyCatalyst::Logger

Simple logger for MyCatalyst.

=cut

package MyCatalyst::Logger;

use strict;
use warnings;

use English;
use Carp::Clan;

BEGIN {
	eval "use base 'Class::Accessor::Fast'";
	
	if (not $EVAL_ERROR) {
		__PACKAGE__->mk_accessors(qw{
			fatal
			error
			warn
			info
			debug
		});
	}
}

1;


=head1 MyCatalyst::View

Custom catalyst view for testing;

=cut

package MyCatalyst::View;

use strict;
use warnings;

use English;
use Carp::Clan;

BEGIN {
	eval "use base 'Class::Accessor::Fast'";
	
	if (not $EVAL_ERROR) {
		__PACKAGE__->mk_accessors(qw{
			template_name
		});
	}
}

sub render {
	my $self          = shift;
	my $c             = shift;
	my $template_name = shift;
	
	croak 'pass template name' if not defined $template_name;
	
	$self->template_name($template_name);
}

1;


=head1 MyCatalyst::TT

Custom catalyst view for testing;

=cut

package MyCatalyst::TT;

use strict;
use warnings;

use English;
use Carp::Clan;

BEGIN {
	eval "use base 'Class::Accessor::Fast'";
	
	if (not $EVAL_ERROR) {
		__PACKAGE__->mk_accessors(qw{
			template_name
		});
	}
}

sub render {
	my $self          = shift;
	my $c             = shift;
	my $template_name = shift;
	
	croak 'pass template name' if not defined $template_name;
	
	$self->template_name($template_name);
}

1;


=head1 MyCatalyst::BrokenView

Custom catalyst view for testing;

=cut

package MyCatalyst::BrokenView;

use strict;
use warnings;

use English;
use Carp::Clan;

BEGIN {
	eval "use base 'Class::Accessor::Fast'";
	
	if (not $EVAL_ERROR) {
		__PACKAGE__->mk_accessors(qw{
			template_name
		});
	}
}

sub render {
	my $self          = shift;
	my $c             = shift;
	my $template_name = shift;
	
	croak 'pass template name' if not defined $template_name;
	
	$self->non_existing_function;
}

1;


=head1 MyCatalyst::Response

Custom catalyst response for testing;

=cut

package MyCatalyst::Response;

use strict;
use warnings;

use English;
use Carp::Clan;

BEGIN {
	eval "use base 'Class::Accessor::Fast'";
	
	if (not $EVAL_ERROR) {
		__PACKAGE__->mk_accessors(qw{
			content_type
			body
			redirect
			status
		});
	}
}

1;


=head1 MyCatalyst::action

Custom catalyst action for testing;

=cut

package MyCatalyst::Action;

use strict;
use warnings;

use English;
use Carp::Clan;

BEGIN {
	eval "use base 'Class::Accessor::Fast'";
	
	if (not $EVAL_ERROR) {
		__PACKAGE__->mk_accessors(qw{
			reverse
		});
	}
}

sub new {
	my $class = shift;
	
	my $self = $class->SUPER::new(@_);
	
	$self->reverse('MyReverse') if not defined $self->reverse;
	
	return $self;
}

1;
