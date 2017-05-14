package Carrot::Meta::Monad::Phase::Run
# /type class
# //parent_classes
#	::Meta::Monad
# //parameters
#	meta_provider  ::Meta::Provider
# /capability "Capabilities of the $meta_monad during run time."
{
	my ($meta_provider) = @ARGUMENTS;

	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Meta/Monad/Phase/Run./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	that  ::Meta::Monad
# //returns
{
	my ($this, $that) = @ARGUMENTS;

	@$this = @$that;
	$this->[ATR_PRINCIPLE] = 'individuality';

	return;
}

sub DESTROY
# /type method
# /effect ""
# //parameters
# //returns
{
	return if (${^GLOBAL_PHASE} eq 'DESTRUCT');
	my ($this) = @ARGUMENTS;

	$this->[ATR_SOURCE_CODE] = IS_UNDEFINED;
	$meta_provider->remove_meta_monad($this->package_name->value);
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.190
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"