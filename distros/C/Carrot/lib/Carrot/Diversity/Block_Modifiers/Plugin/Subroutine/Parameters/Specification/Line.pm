package Carrot::Diversity::Block_Modifiers::Plugin::Subroutine::Parameters::Specification::Line
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Block_Modifiers/Plugin/Subroutine/Parameters/Specification/Line./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	value
# //returns
{
	my ($this, $value) = @ARGUMENTS;

$this->[ATR_BLOCK_ID]
$this->[ATR_OPTIONS]
$this->[ATR_LIMITS]

	my $specifications = [];
	foreach my $line (@$value)
	{

		push($named_types,
			[split(qr{\h+}, $line, PKY_SPLIT_IGNORE_EMPTY_TRAIL)]);
	}
	$this->[ATR_BLOCK_IDD_TYPES] = $named_types;

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.15
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"