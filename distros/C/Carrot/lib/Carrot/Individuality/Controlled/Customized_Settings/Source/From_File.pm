package Carrot::Individuality::Controlled::Customized_Settings::Source::From_File
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';


	Carrot::Meta::Greenhouse::Package_Loader::provide(
		my $file_name_class = '::Personality::Valued::File::Name::Type::Regular::Content::UTF8_wBOM');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	$_[THIS][ATR_FILE_NAME] = IS_UNDEFIED;
	return;
}

sub add_line
# /type method
# /effect ""
# //parameters
#	line
# //returns
{
	$_[THIS][ATR_FILE_NAME] = $file_name_class->constructor($_[SPX_LINE]);
	return;
}

sub as_text
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	$_[THIS][ATR_FILE_NAME]->read_into(my $buffer);
	return(\$buffer);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.69
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"