package CGI::Snapp::HookTestA;

use parent 'CGI::Snapp';
use strict;
use warnings;

# Here, use modules which don't interfere with each other.
# HookTest1 is compiled 1st so its output (see t/hook.test.t's test_a() ) is first.
#
# See the whole set: t/lib/CGI/Snapp/HookTest*.pm.

use CGI::Snapp::Plugin::HookTest1;
use CGI::Snapp::Plugin::HookTest2;

our $VERSION = '2.01';

# --------------------------------------------------

sub prerun_mode_sub_1
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.prerun_mode_sub_1()';

	print "$name\n";

} # End of prerun_mode_sub_1.

# --------------------------------------------------

sub prerun_mode_sub_2
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.prerun_mode_sub_2()';

	print "$name\n";

} # End of prerun_mode_sub_2.

# --------------------------------------------------

sub setup
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.setup()';

	print "$name\n";

	$self -> add_callback('prerun', 'prerun_mode_sub_1');
	$self -> add_callback('prerun', 'prerun_mode_sub_2');
	$self -> run_modes([qw/start_sub/]);
	$self -> start_mode('start_sub');

} # End of setup.

# --------------------------------------------------

sub start_sub
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.start_sub()';

	print "$name\n";

	return $name;

} # End of start_sub.

# --------------------------------------------------

1;
