package CGI::Snapp::Dispatch::PSGITest;

use parent 'CGI::Snapp';
use strict;
use warnings;

our $VERSION = '2.00';

# --------------------------------------------------

sub setup
{
	my($self) = @_;

	$self -> run_modes(start => sub{return 'Hello World'});

} # End of setup.

# --------------------------------------------------

1;
