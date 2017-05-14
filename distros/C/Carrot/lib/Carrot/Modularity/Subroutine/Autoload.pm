package Carrot::Modularity::Subroutine::Autoload
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Subroutine/Autoload./manual_modularity.pl');
	} #BEGIN

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide(
		my $package_name_class = '::Modularity::Package::Name');

	$expressiveness->package_resolver->provide_instance(
		my $translated_errors = '::Meta::Greenhouse::Translated_Errors');

	$expressiveness->declare_provider;

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

#	$this->[ATR_META_MONADS] = $meta_monads;

	return;
}

sub managed_modularity
# /type method
# /effect ""
# //parameters
#	definitions
#	meta_monad  ::Meta::Monad
# //returns
{
	my ($this, $meta_monad, $definitions) = @ARGUMENTS;

	return unless ($meta_monad->dot_directory->
		entry('autoload')->exists);
	my $package_name = $meta_monad->package_name;
	my $pkg_name = $package_name->value;
	if ($pkg_name eq 'main')
	{
		die('Autoload currently not supported for main package.');
	}

	my $autoload_pl = $package_name->dot_directory_logical.'/autoload.pl';
	$definitions->add_require($autoload_pl);
	$definitions->add_crosslinks(__PACKAGE__, ['AUTOLOAD']);

	return;
}

our $AUTOLOAD;
sub AUTOLOAD
# /type function
# /effect "Loads the code for a method from a .pl file in ./autoload."
# /parameters *
# /returns *
{
	if (TRACE_FLAG)
	{
		print(STDERR "Autoload caller: ", join("\n", caller), "\n");
	}
	my $sub_on_demand = $AUTOLOAD; # danger of a changing global variable
	unless ($sub_on_demand =~ m{^(?:([\w\:]+)(::))?(\w+)$},)
	{
#		$translated_errors->advocate(
#			'invalid_name',
#			[$AUTOLOAD]);
	}
	my ($pkg_name, $sub_name) = ($1, $3);
	return if ($sub_name eq 'DESTROY');
#	unless ($_[THIS]->can($sub_name))
#	{
#		die("Subroutine name '$sub_name' isn't in autoload.pl");
#	}

	my $package_name = $package_name_class->indirect_constructor($pkg_name);

	my $dot_directory = $package_name->dot_directory_actual;
	$dot_directory->require_fatally;

	my $autoload = $dot_directory->entry('autoload');
	$autoload->consider_directory;
	$autoload->require_fatally;

	my $sub_file = $autoload->entry($sub_name.'.pl');
	$sub_file->require_fatally;

	require($sub_file->value);

	die($sub_on_demand) unless (defined(&$sub_on_demand));
	goto(&$sub_on_demand);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.175
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
