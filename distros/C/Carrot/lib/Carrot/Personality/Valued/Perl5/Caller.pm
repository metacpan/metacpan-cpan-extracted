package Carrot::Personality::Valued::Perl5::Caller
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Personality/Valued/Perl5/Caller./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	unless (exists($this->[RDX_CALLER_PACKAGE]))
	{
		$this->[RDX_CALLER_PACKAGE] = '';
		$this->[RDX_CALLER_FILE] = '';
		$this->[RDX_CALLER_LINE] = -1;
	}

	return;
}

sub package
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][RDX_CALLER_PACKAGE]);
}

sub file
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][RDX_CALLER_FILE]);
}

sub line
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][RDX_CALLER_LINE]);
}

sub sub_name
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][RDX_CALLER_SUB_NAME]);
}

sub has_args
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][RDX_CALLER_HAS_ARGS]);
}

sub wants_array
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][RDX_CALLER_WANTS_ARRAY]);
}

sub eval_text
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][RDX_CALLER_EVAL_TEXT]);
}

sub is_require
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return($_[THIS][RDX_CALLER_IS_REQUIRE]);
}

sub hints
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][RDX_CALLER_HINTS]);
}

sub bit_mask
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][RDX_CALLER_BIT_MASK]);
}

sub hint_hash
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][RDX_CALLER_HINT_HASH]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.63
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"