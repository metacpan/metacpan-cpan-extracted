package CGI::Application::Demo::Basic::One;

# Documentation:
#	POD-style documentation is at the end. Extract it with pod2html.*.
#
# Note:
#	o tab = 4 spaces || die
#
# Author:
#	Ron Savage <ron@savage.net.au>
#	http://savage.net.au/index.html

use base 'CGI::Application';
use strict;
use warnings;

require 5.005_62;

use CGI;

our $VERSION = '1.06';

# -----------------------------------------------

sub setup
{
	my($self) = @_;

	$self -> run_modes(start => \&start);

}	# End of setup.

# -----------------------------------------------

sub start
{
	my($self)		= @_;
	my($package)	= __PACKAGE__;
	my($time)		= scalar localtime;
	my($url)		= $self -> query -> url;
	my($path_info)	= $self -> query -> path_info;
	my($output)		=<<EOS;
<html>
	<head>
		<title>$package</title>
	</head>
	<body>
		<h1 align="center">$package</h1>
		<ul>
			<li>Time: $time</li>
			<li>URL: $url</li>
			<li>Path info: $path_info</li>
			<li>CGI V $CGI::VERSION</li>
		</ul>
	</body>
</html>
EOS

	return $output;

}	# End of start.

# -----------------------------------------------

1;
