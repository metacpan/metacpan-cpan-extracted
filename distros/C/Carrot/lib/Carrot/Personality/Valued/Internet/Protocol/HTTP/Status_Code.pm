package Carrot::Personality::Valued::Internet::Protocol::HTTP::Status_Code
# /type class
# /attribute_type ::One_Anonymous::Scalar::Access
# /autoload *
# /capability "Represents a HTTP status code"
{
	use strict;
	use warnings 'FATAL' => 'all';

	MODULARITY {
		my $expressiveness = Carrot::modularity;
		$expressiveness->global_constants->add_plugins(
			'[=this_pkg=]::Constants');
	} #MODULARITY

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.56
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2010-2014 Winfried Trümper <pub+perl@wt.tuxomania.net>"
