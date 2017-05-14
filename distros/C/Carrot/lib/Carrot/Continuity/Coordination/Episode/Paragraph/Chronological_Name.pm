package Carrot::Continuity::Coordination::Episode::Paragraph::Chronological_Name
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';
	use POSIX qw(strftime);

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $epoch_time = '::Individuality::Singular::Process::Epoch_Time',
		my $loop = '::Continuity::Coordination::Episode::Loop');
	
# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	pattern
#	subject
# //returns
{
	my ($this, $pattern, $subject) = @ARGUMENTS;

	$this->[ATR_PATTERN] = $pattern;
	$this->[ATR_NAME] = '';
	$this->[ATR_SUBJECT] = $subject;

	$this->[ATR_TIME_BOUNDARY] = $loop->construct_standard_episode(
		'::Target::Time_Boundary', $this, $pattern);
	$this->[ATR_TIME_BOUNDARY]->activate;

	return;
}

sub evt_time_boundary
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	my $name = strftime($this->[ATR_PATTERN], gmtime($$epoch_time));
#WISH: if there is no change, try again in 10 seconds, ten times
	return if ($name eq $this->[ATR_NAME]);
	$this->[ATR_NAME] = $name;
	$this->[ATR_SUBJECT]->evt_chronological_name_changed($name);
	return;
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