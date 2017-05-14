package Carrot::Productivity::Text::Placeholder::Miniplate::Current_Strftime
# /type class
# //parent_classes
#	[=component_pkg=]::_Corporate
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';
	require POSIX;

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_TIMESTAMP] = IS_UNDEFINED;

	return;
}

my $can = IS_UNDEFINED;
sub find_call
# /type method
# /effect ""
# //parameters
#	placeholder
# //returns
#	?
{
	my ($this, $placeholder) = @ARGUMENTS;

	return(IS_UNDEFINED) unless ($placeholder =~ m{^current_strftime@(.*)});

	return([$can, [$this, $1]]);
}

sub syp_date_time
# /type method
# /effect ""
# //parameters
#	format
# //returns
#	?
{
	my ($this, $format) = @ARGUMENTS;

	my $timestamp = $this->[ATR_TIMESTAMP] // time;
	my $date_time = POSIX::strftime($format, localtime($timestamp));

	return($date_time)
}
$can = \&syp_date_time;
# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.46
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"