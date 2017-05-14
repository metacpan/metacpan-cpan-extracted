package Carrot::Individuality::Controlled::Class_Names::Monad
# /type class
# //parent_classes
#	::Individuality::Controlled::_Corporate::Monad
# //parameters
#	inheritance  ::Modularity::Object::Inheritance::ISA_Occupancy
# /capability ""
{
#	my ($inheritance) = @ARGUMENTS;

	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide(
		my $array_class = '::Personality::Elemental::Array::Instances',
		my $tamed_class = '[=project_pkg=]::Tamed');

	$expressiveness->package_resolver->provide_instance(
		'::Modularity::Package::',
			my $pkg_patterns = '::Patterns',
			my $prefixed_list = '::Prefixed_List',
			my $package_resolver = '::Resolver');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	meta_monad  ::Meta::Monad
#	mapping
# //returns
{
#	my ($this, $meta_monad, $mapping) = @ARGUMENTS;

	$this->[ATR_PERL_ISA] = $meta_monad->parent_classes->perl_isa;
	$this->[ATR_PACKAGE_NAME] = $meta_monad->package_name,
	$this->[ATR_ANCHOR] = IS_UNDEFINED;
	$this->[ATR_MAPPING] = $mapping;

	return;
}

sub tamed
# /type method
# /effect ""
# /parameters *
# //returns
#	?
{
	my $this = shift(\@ARGUMENTS);

	my $tamed = $this->clone_constructor(@ARGUMENTS);
	$tamed->re_constructor($tamed_class->value);

	return($tamed);
}

sub assign_anchor
# /type method
# /effect ""
# //parameters
#	anchor          ::Personality::Abstract::Text
# //returns
{
	my ($this, $anchor) = @ARGUMENTS;

	$pkg_patterns->resolve_placeholders(
		$anchor,
		$this->[ATR_PACKAGE_NAME]->value);

	my $package_name = $this->resolve(
		$anchor,
		$this->[ATR_ANCHOR]);
	$this->[ATR_ANCHOR] = $package_name->value;

	return($this->[ATR_ANCHOR]);
}

#no use case so far
sub provide_name_only
# /type method
# /effect ""
# //parameters
#	pkg_name  +multiple  ::Personality::Abstract::Text
# //returns
{
	my $this = shift(\@ARGUMENTS);

	my $pkg_symbol = $this->[ATR_PACKAGE_NAME]->value;
	my $anchor = $this->[ATR_ANCHOR] // 'Carrot';
	foreach my $pkg_name (@ARGUMENTS)
	# /remove always
	{
		next if ($prefixed_list->is_anchor_prefix(
			$pkg_name,
			$anchor,
			$pkg_symbol));

		my $package_name = $this->resolve($pkg_name, $anchor);
		$pkg_name = $package_name;
	}

	if (0)
	{
		my $file_name = '';
		re_match($file_name,
			' PERIOD  WORD_CHARACTER MANY_TIMES  ON_END ',
			'ENGLISH, SAFER_UNICODE, SINGLE_LINE');
	}

	return;
}

sub provide
# /type method
# /effect "Replaces the supplied string with an instance."
# //parameters
#	pkg_name  +multiple       ::Personality::Abstract::Text
# //returns
{
	my $this = shift(\@ARGUMENTS);

	my $pkg_symbol = $this->[ATR_PACKAGE_NAME]->value;
	my $anchor = $this->[ATR_ANCHOR] // 'Carrot';
	foreach my $pkg_name (@ARGUMENTS)
	{
		next if ($prefixed_list->is_anchor_prefix(
			$pkg_name,
			$anchor,
			$pkg_symbol));

		my $package_name = $this->resolve_n_load($pkg_name, $anchor);
		$pkg_name = $package_name;
	}
	return;
}

my $map_lookup = \&map_lookup;
sub map_lookup
# /type method
# /effect ""
# //parameters
#	seen
#	pkg_name        ::Personality::Abstract::Text
# //returns
#	?
{
	my ($this, $seen, $pkg_name) = @ARGUMENTS;

	my $mapping = $this->[ATR_MAPPING];
	if (defined($mapping->{$pkg_name}))
	{
		return($mapping->{$pkg_name});
	}
	return($inheritance->first_defined_skip_seen(
			$this->[ATR_PERL_ISA],
			$map_lookup,
			$seen,
			$pkg_name));
}

sub resolve
# /type method
# /effect ""
# //parameters
#	pkg_name        ::Personality::Abstract::Text
#	anchor          ::Personality::Abstract::Text +IS_UNDEFINED
# //returns
#	?
{
	my ($this, $pkg_name, $anchor) = @ARGUMENTS;

	my $mapped = $this->map_lookup($this->initially_seen, $pkg_name)
		// $pkg_name;
	return($package_resolver->resolve(
		       $mapped,
		       $anchor // $this->[ATR_ANCHOR] // 'Carrot'));
}

sub resolve_n_load
# /type method
# /effect ""
# //parameters
#	pkg_name        ::Personality::Abstract::Text
#	anchor          ::Personality::Abstract::Text
# //returns
#	?
{
	my ($this, $pkg_name, $anchor) = @ARGUMENTS;

	my $package_name = $this->resolve($pkg_name,
		$anchor // $this->[ATR_ANCHOR] // 'Carrot');
	$package_name->load;

	return($package_name);
}

sub indirect_instance
# /type method
# /effect ""
# //parameters
#	pkg_name  ::Personality::Abstract::Text
#	*
# //returns
#	::Personality::Abstract::Instance
{
	my ($this, $pkg_name) = splice(\@ARGUMENTS, 0, 2);

	unless (Scalar::Util::blessed($pkg_name))
	{
		$pkg_patterns->resolve_placeholders(
			$pkg_name,
			$this->[ATR_PACKAGE_NAME]->value);
		$pkg_name = $this->resolve_n_load(
			$pkg_name,
			$this->[ATR_ANCHOR]);
	}
	return($pkg_name->indirect_constructor(@ARGUMENTS));
}

sub indirect_instances
# /type method
# /effect ""
# //parameters
#	pkg_names       ::Personality::Abstract::Text
# //returns
#	::Personality::Abstract::Instance
{
	my $this = shift(\@ARGUMENTS);
	return($array_class->indirect_constructor(
		       [map($this->indirect_instance(@{$_}), @ARGUMENTS)]));
}

sub indirect_instance_from_text
# /type method
# /effect ""
# //parameters
#	text
# //returns
#	::Personality::Abstract::Instance
{
	return($_[THIS]->indirect_instance(
		split(qr{\h+}, $_[SPX_TEXT], PKY_SPLIT_IGNORE_EMPTY_TRAIL)));
}

sub provide_instance
# /type method
# /effect "Replaces the supplied string with an instance of that type."
# //parameters
#	pkg_name  +multiple  ::Personality::Abstract::Text
# //returns
{
	my $this = shift(\@ARGUMENTS);

	$this->provide(@ARGUMENTS);
	foreach my $pkg_name (@ARGUMENTS)
	{
		next if (Scalar::Util::readonly($pkg_name));
		$pkg_name = $this->indirect_instance($pkg_name);
	}
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.225
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
