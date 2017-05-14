package Carrot::Personality::Valued::Internet::Protocol::HTTP::Header::Names
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	MODULARITY {
		my $expressiveness = Carrot::modularity;
		$expressiveness->global_constants->add_plugins(
			'[=this_pkg=]::Constants');
	} #MODULARITY

	my $expressiveness = Carrot::individuality;
	my $class_names = $expressiveness->class_names;
	$expressiveness->customized_settings->provide_value(
		my $unknown_class = 'unknown_class',
		my $default_class = 'default_class',
		my $http_header_names = 'http_header_names');

	$class_names->assign_anchor('[=parent_pkg=]::Data');

	my $unknown_class_name = $unknown_class->value
		->resolved($class_names);
	my $default_class_name = $default_class->value
		->resolved($class_names);

	my $mapping = $http_header_names->plain_values_1iMxN;

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_NAMES] = {};

	return;
}

sub create
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
		my $class_name;
		if (exists($mapping->{$name}))
		{
			$class_name = $mapping->{$name}->[2];
			if (length($class_name))
			{
				$class_names->provide($class_name);
			} else {
				$class_name = $default_class_name;
			}
		} else {
			$class_name = $unknown_class_name;
		}
		$names->{$name} = $class_name;
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
	foreach my $name (@$names)
	{
		push($grouped->[$mapping->{$name}->[1] // 1], $name);
	}
	return ([@{$grouped->[0]}, @{$grouped->[1]}, @{$grouped->[2]}]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.227
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2010-2014 Winfried Trümper <pub+perl@wt.tuxomania.net>"
