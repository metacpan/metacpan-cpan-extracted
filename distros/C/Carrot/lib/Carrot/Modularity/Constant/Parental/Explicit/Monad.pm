package Carrot::Modularity::Constant::Parental::Explicit::Monad
# /type class
# /attribute_type ::Many_Declared::Ordered
# //parameters
#	monad_provider  ::Modularity::Constant::Parental::Explicit
#	inheritance  ::Modularity::Object::Inheritance::ISA_Occupancy
# /capability ""
{
	my ($monad_provider, $inheritance) = @ARGUMENTS;

	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Parental/Explicit/Monad./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	meta_monad  ::Meta::Monad
# //returns
{
	my ($this, $meta_monad) = @ARGUMENTS;

	$this->[ATR_META_MONAD] = $meta_monad;
	$this->[ATR_NAMES] = [];

	return;
}

my $inherit = \&inherit;
sub inherit
# /type method
# /effect ""
# //parameters
#	definitions
# //returns
{
	my ($this, $definitions) = @ARGUMENTS;

	if (@{$this->[ATR_NAMES]})
	{
		$definitions->add_crosslinks(
			$this->[ATR_META_MONAD]->package_name->value,
			$this->[ATR_NAMES]);
	}
	$inheritance->call_occupied(
		$this->[ATR_META_MONAD]->parent_classes->perl_isa,
		$inherit,
		$definitions);
	return;
}

sub set_local_inheritable
# /type method
# /effect ""
# //parameters
#	names
# //returns
{
	my ($this, $names) = @ARGUMENTS;

	$this->[ATR_NAMES] = $names;

	$monad_provider->store_monad(
		$this->[ATR_META_MONAD]->package_name->value,
		$this);
	return;
}

sub parse_source
# /type method
# /effect ""
# //parameters
#	definitions
# //returns
{
	my ($this, $definitions) = @ARGUMENTS;

	$this->inherit($definitions);

	my $source_code = $this->[ATR_META_MONAD]->source_code;
	my $names = [($$source_code =~ m{
			(?:\012|\015\012?)\h*sub\h+(\w+)\(\)
			(?:\012|\015\012?)\h*\#\h+/type\h+constant\h+/inheritable
			(?:\012|\015\012?)\h*\{[^\}]*\}}sgx)];
	return unless (@$names);

	$this->[ATR_NAMES] = $names;
	$monad_provider->store_monad(
		$this->[ATR_META_MONAD]->package_name->value,
		$this);

#	$definitions->(
#		'::Modularity::Constant::Parental::Explicit'
#		'set_local_inheritable',
#		$names);
	my $code = sprintf(q{
$expressiveness->explicit_parental_constants->set_local_inheritable([qw(%s)]);
},
		join(' ', @$names));
	$definitions->add_code($code);

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.142
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"