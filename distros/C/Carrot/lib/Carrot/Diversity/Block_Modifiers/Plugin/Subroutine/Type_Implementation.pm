package Carrot::Diversity::Block_Modifiers::Plugin::Subroutine::Type_Implementation
# /type class
# /instances singular
# /implements [=component_pkg=]::_Prototype
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Block_Modifiers/Plugin/Subroutine/Type_Implementation./manual_modularity.pl');
	} #BEGIN

	my $pkg_names = {};

	my $expressiveness = Carrot::individuality;
	$expressiveness->declare_provider; # used in ::Prototype::Implements

# =--------------------------------------------------------------------------= #

sub address
# /type implementation
{
	return(['sub', 'type', 'implementation']);
}

sub trigger_modifier
# /type implementation
{
	my ($this, $meta_monad, $source_code, $all_blocks) = @ARGUMENTS;

	$meta_monad->provide(
		my $prototype = '::Diversity::Block_Modifiers::Plugin::Subroutine::Prototype');

	my $pkg_name = $all_blocks->{'package'}{'implements'}->modifier_value;
	$all_blocks->{'sub'}{$this->[ATR_BLOCK_ID]} =
		$prototype->all_blocks_of($pkg_name, $this->[ATR_BLOCK_ID]);

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.215
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
