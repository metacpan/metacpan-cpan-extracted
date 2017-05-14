package Carrot::Personality::Valued::Perl5::Eval_Error
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
#		require Carrot::Meta::Greenhouse::Minimal_Constructor;
		require('Carrot/Personality/Valued/Perl5/Eval_Error./manual_modularity.pl');

		require overload;
		overload->import(
			'""' => 'overload_stringification');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub constructor
# /type method
# /effect "Fills an newly constructed instance with life."
# //parameters
#	error
# //returns
{
	my ($class) = @ARGUMENTS;
	my $this = Carrot::Meta::Greenhouse::Minimal_Constructor::array_based(
		$class);

	$this->[ATR_STATUS] = IS_UNDEFINED;
	if ($#ARGUMENTS > ADX_FIRST_ELEMENT)
	{
		$this->[ATR_CATCHER] = [caller];
		$this->[ATR_ERROR] = $_[SPX_ERROR];
		$this->recognize;
	}

	return($this);
}

sub recognize
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	if (defined(Scalar::Util::blessed($this->[ATR_ERROR])))
	{
		$this->[ATR_STATUS] = EVAL_ERROR_COOKED;

	} elsif (length($this->[ATR_ERROR]) == 0)
	{
		$this->[ATR_STATUS] = EVAL_ERROR_NONE;

	} else {
		$this->[ATR_STATUS] = EVAL_ERROR_RAW;
	}

	return;
}

sub failure
# /type method
# /effect ""
# //parameters
#	error  ::Personality::Abstract::Text
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_CATCHER] = [caller];
	$this->[ATR_ERROR] = $_[SPX_ERROR];
	$this->recognize;

	return;
}

sub escalate
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	die($_[THIS][ATR_ERROR]);
}

#FIXME: not defined($_[THIS][ATR_STATUS]) -> fatal
sub is_failure
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(defined($_[THIS][ATR_STATUS])
		and ($_[THIS][ATR_STATUS] != EVAL_ERROR_NONE));
}

sub is_none
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(defined($_[THIS][ATR_STATUS])
		and ($_[THIS][ATR_STATUS] == EVAL_ERROR_NONE));
}

sub is_raw
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(defined($_[THIS][ATR_STATUS])
		and ($_[THIS][ATR_STATUS] == EVAL_ERROR_RAW));
}

sub is_cooked
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(defined($_[THIS][ATR_STATUS])
		and ($_[THIS][ATR_STATUS] == EVAL_ERROR_COOKED));
}

sub as_text
# /type method
# /effect ""
# /parameters *
# //returns
#	::Personality::Abstract::Text
{
	my $this = shift(\@ARGUMENTS);

	if ($this->[ATR_STATUS] == EVAL_ERROR_RAW)
	{
		return($this->[ATR_ERROR]);

	} elsif ($this->[ATR_STATUS] == EVAL_ERROR_COOKED)
	{
		return($this->[ATR_ERROR]->as_text(@ARGUMENTS));

	} else {
		return(undef);
	}
}

#sub raise_as_exception
## method (<this>) public
#{
#	my ($this) = @ARGUMENTS;
#
#	return if ($this->[ATR_STATUS] == EVAL_ERROR_NONE);
#	if ($this->[ATR_STATUS] == EVAL_ERROR_COOKED)
#	{
#		die($this->[ATR_ERROR]);
#	}
##FIXME: RAW
#}

sub category
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	my $rv = ();
	if ($$this =~ m{^Can't locate [\w\.\:\/]+ in \@INC})
	{
		$rv = ERROR_CATEGORY_SETUP;
	} elsif ($$this =~ m{syntax error})
	{
		$rv = ERROR_CATEGORY_IMPLEMENTATION;
	} elsif ($$this =~ m{Can\'t call method})
	{
		$rv = ERROR_CATEGORY_IMPLEMENTATION;

	} elsif ($$this =~ m{Global symbol "\$\w+" requires explicit package name})
	{
		$rv = ERROR_CATEGORY_IMPLEMENTATION;
	} else {
		$rv = ERROR_CATEGORY_IMPLEMENTATION;
	}

	return($rv);
}

sub overload_stringification
# /type method
# /effect "Overloads the double quotes operator."
# //parameters
#	that
#	is_swapped
# //returns
#	::Personality::Abstract::Text
{
#	my ($this, $that, $is_swapped) = @ARGUMENTS;

	return($_[THIS][ATR_ERROR]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.100
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
