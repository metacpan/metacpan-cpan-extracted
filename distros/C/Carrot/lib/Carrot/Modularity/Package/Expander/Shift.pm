package Carrot::Modularity::Package::Expander::Shift
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Package/Expander/Shift./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $named_re = '::Meta::Greenhouse::Named_RE',
		my $english_re = '::Diversity::English::Regular_Expression');

	$named_re->provide(
		my $re_perl_pkg_last_element = 'perl_pkg_last_element');

	my $re_expand = $english_re->compile('
		ON_START ( ANY_CHARACTER ANY_TIMES )
			PERL_PKG_DELIMITER
			DOUBLE LESS_SIGN  ASTERISK
			PERL_PKG_DELIMITER
		( ANY_CHARACTER ANY_TIMES )  ON_END',
		[RE_MOD_SAFER_UNICODE,  RE_MOD_SINGLE_LINE]);

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
        my ($this, $base, $end) = @ARGUMENTS;

        $this->[ATR_BASE] = $base;
        $this->[ATR_END] = $end;

        return;
}

sub expands
# /type class_method
# /effect ""
# //parameters
#	pkg_name
# //returns
#	?
#	?
{
	if ($_[SPX_CANDIDATE] =~ m{$re_expand}o) #^(.+)::<<\*::(.+)$
	{
		return($_[SPX_CLASS]->constructor($1, $2));
	} else {
		return;
	}
}

sub expand
# /type method
# /effect ""
# //parameters
#	calling_pkg
# //returns
#	?
{
	my ($this, $calling_pkg) = @ARGUMENTS;

	my $pkg_names = [];
	my $minimum_length = length($this->[ATR_END]);
	while ($calling_pkg =~ s{$re_perl_pkg_last_element}{}o)
	{
		last if (length($calling_pkg) < $minimum_length);
		push($pkg_names, "${calling_pkg}::$this->[ATR_BASE]");
	}
	return($pkg_names);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.227
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"