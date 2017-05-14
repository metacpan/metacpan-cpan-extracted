package Carrot::Diversity::Block_Modifiers::Plugins
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Block_Modifiers/Plugins./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $package_resolver = '::Modularity::Package::Resolver');

	$package_resolver->provide(
		my $generic_class = '::Diversity::Block_Modifiers::Plugin::_Generic');

	my $plugins = {
#		'file' => {
#			'revision_control' => $generic_class,
#			'license' => $generic_class,
#		},
		'package' => {
			'type' => {
				'*' => $generic_class
			},
			'capability' => $generic_class,
		},
		'sub' => {
			'type' => {
				'*' => $generic_class
			},
			'effect' => $generic_class,
		},
		'for' => {},
		'foreach' => {},
		'while' => {},
		'if' => {},
		'eval' => {},
		'*' => {}
	};

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_PLUGINS] = $plugins;

	return;
}

sub add
# /type method
# /effect ""
# //parameters
#	package_name    ::Modularity::Package::Name
# //returns
{
	my ($this, $package_name) = @ARGUMENTS;

	$package_resolver->provide(
		my $keyword_class = $package_name->value);

	my $address = [@{$keyword_class->indirect->address}];

	my $position = $this->[ATR_PLUGINS];
	my $last_element = pop($address);
	unless (defined($last_element))
	# /assertion
	{
		die(join('--', @$address));
	}
	foreach my $element (@$address)
	{
		unless (exists($position->{$element}))
		{
			$position->{$element} = {};
		}
		$position = $position->{$element};
	}
	if (exists($position->{$last_element})
	and not defined($position->{$last_element}))
	{
		die("Overwriting keyword '$last_element' is not allowed.");
	} else {
		$position->{$last_element} = $keyword_class;
	}

	return;
}

sub get
# /type method
# /effect ""
# //parameters
#	address
# //returns
{
	my ($this, $address) = @ARGUMENTS;

	my $class = $this->[ATR_PLUGINS];
	my ($type, $keyword, $value) = @$address;

	unless (exists($class->{$type}))
	{
		die("Unknown type '$type'.");
	}
	unless (exists($class->{$type}{$keyword}))
	{
		if (exists($class->{'*'}{$keyword}))
		{
			$type = '*';
		} else {
			die("Unknown modifier '$keyword' for block type '$type'.");
		}
	}
	$class = $class->{$type}{$keyword};
	return($class) if (defined(Scalar::Util::blessed($class)));

	unless (defined($value) and exists($class->{$value}))
	{
		if (exists($class->{'*'}))
		{
			$value = '*';
		} else {
			die("Unknown element '$value'.");
		}
	}
	return($class->{$value});
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.381
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
