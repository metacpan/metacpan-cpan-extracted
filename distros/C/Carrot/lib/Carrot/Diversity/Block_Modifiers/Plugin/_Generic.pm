package Carrot::Diversity::Block_Modifiers::Plugin::_Generic
# /type class
# /implements [=component_pkg=]::_Prototype
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Block_Modifiers/Plugin/_Generic./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub address
# /type implementation
{
	return(IS_UNDEFINED);
}

sub trigger_modifier
# /type implementation
{
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.104
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
