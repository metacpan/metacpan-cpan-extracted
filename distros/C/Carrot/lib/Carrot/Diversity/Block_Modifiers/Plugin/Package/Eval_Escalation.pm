package Carrot::Diversity::Block_Modifiers::Plugin::Package::Eval_Escalation
# /type class
# /implements [=component_pkg=]::_Prototype
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Block_Modifiers/Plugin/Package/Eval_Escalation./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub address
# /type implementation
{
	return(['package', 'eval_escalation']);
}

sub trigger_modifier
# /type implementation
{
	my ($this, $meta_monad, $source_code, $all_blocks) = @ARGUMENTS;

	$source_code->
#	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
#		my $translated_errors = '::Meta::Greenhouse::Translated_Errors');

		# find value for $details

	$source_code->modify_block_code( # calls re_replacement_value
		$this->[ATR_BLOCK_ID],
		$this);

	return;
}

sub re_replacement_value
# /type method
# /effect "Modifies matching text of a regular expression."
# //parameters
#	matched_code
# //returns
{
	my ($this, $matched_code) = @ARGUMENTS;

	$matched_code = qq{
	eval {
$matched_code
		return(IS_TRUE);

	} or $translated_errors->escalate(
		'$this->[ATR_VALUE]',
		[$this->[ATR_DETAIL]],
		$EVAL_ERROR);
};

	return($matched_code);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.118
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
