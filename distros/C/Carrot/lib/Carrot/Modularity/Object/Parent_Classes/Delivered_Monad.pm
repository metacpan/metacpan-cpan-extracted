package Carrot::Modularity::Object::Parent_Classes::Delivered_Monad
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Object/Parent_Classes/Delivered_Monad./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide(
	        my $package_name_class = '::Modularity::Package::Name',
		my $attribute_type_class = '::Diversity::Attribute_Type');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	pkg_name
#	perl_isa
# //returns
{
	my ($this, $pkg_name, $perl_isa) = @ARGUMENTS;

	$this->[ATR_PERL_ISA] = $perl_isa;
	$this->[ATR_PACKAGE_NAME] = $package_name_class
		->constructor($pkg_name);
	$this->[ATR_ATTRIBUTE_TYPE] = IS_UNDEFINED;
	$this->[ATR_ATTRIBUTE_TYPE] =
		my $attribute_type = $attribute_type_class->constructor($this);

	#FIXME: unclear whether required and if, whether it should go
	# into the upstream method as well
	my $type = $this->inherit_type({});
	$attribute_type->assign($type) if (defined($type));

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.315
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
