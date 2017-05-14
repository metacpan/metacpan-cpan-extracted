package Carrot::Individuality::Singular::Execution::STDERR_Redirector::Monad
# /type class
# /attribute_type ::One_Anonymous::Typeglob
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';
	require File::Spec;

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $distinguished_exceptions = '::Individuality::Controlled::Distinguished_Exceptions');

	$distinguished_exceptions->provide(
		my $file_not_found = 'file_not_found');

	my $dev_null = File::Spec->devnull;

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	file_name       ::Personality::Valued::File::Name
# //returns
{
	my ($this, $file_name) = @ARGUMENTS;

	$this->to_file($file_name);

	return;
}

sub to_file
# /type method
# /effect ""
# //parameters
#	file_name       ::Personality::Valued::File::Name
# //returns
{
	my ($this, $file_name) = @ARGUMENTS;

	my $rv = open($this, PKY_OPEN_MODE_WRITE, $file_name);
	unless (defined($rv))
	{
		$file_not_found->raise_exception(
			{'file_name' => $file_name},
			ERROR_CATEGORY_SETUP);
	}

	return;
}

 sub to_null
# /type method
# /effect ""
# //parameters
#	file_name       ::Personality::Valued::File::Name
# //returns
{
	my ($this, $file_name) = @ARGUMENTS;

	$this->to_file($dev_null);

	return;
}

sub to_file_handle
# /type method
# /effect ""
# //parameters
#	file_handle
# //returns
{
	my ($this, $file_handle) = @ARGUMENTS;

	open($this, PKY_OPEN_MODE_WRITE, $file_handle);

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