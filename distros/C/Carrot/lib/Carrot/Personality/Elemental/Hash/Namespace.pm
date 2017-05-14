package Carrot::Personality::Elemental::Hash::Namespace
# /type class
# /attribute_type ::One_Anonymous::Hash
# /capability ""
{
	die('Obviously this is broken.');

	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $distinguished_exceptions = '::Individuality::Controlled::Distinguished_Exceptions');

	$distinguished_exceptions->provide(
		my $hash_element_missing = 'hash_element_missing',
		my $hash_key_duplicate = 'hash_key_duplicate');

	#
# =--------------------------------------------------------------------------= #

sub register
# /type method
# /effect ""
# //parameters
#	key
#	value
# //returns
#	?
{
	my ($this, $key, $value) = @ARGUMENTS;

	if (exists($this->{$key}))
	{
		$hash_key_duplicate->raise_exception(
			{+HKY_DEX_BACKTRACK => $key,
			 'key' => $key,
			 'value' => \$this->{$key}},
			ERROR_CATEGORY_SETUP);
	}
	$this->unlock_attribute_structure;
	$this->{$key} = $value;
	$this->lock_attribute_structure;
}

sub by_name
# /type method
# /effect ""
# //parameters
#	key
# //returns
#	?
{
	my ($this, $key) = @ARGUMENTS;

	unless (exists($this->{$key}))
	{
		$hash_element_missing->raise_exception(
#No such element '%s' in index.
			{'key' => $key},
			ERROR_CATEGORY_SETUP);
	}
	return($this->{$key});
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.50
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
