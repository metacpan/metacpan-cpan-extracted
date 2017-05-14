package Carrot::Continuity::Coordination::Episode::Source::Time::Line
# /type class
# /attribute_type ::One_Anonymous::Array
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	argument  +multiple
# //returns
{
	my $this = shift(\@ARGUMENTS);

	push(@$this, @ARGUMENTS);
	return;
}

sub insert
# /type method
# /effect ""
# //parameters
#	value
# //returns
{
	my ($this, $value) = @ARGUMENTS;

	my ($i, $element);
	keys(@$this); # reset 'each' iterator
	while (($i, $element) = each(@$this))
	{
		last if ($element > $value);
	}

	return unless (defined($i));
	splice(@$this, $i, 0, $value);

	return;
}

sub remove
# /type method
# /effect ""
# //parameters
#	value
# //returns
{
	my ($this, $value) = @ARGUMENTS;

	my ($i, $element) = (-1, IS_UNDEFINED);

	keys(@$this); # reset 'each' iterator
	while (($i, $element) = each(@$this))
	{
		last if ($element == $value);
	}

	return unless (defined($i));
	splice(@$this, $i, 1);

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