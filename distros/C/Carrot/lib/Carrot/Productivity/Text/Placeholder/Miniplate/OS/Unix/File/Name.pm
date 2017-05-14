package Carrot::Productivity::Text::Placeholder::Miniplate::OS::Unix::File::Name
# /type class
# //parent_classes
#	::Productivity::Text::Placeholder::Miniplate::_Corporate
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	sub IDX_SUBJ_FULL() { 0 }
	sub IDX_SUBJ_PATH() { 1 }
	sub IDX_SUBJ_BASE() { 2 }
	sub IDX_SUBJ_EXTENSION() { 3 }

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_SUBJECT] = [];

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

	my ($full, $path, $extension) = ($name, '', '');
	if ($name =~ s{^(.*)/}{}s)
	{
		$path = $1;
	}
	if ($name =~ s{\.(.*?)$}{}s)
	{
		$extension = $1;
	}

	$this->[ATR_SUBJECT] = [$full, $path, $name, $extension];

	return;
}

sub syp_file_name_full
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_SUBJECT][IDX_SUBJ_FULL])
}

sub syp_file_name_path
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_SUBJECT][IDX_SUBJ_PATH])
}

sub syp_file_name_base
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_SUBJECT][IDX_SUBJ_BASE])
}

sub syp_file_name_extension
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_SUBJECT][IDX_SUBJ_EXTENSION])
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.57
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"