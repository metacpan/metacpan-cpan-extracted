package Carrot::Diversity::Block_Modifiers::Plugin::Any::Comment
# /type class
# /implements [=component_pkg=]::_Prototype
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Block_Modifiers/Plugin/Any/Comment./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub address
# /type implementation
{
	return(['*', 'comment']);
}

sub trigger_modifier
# /type implementation
{
	my ($this, $meta_monad, $source_code, $all_blocks) = @ARGUMENTS;

	$source_code->modify_block_code(
		$this->[ATR_BLOCK_ID],
		$this);

	return;
}

sub re_replacement_value
# /type method
# /effect ""
# //parameters
#	matched_code
# //returns
{
	my ($this, $matched_code) = @ARGUMENTS;

	$matched_code =~ s{(?:\012|\015\012)\K}{#}sg;

	return($matched_code);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.110
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
