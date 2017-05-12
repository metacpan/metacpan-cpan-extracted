package <tmpl_var main_module>::Dispatch;

=head1 NAME

Template URL dispatcher for CGI::Application::Structured apps.

=cut 

use base 'CGI::Application::Dispatch';

sub dispatch_args {
	return {
		prefix      => <tmpl_var main_module>::C,
		args_to_new =>{PARAMS =>{cfg_file => 'config/config.pl'}},
		table       => [
			''                   => {app => 'home'},
			':app'               => {},
			':app/:rm/:id?'      => {},
			':app/:rm/:id/:extra1?' => {},

		],
		default => 'home'

	};
}
1;
