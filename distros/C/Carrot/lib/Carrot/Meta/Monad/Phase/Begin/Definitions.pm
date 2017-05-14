package Carrot::Meta::Monad::Phase::Begin::Definitions
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability "Generate code for managed_modularity.pl"
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Meta/Monad/Phase/Begin/Definitions./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide(
		my $array_class = '::Diversity::Attribute_Type::One_Anonymous::Array');

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $translated_errors = '::Meta::Greenhouse::Translated_Errors');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	meta_monad        ::Meta::Monad::Phase::Begin
# //returns
{
	my ($this, $meta_monad) = @ARGUMENTS;

	$this->[ATR_PKG_NAME] = $meta_monad->package_name->value;
	$this->[ATR_SOURCE_CODE] = $meta_monad->source_code;

	$this->[ATR_SEEN] = {};
	$this->[ATR_LINES] = $array_class->constructor;

	return;
}

sub already_exists
# /type method
# /effect ""
# //parameters
#	name
# //returns
#	::Personality::Abstract::Boolean
{
	my ($this, $name) = @ARGUMENTS;

	return(IS_TRUE) if (exists($this->[ATR_SEEN]{$name}));
	my $sub_name = "$this->[ATR_PKG_NAME]::$name";
#FIXME: \n is not safe - might be on a different platform
	if (defined(&$sub_name)
	or (${$this->[ATR_SOURCE_CODE]} =~ m{\nsub\s+$name\(\)}s))
	{
		$this->[ATR_SEEN]{$name} = IS_EXISTENT;
		return(IS_TRUE);
	}
	return(IS_FALSE);
}

sub add_require
# /type method
# /effect ""
# //parameters
#	file_name
# //returns
{
	my ($this, $file_name) = @ARGUMENTS;

	$file_name =~ s{[^\w:\-\./]}{X}sgaa;
	#FIXME: non-portable to Windows
	if ($file_name =~ m{(\A|/)(\.\.|\.|)(/|\z)}s)
	{
		$translated_errors->oppose(
			'policy_no_dot',
			[$file_name]);
	}
	if ($file_name =~ m{\A/}s)
	{
		$translated_errors->oppose(
			'policy_only_relative',
			[$file_name]);
	}

	return if ($this->already_exists($file_name));
	$this->[ATR_LINES]->append_value('require(q{'.$file_name.'});');
	$this->[ATR_SEEN]{$file_name} = IS_EXISTENT;

	return;
}

sub add_alias
# /type method
# /effect ""
# //parameters
#	source_pkg
#	name
#	original
# //returns
{
	my ($this, $source_pkg, $name, $original) = @ARGUMENTS;

	return if ($this->already_exists($name));
	$this->[ATR_LINES]->append_value(
		sprintf('*%s = \&%s::%s;', $name, $source_pkg, $original));
	$this->[ATR_SEEN]{$name} = IS_EXISTENT;

	return;
}

sub add_crosslinks
# /type method
# /effect ""
# //parameters
#	source_pkg
#	names
# //returns
{
	my ($this, $source_pkg, $names) = @ARGUMENTS;

	foreach my $name (@$names)
	{
		$this->add_crosslink($source_pkg, $name);
	}

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

	return if ($this->already_exists($name));
	$this->[ATR_LINES]->append_value(
		sprintf('*%s = \&%s::%s;', $name, $source_pkg, $name));
	$this->[ATR_SEEN]{$name} = IS_EXISTENT;

	return;
}

sub add_constant_function
# /type method
# /effect ""
# //parameters
#	name
#	value
# //returns
{
	my ($this, $name, $value) = @ARGUMENTS;

	return if ($this->already_exists($name));
	$this->[ATR_LINES]->append_value(
		sprintf('sub %s() { %s };', $name, $value));
	$this->[ATR_SEEN]{$name} = IS_EXISTENT;

	return;
}

sub add_dynamic_alias
# /type method
# /effect ""
# //parameters
#	name
#	value
# //returns
{
	my ($this, $name, $value) = @ARGUMENTS;

	if ($name =~ m{\W}s)
	{
		$translated_errors->oppose(
			'invalid_symbol_name',
			[$name]);
	}
	unless ($value =~ m{^[\w:]+$}s)
	{
		$translated_errors->oppose(
			'invalid_subroutine_name',
			[$value]);
	}

	$this->[ATR_LINES]->append_value(
		sprintf(q{*%s = %s(__PACKAGE__, '%s');},
			$name, $value, $name));
	return;
}

sub add_code
# /type method
# /effect ""
# //parameters
#	perl_code
# //returns
{
	my ($this, $perl_code) = @ARGUMENTS;

	$this->[ATR_LINES]->append_value($perl_code);

	return;
}

sub as_perl_code
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	my $datetime = scalar(gmtime(time()));

	my $perl_code = join("\n",
		"# Automatically created on $datetime GMT.",
		'# Manual changes will get lost.',
		"package $this->[ATR_PKG_NAME];",
		'my ($expressiveness) = @_;',
		'use strict;',
		'use warnings;',
		'#--8<-- cut -->8--',
		@{$this->[ATR_LINES]},
		'#--8<-- cut -->8--',
		'return(1);',
		'');

	return(\$perl_code);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.111
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"