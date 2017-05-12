package CGI::Snapp::Plugin::HookTest2;

use strict;
use warnings;
use vars '@EXPORT';

@EXPORT = (qw/init_sub_2_1 init_sub_2_2/);

our $VERSION = '2.01';

# --------------------------------------------------

sub import
{
	my($caller) = caller;

	# Class-level callbacks.

	$caller -> add_callback('init', 'init_sub_2_1');
	$caller -> add_callback('init', 'init_sub_2_2');
	$caller -> add_callback('teardown', \&teardown_sub);

	goto &Exporter::import;

} # End of import.

# --------------------------------------------------

sub init_sub_2_1
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.init_sub_2_1()';

	print "$name\n";

	# Add run mode (no_rm_2_1 => no_sub_2_1), so t/hook.pl can check it.

	$self -> run_modes(no_rm_2_1 => 'no_sub_2_1');

} # End of init_sub_2_1.

# --------------------------------------------------

sub init_sub_2_2
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.init_sub_2_2()';

	print "$name\n";

	# Add run mode (no_rm_2_2 => no_sub_2_2), so t/hook.pl can check it.

	$self -> run_modes(no_rm_2_2 => 'no_sub_2_2');

} # End of init_sub_2_2.

# --------------------------------------------------

sub teardown_sub
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.teardown_sub()';

	print "$name\n";

} # End of teardown_sub.

# --------------------------------------------------

1;
