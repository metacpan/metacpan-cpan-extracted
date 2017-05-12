package CGI::Snapp::RedirectTest;

use parent 'CGI::Snapp';
use strict;
use warnings;

our $VERSION = '2.01';

# --------------------------------------------------

sub cgiapp_prerun
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.cgiapp_prerun()';

	print "$name\n";

	$self -> redirect('http://first.net.au/') if ($self -> param('test.prerun.mode') );

} # End of cgiapp_prerun.

# --------------------------------------------------

sub first_sub
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.first_sub()';

	print "$name\n";

	if ($self -> param('test.local.url') )
	{
		$self -> redirect('login.html');
	}
	elsif ($self -> param('test.without.status') )
	{
		$self -> redirect('http://second.net.au/');
	}
	elsif ($self -> param('test.with.status') )
	{
		$self -> redirect('http://third.net.au/', '301 Moved Permanently');
	}

	return $name;

} # End of first_sub.

# --------------------------------------------------

sub setup
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.setup()';

	print "$name\n";

	# Add callback methods belonging to this package.

	__PACKAGE__ -> add_callback('prerun', 'cgiapp_prerun');

} # End of setup.

# --------------------------------------------------

1;
