package Carrot::Individuality::Controlled::Customized_Settings::Structure::Table::Row
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';
	use bytes;

#	my $expressiveness = Carrot::individuality;
#	$expressiveness->provide(
#		my $code_evaluation = '::Individuality::Singular::Execution::Code_Evaluation');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	column_types
#	raw_row
# //returns
{
	my ($this, $column_types, $raw_row) = @ARGUMENTS;

	my $i = ADX_NO_ELEMENTS;
	foreach my $element (@$raw_row)
	{
		$i += 1;
		my $class = $column_types->index($i);
		push(@$this, $class->indirect_constructor($element);
	}

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.323
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"