package CGI::Snapp::App2;

use parent 'CGI::Snapp';
use strict;
use warnings;

our $VERSION = '2.00';

# --------------------------------------------------

sub rm1
{
	my($self) = @_;

	return __PACKAGE__ . ' -> rm1' . ($self -> param('hum') ? ' hum=' . $self -> param('hum') : '');

} # End of rm1.

# --------------------------------------------------

sub rm2
{
	my($self) = @_;

	return __PACKAGE__ . ' -> rm2' . ($self -> param('hum') ? ' hum=' . $self -> param('hum') : '');

} # End of rm2.

# --------------------------------------------------

sub rm3
{
	my($self)  = @_;
	my($param) = $self -> param('my_param') || '';

	return __PACKAGE__ . " -> rm3 my_param=$param" . ($self -> param('hum') ? ' hum=' . $self -> param('hum') : '');

} # End of rm3.

# --------------------------------------------------
# Because of caching, we can't re-use PATH_INFO, so we do this.

sub rm4
{
	my($self) = shift;

	return $self -> rm3;

} # End of rm4.

# --------------------------------------------------

sub rm5
{
	my($self)   = @_;
	my($return) = '';

	if ($self -> param('the_rest') )
	{
		$return = 'the_rest=' . $self -> param('the_rest');
	}
	else
	{
		$return = 'dispatch_url_remainder=' . $self -> param('dispatch_url_remainder');
	}

	return __PACKAGE__ . " -> rm5 $return";

} # End of rm5.

# --------------------------------------------------

sub rm6_GET
{
	my($self) = @_;

	return 'I am rm6_GET';

} # End of rm6_GET.

# --------------------------------------------------

sub rm7_put
{
	my($self) = @_;

	return 'I am rm7_put';

} # End of rm7_put.

# --------------------------------------------------

sub setup
{
	my($self) = @_;

	$self -> start_mode('rm1');
	$self -> run_modes([qw/rm1 rm2 rm3 rm4 rm5 rm6_GET rm7_put/]);

} # End of setup.

# --------------------------------------------------

1;
