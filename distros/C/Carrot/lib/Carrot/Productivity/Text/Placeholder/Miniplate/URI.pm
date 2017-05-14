package Carrot::Productivity::Text::Placeholder::Miniplate::URI
# /type class
# //parent_classes
#	[=component_pkg=]::_Corporate
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';
	require URI;

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	$_[THIS][ATR_URI] = IS_UNDEFINED;
	return;
}

sub set_subject
# /type method
# /effect ""
# //parameters
#	uri
# //returns
#	?
{
	$_[THIS][ATR_URI] = URI->new($_[SPX_URI]);
}

sub syp_uri_scheme
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_URI]->scheme)
}

sub syp_uri_host
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_URI]->host)
}

sub syp_uri_path
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_URI]->path)
}

sub syp_uri_opaque
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_URI]->opaque)
}

sub syp_uri_full
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_URI])
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.47
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"