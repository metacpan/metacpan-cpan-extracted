package Carrot::Modularity::Constant::Global::Text::Line_Separators
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Global/Text/Line_Separators./manual_modularity.pl');
	} #BEGIN

	sub TXT_LINE_BREAK()       { qq{\n}   } # platform dependent
	sub TXT_CRLF()             { qq{\015\012} } # not platform dependent

	sub TXT_ANY_LINE_BREAK()   { qr{(?:\012|\015\012?)} } # not platform dependent

# =--------------------------------------------------------------------------= #

sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text::Word
#	::Personality::Abstract::Array?
{
	return('TXT_', [qw(
		LINE_BREAK
		ANY_LINE_BREAK
		CRLF)]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.61
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
