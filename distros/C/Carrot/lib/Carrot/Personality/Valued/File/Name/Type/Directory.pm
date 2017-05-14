package Carrot::Personality::Valued::File::Name::Type::Directory
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Personality/Valued/File/Name/Type/Directory./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $translated_errors = '::Meta::Greenhouse::Translated_Errors');

	Carrot::Meta::Greenhouse::Package_Loader::provide(
		my $file_name_class = '::Personality::Valued::File::Name');

# =--------------------------------------------------------------------------= #

sub require_fatally
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->SUPER::require_fatally;
	unless ($this->is_type_directory)
	{
		$translated_errors->oppose(
			'not_a_directory',
			[$$this]);
	}

	return;
}

sub change_fatally
# /type method
# /effect ""
# //parameters
# //returns
{
	unless (chdir(${$_[THIS]}))
	{
		$translated_errors->oppose(
			'syscall_related',
			[${$_[THIS]}, 'chdir', $OS_ERROR]);
	}
	return;
}

sub entry
# /type method
# /effect ""
# //parameters
#	name
# //returns
#	::Personality::Abstract::Instance
{
	return($file_name_class->constructor(
		       ${$_[THIS]}
		       .OS_FS_PATH_DELIMITER
		       .$_[SPX_NAME]));
}

sub entry_with_type
# /type method
# /effect ""
# //parameters
#	name
#	type
# //returns
#	::Personality::Abstract::Instance
{
	my $entry = $_[THIS]->entry($_[SPX_NAME]);
	$entry->class_change($_[SPX_TYPE]);
	return($entry);
}

sub directory_entry
# /type method
# /effect ""
# //parameters
#	name
# //returns
#	::Personality::Abstract::Instance
{
	return($_[THIS]->sibling_constructor(
		       ${$_[THIS]}
		       .OS_FS_PATH_DELIMITER
		       .$_[SPX_NAME]));
}

sub entry_if_exists
# /type method
# /effect ""
# //parameters
#	name
# //returns
#	::Personality::Abstract::Instance +undefined
{
	my $file_name = $_[THIS]->entry($_[SPX_NAME]);
	return($file_name->exists ? $file_name: IS_UNDEFINED);
#	my $file_name = ${$_[THIS]}.OS_FS_PATH_DELIMITER.$_[SPX_NAME];
#	return(IS_UNDEFINED) unless (-e $file_name);
#	return($file_name_class->constructor($file_name));
}

sub qualify_file
# /type method
# /effect ""
# //parameters
#	name
# //returns
{
	$_[SPX_NAME]->qualify(${$_[THIS]});
	return;
}

sub qualify_file_if_exists
# /type method
# /effect ""
# //parameters
#	name
# //returns
#	::Personality::Abstract::Boolean
{
	my $candidate = $_[SPX_NAME]->qualified(${$_[THIS]});
	return(IS_FALSE) unless ($candidate->exists);
	$_[SPX_NAME]->assign($candidate);
	return(IS_TRUE);
}

sub create_fatally
# /type method
# /effect ""
# //parameters
#	name
# //returns
#	?
{
	unless (mkdir(${$_[THIS]}))
	{
		$translated_errors->advocate(
			'syscall_related',
			[${$_[THIS]}, 'mkdir', $OS_ERROR]);
	}
	return;
}

sub create_fatally_if_missing
# /type method
# /effect ""
# //parameters
#	name
# //returns
#	?
{
	unless ($_[THIS]->is_type_directory)
	{
		$_[THIS]->create_fatally;
	}
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.123
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
