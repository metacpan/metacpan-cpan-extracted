package Carrot::Personality::Valued::File::Name::Status
# /type class
# //parent_classes
#	::Personality::Valued::Perl5::Stat
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Personality/Valued/File/Name/Status./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide(
		my $timestamp_class = '::Personality::Valued::Date::Timestamp');

# =--------------------------------------------------------------------------= #

sub access_timestamp
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Instance
{
	return($timestamp_class->constructor($_[THIS][RDX_STAT_ATIME]));
}

sub modification_timestamp
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Instance
{
	return($timestamp_class->constructor($_[THIS][RDX_STAT_MTIME]));
}

sub status_change_timestamp
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Instance
{
	return($timestamp_class->constructor($_[THIS][RDX_STAT_CTIME]));
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.32
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
