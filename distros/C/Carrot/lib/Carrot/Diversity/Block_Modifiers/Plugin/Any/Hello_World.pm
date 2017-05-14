package Carrot::Diversity::Block_Modifiers::Plugin::Any::Hello_World
# /type class
# /implements [=component_pkg=]::_Prototype
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Block_Modifiers/Plugin/Any/Hello_World./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub address
# /type implementation
{
	return(['*', 'hello_world']);
}

sub trigger_modifier
# /type implementation
{
	my ($this, $meta_monad, $source_code, $all_blocks) = @ARGUMENTS;

	require Data::Dumper;
	print(STDERR Data::Dumper::Dumper($this));

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.87
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
