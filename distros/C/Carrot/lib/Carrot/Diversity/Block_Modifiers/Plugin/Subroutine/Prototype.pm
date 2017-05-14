package Carrot::Diversity::Block_Modifiers::Plugin::Subroutine::Prototype
# /type class
# /instances singular
# /implements [=component_pkg=]::_Prototype
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Block_Modifiers/Plugin/Subroutine/Prototype./manual_modularity.pl');
	} #BEGIN

	my $expressiveness = Carrot::individuality;
	$expressiveness->declare_provider; # used in ::Prototype::Implements

	my $pkg_names = {};

# =--------------------------------------------------------------------------= #

sub address
# /type implementation
{
	return(['sub', 'prototype', '*']);
}

sub trigger_modifier
# /type implementation
{
	my ($this, $meta_monad, $source_code, $all_blocks) = @ARGUMENTS;

	my $pkg_name = $meta_monad->package_name->value;
	$pkg_names->{$pkg_name}{$this->[ATR_BLOCK_ID]} =
		$all_blocks->{'sub'}{$this->[ATR_BLOCK_ID]};

	$source_code->remove_block_id($this->[ATR_BLOCK_ID]);

	return;
}

sub all_blocks_of
# /type method
# /effect ""
# //parameters
#	pkg_name
#	block_id
# //returns
{
	my ($this, $pkg_name, $block_id) = @ARGUMENTS;

	unless (exists($pkg_names->{$pkg_name}))
	{
		return(IS_UNDEFINED);
	}
	unless (exists($pkg_names->{$pkg_name}{$block_id}))
	{
		return(IS_UNDEFINED);
	}

	my $all_blocks = $pkg_names->{$pkg_name}{$block_id};
        Internals::hv_clear_placeholders(%$all_blocks);
	Internals::SvREADONLY(%$all_blocks, 1);

	return($all_blocks);
}

sub fatally_compare
# /type method
# /effect ""
# //parameters
#	pkg_name
#	sub_definitions2
# //returns
{
	my ($this, $pkg_name, $sub_definitions2) = @ARGUMENTS;

	unless (exists($pkg_names->{$pkg_name}))
	{
		die("Could not find package '$pkg_name' in subroutine definitions.");
	}

	my $sub_definitions1 = $pkg_names->{$pkg_name};
	foreach my $sub_name (keys($sub_definitions1))
	{
		next if ($sub_definitions1->{$sub_name}{'type'}->modifier_value ne 'prototype');
		unless (exists($sub_definitions2->{$sub_name}))
		{
			#FIXME: missing pkg_name
			die("Package '$pkg_name' doesn't implement subroutine '$sub_name'.");
		}
		if (refaddr($sub_definitions1->{$sub_name}) ==
		refaddr($sub_definitions2->{$sub_name}))
		{
			next;
		}

		die("This block modifier can't check wild subroutine implementations, yet.");
		# same parameters, same returned
	}

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.217
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
