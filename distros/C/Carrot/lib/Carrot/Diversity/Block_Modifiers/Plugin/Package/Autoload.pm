package Carrot::Diversity::Block_Modifiers::Plugin::Package::Autoload
# /type class
# /implements [=component_pkg=]::_Prototype
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Block_Modifiers/Plugin/Package/Autoload./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub address
# /type implementation
{
	return(['package', 'autoload']);
}

sub trigger_modifier
# /type implementation
{
	my ($this, $meta_monad, $source_code, $all_blocks) = @ARGUMENTS;

	return unless ($meta_monad->dot_directory->
		entry('autoload')->exists);
	my $package_name = $meta_monad->package_name;
	my $pkg_name = $package_name->value;

	my $autoload_pl = $package_name->dot_directory_logical.'/autoload.pl';

	my $begin_block = $source_code->begin_block;
	$begin_block->add_require($autoload_pl);
	$begin_block->add_crosslink(__PACKAGE__, 'AUTOLOAD');
	$begin_block->commit;

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.182
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
