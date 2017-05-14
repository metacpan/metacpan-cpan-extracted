package Carrot::Diversity::Block_Modifiers::Plugin::Any::Remove
# /type class
# /implements [=component_pkg=]::_Prototype
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Block_Modifiers/Plugin/Any/Remove./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub address
# /type implementation
{
	return(['*', 'remove']);
}

sub trigger_modifier
# /type implementation
{
	my ($this, $meta_monad, $source_code, $all_blocks) = @ARGUMENTS;

	$source_code->remove_block_id($this->[ATR_BLOCK_ID]);

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.98
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
