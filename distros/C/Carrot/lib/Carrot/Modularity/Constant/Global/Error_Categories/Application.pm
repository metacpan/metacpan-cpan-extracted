package Carrot::Modularity::Constant::Global::Error_Categories::Application
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Global/Error_Categories/Application./manual_modularity.pl');
	} #BEGIN

	sub ERROR_CATEGORY_META() { "\x{1}meta" }
	sub ERROR_CATEGORY_SETUP() { "\x{1}setup" }
	sub ERROR_CATEGORY_IMPLEMENTATION() { "\x{1}implementation" }
	sub ERROR_CATEGORY_USAGE() { "\x{1}usage" }
	sub ERROR_CATEGORY_POLICY() { "\x{1}policy" }
	sub ERROR_CATEGORY_RESOURCES() { "\x{1}resources" }
	sub ERROR_CATEGORY_OS_PROCESS() { "\x{1}os_process" }
	sub ERROR_CATEGORY_OS_SIGNAL_ALARM() { "\x{1}os_signal_alarm" }

# =--------------------------------------------------------------------------= #

sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text::Word
#	::Personality::Abstract::Array?
{
	return('ERROR_CATEGORY_', [qw(
		META
		SETUP
		IMPLEMENTATION
		USAGE
		POLICY
		HARDWARE
		OS_RESOURCES
		OS_SIGNAL_ALARM)]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.38
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
