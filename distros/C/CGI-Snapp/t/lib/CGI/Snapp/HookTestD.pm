package CGI::Snapp::HookTestD;

use parent 'CGI::Snapp';
use strict;
use warnings;

# Here, use modules which do interfere with each other.
# HookTest3 is compiled 1st but its output (see t/hook.test.t's test_d() ) is overridden by like-named subs in A & B..
# But be warned, its output is not in the same order as for CGI::Snapp::HookTestA, i.e. without HookTest3.
#
# See the whole set: t/lib/CGI/Snapp/HookTest*.pm.

use CGI::Snapp::Plugin::HookTest::HookTest3;
use CGI::Snapp::Plugin::HookTest1;
use CGI::Snapp::Plugin::HookTest2;

our $VERSION = '2.01';

# --------------------------------------------------

sub setup
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.setup()';

	print "$name\n";

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
