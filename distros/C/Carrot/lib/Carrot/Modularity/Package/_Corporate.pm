package Carrot::Modularity::Package::_Corporate
# /type class
# /instances none
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Package/_Corporate./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $named_re = '::Meta::Greenhouse::Named_RE',
		my $pkg_patterns = '::Modularity::Package::Patterns');

	$named_re->provide(
		my $re_perl_pkg_name = 'perl_pkg_name');

# =--------------------------------------------------------------------------= #

sub is_valid
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return((${$_[THIS]} =~ m{$re_perl_pkg_name}o));
}

sub import_textual_value
# /type method
# /effect "Verifies the parameter"
# //parameters
#	value
# //returns
#	::Personality::Abstract::Boolean
{
	return(($_[SPX_VALUE] =~ m{$re_perl_pkg_name}o));
}

sub qualify
# /type method
# /effect ""
# //parameters
#	prefix
# //returns
{
	my ($this, $prefix) = @ARGUMENTS;
	$pkg_patterns->qualify_package_name($$this, $prefix);
	return;
}

sub is_relative
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return($pkg_patterns->is_relative_package_name(${$_[THIS]}));
}

#NOTE: absolute are several things
#sub is_absolute

sub base_name_logical
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text
{
	return((${$_[THIS]} =~ s{::}{/}saagr));
}

sub file_name_logical
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text
{
	return($_[THIS]->base_name_logical.'.pm');
}

# for searching through @INC
sub dot_directory_logical
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text
{
	return($_[THIS]->base_name_logical.'.');
}

sub relative_name
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text
{
	return(${$_[THIS]} =~ s{\A.*::}{}saar);
}

sub prefix
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text
{
	return(${$_[THIS]} =~ s{[^\:]+\z}{}saar);
}

sub leading_underscore
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} =~ m{::_}s); # ::_Role::, ::_Corporate::
}

sub hierarchy_depth
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Number
{
	return((${$_[THIS]} =~ m{(::)}sg));
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.102
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
