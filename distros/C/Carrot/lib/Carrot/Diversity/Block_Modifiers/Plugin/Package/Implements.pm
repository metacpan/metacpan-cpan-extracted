package Carrot::Diversity::Block_Modifiers::Plugin::Package::Implements
# /type class
# /implements [=component_pkg=]::_Prototype
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Block_Modifiers/Plugin/Package/Implements./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $pkg_patterns = '::Modularity::Package::Patterns');

# =--------------------------------------------------------------------------= #

sub address
# /type implementation
{
	return(['package', 'implements']);
}

sub trigger_modifier
# /type implementation
{
	my ($this, $meta_monad, $source_code, $all_blocks) = @ARGUMENTS;

	my $pkg_name = $this->[ATR_VALUE];
	$pkg_patterns->resolve_placeholders(
		$pkg_name,
		$meta_monad->package_name->value);
	$meta_monad->class_names->resolve_n_load($pkg_name);
	$meta_monad->parent_classes->add($pkg_name);

	my $code = "\$expressiveness->parent_classes->add('$pkg_name');";
	$source_code->insert_after_modularity($code);

	$meta_monad->provide(
		my $prototype = '::Diversity::Block_Modifiers::Plugin::Subroutine::Prototype');
	$prototype->fatally_compare(
		$pkg_name,
		$all_blocks->{'sub'});

	$this->[ATR_VALUE] = $pkg_name;

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.173
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
