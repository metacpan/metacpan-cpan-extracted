package Carrot::Personality::Valued::Internet::Protocol::HTTP::Header::Data::Cookie
# /type class
# /attribute_type ::Many_Declared::Ordered
# //parent_classes
#	::Personality::Valued::Internet::Protocol::HTTP::
#		::Header_Lines::_Cookies
#		::URL_Encoding
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_RAW] = IS_UNDEFINED;
	$this->[ATR_COOKIES] = {};

	return;
}

sub value
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_RAW]);
}

sub assign_value
# /type method
# /effect ""
# //parameters
#	raw
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_RAW] = $_[SPX_RAW];
	$this->[ATR_COOKIES] = $this->cookie_deserialize($_[SPX_RAW]);

	return;
}

sub cookies
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_COOKIES]);
}

sub by_name
# /type method
# /effect ""
# //parameters
#	name
# //returns
#	?
{
	return unless (defined($_[SPX_NAME]));
	return unless (exists($_[THIS][ATR_COOKIES]{$_[SPX_NAME]}));
	return(join(',', @{$_[THIS][ATR_COOKIES]{$_[SPX_NAME]}}));
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.53
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2010-2014 Winfried Trümper <pub+perl@wt.tuxomania.net>"