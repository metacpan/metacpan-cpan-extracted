package Carrot::Modularity::Object::Parent_Classes
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Object/Parent_Classes./manual_modularity.pl');
	} #BEGIN

#	require Carrot::Modularity::Package::Block_Options;
#	my $pkg_options =
#		Carrot::Modularity::Package::Block_Options->constructor;

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $translated_errors = '::Meta::Greenhouse::Translated_Errors');

	my $upgrades = Carrot::Meta::Greenhouse::Shared_Subroutines::upgrades;

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide_name_only(
		my $monad_class = '[=this_pkg=]::Monad',
		my $delivered_monad_class = '[=this_pkg=]::Delivered_Monad');
	$expressiveness->declare_provider;

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_MONADS] = my $monads = {};
	$this->[ATR_MONAD_CLASS] = $monad_class;

	$monad_class->load($this);
	$delivered_monad_class->load;

	return;
}

sub manual_principle
# /type method
# /effect "Returns an individual monad for a package."
# /alias_name manual_modularity
# //parameters
#	meta_monad ::Meta::Monad
# //returns
#       ::Personality::Abstract::Instance
{
        my ($this, $meta_monad) = @ARGUMENTS;

        my $pkg_name = $meta_monad->package_name->value;
        my $monads = $this->[ATR_MONADS];
        if (exists($monads->{$pkg_name}))
        {
                return($monads->{$pkg_name});
        }

        return($monads->{$pkg_name} =
		$monad_class->indirect_constructor($meta_monad));
}
#FIXME: quick hack before removing _Corporate
*manual_modularity = \&manual_principle;

# used by Universal.pm
sub lookup
# /type method
# /effect ""
# //parameters
#	pkg_name       ::Personality::Abstract::Text
# //returns
#	::Personality::Abstract::Instance +undefined
{
	my ($this, $pkg_name) = @ARGUMENTS;

	if (exists($this->[ATR_MONADS]{$pkg_name}))
	{
		return($this->[ATR_MONADS]{$pkg_name});
	}
	if (exists($upgrades->{$pkg_name}))
	{
		#FIXME: was put here for easier individual debugging;
		# more efficient is to have it in the attribute_construction
		$this->[ATR_MONADS]{$pkg_name} = $delivered_monad_class
			->indirect_constructor(
				$pkg_name,
				$upgrades->{$pkg_name});
		return($this->[ATR_MONADS]{$pkg_name});
	}

	$translated_errors->oppose(
		'hash_key_missing',
		[$pkg_name, 'ATR_MONADS']);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.278
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
