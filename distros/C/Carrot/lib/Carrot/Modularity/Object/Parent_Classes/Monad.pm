package Carrot::Modularity::Object::Parent_Classes::Monad
# /type class
# /attribute_type ::Many_Declared::Ordered
# //parameters
#	monad_provider  ::Modularity::Object::Parent_Classes
# /capability ""
{
	my ($monad_provider) = @ARGUMENTS;

	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Object/Parent_Classes/Monad./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $translated_errors = '::Meta::Greenhouse::Translated_Errors',
		my $package_resolver = '::Modularity::Package::Resolver');
	$package_resolver->provide(
	        my $iterator_class = '::Personality::Reflective::Iterate::Array::Forward',
		my $attribute_type_class = '::Diversity::Attribute_Type');
	$package_resolver->provide_instance(
		my $prefixed_list = '::Modularity::Package::Prefixed_List');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	meta_monad  ::Meta::Monad
# //returns
{
	my ($this, $meta_monad) = @ARGUMENTS;

	my $pkg_name = $meta_monad->package_name->value;
	{
		no strict 'refs';
		my $perl_isa = \@{$pkg_name.'::ISA'};
		$this->[ATR_PERL_ISA] = $perl_isa;
	}
	$this->[ATR_PACKAGE_NAME] = $meta_monad->package_name;
	$this->[ATR_ATTRIBUTE_TYPE] = IS_UNDEFINED;
	$this->[ATR_ATTRIBUTE_TYPE] = $attribute_type_class
		->indirect_constructor($this);

	return;
}

sub perl_isa
# /type method
# /effect ""
# //parameters
# //returns
{
	return($_[THIS][ATR_PERL_ISA]);
}

sub contains
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	::Personality::Abstract::Boolean
{
	#FIXME: bless \@ISA like it was before?
	for (@{$_[THIS][ATR_PERL_ISA]}) {
		return(IS_TRUE) if ($_ eq $_[SPX_VALUE]);
	}
	return(IS_FALSE);
}

sub attribute_type
# /type method
# /effect ""
# //parameters
# //returns
{
	return($_[THIS][ATR_ATTRIBUTE_TYPE]);
}

sub add_qualified
# /type method
# /effect ""
# //parameters
#	pkg_name
# //returns
{
	my ($this, $pkg_name) = @ARGUMENTS;

	return if (grep(($pkg_name eq $_), @{$this->[ATR_PERL_ISA]}));
	push($this->[ATR_PERL_ISA], $pkg_name);
	return;
}

sub inherit_type
# /type method
# /effect ""
# //parameters
#	seen
# //returns
#	?
{
	my ($this, $seen) = @ARGUMENTS;

	if (defined($this->[ATR_ATTRIBUTE_TYPE]))
	{
		my $type = $this->[ATR_ATTRIBUTE_TYPE]->value;
		return($type) if (defined($type));
	}

	foreach my $parent_class (@{$this->[ATR_PERL_ISA]})
	{
		next if (exists($seen->{$parent_class}));
		$seen->{$parent_class} = IS_EXISTENT;
		next if ($parent_class =~ m{::Personality::Abstract::}s);

		my $monad = $monad_provider->lookup($parent_class);
#FIXME: isn't this fatal?
#FIXME: fails if no /attribute_type
		next unless (defined($monad));
		my $type = $monad->inherit_type($seen);
		return($type) if (defined($type));
	}
	return(IS_UNDEFINED);
}

#FIXME: change to inherited_attribute_type
sub inherited_type
# /type method
# /effect ""
# //parameters
#	pkg_name
# //returns
{
	my ($this, $pkg_name) = @ARGUMENTS;

	return if (grep(($pkg_name eq $_), @{$this->[ATR_PERL_ISA]}));
	push($this->[ATR_PERL_ISA], $pkg_name);
	return;
}

sub add
# /type method
# /effect ""
# //parameters
#	pkg_name  +multiple
# //returns
{
	my $this = shift(\@ARGUMENTS);

	my $package_names = $prefixed_list->resolved_package_names(
		[@ARGUMENTS], # copy of remaining parameters - read-only strings
		'Carrot',
		$this->[ATR_PACKAGE_NAME]->value);

	my $isa = [];
	foreach my $package_name (@$package_names)
	{
		my $pkg_name = $package_name->value;

		next if (grep(($pkg_name eq $_), @{$this->[ATR_PERL_ISA]}));
		$package_name->load;

		push($isa, $pkg_name);
	}

#Use of uninitialized value in unshift at ... line 170.
#	unshift($this->[ATR_PERL_ISA], @$isa);
	@{$this->[ATR_PERL_ISA]} = (@$isa, @{$this->[ATR_PERL_ISA]});

#FIXME: fails if no /attribute_type set
	my $type = $this->inherit_type({});
	if (defined($type))
	{
		$this->attribute_type->assign($type);
	}

	return;
}

sub hyperseded
# /type method
# /effect ""
# //parameters
#	method_class
#	method_name
# //returns
#	?
{
	my ($this, $method_class, $method_name) = @ARGUMENTS;

	my $rider1 = $this->[ATR_PACKAGE_NAME]->indirect_can($method_name);
	my $rider2 = $method_class->can($method_name);

	my $iterator = $iterator_class->indirect_constructor(
		$this->[ATR_PERL_ISA]);
	while ($iterator->advance)
	{
		my $pkg_name = $iterator->current_element;
		last if ($pkg_name->isa($method_class));
	}
	while ($iterator->advance)
	{
		my $pkg_name = $iterator->current_element;
		my $candidate = $pkg_name->can($method_name);
		next unless (defined($candidate));
		next if (($candidate == $rider1) or ($candidate == $rider2));
		return($candidate);
	}

	$translated_errors->advocate(
		'superseded_method_not_found',
		[$method_name, $method_class]);

#	return(IS_UNDEFINED);
}

sub superseded
# /type method
# /effect ""
# //parameters
#	method_name
# //returns
{
	my ($this, $method_name) = @ARGUMENTS;

	my $rider = $this->[ATR_PACKAGE_NAME]->indirect_can($method_name);

	foreach my $parent_class (@{$this->[ATR_PERL_ISA]})
	{
		my $candidate = $parent_class->can($method_name);
		next unless (defined($candidate));
		next if ($candidate == $rider);
		return($candidate);
	}

	$translated_errors->advocate(
		'missing_superseded_method',
		[$this->[ATR_PACKAGE_NAME]->value, $method_name]);
	return; # never reached
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.318
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
