package Carrot::Personality::Structured::Internet::Protocol::HTTP::Response::Line
# /type class
# /attribute_type ::Many_Declared::Ordered
# /class_anchor   ::Personality::Valued::Internet::Protocol::HTTP
# //attribute_construction
#	protocol     ::Protocol_Version +method
#	status_code  ::Status_Code +method
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

#	my $expressiveness = Carrot::individuality;
#	$expressiveness->class_names->provide(
#		'::Personality::Valued::Internet::Protocol::HTTP::',
#			my $protocol_class = '::Protocol_Version',
#			my $status_class = '::Status_Code');

# =--------------------------------------------------------------------------= #

sub assign_value
# /type method
# /effect ""
# //parameters
#	protocol
#	status_code
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_PROTOCOL]->assign_value($_[SPX_PROTOCOL]);
	$this->[ATR_STATUS_CODE]->assign_value($_[SPX_STATUS_CODE]);

	return;
}

sub append_to_value
# /type method
# /effect ""
# //parameters
#	value
# //returns
{
	my $this = $_[THIS];

	$_[SPX_VALUE] .=
		$this->[ATR_PROTOCOL]->value
		. ' '
		. $this->[ATR_STATUS_CODE]->numerical_n_textual
		. "\015\012";

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.90
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2010-2014 Winfried Trümper <pub+perl@wt.tuxomania.net>"
