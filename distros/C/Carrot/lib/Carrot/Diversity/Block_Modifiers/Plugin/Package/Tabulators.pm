package Carrot::Diversity::Block_Modifiers::Plugin::Package::Tabulators
# /type class
# /implements [=component_pkg=]::_Prototype
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Block_Modifiers/Plugin/Package/Tabulators./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $pkg_patterns = '::Modularity::Package::Patterns',
		my $pkg_tabulator = '::Modularity::Package::Tabulator');

# =--------------------------------------------------------------------------= #

sub address
# /type implementation
{
	return(['package', 'tabulators']);
}

sub trigger_modifier
# /type implementation
{
	my ($this, $meta_monad, $source_code, $all_blocks) = @ARGUMENTS;

	my $value = $this->[ATR_VALUE];

	my $calling_pkg = $meta_monad->package_name->value;
	foreach my $pkg_name (@$value)
	{
		$pkg_patterns->resolve_placeholders(
			$pkg_name,
			$calling_pkg);
	}
	$pkg_tabulator->add($meta_monad, $value);

	my $code = q{
		Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
			my $pkg_tabulator = '::Modularity::Package::Tabulator');
		$pkg_tabulator->add($expressiveness, [qw(}
		.join("\n", map("\t$_", @$value))
		.q{)]);};
	$source_code->insert_after_modularity($code);

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.109
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
