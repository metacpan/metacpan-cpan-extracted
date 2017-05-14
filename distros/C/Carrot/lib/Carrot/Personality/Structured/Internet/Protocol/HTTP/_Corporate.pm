package Carrot::Personality::Structured::Internet::Protocol::HTTP::_Corporate
# /type class
# /instances none
# /attribute_type ::Many_Declared::Ordered
# /class_anchor ::Personality::Valued::Internet::Protocol::HTTP::
# //attribute_construction
#	line          IS_UNDEFINED +commented
#	header_lines  ::Header::Lines +method
#	body          IS_UNDEFINED +method
#	pending       IS_FALSE +predicate +set
#	cachable      IS_FALSE +predicate +set
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->class_names->provide(
#		'::Personality::Valued::Internet::Protocol::HTTP::',
			my $scalar_body_class = '::Body::Scalar',
			my $file_handle_body_class = '::Body::File_Handle');

# =--------------------------------------------------------------------------= #

sub scalar_body
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	?
{
	$_[THIS][ATR_BODY] = $scalar_body_class
		->indirect_instance($_[SPX_VALUE]);
}

sub file_handle_body
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	?
{
	$_[THIS][ATR_BODY] = $file_handle_body_class
		->indirect_instance($_[SPX_VALUE]);
}

sub append_head_to
# /type method
# /effect ""
# //parameters
#	string
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_LINE]->append_to($_[SPX_STRING]);
	$this->[ATR_HEADER_LINES]->append_to($_[SPX_STRING]);
	$_[SPX_STRING] .= "\015\012";

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.95
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2010-2014 Winfried Trümper <pub+perl@wt.tuxomania.net>"
