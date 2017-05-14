package Carrot::Meta::Monad::Managed_File
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability "Determine and perform update of a compiled definitions file"
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Meta/Monad/Managed_File./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	meta_monad
# //returns
{
	my ($this, $meta_monad) = @ARGUMENTS;

	$this->[ATR_PKG_MTIME] = $meta_monad->package_file->status
		->modification_timestamp;
	$this->[ATR_NEEDS_UPDATE] = IS_FALSE;
	$this->[ATR_NAME] = IS_UNDEFINED;

	return;
}

sub name
# /type method
# /effect ""
# //parameters
# //returns
{
	return($_[THIS][ATR_NAME]);
}

sub needs_update
# /type method
# /effect ""
# //parameters
# //returns
{
	return($_[THIS][ATR_NEEDS_UPDATE]);
}

sub set
# /type method
# /effect ""
# //parameters
#	file_name
# //returns
{
	my ($this, $file_name) = @ARGUMENTS;

	if ($file_name->exists)
	{
		if ($this->[ATR_PKG_MTIME]->is_newer(
				$file_name->status->modification_timestamp))
		{
			$this->[ATR_NEEDS_UPDATE] = IS_FALSE;
		} else {
			$this->[ATR_NEEDS_UPDATE] = IS_TRUE;
		}
	} else {
			$this->[ATR_NEEDS_UPDATE] = IS_TRUE;
	}
	$this->[ATR_NAME] = $file_name;

	return;
}

sub update
# /type method
# /effect ""
# //parameters
#	definitions
# //returns
{
	my ($this, $definitions) = @ARGUMENTS;

	my $file_name = $this->[ATR_NAME];
	$file_name->consider_regular_content;
	my $perl_code = $definitions->as_perl_code;
	$file_name->overwrite_from($$perl_code);
	return;
}

sub require
# /type method
# /effect ""
# //parameters
#	meta_monad
# //returns
{
	my ($this, $meta_monad) = @ARGUMENTS;

	@ARGUMENTS = ($meta_monad);
	CORE::require($this->[ATR_NAME]->value);
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.255
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
