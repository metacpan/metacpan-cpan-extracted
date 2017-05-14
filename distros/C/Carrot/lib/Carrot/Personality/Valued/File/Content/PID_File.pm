package Carrot::Personality::Valued::File::Content::PID_File
# /type class
# //parent_classes
#	::Personality::Valued::File::Name::Type::Regular::Content::UTF8_wBOM
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';
	use bytes;


# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	file_name 	 ::Personality::Abstract::Raw::Text
# //returns
{
	my ($this, $file_name) = @ARGUMENTS;

	$$this = $file_name;

	my $parent_directory = $this->parent_directory;
	$parent_directory->require_fatally;

	if ($this->exists)
	{
		$this->require_type_regular_fatally;
#		 unless ($this->is_owned_effectively)
#		 {
#			 $file_not_owned->raise_exception(
#				 {+HKY_DEX_BACKTRACK => $file_name,
#				  'file_name' => $file_name,
#				 'uid' => $EFFECTIVE_USER_ID},
#				 ERROR_CATEGORY_SETUP);
#		 }
	}

	return;
}

sub retrieve
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	$_[THIS]->read_into(my $pid);
	return($pid);
}

sub store
# /type method
# /effect ""
# //parameters
#	pid
# //returns
{
	$_[THIS]->overwrite_from($_[SPX_PID]);
	return;
}

sub store_current
# /type method
# /effect ""
# //parameters
# //returns
{
	$_[THIS]->overwrite_from($PROCESS_ID);
	return;
}

sub remove
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	if ($this->exists)
	{
		unless ($this->superseded)
		{
#			$perl_unlink_failed->raise_exception(
#				{+HKY_DEX_BACKTRACK => $$this,
#				 'file_name' => $$this,
#				 'os_error' => $OS_ERROR},
#				ERROR_CATEGORY_SETUP);
		}
	}
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.49
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"