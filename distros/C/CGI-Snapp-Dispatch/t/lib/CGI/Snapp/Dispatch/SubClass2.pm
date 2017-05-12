package CGI::Snapp::Dispatch::SubClass2;

use parent 'CGI::Snapp::Dispatch';
use strict;
use warnings;

our $VERSION = '2.00';

# --------------------------------------------------

sub dispatch_args
{
	my($self, $args) = @_;

	return
	{
		args_to_new =>
		{
			PARAMS => {hum => 'electra_2000'},
		},
		prefix  => 'CGI::Snapp',
		table   =>
		[
			'foo/bar'             => {app => 'Snapp::App2', rm => 'rm2', prefix => 'CGI'},
			':app/bar/:my_param'  => {rm => 'rm3'},
			':app/foo/:my_param?' => {rm => 'rm3'},
			':app/baz/*'          => {rm => 'rm5'},
			':app/bap/*'          => {rm => 'rm5', '*' => 'the_rest'},
			':app/:rm/:my_param'  => {},
			':app/:rm'            => {},
			':app'                => {},
			''                    => {app => 'App2', rm => 'rm1'},
		],
    };

} # End of dispatch_args.

# --------------------------------------------------

1;
