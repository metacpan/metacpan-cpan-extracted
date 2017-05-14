package Carrot::Diversity::Block_Modifiers::Monad
# /type class
# /attribute_type ::Many_Declared::Ordered
# //parameters
#	plugins  [=project_pkg=]::Plugins
# /capability "Maintains the block modifiers of a package."
{
	my ($plugins) = @ARGUMENTS;

	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Block_Modifiers/Monad./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $loader = '::Modularity::Package::Loader',
		my $translated_errors = '::Meta::Greenhouse::Translated_Errors');

	my $parser_class = 'Carrot::Diversity::Block_Modifiers::Monad::Parser';
	$loader->load($parser_class, $plugins);

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	source_code
# //returns
{
	my ($this, $source_code) = @ARGUMENTS;

	$this->[ATR_ALL_BLOCKS] = IS_UNDEFINED;
	$this->[ATR_TRIGGER] = [];

	my $parser = $parser_class->constructor($this);
	$this->[ATR_PARSER] = $parser;
	$parser->parse_code($source_code);

	$this->[ATR_ALL_BLOCKS] = $parser->all_blocks;

	return;
}

sub all_blocks
# /type method
# /effect ""
# //parameters
# //returns
{
	return($_[THIS][ATR_ALL_BLOCKS]);
}

sub add_trigger
# /type method
# /effect ""
# //parameters
#	trigger
# //returns
{
	push($_[THIS][ATR_TRIGGER], $_[SPX_TRIGGER]);
	return;
}

sub managed_diversity
# /type method
# /effect ""
# //parameters
#	meta_monad  ::Meta::Monad::Phase::Prepare
#	source_code
# //returns
{
	my ($this, $meta_monad, $source_code) = @ARGUMENTS;

	foreach my $modifier (@{$this->[ATR_TRIGGER]})
	{
		eval {
			my $generated = $modifier->trigger_modifier(
				$meta_monad,
				$source_code,
				$this->[ATR_ALL_BLOCKS]);
			if (defined($generated))
			{
				$this->[ATR_PARSER]->parse_code($generated);
				$source_code->insert_before_perl_file_loaded($$generated);
			}
			return(IS_TRUE);

		} or $translated_errors->escalate(
			'modifier_failed',
			[$modifier->class_name],
			$EVAL_ERROR);
	}

	unless (DEBUG_FLAG)
	{
		$$source_code =~ s{(\{|\})\K #--8<-- [\w\-\:]+ -->8--#}{}saag;
		$$source_code =~ s{\h*#--8<-- [\w\-\:]+ -->8--#\n}{}saag;
	}

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.360
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
