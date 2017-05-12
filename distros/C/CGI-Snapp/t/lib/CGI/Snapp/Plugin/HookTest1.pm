package CGI::Snapp::Plugin::HookTest1;

use strict;
use warnings;
use vars '@EXPORT';

@EXPORT = (qw/init_sub_1_1 init_sub_1_2/);

our $VERSION = '2.01';

# --------------------------------------------------

sub import
{
	my($caller) = caller;

	# Class-level callbacks.

	$caller -> add_callback('init', 'init_sub_1_1');
	$caller -> add_callback('init', 'init_sub_1_2');
	$caller -> add_callback('teardown', \&teardown_sub);

	goto &Exporter::import;

} # End of import.

# --------------------------------------------------

sub init_sub_1_1
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.init_sub_1_1()';

	print "$name\n";

	# Add run mode (no_rm_1_1 => no_sub_1_1), so t/hook.pl can check it.

	$self -> run_modes(no_rm_1_1 => 'no_sub_1_1');

} # End of init_sub_1_1.

# --------------------------------------------------

sub init_sub_1_2
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.init_sub_1_2()';

	print "$name\n";

	# Add run mode (no_rm_1_2 => no_sub_1_2), so t/hook.pl can check it.

	$self -> run_modes(no_rm_1_2 => 'no_sub_1_2');

} # End of init_sub_1_2.

# --------------------------------------------------

sub teardown_sub
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.teardown_sub()';

	print "$name\n";

} # End of teardown_sub.

# --------------------------------------------------

1;
