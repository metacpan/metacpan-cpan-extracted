package Carrot::Diversity::Block_Modifiers::Plugin::_Prototype
# /type class
# /instances none
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Block_Modifiers/Plugin/_Prototype./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	block_id  ::Personality::Abstract::Text
#	value     ::Personality::Abstract::Text
# //returns
{
	my ($this, $block_id, $value) = @ARGUMENTS;

	$this->[ATR_BLOCK_ID] = $block_id;
	$this->[ATR_VALUE] = $value;

	return;
}

sub block_id
# /type method
# /effect "Returns the attribute block_id."
# //parameters
# /returns
#	::Personality::Abstract::Text
{
	return($_[THIS][ATR_BLOCK_ID]);
}

sub modifier_value
# /type method
# /effect "Returns the attribute value."
# //parameters
# /returns
#	::Personality::Abstract::Text
{
	return($_[THIS][ATR_VALUE]);
}

sub address
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Array
# /prototype mandatory
;

sub trigger_modifier
# /type method
# /effect ""
# //parameters
#	meta_monad  ::Meta::Monad
#	source_code      ::Modularity::Package::Source
#	all_blocks       ::Diversity::Block_Modifiers::Plugin::Monad::Blocks
# //returns
#	::Modularity::Package::Source +IS_UNDEFINED
# /prototype mandatory
;

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.99
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
