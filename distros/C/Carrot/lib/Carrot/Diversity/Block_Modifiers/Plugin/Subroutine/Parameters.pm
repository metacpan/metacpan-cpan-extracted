package Carrot::Diversity::Block_Modifiers::Plugin::Subroutine::Parameters
# /type class
# /implements [=component_pkg=]::_Prototype
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Block_Modifiers/Plugin/Subroutine/Parameters./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide(
		my $specification_class = '::Diversity::Block_Modifiers::Plugin::Subroutine::Parameters::Specification');

# =--------------------------------------------------------------------------= #

sub address
# /type implementation
{
	return(['sub', 'parameters']);
}

sub trigger_modifier
# /type implementation
{
	my ($this, $meta_monad, $source_code, $all_blocks) = @ARGUMENTS;

	my $value = $this->[ATR_VALUE];
        if ((ref($value) eq '') and ($value eq '0'))
        {
                $value = [];
        }
	my $specification = $this->[ATR_VALUE] = $specification_class
		->constructor($value);
	my $names = $specification->names;
	return unless (@$names);

	my $block_id = $this->[ATR_BLOCK_ID];
	unless ($$source_code =~ m
		{
			(?:\012|\015\012?)\{\ \#--8<--\ sub-$block_id-open\ -->8--\#
		}sxg)
	{
		return if ($$source_code =~ m
			{
				(?:\012|\015\012?)\;\ \#--8<--\ sub-$block_id-openclose\ -->8--\#
			}sx);
		die("Could not match start of subroutine '$block_id'.\n");
	}
	my $open_pos = pos($$source_code);

	if ($$source_code =~ m
		{
			\G((?:\012|\015\012?)[^\012\015\#]+=\h*(?:(?:shift|splice)\()?(?:\\?@(?:ARGUMENTS|_)|\$_\[THIS\])\W)
		}sxgc)
	{
		pos($$source_code) = IS_UNDEFINED;
		return;
	}

	unless ($$source_code =~ m
		{
			\G(.*)(?:\012|\015\012?)\}\ \#--8<--\ sub-$block_id-close\ -->8--\#
		}sxg)
	{
		die("Could not match end of subroutine '$block_id'.");
	}
	my $perl_code = $1;
	return if ($perl_code =~ m{\$_\[THIS\]}saa);

	my $copied_names = ['this', @$names];
	my $sub_modifiers = $all_blocks->{'sub'}{$this->[ATR_BLOCK_ID]};

	unless ($sub_modifiers->{'type'}->modifier_value eq 'method')
	{
		shift($copied_names);
	}
	my $seman_deipoc = [reverse(@$copied_names)];
	foreach my $name (@$seman_deipoc)
	{
		if (index($perl_code, "\$$name") == RDX_INDEX_NO_MATCH)
		{
			pop($copied_names);
			if ((index($perl_code, 'SPX_'.uc($name)) == RDX_INDEX_NO_MATCH)
			and ($name ne 'this'))
			{
#				die("Unused parameter '$name' in subroutine '$block_id'.");
			}
		} else {
			last;
		}
	}
	my $arguments_definition =
		"\tmy ("
		.join(', ', map("\$$_", @$copied_names))
		.') = @ARGUMENTS;';

	pos($$source_code) = $open_pos;
	unless ($$source_code =~ s{\G(\012|\015\012?)\K}{$arguments_definition$1}sx)
	{
		die("Could not add argument processing to subroutine '$block_id'.");
	}

	return;
}

sub named_types
# /type method
# /effect "Parses a comment block like this into a hash."
# //parameters
# //returns
#	::Personality::Abstract::Instance
{
	return($_[THIS][ATR_VALUE]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.228
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
