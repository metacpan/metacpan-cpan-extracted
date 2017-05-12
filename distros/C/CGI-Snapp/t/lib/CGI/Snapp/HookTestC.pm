package CGI::Snapp::HookTestC;

use parent 'CGI::Snapp';
use strict;
use warnings;

# Here, use modules which do interfere with each other.
# HookTest3 is compiled last so its output (see t/hook.test.t's test_c() ) overrides like-named subs in A & B..
#
# See the whole set: t/lib/CGI/Snapp/HookTest*.pm.

use CGI::Snapp::Plugin::HookTest1;
use CGI::Snapp::Plugin::HookTest2;
use CGI::Snapp::Plugin::HookTest::HookTest3;

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
