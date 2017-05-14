package Carrot::Modularity::Package::Source_Code::Begin_Block
# /type class
# /instances singular
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
        use strict;
        use warnings 'FATAL' => 'all';

        BEGIN {
                require('Carrot/Modularity/Package/Source_Code/Begin_Block./manual_modularity.pl');
        } #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide(
		my $array_class = '::Diversity::Attribute_Type::One_Anonymous::Array');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this, $source_code) = @ARGUMENTS;

        $this->[ATR_SOURCE_CODE] = $source_code;
        $this->[ATR_LINES] = $array_class->constructor;

        return;
}

sub add_require
# /type method
# /effect ""
# //parameters
#	file_name
# //returns
{
	my ($this, $file_name) = @ARGUMENTS;

	$this->[ATR_LINES]->append_value("require(q{$file_name});");

	return;
}

sub add_crosslink
# /type method
# /effect ""
# //parameters
#	source_pkg
#	name
# //returns
{
	my ($this, $source_pkg, $name) = @ARGUMENTS;

	$this->[ATR_LINES]->append_value(
		sprintf('*%s = \&%s::%s;', $name, $source_pkg, $name));

	return;
}

sub commit
# /type method
# /effect ""
# //parameters
# //returns
{
        my ($this) = @ARGUMENTS;

	my $code = join("\n", @{$this->[ATR_LINES]});
	$this->[ATR_SOURCE_CODE]->insert_after_modularity($code);
	$this->[ATR_LINES] = [];

        return;
}

# =--------------------------------------------------------------------------= #

        return(1);
}
# //revision_control
#       version 1.1.2
#       branch main
#       maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
