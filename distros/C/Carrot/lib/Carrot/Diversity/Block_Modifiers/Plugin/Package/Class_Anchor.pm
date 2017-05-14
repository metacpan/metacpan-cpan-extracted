package Carrot::Diversity::Block_Modifiers::Plugin::Package::Class_Anchor
# /type class
# /implements [=component_pkg=]::_Prototype
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Block_Modifiers/Plugin/Package/Class_Anchor./manual_modularity.pl');
	} #BEGIN

	require Carrot::Diversity::Attribute_Type::Many_Declared::Ordered;
        require Carrot::Modularity::Package::Patterns;
        my $pkg_patterns = Carrot::Modularity::Package::Patterns->constructor;

# =--------------------------------------------------------------------------= #

sub address
# /type implementation
{
	return(['package', 'class_anchor']);
}

sub trigger_modifier
# /type implementation
{
	my ($this, $meta_monad, $source_code, $all_blocks) = @ARGUMENTS;

	$this->[ATR_VALUE] =~ s{::\z}{}saa;

	$this->[ATR_VALUE] = $meta_monad->class_names
		->assign_anchor($this->[ATR_VALUE]);
	my $code = qq{\$expressiveness->class_names->assign_anchor(\n}
		.qq{\t\t\t'$this->[ATR_VALUE]');};
	$source_code->insert_after_modularity($code);

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.149
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
