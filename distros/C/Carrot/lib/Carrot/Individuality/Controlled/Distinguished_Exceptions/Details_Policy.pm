package Carrot::Individuality::Controlled::Distinguished_Exceptions::Details_Policy
# /type class
# /attribute_type ::One_Anonymous::Scalar
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Individuality/Controlled/Distinguished_Exceptions/Details_Policy./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub DEX_POLICY_HIDE() { -1 }
sub DEX_POLICY_BLANK() { 0 }
sub DEX_POLICY_DISCLOSE() { 1 }

my $default_policy = DEX_POLICY_DISCLOSE;

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	${$_[THIS]} = $default_policy;
	return;
}

sub set_hide
# /type method
# /effect ""
# //parameters
# //returns
{
	${$_[THIS]} = DEX_POLICY_HIDE;
	return;
}

sub is_hide
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} == DEX_POLICY_HIDE);
}

sub set_blank
# /type method
# /effect ""
# //parameters
# //returns
{
	${$_[THIS]} = DEX_POLICY_BLANK;
	return;
}

sub is_blank
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} == DEX_POLICY_BLANK);
}

sub set_disclose
# /type method
# /effect ""
# //parameters
# //returns
{
	${$_[THIS]} = DEX_POLICY_DISCLOSE;
	return;
}

sub is_disclose
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} == DEX_POLICY_DISCLOSE);
}


sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	return('DEX_POLICY_', [qw(
		HIDE
		BLANK
		DISCLOSE)]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.51
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"