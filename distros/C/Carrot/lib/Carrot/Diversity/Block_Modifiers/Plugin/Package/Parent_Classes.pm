package Carrot::Diversity::Block_Modifiers::Plugin::Package::Parent_Classes
# /type class
# /implements [=component_pkg=]::_Prototype
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Block_Modifiers/Plugin/Package/Parent_Classes./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub address
# /type implementation
{
	return(['package', 'parent_classes']);
}

sub trigger_modifier
# /type implementation
{
	my ($this, $meta_monad, $source_code, $all_blocks) = @ARGUMENTS;

	if (ref($this->[ATR_VALUE]) ne 'ARRAY')
	{
		$this->[ATR_VALUE] = [$this->[ATR_VALUE]];
	}
	my $parent_classes = $meta_monad->parent_classes;
	$parent_classes->add(@{$this->[ATR_VALUE]});

	my $code = qq{\$expressiveness->parent_classes->add(qw(\n\t\t\t}
		.join("\n\t\t\t", @{$parent_classes->perl_isa})
		.'));';
	$source_code->insert_after_modularity($code);

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
