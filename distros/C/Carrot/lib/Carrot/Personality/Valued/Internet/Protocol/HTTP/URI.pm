package Carrot::Personality::Valued::Internet::Protocol::HTTP::URI
# /type class
# /attribute_type ::Many_Declared::Ordered
# //attribute_construction
#	path	[=this_pkg=]::Path +ondemand
#	query	[=this_pkg=]::Query +ondemand
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

# =--------------------------------------------------------------------------= #

sub attribute_constructionn
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
#	?
{
	$_[THIS][ATR_PATH] = IS_UNDEFINED;
	$_[THIS][ATR_QUERY] = IS_UNDEFINED;
}

sub assign_value
# /type method
# /effect ""
# //parameters
#	value
# //returns
{
	if ($_[SPX_VALUE] =~ m{(\A.*?)\?(.*)\z}s)
	{
		$this->path->assign_value($1);
		$this->query->assign_value($2);
	} else {
		$this->path->assign_value($_[SPX_VALUE]);
		$this->[ATR_QUERY] = IS_UNDEFINED;
	}
	return;
}

sub value
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my $this = $_[THIS];

	if (defined($this->[ATR_QUERY]))
	{
		return($this->[ATR_PATH]->value
			.'?'
			.$this->[ATR_QUERY]->value);
	} else {
		return($this->[ATR_PATH]->value);
	}
}

sub clear
# /type method
# /effect ""
# //parameters
# //returns
{
	$_[THIS][ATR_PATH] = IS_UNDEFINED;
	$_[THIS][ATR_QUERY] = IS_UNDEFINED;
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.72
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2010-2014 Winfried Trümper <pub+perl@wt.tuxomania.net>"
