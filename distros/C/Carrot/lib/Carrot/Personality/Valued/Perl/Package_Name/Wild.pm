package Carrot::Personality::Valued::Perl::Package_Name::Wild
# /type class
# //parent_classes
#	::Personality::Elemental::Scalar::Textual
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';


	my $syntax_re = '(^|::)(\w+|\[=(package|sibling|parent|project|former|generic_oo|singular_monad)=\])(::\w+)*$';
# =--------------------------------------------------------------------------= #

sub import_textual_value
# /type method
# /effect "Verifies the parameter"
# //parameters
#	value
# //returns
#	::Personality::Abstract::Boolean
{
	return($_[SPX_VALUE] =~ m{$syntax_re}so);
}

sub resolved
# /type method
# /effect ""
# //parameters
#	class_names
#	*
# //returns
#	?
{
	my ($this, $class_names) = splice(\@ARGUMENTS, 0, 2);

	$$this =~ s{\h+$}{}s;
	my $arguments = [split(qr{\h+}, $$this, PKY_SPLIT_RETURN_FULL_TRAIL)];
	my $pkg_name = $arguments->[0];
	my $resolved = $class_names->resolve_n_load($pkg_name, IS_UNDEFINED);

	return($resolved);
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
