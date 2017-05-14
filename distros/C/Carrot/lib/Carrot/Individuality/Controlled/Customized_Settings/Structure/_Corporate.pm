package Carrot::Individuality::Controlled::Customized_Settings::Structure::_Corporate
# /type class
# /instances none
# //parent_classes
#	[=component_pkg=]
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

# =--------------------------------------------------------------------------= #

sub process_clone
# /type method
# /effect ""
# //parameters
#	raw_data
# //returns
#	?
{
	my ($this, $raw_data) = @ARGUMENTS;

	my $clone = $this->clone_constructor;
	$clone->modify($raw_data);

	return($clone);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.51
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
