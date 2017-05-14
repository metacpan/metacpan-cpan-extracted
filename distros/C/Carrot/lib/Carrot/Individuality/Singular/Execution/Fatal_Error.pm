package Carrot::Individuality::Singular::Execution::Fatal_Error
# /type class
# /attribute_type ::One_Anonymous::Scalar
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->class_names->provide(
		my $details_class = '::Individuality::Singular::Execution::Fatal_Error::Details');
	$expressiveness->declare_provider;

# =--------------------------------------------------------------------------= #

sub trigger
# /type method
# /effect ""
# /parameters *
# //returns
#	::Personality::Abstract::Instance
{
	my $this = shift(\@ARGUMENTS);
	die($this->record(@ARGUMENTS))
}

sub record
# /type method
# /effect ""
# /parameters *
# //returns
#	::Personality::Abstract::Instance
{
	my $this = shift(\@ARGUMENTS);
	return($details_class->indirect_constructor(@ARGUMENTS));
}

sub trigger_here
# /type method
# /effect ""
# /parameters *
# //returns
{
	shift(\@ARGUMENTS)->trigger([caller(1)], @ARGUMENTS);
	return;
}

sub trigger_there
# /type method
# /effect ""
# /parameters *
# //returns
{
	shift(\@ARGUMENTS)->trigger([caller(2)], @ARGUMENTS);
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.57
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
