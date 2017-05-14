package Carrot::Diversity::Block_Modifiers::Plugin::Package::Attribute_Type
# /type class
# /implements [=component_pkg=]::_Prototype
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Block_Modifiers/Plugin/Package/Attribute_Type./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub address
# /type implementation
{
	return(['package', 'attribute_type']);
}

sub trigger_modifier
# /type implementation
{
	my ($this, $meta_monad, $source_code, $all_blocks) = @ARGUMENTS;

	$meta_monad->parent_classes->attribute_type->assign(
		$this->[ATR_VALUE]);
	my $code =
		q{$expressiveness->parent_classes->attribute_type->assign(}
		."\n\t\t\t'"
		.$this->[ATR_VALUE]
		.q{');};
	$source_code->insert_after_modularity($code);

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.95
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
