package Carrot::Personality::Valued::Internet::Protocol::HTTP::Protocol_Version
# /type class
# /attribute_type ::One_Anonymous::Scalar::Access
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		my $expressiveness = Carrot::modularity;
		$expressiveness->global_constants->add_plugins(
			'[=this_pkg=]::Constants');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub numerical_version
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(${$_[THIS]} =~ m{^HTTP/(\d\.\d)$}s);
}

sub equals_numerical_version
# /type method
# /effect ""
# //parameters
#	version
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} =~ m{^HTTP/$_[SPX_VERSION]$}s);
}

sub set_numerical_version
# /type method
# /effect ""
# //parameters
#	version
# //returns
{
	${$_[THIS]} = "HTTP/$_[SPX_VERSION]";
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.46
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2010-2014 Winfried Trümper <pub+perl@wt.tuxomania.net>"
