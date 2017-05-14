package Carrot::Modularity::Package::File_Name::Qualification
# /type class
# /instances singular
# /capability "Qualification of a file based on @MODULE_SEARCH_PATH"
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Package/File_Name/Qualification./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub as_list
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(join(', ', @MODULE_SEARCH_PATH));
}

sub find_first
# /type method
# /effect ""
# //parameters
#	name
# //returns
#	?
{
	my ($this, $pkg_file) = @ARGUMENTS;

	foreach my $directory (@MODULE_SEARCH_PATH)
	{
		my $file_name = "$directory/$pkg_file";
		return($file_name) if (-e $file_name);;
	}
	return(IS_UNDEFINED);
}

sub qualify_first
# /type method
# /effect ""
# //parameters
#	pkg_file       ::Personality::Valued::File::Name
# //returns
#	::Personality::Abstract::Boolean
{
	my ($this, $pkg_file) = @ARGUMENTS;

	my $found = $this->find_first($pkg_file);
	return(IS_FALSE) unless (defined($found));
	$_[SPX_PKG_FILE] = $found;
	return(IS_TRUE);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.72
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
