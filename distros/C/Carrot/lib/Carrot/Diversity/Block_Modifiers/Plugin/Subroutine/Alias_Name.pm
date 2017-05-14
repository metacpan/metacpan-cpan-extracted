package Carrot::Diversity::Block_Modifiers::Plugin::Subroutine::Alias_Name
# /type class
# /implements [=component_pkg=]::_Prototype
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Block_Modifiers/Plugin/Subroutine/Alias_Name./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub address
# /type implementation
{
	return(['sub', 'alias_name', '*']);
}

sub trigger_modifier
# /type implementation
{
	my ($this, $meta_monad, $source_code, $all_blocks) = @ARGUMENTS;

	my $block_id = $this->[ATR_BLOCK_ID];
	my $definition = "\n\*$this->[ATR_VALUE] = \\&$block_id;";

	my $modified = $$source_code =~
		s{
			(?:\012|\015\012?)\}\ \#--8<--\ sub-$block_id-close\ -->8--\#\K
		}{$definition}sxg;
	unless ($modified)
	{
		die("Could not match start of subroutine '$block_id'.");
	}

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.99
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
