package Carrot::Productivity::Text::Placeholder::Miniplate::OS::Unix::File::Properties
# /type class
# //parent_classes
#	::Productivity::Text::Placeholder::Miniplate::_Corporate
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $distinguished_exceptions = '::Individuality::Controlled::Distinguished_Exceptions');

	$distinguished_exceptions->provide(
		my $file_not_found = 'file_not_found');

# =--------------------------------------------------------------------------= #

sub as_rwx_string($)
# /type function
# /effect ""
# //parameters
#	P_MODE
# //returns
#	?
{
	my $permissions = [split('', unpack('b*', pack('i', $_[SPX_MODE])),
		PKY_SPLIT_RETURN_FULL_TRAIL)];
	foreach my $i (0, 3, 6)
	{
		$permissions->[$i] = ($permissions->[$i]) ? 'x' : '-';
		$permissions->[$i+1] = ($permissions->[$i+1]) ? 'w' : '-';
		$permissions->[$i+2] = ($permissions->[$i+2]) ? 'r' : '-';
	}
	$permissions->[0] = 's' if ($permissions->[9]);
	$permissions->[3] = 's' if ($permissions->[10]);
	$permissions->[6] = 's' if ($permissions->[11]);
	return(join('', reverse(splice($permissions, 0, 9))));
}

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_SUBJECT] = IS_UNDEFINED;
	$this->[ATR_STAT] = [];

	return;
}

sub set_subject
# /type method
# /effect ""
# //parameters
#	name
# //returns
{
	my ($this, $name) = @ARGUMENTS;

	unless (-e $name)
	{
		$file_not_found->raise_exception(
			{'file_name' => $name},
			ERROR_CATEGORY_SETUP);
	}
	$this->[ATR_SUBJECT] = $name;
	$this->[ATR_STAT] = [stat($name)];

	return;
}

sub syp_file_mode_octal
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_STAT][RDX_STAT_MODE]);
}

sub syp_file_mode_rwx
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(as_rwx_string($_[THIS][ATR_STAT][RDX_STAT_MODE]));
}

sub syp_file_owner_id
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_STAT][RDX_STAT_UID]);
}

sub file_owner_name
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return((getpwuid($_[THIS][ATR_STAT][RDX_STAT_UID]))[RDX_GETPW_NAME]);
}

sub syp_file_group_id
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_STAT][RDX_STAT_GID]);
}

sub syp_file_group_name
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return((getgrgid($_[THIS][ATR_STAT][RDX_STAT_GID]))[RDX_GETGR_NAME]);
}

sub syp_file_size
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_STAT][RDX_STAT_SIZE]);
}

sub syp_file_timestamp_access
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(localtime($_[THIS][ATR_STAT][RDX_STAT_ATIME]));
}

sub syp_file_timestamp_modification
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(localtime($_[THIS][ATR_STAT][RDX_STAT_MTIME]));
}

sub syp_file_timestamp_status
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(localtime($_[THIS][ATR_STAT][RDX_STAT_CTIME]));
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.68
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"