package Carrot::Modularity::Constant::Local::Static_Flags
# /type class
# /instances singular
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/Local/Static_Flags./manual_modularity.pl');
	} #BEGIN

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide(
		my $dot_ini_class = '::Meta::Greenhouse::Dot_Ini');
	$expressiveness->package_resolver->provide_instance(
		my $pkg_patterns = '::Modularity::Package::Patterns');

	my $THIS = IS_UNDEFINED;

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;
	if (defined($THIS))
	{
		$this = $THIS;
	} else {
		$THIS = $this;
	}

	$this->[ATR_PACKAGE_RULES] = {'*' => {}};
	$this->[ATR_PREFIX_RULES] = {'*' => []};

	my $dot_ini = $dot_ini_class->indirect_constructor($this);
	$dot_ini->find_configuration;

	return;
}

sub dot_ini_got_separated_values
# /type method
# /effect ""
# //parameters
#	values
# //returns
{
	my ($this, $values) = @ARGUMENTS;

	my ($flag_value, $flag_name, $pkg_name) = @$values;
	if ($pkg_name eq '*')
	{
		$this->[ATR_PACKAGE_RULES]{'*'}{$flag_name} = $flag_value;

	} elsif ($pkg_patterns->is_package_anchor($pkg_name))
	{
		unless (exists($this->[ATR_PREFIX_RULES]{$flag_name}))
		{
			$this->[ATR_PREFIX_RULES]{$flag_name} = [];
		}
		push($this->[ATR_PREFIX_RULES]{$flag_name},
			[$pkg_name, length($pkg_name), $flag_value]);

	} else {
		$this->[ATR_PACKAGE_RULES]{$pkg_name}{$flag_name} = $flag_value;
	}
	return;
}

sub first_match
# /type method
# /effect ""
# //parameters
#	pkg_name        ::Personality::Abstract::Text
#	rules
# //returns
#	?
{
	my ($this, $pkg_name, $rules) = @ARGUMENTS;

	foreach my $rule (@$rules)
	{
		my ($prefix, $length, $flag_value) = @$rule;
		if (substr($pkg_name, 0, $length) eq $prefix)
		{
			return($flag_value);
		}
	}

	return(IS_UNDEFINED);
}

my $is_true = \&Carrot::Modularity::Constant::Global::Boolean::IS_TRUE;
my $is_false = \&Carrot::Modularity::Constant::Global::Boolean::IS_FALSE;

sub flag_for($$)
# /type function
# /effect ""
# //parameters
#	pkg_name        ::Personality::Abstract::Text
#	flag_name
# //returns
#	?
{
	my ($pkg_name, $flag_name) = @ARGUMENTS;

	if ($THIS->_flag_for($pkg_name, $flag_name))
	{
		return($is_true);
	} else {
		return($is_false);
	}
}

sub _flag_for($$)
# /type method
# /effect ""
# //parameters
#	pkg_name        ::Personality::Abstract::Text
#	flag_name
# //returns
#	?
{
	my ($this, $pkg_name, $flag_name) = @ARGUMENTS;

	my $rules = $this->[ATR_PACKAGE_RULES];
	if (exists($rules->{$pkg_name}))
	{
		my $pkg = $rules->{$pkg_name};
		return($pkg->{$flag_name}) if (exists($pkg->{$flag_name}));
		return($pkg->{'*'}) if (exists($pkg->{'*'}));
	}

	my $prefix_rules = $this->[ATR_PREFIX_RULES];
	if (exists($prefix_rules->{$flag_name}))
	{
		if (my $value = $this->first_match(
			   $pkg_name, $prefix_rules->{$flag_name})) {
			return($value);
		}
	}
	if (exists($prefix_rules->{'*'}))
	{
		if (my $value = $this->first_match(
			   $pkg_name, $prefix_rules->{'*'})) {
			return($value);
		}
	}

	if (exists($rules->{'*'}{$flag_name}))
	{
		return($rules->{'*'}{$flag_name});
	}

	return(IS_UNDEFINED);
}

sub constants_definitions
# /type method
# /effect ""
# //parameters
#	definitions
#	meta_monad  ::Meta::Monad
# //returns
{
	my ($this, $meta_monad, $definitions) = @ARGUMENTS;

	my $flag_names = $meta_monad->source_code->unique_matches(
		qr{[^\w\:](\w+)_FLAG\b});
	return unless (@$flag_names);

	foreach my $flag_name (@$flag_names)
	{
		next if ($flag_name ne uc($flag_name));
#		die("Lower or mixed case flag '$flag_name'.");

		$definitions->add_dynamic_alias(
			$flag_name.'_FLAG',
			__PACKAGE__.'::flag_for');
	}

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.194
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"