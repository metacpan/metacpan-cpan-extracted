package Carrot::Meta::Greenhouse::Carrot_Arguments
# /type class
# /instances singular
# /attribute_type ::One_Anonymous::Hash
# /capability "Initial management of named directories."
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Meta/Greenhouse/Carrot_Arguments./manual_modularity.pl');
	} #BEGIN

	my $THIS = bless({'carrot-mode' => 'default'}, __PACKAGE__);
	foreach my $argument (splice(\@PROGRAM_ARGUMENTS))
	{
		if ($argument =~ m{\A--(carrot-[\w\-]+)=(\"|\'|)(.*?)\g{2}\z}s)
		{
			$THIS->{$1} = $3;
		} else {
			push(\@PROGRAM_ARGUMENTS, $argument);
		}
	}
	Internals::hv_clear_placeholders(%$THIS);
        Internals::SvREADONLY(%$THIS, 1);

# =--------------------------------------------------------------------------= #

sub constructor
# /type class_method
# /effect "Constructs a new instance."
# //parameters
# //returns
#	::Personality::Abstract::Instance
{
	return($THIS);
}

sub assign_if_exists
# /type method
# /effect "Resolves placeholders with actual directories."
# //parameters
#	key
#	value
# //returns
#	 ?
{
	my ($this, $key) = @ARGUMENTS;

	if (exists($this->{$key}))
	{
		$_[SPX_VALUE] = $this->{$key};
	}
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.164
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
