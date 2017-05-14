package Carrot::Individuality::Singular::Application::DBH::Wrapper
# /type class
# /attribute_type ::One_Anonymous::Scalar
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $distinguished_exceptions = '::Individuality::Controlled::Distinguished_Exceptions');

	$distinguished_exceptions->provide(
		my $failed_statement = 'failed_statement');

# =--------------------------------------------------------------------------= #

sub _fatal_end
# /type method
# /effect ""
# //parameters
#	statement
#	attributes
#	*
# //returns
{
	my ($this, $statement, $attributes) = splice(\@ARGUMENTS, 0, 3);

	require Data::Dumper;
	$failed_statement->raise_exception(
		{+HKY_DEX_BACKTRACK => $statement,
		 'statement' => $statement,
		 'error_message' => ${$this}->errstr,
		 'values' => \(my $values = Data::Dumper::Dumper(\@ARGUMENTS))},
		ERROR_CATEGORY_SETUP);
	return;
}

sub do
# /type method
# /effect ""
# /parameters *
# //returns
#	?
{
	my $this = shift(\@ARGUMENTS);

	my $rv = ${$this}->do(@ARGUMENTS);
	unless (defined($rv))
	{
		$this->_fatal_end(@ARGUMENTS);
	}
	return($rv);
}

sub prepare
# /type method
# /effect ""
# /parameters *
# //returns
#	?
{
	my $this = shift(\@ARGUMENTS);

	my $rv = ${$this}->prepare(@ARGUMENTS);
	unless (defined($rv))
	{
		$this->_fatal_end(@ARGUMENTS);
	}
	return($rv);
}

sub selectrow_arrayref
# /type method
# /effect ""
# /parameters *
# //returns
#	?
{
	my $this = shift(\@ARGUMENTS);

	my $rv = ${$this}->selectrow_arrayref(@ARGUMENTS);
	if ($#$rv == ADX_NO_ELEMENTS)
	{
		$this->_fatal_end(@ARGUMENTS);
	}
	return($rv);
}


our $AUTOLOAD;
my $creator = 'sub %s { return(${shift(\@ARGUMENTS)}->%s(@ARGUMENTS)); };';
sub AUTOLOAD
# /type function
# /effect ""
{
	my $method = $AUTOLOAD;
	$method =~ s{^.*::}{}s;
	eval sprintf($creator, $method, $method);
	die($EVAL_ERROR) if (length($EVAL_ERROR));
	my $can = $_[THIS]->can($method);
	die("Couldn't generate proxy method '$method'.") unless (defined($can));
	goto($can);
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
