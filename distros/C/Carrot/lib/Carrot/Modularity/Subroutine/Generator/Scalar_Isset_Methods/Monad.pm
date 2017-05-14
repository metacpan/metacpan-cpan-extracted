package Carrot::Modularity::Subroutine::Generator::Scalar_Isset_Methods::Monad
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Subroutine/Generator/Scalar_Isset_Methods/Monad./manual_modularity.pl');
	} #BEGIN

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide(
		my $autoload_directory_class =
			'::Modularity::Subroutine::Autoload::Directory');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	meta_monad  ::Meta::Monad
# //returns
{
	my ($this, $meta_monad) = @ARGUMENTS;

	$this->[ATR_PACKAGE_NAME] = $meta_monad->package_name;
	$this->[ATR_AUTOLOAD_DIRECTORY] =
		$autoload_directory_class->indirect_constructor(
			$meta_monad);

	return;
}

my $set_template = q{
package %s;
use strict;
use warnings;
sub set_%s
{
	${$_[THIS]} = '%s';
	return;
}
};

my $is_template = q{
package %s;
use strict;
use warnings;
sub is_%s
{
	return(${$_[THIS]} eq '%s');
}
};

sub direct
# /type method
# /effect ""
# //parameters
#	value  +multiple
# //returns
{
	my $this = shift(\@ARGUMENTS);

	my $autoload_directory = $this->[ATR_AUTOLOAD_DIRECTORY];
	my $pkg_name = $this->[ATR_PACKAGE_NAME]->value;
	foreach my $value (@ARGUMENTS)
	{
		$autoload_directory->store_unless_exists(
			"set_$value",
			sprintf($set_template, $pkg_name, $value, $value));
		$autoload_directory->store_unless_exists(
			"is_$value",
			sprintf($is_template, $pkg_name, $value, $value));
	}

	return;
}

sub enumerated
# /type method
# /effect ""
# //parameters
#	offset
# //returns
{
	my ($this, $offset) = splice(\@ARGUMENTS, 0, 2);

	$this->indirect(map([$_, $offset++], @ARGUMENTS));

	return;
}

sub indirect
# /type method
# /effect ""
# //parameters
#	pair  +multiple
# //returns
{
	my $this = shift(\@ARGUMENTS);

	my $autoload_directory = $this->[ATR_AUTOLOAD_DIRECTORY];
	my $pkg_name = $this->[ATR_PACKAGE_NAME]->value;
	foreach my $pair (@ARGUMENTS)
	{
		my ($name, $value) = @$pair;
		$autoload_directory->store_unless_exists(
			"set_$value",
			sprintf($set_template, $pkg_name, $name, $value));
		$autoload_directory->store_unless_exists(
			"is_$value",
			sprintf($is_template, $pkg_name, $name, $value));
	}

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.204
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"