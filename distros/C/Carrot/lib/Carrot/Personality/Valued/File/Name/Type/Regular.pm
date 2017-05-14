package Carrot::Personality::Valued::File::Name::Type::Regular
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Personality/Valued/File/Name/Type/Regular./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $translated_errors = '::Meta::Greenhouse::Translated_Errors');

# =--------------------------------------------------------------------------= #

sub require_fatally
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->SUPER::require_fatally;
	unless ($this->is_type_regular)
	{
		$translated_errors->advocate('not_a_regular_file', [$$this]);
	}

	return;
}

sub directory
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return((${$_[THIS]} =~ s{/[^/]*$}{}sr));
}

sub extension
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return((${$_[THIS]} =~ s{^.*\.}{}sr));
}

sub change_extension
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	?
{
	return((${$_[THIS]} =~ s{\.\K\w+$}{$_[SPX_VALUE]}s));
}

sub changed_extension
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	?
{
	my $file_name = (${$_[THIS]} =~ s{\.\K\w+$}{$_[SPX_VALUE]}sr);
	return($_[THIS]->sibling_constructor($file_name));
}

sub byte_size_is_bigger
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	?
{
	return((stat(${$_[THAT]}))[RDX_STAT_SIZE]
		> (stat(${$_[THIS]}))[RDX_STAT_SIZE]);
}

sub byte_size_is_equal
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	?
{
	return((stat(${$_[THAT]}))[RDX_STAT_SIZE]
		== (stat(${$_[THIS]}))[RDX_STAT_SIZE]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.83
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
