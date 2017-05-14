package Carrot::Personality::Elemental::Scalar::Textual
# /type class
# /attribute_type ::One_Anonymous::Scalar::Access
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Personality/Elemental/Scalar/Textual./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub append_value
# /type method
# /effect "Append the argument value to the scalar value of the instance."
# //parameters
#	value  ::Personality::Abstract::Text
# //returns
{
	${$_[THIS]} .= $_[SPX_VALUE];
	return;
}

sub append_to_value
# /type method
# /effect "Append the argument value to the scalar value of the instance."
# //parameters
#	value  ::Personality::Abstract::Text
# //returns
{
	$_[SPX_VALUE] .= ${$_[THIS]};
	return;
}

sub appended_value
# /type method
# /effect "Return the scalar value of the instance and the argument value concatenated."
# //parameters
#	value  ::Personality::Abstract::Text
# //returns
#	::Personality::Abstract::Text
{
	return(${$_[THIS]} . $_[SPX_VALUE]);
}

sub append
# /type method
# /effect "Append the argument instance to the scalar value of the instance."
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
{
	${$_[THIS]} .= ${$_[THAT]};
	return;
}

sub appended
# /type method
# /effect "Return the scalar value of the instance and the argument instance concatenated."
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	::Personality::Abstract::Text
{

	return(${$_[THIS]} . ${$_[THAT]});
}

sub chomp
# /type method
# /effect "Remove leading and trailing whitespaces from the scalar value of the instance."
# //parameters
# //returns
{
	chomp(${$_[THIS]});
	return;
}

sub die
# /type method
# /effect "Die with the text of the scalar value of the instance."
# //parameters
# //returns
{
	CORE::die(${$_[THIS]});
	return;
}

sub print
# /type method
# /effect "Print with the text of the scalar value of the instance."
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(CORE::print ${$_[THIS]});
}

sub is_equal_value
# /type method
# /effect "Tests the scalar value of the instance and the argument value for equality."
# //parameters
#	value  ::Personality::Abstract::Text
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} eq $_[SPX_VALUE]);
}

sub is_equal
# /type method
# /effect "Tests this instance and the argument instance for equality of scalar values."
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} eq ${$_[THAT]});
}

sub first_index_value
# /type method
# /effect "Returns the character position where the argument string was found."
# //parameters
#	text
#	offset  +optional
# //returns
#	::Personality::Abstract::Number
{
	my $this = shift(\@ARGUMENTS);
	return(index($$this, @ARGUMENTS));
}

sub first_index
# /type method
# /effect "Returns the character position where the argument instance was found."
# //parameters
#	text
#	offset  +optional
# //returns
#	::Personality::Abstract::Number
{
	my ($this, $that) = splice(\@ARGUMENTS, 0, 2);
	return(index($$this, $$that, @ARGUMENTS));
}

sub folded_case # requires 5.16.0
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text
{
	return(fc(${$_[THIS]}));
}

sub fold_case # requires 5.16.0
# /type method
# /effect ""
# //parameters
# //returns
{
	${$_[THIS]} = fc(${$_[THIS]});
	return;
}

sub is_greater_value
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Text
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} gt $_[SPX_VALUE]);
}

sub is_greater
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} gt ${$_[THAT]});
}

sub is_greater_equal_value
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Text
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} ge $_[SPX_VALUE]);
}

sub is_greater_equal
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} ge ${$_[THAT]});
}

sub is_between
# /type method
# /effect ""
# //parameters
#	lower
#	upper
# //returns
#	::Personality::Abstract::Boolean
{
	return((${$_[THIS]} gt $_[SPX_LOWER])
		and (${$_[THIS]} lt $_[SPX_UPPER]));
}

sub is_within
# /type method
# /effect ""
# //parameters
#	lower
#	upper
# //returns
#	::Personality::Abstract::Boolean
{
	return((${$_[THIS]} ge $_[SPX_LOWER])
		and (${$_[THIS]} le $_[SPX_UPPER]));
}

sub last_index_value
# /type method
# /effect "Returns the character position where the argument string was found."
# //parameters
#	text
#	offset  +optional
# //returns
#	::Personality::Abstract::Number
{
	my $this = shift(\@ARGUMENTS);
	return(rindex($$this, @ARGUMENTS));
}

sub last_index
# /type method
# /effect "Returns the character position where the argument instance was found."
# //parameters
#	text
#	offset  +optional
# //returns
#	::Personality::Abstract::Number
{
	my ($this, $that) = splice(\@ARGUMENTS, 0, 2);
	return(rindex($$this, $$that, @ARGUMENTS));
}

sub length
# /type method
# /effect "Returns the amount of logical characters in the instance."
# //parameters
# //returns
#	::Personality::Abstract::Number
{
	return(CORE::length(${$_[THIS]}));
}

sub is_same_length_value
# /type method
# /effect ""
# //parameters
#	value            ::Personality::Abstract::Text
# //returns
#	::Personality::Abstract::Boolean
{
	return(CORE::length(${$_[THIS]}) == CORE::length($_[SPX_VALUE]));
}

sub is_same_length
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	::Personality::Abstract::Boolean
{
	return(CORE::length(${$_[THIS]}) == CORE::length(${$_[THAT]}));
}

sub is_lesser_value
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Text
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} lt $_[SPX_VALUE]);
}

sub is_lesser
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} lt ${$_[THAT]});
}

sub is_lesser_equal_value
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Text
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} le $_[SPX_VALUE]);
}

sub is_lesser_equal
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} le ${$_[THAT]});
}

sub lowered_case
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text
{
	return(lc(${$_[THIS]}));
}

sub lower_case
# /type method
# /effect ""
# //parameters
# //returns
{
	${$_[THIS]} = lc(${$_[THIS]});
	return;
}

sub ordinal_number
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Number
{
	return(ord(${$_[THIS]}));
}

sub repeat
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Number
# //returns
{
	${$_[THIS]} x= $_[SPX_VALUE];
	return;
}

sub repeated
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Number
# //returns
#	::Personality::Abstract::Text
{
	return(${$_[THIS]} x $_[SPX_VALUE]);
}

sub matches_regexp
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Regular_Expression
# //returns
#	*
{
	return(${$_[THIS]} =~ m{$_[SPX_VALUE]});
}

sub quoted_meta_characters
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text
{
	return(quotemeta(${$_[THIS]}));
}

sub quote_meta_characters
# /type method
# /effect ""
# //parameters
# //returns
{
	${$_[THIS]} = quotemeta(${$_[THIS]});
	return;
}

sub reverse
# /type method
# /effect ""
# //parameters
# //returns
{
	${$_[THIS]} = CORE::reverse(${$_[THIS]});
	return;
}

sub reversed
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text
{
	return(CORE::reverse(${$_[THIS]}));
}

sub split
# /type method
# /effect ""
# //parameters
#	pattern
#	limit
# //returns
#	::Personality::Abstract::Array
{
	my ($this, $pattern, $limit) = @ARGUMENTS;
	return([CORE::split($pattern, $$this,
		$limit || PKY_SPLIT_RETURN_FULL_TRAIL)]);
}

#sub sort_direction
## /type method
## /effect ""
## //parameters
##	<that>           ::Personality::Abstract::Instance
## //returns
##	::Personality::Abstract::Number
#{
#	return(${$_[THIS]} cmp ${$_[THAT]});
#}

sub substitute_re
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Regular_Expression
#	replacement  ::Personality::Abstract::Text::Interpolated
# //returns
#	::Personality::Abstract::Number
{
	return(${$_[THIS]} =~ s{$_[SPX_VALUE]}{$_[SPX_REPLACEMENT]});
}

sub substituted_re
# /type method
# /effect ""
# //parameters
#	value  ::Personality::Abstract::Regular_Expression
#	replacement  ::Personality::Abstract::Text::Interpolated
# //returns
#	::Personality::Abstract::Text
{
	return(${$_[THIS]} =~ s{$_[SPX_VALUE]}{$_[SPX_REPLACEMENT]}r);
}

sub substringed
# /type method
# /effect ""
# /parameters *
# //returns
#	::Personality::Abstract::Text
{
	my $this = shift(\@ARGUMENTS);
	return(substr($$this, @ARGUMENTS));
}

sub substring
# /type method
# /effect ""
# /parameters *
# //returns
{
	my $this = shift(\@ARGUMENTS);
	$$this = substr($$this, @ARGUMENTS);
	return;
}

sub uppered_case
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text
{
	return(uc(${$_[THIS]}));
}

sub upper_case
# /type method
# /effect ""
# //parameters
# //returns
{
	${$_[THIS]} = uc(${$_[THIS]});
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.144
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
