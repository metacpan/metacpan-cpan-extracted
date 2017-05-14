package Carrot::Personality::Valued::Text
# /type class
# //parent_classes
#	::Personality::Elemental::Scalar::Textual
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';


# =--------------------------------------------------------------------------= #

sub import_textual_value
# /type method
# /effect "Verifies the parameter"
# //parameters
#       value
# //returns
#       ::Personality::Abstract::Boolean
{
	return(IS_TRUE);
}

#sub trim_white_space_ends
## /type method
## /effect ""
## //parameters
## //returns
#{
#        $_[THIS] =~ s{\s+$}{}s;
#        $_[THIS] =~ s{^\s+}{}s;
#        return;
#}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.42
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
