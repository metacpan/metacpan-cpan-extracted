package Carrot::Personality::Valued::Perl5::Caller::Fancy
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Personality/Valued/Perl5/Caller/Fancy./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide(
		my $package_name_class = '::Modularity::Package::Name',
		my $file_name_class = '::Personality::Valued::File::Name::Type::Regular::Content::UTF8_wBOM');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->SUPER::attribute_construction;
	$this->_re_constructor;

	return;
}

sub _re_constructor
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[RDX_CALLER_PACKAGE] = $package_name_class->constructor(
		$this->[RDX_CALLER_PACKAGE]);
	$this->[RDX_CALLER_FILE] = $file_name_class->constructor(
		$this->[RDX_CALLER_FILE]);

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.61
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"