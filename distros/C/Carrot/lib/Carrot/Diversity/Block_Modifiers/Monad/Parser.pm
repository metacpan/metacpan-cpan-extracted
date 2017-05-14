package Carrot::Diversity::Block_Modifiers::Monad::Parser
# /type class
# /attribute_type ::Many_Declared::Ordered
# //parameters
#	plugins  [=project_pkg=]::Plugins
# /capability "Delegates data processing to modifier plugins."
{
	my ($plugins) = @ARGUMENTS;

	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Block_Modifiers/Monad/Parser./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide(
		my $extension_class = '::Diversity::Block_Modifiers::Monad::Source_Code',
		my $blocks_class = '::Diversity::Block_Modifiers::Monad::Blocks');

	my $id_counter = 0;

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	monad   ::Diversity::Block_Modifiers::Monad
# //returns
{
	my ($this, $monad) = @ARGUMENTS;

	my $blocks = { 'file' => {}, 'package' => {}, 'sub' => {} };

	$this->[ATR_MONAD] = $monad;
	$this->[ATR_ALL_BLOCKS] = $blocks_class->constructor($blocks);

	return;
}

sub all_blocks
# /type method
# /effect ""
# //parameters
# //returns
#	::Diversity::Block_Modifiers::Monad::Blocks
{
	return($_[THIS][ATR_ALL_BLOCKS]);
}

my $utf8_bom = chr(0xEF).chr(0xBB).chr(0xBF);
sub parse_code
# /type method
# /effect ""
# //parameters
#	source_code  ::Modularity::Package::Source
# //returns
{
	my ($this, $source_code) = @ARGUMENTS;

	my $expected = MLX_BLOCK_OPEN_CLOSE;
	my ($indentation, $type, $id) = ('', '', IS_UNDEFINED);

	my $lines = $source_code->as_lines;
	my $bom = '';
	if ($lines->[ADX_FIRST_ELEMENT] =~ s{\A($utf8_bom)}{}so)
	{
		$bom = $1;
	}
	my $block = [];
	my $amended = [];
	my $block_stack = [];
	foreach my $line (@$lines)
	{
		if ($expected == MLX_BLOCK_MODIFIER)
		{
			push($amended, $line);
			if ($line =~ m{\A${indentation}\#\h+(.*)\z}s)
			{
				push($block, $1);
				next;

			} elsif ($line =~ m{\A${indentation}\{\z}s)
			{
				$amended->[ADX_LAST_ELEMENT] .=
					" #--8<-- $type-$id-open -->8--#";
				push($block_stack, [$indentation, $type, $id]);

			} elsif ($line =~ m{\A\;\z}s)
			{
				$amended->[ADX_LAST_ELEMENT] .=
					" #--8<-- $type-$id-openclose -->8--#";

			} else {
				die("Unknown format of line '$line'.");
			}
			if (@$block)
			{
				$this->parse_block($type, $id, $block);
			}
			$expected = MLX_BLOCK_OPEN_CLOSE;
			$block = IS_UNDEFINED;

		} elsif ($expected == MLX_BLOCK_OPEN_CLOSE)
		{
			if ($#$block_stack > ADX_NO_ELEMENTS
			and ($line =~ m{\A${indentation}\}\z}s))
			{
				($indentation, $type, $id) = @{pop($block_stack)};
				push($amended, "${indentation}\} #--8<-- $type-$id-close -->8--#");
				if (@$block_stack)
				{
					$indentation = $block_stack->[-1][0];
				} else {
					$indentation = '';
				}
				next;

			} elsif ($line =~ m{\A(package|sub)\h+([\w:]+)\z}s)
			{
				($indentation, $type, $id) = ('', $1, $2);
				push($amended, "#--8<-- $type-$id-head -->8--#");
				$expected = MLX_BLOCK_MODIFIER;
				$block = [];

			} elsif ($line =~ m{\A(\h+)(for|foreach|while|if)\h+}s)
			{
				($indentation, $type) = ($1, $2);
				$id = sprintf("ANON%05d", $id_counter++);
				push($amended, "$indentation#--8<-- $type-$id-head -->8--#");
				$expected = MLX_BLOCK_MODIFIER;
				$block = [];
#			} else {
			}
			push($amended, $line);

#		} elsif ($expected == MLX_BLOCK_END)
#		{
#			next unless ($line eq '}');
#			($indentation, $type, $id) = ('', 'file', '');
#			$expected = MLX_BLOCK_MODIFIER;
#			$block = [];
#
#		} elsif ($line =~ m{\A\h+return(PERL_FILE_LOADED);\z}s)
#		{
#			$expected == MLX_BLOCK_END;
		}
	}
	$$source_code = $bom . join("\n", @$amended);
	$source_code->class_change($extension_class);

	if ($expected == MLX_BLOCK_MODIFIER)
	{
		die("The block '$type-$id' expects modifiers, but the end of the file was reached.\n");#$$source_code
	}

	if ($#$block_stack > ADX_NO_ELEMENTS)
	{
		die("The block '$block_stack->[-1][-1]' wasn't closed before the end of the file was reached.\n");#$$source_code
	}

	return;
}

sub parse_block
# /type method
# /effect ""
# //parameters
#	type	::Personality::Abstract::Text
#	name	::Personality::Abstract::Text
#	block	::Personality::Abstract::Array
# //returns
{
	my ($this, $type, $name, $block) = @ARGUMENTS;

	my $continuation = IS_UNDEFINED;
	my ($keyword, $argument);
	foreach my $line (@$block)
	{
		if (defined($continuation))
		{
			if ($line =~ m{\A/}s)
			{
				$this->found_keyword(
					[$type, $keyword],
					$name,
					$continuation);
				$continuation = IS_UNDEFINED;

			} else {
				push($continuation, $line);
				next;
			}
		}

		# quoted modifier argument
		if ($line =~ m{\A/(\w+)\h+\"([^\"]*)\"\z}s)
		{
			$this->found_keyword(
				[$type, $1],
				$name,
				[$2]);
			next;

		# multi-line modifier argument
		} elsif ($line =~ m{\A//(\w+)\z}s)
		{
			($keyword, $argument) = ($1, IS_UNDEFINED);
			$continuation = [];
			next;
		}

		# multiple modifiers per line (word-argument)
		while ($line =~ m{\G/(\w+)\h+([^/]\S*)(?:\h+|\z)}sgc)
		{
			$this->found_keyword(
				[$type, $1, $2],
				$name,
				$2);
		}
		if ($line =~ m{\G(.+)\z}g)
		{
			die("Could not match block modifier line '$1'.");
		}
	}
	if (defined($continuation))
	{
		$this->found_keyword(
			[$type, $keyword],
			$name,
			$continuation);
	}

	return;
}

sub found_keyword
# /type method
# /effect ""
# //parameters
#	path	::Personality::Abstract::Array
#	name	::Personality::Abstract::Text
#	value	::Personality::Abstract::Array | ::Personality::Abstract::Text
# //returns
{
	my ($this, $path, $name, $value) = @ARGUMENTS;

	my $keyword_class = $plugins->get($path);
	my $keyword_trigger = $keyword_class
		->indirect_constructor($name, $value);

	$this->[ATR_MONAD]->add_trigger($keyword_trigger);

	$this->[ATR_ALL_BLOCKS]->add(
		[$path->[MLX_BLOCK_TYPE], $name, $path->[MLX_BLOCK_NAME]],
		$keyword_trigger);

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.56
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
