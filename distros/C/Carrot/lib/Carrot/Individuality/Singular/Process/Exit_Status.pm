package Carrot::Individuality::Singular::Process::Exit_Status
# /type class
# /instances singular
# /attribute_type ::One_Anonymous::Scalar
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;

#NOTE: currently best compromise to satisfy END{}
	my $THIS = \(my $this = 0);
	bless($THIS, __PACKAGE__);

	$expressiveness->declare_provider;

# =--------------------------------------------------------------------------= #

sub constructor
# /type class_method
# /effect "Constructs a new instance."
# //parameters
# //returns
#	::Personality::Abstract::Instance
{
	return($THIS);
}

sub assign_value
# /type method
# /effect ""
# //parameters
#	exit_status
# //returns
{
	my ($this, $exit_status) = @ARGUMENTS;

	if ($exit_status > $$this)
	{
		$$this = $exit_status;
	}
	return;
}

sub reset
# /type method
# /effect ""
# //parameters
# //returns
{
	$$THIS = 0;
	return;
}

END {
	# CHILD_ERROR refers to the own process only here
	if ($$THIS > $CHILD_ERROR)
	{
		$CHILD_ERROR = $$THIS;
	}
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.59
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
