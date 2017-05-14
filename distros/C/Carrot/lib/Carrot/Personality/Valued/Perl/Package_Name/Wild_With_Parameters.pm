package Carrot::Personality::Valued::Perl::Package_Name::Wild_With_Parameters
# /type class
# //parent_classes
#	::Personality::Valued::Perl::Package_Name::Wild
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';


	my $syntax_re = '(^|::)(\w+|\[=(variant|any|package|parent_name|grandparent_name|project|generic_oo|singular_monad)=\])(::\w+)*(\h+|$)';
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

sub indirect_instance
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
	my (@arguments) = split(qr{\h+}, $$this, PKY_SPLIT_RETURN_FULL_TRAIL);
	my $pkg_name = shift(@arguments);
	my $instance = $class_names->indirect_instance(
		$pkg_name,
		@ARGUMENTS,
		@arguments);

	return($instance);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.84
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
