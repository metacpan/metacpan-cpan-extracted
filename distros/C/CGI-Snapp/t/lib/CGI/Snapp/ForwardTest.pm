package CGI::Snapp::ForwardTest;

use parent 'CGI::Snapp';
use strict;
use warnings;

our $VERSION = '2.01';

# --------------------------------------------------

sub first_sub
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.first_sub()';

	return $name;

} # End of first_sub.

# --------------------------------------------------

sub second_sub
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.second_sub()';

	print "$name\n";

	return $self -> forward('third_rm');

} # End of second_sub.

# --------------------------------------------------

sub setup
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.setup()';

	print "$name\n";

	$self -> add_callback('forward_prerun', 'fourth_sub');

} # End of setup.

# --------------------------------------------------

sub third_sub
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.third_sub()';

	print "$name\n";

	return $name;

} # End of third_sub.

# --------------------------------------------------

sub fourth_sub
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.fourth_sub()';

	print "$name\n";

} # End of fourth_sub.

# --------------------------------------------------

1;
