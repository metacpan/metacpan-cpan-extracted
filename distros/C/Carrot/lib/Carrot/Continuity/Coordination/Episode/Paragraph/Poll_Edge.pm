package Carrot::Continuity::Coordination::Episode::Paragraph::Poll_Edge
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $loop = '::Continuity::Coordination::Episode::Loop');

	my $default_name = 'evt_poll_edge';
# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this, $instance, $name, $test, $period) = @ARGUMENTS;

	my $target = $loop->construct_standard_episode(
		'::Target::Periodic', $this, $period || 60);
	$target->activate;
	my $callback = $target->create_callback($instance, $default_name, $name);
	my $result = $test->();
	@$this = ($target, $instance, $callback, $test, $result);
	return;
}

sub evt_time_periodic
# /type method
# /effect "Act on a periodic time event."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	my $result = $this->[ATR_TEST]->();
	if ($result ne $this->[ATR_RESULT]) { # call on edge only
		$this->[ATR_RESULT] = $result;
		return(&{$this->[ATR_CALLBACK]}($this->[ATR_INSTANCE], $result));
	}
	return;
}

sub deactivate {
	$_[THIS][ATR_TARGET]->deactivate;
}

sub DESTROY
# /type method
# /effect ""
# //parameters
# //returns
{
	if (defined($_[THIS]) and defined($_[THIS][ATR_TARGET]))
	{
		$_[THIS][ATR_TARGET]->deactivate;
	}
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.53
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"