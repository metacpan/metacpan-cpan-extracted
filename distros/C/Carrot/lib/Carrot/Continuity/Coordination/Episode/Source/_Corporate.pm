package Carrot::Continuity::Coordination::Episode::Source::_Corporate
# /type class
# /instances none
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->class_names->provide_instance(
		my $loop = '[=project_pkg=]::Loop');

# =--------------------------------------------------------------------------= #

sub T_ETERNITY() { 2**31 -1; };

sub max_timeout
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Seconds
{
	return(T_ETERNITY);
}

sub await
# /type method
# /effect ""
# //parameters
#	value
# //returns
{
	sleep($_[SPX_VALUE]);
	return;
}

sub DESTROY
# /type method
# /effect ""
# //parameters
# //returns
{
	if (defined($loop))
	{
		$loop->deregister($_[THIS]);
		$loop = IS_UNDEFINED;
	}
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.55
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
