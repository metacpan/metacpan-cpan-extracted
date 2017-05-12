package CGI::Snapp::Dispatch::SubClass3;

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
		prefix  => 'CGI::Snapp',
		table   =>
		[
			'foo/bar'        => {app => 'Snapp::App2', rm => 'rm2', prefix => 'CGI'},
			'foo/:rm'        => {app => 'Snapp::App2', rm => 'rm2', prefix => 'CGI'},
			'/app2/:rm[get]' => {app => 'App2'},
			':app/:rm[put]'  => {},
		],
    };

} # End of dispatch_args.

# --------------------------------------------------

1;
