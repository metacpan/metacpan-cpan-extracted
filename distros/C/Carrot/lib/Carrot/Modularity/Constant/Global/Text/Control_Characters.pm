package Carrot::Modularity::Constant::Global::Text::Control_Characters
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Global/Text/Control_Characters./manual_modularity.pl');
	} #BEGIN

	sub CHR_NULL()            { chr(0) }
	sub CHR_TABULATOR()       { chr(9) }
	sub CHR_LINE_FEED()       { chr(10) }
	sub CHR_CARRIAGE_RETURN() { chr(13) }
	sub CHR_FORM_FEED()       { chr(12) }
	sub CHR_BELL()            { chr(7) }
	sub CHR_ESCAPE()          { chr(27) }

# =--------------------------------------------------------------------------= #

sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text::Word
#	::Personality::Abstract::Array?
{
	return('CHR_', [qw(
		NULL
		TABULATOR
		LINE_FEED
		CARRIAGE_RETURN
		FORM_FEED
		BELL
		ESCAPE)]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.46
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
