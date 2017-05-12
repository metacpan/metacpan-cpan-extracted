package CGI::Snapp::RunModes;

use parent 'CGI::Snapp';
use strict;
use warnings;

use Carp;

our $VERSION = '2.01';

# ------------------------------------------------

sub autoload_sub
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.autoload_sub';

	print "$name\n";

	return $name;

} # End of autoload_sub.

# ------------------------------------------------

sub eighth_sub
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.eighth_sub()';

	print "$name\n";

	return $name;

} # End of eighth_sub.

# ------------------------------------------------

sub error_hook_sub
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.error_hook_sub()';

	print "$name\n";

	return $name;

} # End of error_hook_sub.

# ------------------------------------------------

sub error_mode_sub
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.error_mode_sub()';

	print "$name\n";

	return $name;

} # End of error_mode_sub.

# ------------------------------------------------

sub fake_hook_sub
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.fake_hook_sub()';

	print "$name\n";

	$self -> call_hook('did_not_register', '');

	return $name;

} # End of fake_hook_sub.

# ------------------------------------------------

sub faulty_error_mode_sub
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.faulty_error_mode_sub()';

	print "$name\n";

	croak "$name\n";

} # End of faulty_error_mode_sub.

# ------------------------------------------------

sub faulty_run_mode_sub
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.faulty_run_mode_sub()';

	print "$name\n";

	croak "$name\n";

} # End of faulty_run_mode_sub.

# ------------------------------------------------

sub first_sub
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.first_sub()';

	print "$name\n";

	return $name;

} # End of first_sub.

# ------------------------------------------------

sub fifth_sub
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.fifth_sub()';

	print "$name\n";

	return $name;

} # End of fifth_sub.

# ------------------------------------------------

sub fourth_sub
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.fourth_sub()';

	print "$name\n";

	return $name;

} # End of fourth_sub.

# ------------------------------------------------

sub mode_param_sub
{
	my($self) = @_;

	return $self -> query -> param('mode_param_sub_rm');

} # End of mode_param_sub.

# ------------------------------------------------

sub second_sub
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.second_sub()';

	print "$name\n";

	return $name;

} # End of second_sub.

# ------------------------------------------------

sub set_mode_param_1
{
	my($self) = @_;

	$self -> mode_param(\&mode_param_sub);

} # End of set_mode_param_1.

# ------------------------------------------------

sub set_mode_param_2
{
	my($self) = @_;

	$self -> mode_param('rm');

	# This will croak when the run mode is locked.

	$self -> prerun_mode('begin');

} # End of set_mode_param_2.

# ------------------------------------------------

sub sixth_sub
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.sixth_sub()';

	print "$name\n";

	return $name;

} # End of sixth_sub.

# ------------------------------------------------

sub third_sub
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.error_mode_sub()';

	print "$name\n";

	croak "$name\n";

} # End of third_sub.

# --------------------------------------------------

1;
