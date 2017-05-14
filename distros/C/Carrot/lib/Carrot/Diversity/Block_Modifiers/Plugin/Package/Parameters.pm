package Carrot::Diversity::Block_Modifiers::Plugin::Package::Parameters
# /type class
# /implements [=component_pkg=]::_Prototype
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Block_Modifiers/Plugin/Package/Parameters./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide(
		my $specification_class = '::Diversity::Block_Modifiers::Plugin::Package::Parameters::Specification');

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $translated_errors = '::Meta::Greenhouse::Translated_Errors');

# =--------------------------------------------------------------------------= #

sub address
# /type implementation
{
	return(['package', 'parameters']);
}

sub trigger_modifier
# /type implementation
{
	my ($this, $meta_monad, $source_code, $all_blocks) = @ARGUMENTS;

	my $specification = $specification_class
		->constructor($this->[ATR_VALUE]);
	my $names = $specification->names;
	return unless (@$names);

	$source_code->seek_modifier_open($this->[ATR_BLOCK_ID]);

	return if ($$source_code =~ m
		{
			\G(?:\012|\015\012?)[^\012\015\#]+=\h*@(ARGUMENTS|_)\h*;
		}sxgc);

	my $perl_code =
		'	my ('
		.join(', ', map("\$$_", @$names))
		.') = @ARGUMENTS;';

	unless ($$source_code =~ s{\G(\012|\015\012?)\K}{$perl_code$1}sx)
	{
		die("Could not add argument processing to package '$this->[ATR_BLOCK_ID]'.");
	}

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.179
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
