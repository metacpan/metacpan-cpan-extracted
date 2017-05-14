package Carrot::Continuity::Operation::Program::Work::Hello_World
# /type class
# /implements [=project_pkg=]::_Plugin_Prototype
# /capability "A sample program plugin."
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $loop = '::Continuity::Coordination::Episode::Loop',
		my $customized_settings = '::Individuality::Controlled::Customized_Settings');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	information_barb
# //returns
{
	my ($this, $information_barb) = @ARGUMENTS;

	$customized_settings->provide_plain_value(
		my $seconds = 'seconds_to_wait');
	print STDERR "S: $seconds\n";
	$this->[ATR_CHECK] = $loop->construct_standard_episode(
		'::Target::Periodic', $this, $seconds);

	return;
}

sub activate
# /type implementation
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_CHECK]->activate;

	return;
}

sub deactivate
# /type implementation
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_CHECK]->deactivate;

	return;
}

sub evt_time_periodic
# /type method
# /effect "Act on a periodic time event."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	print STDERR "Hello World $PROCESS_ID\n";

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.79
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"