package Dancer::Plugin::Controller;

our $VERSION = '0.153';

=head1 NAME

Dancer::Plugin::Controller - interface between a model and view

=cut

=head1 SYNOPSIS

	# YourApp.pm

	use Dancer ':syntax';
	use Dancer::Plugin::Controller '0.15';

	use YouApp::Action::Index;


	get '/' => sub { 
		controller(
			action       => 'Index',              # lib/<config:action_prefix>/Index.pm
			template     => 'index',              # views/index.[tt|tpl|...]
			layout       => 'page_custom_layout', # if you need other than default layout
			redirect_404 => '404.html'            # redirect to if action method return undef
		);
	};


	# YourApp::Action::Index.pm
	
	sub main {
		my ($self) = @_;
		
		my $params = $self->params; # $params - contains Dancer::params() and Dancer::vars()

		...

		return $template_params_hashref;
	}


	# config.yml

	plugins:
		"Controller":
			# this is prefiix for module with implementation of action
			action_prefix: 'MyActionPrefix' # default: 'Action'

=cut


use strict;
use warnings;
use utf8;

use Dancer ':syntax';
use Dancer::Plugin;


register controller => sub {
	my ($self, %params) = plugin_args(@_);

	my $template_name = $params{template} || '';
	my $custom_layout = $params{layout} || '';
	my $action_name   = $params{action} || '';
	my $redirect_404  = $params{redirect_404} || '';
	
	my $conf = plugin_setting();
	my $action_prefix = $conf->{action_prefix} || 'Action';

	my $action_base_class = sprintf('%s::%s', Dancer::config->{appname}, $action_prefix);
	my $action_class      = sprintf('%s::%s', $action_base_class, $action_name);
	my $action_params     = {
		Dancer::params(),
		%{Dancer::vars()}
	};
	
	my $action_result = {};
	if ($action_name) {
		no strict 'refs';
		push @{$action_class. '::ISA'}, $action_base_class;
		*{$action_class. '::params'} = sub { $_[0]->{params} };
		use strict 'refs';

		my $action_obj = bless { params => $action_params }, $action_class;
		$action_result = $action_obj->main; 
	}

	if (not defined $action_result and $redirect_404) {
		return redirect $redirect_404;
	}
	else {
		if ($template_name) {
			return Dancer::template(
				$template_name, 
				$action_result, 
				{ layout => $custom_layout || Dancer::config->{layout} }
			);
		}
		else {
			return $action_result;
		}
	}
};

register_plugin;


1;

=head1 AUTHOR

Mikhail N Bogdanov C<< <mbogdanov at cpan.org> >>

=cut
