package Carrot::Modularity::Package::Name::Space
# /type class
# /attribute_type ::One_Anonymous::Scalar
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Package/Name/Space./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance_soonest(
		my $package_resolver = 'Carrot::Modularity::Package::Resolver');

# =--------------------------------------------------------------------------= #

sub get_isa
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	my $isa = eval qq{package $$this { our \@ISA; return(\\\@ISA); };};
	die($EVAL_ERROR) if ($EVAL_ERROR);
	return($isa);
}

sub fresh_n_sane
# /type method
# /effect ""
# //parameters
#	name
# //returns
{
	my ($this, $name) = @ARGUMENTS;

	if (defined(&{'CORE::'.$name}))
	{
		die("The name '$name' looks like a builtin.");
	}
	if ($name =~ m{\W})
	{
		die("The name '$name' doesn't look sane enough.");
	}

	return;
}

sub is_defined_subroutine
# /type method
# /effect ""
# //parameters
#	name
# //returns
#	::Personality::Abstract::Scalar::Boolean
{
	return(defined(&{${$_[THIS]}.'::'.$_[SPX_NAME]}));
}

sub add_crosslink
# /type method
# /effect ""
# //parameters
#	name
#	source_pkg
# //returns
{
	my ($this, $name, $source_pkg) = @ARGUMENTS;

	$this->fresh_n_sane($name);
	$package_resolver->provide($source_pkg);

	my $pkg_name = $source_pkg->value;
	eval qq{package $$this { \*$name = \\&${pkg_name}::$name; };};
	die($EVAL_ERROR) if ($EVAL_ERROR);

	return;
}

sub add_inline_function
# /type method
# /effect ""
# //parameters
#	name
#	value
# //returns
{
	my ($this, $name, $value) = @ARGUMENTS;

	$this->fresh_n_sane($name);
	if ($value =~ m{\W})
	{
		die("The value '$value' doesn't look sane enough.");
	}

	eval qq{package $$this { sub $name() { q{$value} }}};
	die($EVAL_ERROR) if ($EVAL_ERROR);

	return;
}

sub require_file
# /type method
# /effect ""
# //parameters
#	file_name       ::Personality::Valued::File::Name
# //returns
{
	my ($this, $file_name) = @ARGUMENTS;

	eval qq{package $$this { require \$file_name; };};
	die($EVAL_ERROR) if ($EVAL_ERROR);

	return;
}

sub require_files
# /type method
# /effect ""
# //parameters
#	file_names
# //returns
{
	my ($this, $file_names) = @ARGUMENTS;

	eval qq{package $$this { foreach my \$file_name (@\$file_names) { require \$file_name; }}};
	die($EVAL_ERROR) if ($EVAL_ERROR);

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.91
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
