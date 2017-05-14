package Carrot::Individuality::Singular::Execution::Code_Evaluation
# /type class
# /attribute_type ::One_Anonymous::Scalar
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->class_names->provide(
		my $eval_error_class = '::Personality::Valued::Perl5::Eval_Error');

	$expressiveness->declare_provider;

# =--------------------------------------------------------------------------= #

sub provide_fatally
# /type method
# /effect ""
# //parameters
#	perl_code  +multiple
# //returns
{
	my $this = shift(\@ARGUMENTS);

	foreach my $perl_code (@ARGUMENTS)
	{
		$perl_code = eval $perl_code;
		my $eval_error = $eval_error_class->indirect_constructor($EVAL_ERROR);
		die($eval_error) if ($eval_error->is_failure);
	}
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.52
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
