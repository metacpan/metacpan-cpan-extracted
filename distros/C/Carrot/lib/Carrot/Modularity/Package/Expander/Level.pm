package Carrot::Modularity::Package::Expander::Level
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Package/Expander/Level./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $english_re = '::Diversity::English::Regular_Expression',
		my $inc_search_path = '::Modularity::Package::File_Name::Combination',
		my $translated_errors = '::Meta::Greenhouse::Translated_Errors');

	my $re_level = $english_re->compile('
		ON_START ( ANY_CHARACTER ANY_TIMES )
		PERL_PKG_DELIMITER  ASTERISK  ON_END',
		[RE_MOD_SAFER_UNICODE,  RE_MOD_SINGLE_LINE]);

# =--------------------------------------------------------------------------= #

sub expands
# /type class_method
# /effect ""
# //parameters
#	pkg_name
# //returns
#	?
{
	if ($_[SPX_CANDIDATE] =~ m{$re_level}o)
	{
		return($_[SPX_CLASS]->constructor($1));
	} else {
		return;
	}
}

sub expand
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	$this->qualify('Carrot');
	# More than an assertion, because it's setup data
	unless ($this->is_valid)
	{
		$translated_errors->advocate(
			'invalid_package_name',
			[$this->value]);
	}
	my $pkg_base = $this->base_name_logical;

	my $pkg_name = $this->value;
	my $package_names = [];
	foreach my $package_file (@{$inc_search_path->list_level($pkg_base)})
	{
		next if ($package_file->is_supportive);
		push($package_names, $package_file->as_package_name);
	}
	return($package_names);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.238
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
