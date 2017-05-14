package Carrot::Personality::Valued::Internet::Protocol::HTTP::Header::Configuration
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $class_generator = '::Modularity::Package::Generator::Global_Constants',
		'::Individuality::Controlled::',
			my $class_names = '::Class_Names',
			my $distinguished_exceptions = '::Distinguished_Exceptions',
			my $customized_settings = '::Customized_Settings');

	$class_names->provide(
		my $name_class = '[=this_pkg=]::Name');

	$class_names->assign_anchor('[=parent_pkg=]::Data');
	$class_names->provide(
		my $plain_class = '::_Plain');

	$customized_settings->provide_plain_value(
		my $header_names = 'header_names');
	#	my ($name, $type, $order, $class) = @$association;

	if ($class_generator->needs_update('[=parent_pkg=]::Name::Constants'))
	{
		my $names = ;
		my $pairs = [];
		foreach my $name (@$names)
		{
			my $value = $name;
			$name = uc($name =~ s{-}{_}sg);
			push($pairs, [$name, $value]);
		}
		$class_generator->create('HTTP_HEADER_', $pairs);
	}

	if ($customized_settings->are_modified)
	{
		my $pairs = map([(lc($_->[0]) =~ s{-}{_}sgr), $_->[0]], @$header_names);

		require Data::Dumper;
		print STDERR Data::Dumper::Dumper($pairs);
		exit(1);
		$scalar_isset_methods->indirect(@$pairs);
	}

	$distinguished_exceptions->provide(
		my $hash_key_duplicate = 'hash_key_duplicate');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_NAMES] = {};
	$this->[ATR_SERIAL_GROUP] = {};

	return;
}

sub indirect_constructor
# /type method
# /effect ""
# //parameters
#	name
#	type
# //returns
#	?
{
	my ($this, $name, $type) = @ARGUMENTS;

	my $names = $this->[ATR_NAMES];
	unless (exists($names->{$name}))
	{
#		my $header_name = $configured_names->undef_unless_exists($name);
		my $class_name = $header_names->table_query_first(
			'class', 'name', $name);

		$class_names->provide($class_name);
		$names->{$name} = $class_name;
#		$this->[ATR_SERIAL_GROUP]{$name} =
#			$header_name->sort_category;
#		$this->[ATR_TYPES]{$name} =
#			$header_name->sort_category;
	}
	return($names->{$name}->indirect_constructor);
}

sub grouped_names
# /type method
# /effect ""
# //parameters
#	names
# //returns
{
	my ($this, $names) = @ARGUMENTS;

	my $grouped = [[], [], []];
	my $serial_group = $this->[ATR_SERIAL_GROUP];
	foreach my $name (@$names)
	{
		push($grouped->[$serial_group->{$name} // 1], $name);
	}
	return ([@{$grouped->[0]}, @{$grouped->[1]}, @{$grouped->[2]}]);
}

sub register_header_name
# /type method
# /effect ""
# //parameters
#	name
#	pkg_name
# //returns
#	?
{
	my ($this, $name, $pkg_name) = @ARGUMENTS;

	if (exists($configured_names->{$name}))
	{
		$hash_key_duplicate->raise_exception(
			{+HKY_DEX_BACKTRACK => $name,
			'key' => $name,
			'hash' => 'configured_names->',
			'value' => $configured_names->{$name}},
			ERROR_CATEGORY_SETUP);
	}

	$configured_names->{$name} = $class_names->indirect_instance($pkg_name);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.159
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2010-2014 Winfried Trümper <pub+perl@wt.tuxomania.net>"