package Carrot::Personality::Elemental::Regular_Expression::English
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Personality/Elemental/Regular_Expression/English./manual_modularity.pl');
	} #BEGIN

	require Carrot::Diversity::English::Regular_Expression;
	my $re_english = Carrot::Diversity::English::Regular_Expression->constructor;

# =--------------------------------------------------------------------------= #

sub constructor
# /type class_method
# /effect "Constructs a new instance."
# /parameters *
# //returns
#       ::Personality::Abstract::Instance
{
        my $class = shift(\@ARGUMENTS);

        return(bless($re_english->compile(@ARGUMENTS), $class));
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.112
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
