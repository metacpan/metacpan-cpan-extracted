package CGI::Snapp::App1;

use parent 'CGI::Snapp';
use strict;
use warnings;

our $VERSION = '2.00';

# --------------------------------------------------

sub rm1
{
	my($self) = @_;

	return 'I am rm1() - Hear me roar';

} # End of rm1;

# --------------------------------------------------

sub rm2
{
	my($self) = @_;

	return '(key1 => ' . $self -> param('key1') . ')';

} # End of rm2;

# --------------------------------------------------

sub setup
{
	my($self) = @_;

	$self -> run_modes({rm1 => 'rm1', rm2 => 'rm2'});

} # End of setup

# --------------------------------------------------

1;
