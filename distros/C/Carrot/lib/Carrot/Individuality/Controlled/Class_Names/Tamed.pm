package Carrot::Individuality::Controlled::Class_Names::Tamed
# /type class
# //parent_classes
#	::Individuality::Controlled::Class_Names::Monad
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide(
		my $translated_errors = '::Meta::Greenhouse::Translated_Errors',
		my $array_class = '::Personality::Elemental::Array::Texts',
		my $prefixed_list_class = '::Modularity::Package::Prefixed_List');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

# Hey ::Modularity::Constant::Parental::Ordered_Attributes, we use these:
# ATR_PREFIX ATR_MAPPING ATR_RESOLVED
	if ($#$this == ADX_NO_ELEMENTS)
	{
		$this->superseded;
	}
	$this->[ATR_CHECKED_PACKAGES] = {};
	$this->[ATR_TRUSTED_PREFIXES] = $array_class->indirect_constructor;
	$this->[ATR_REQUIRED_METHODS] = [];

	return;
}

sub add_trusted_name_prefix
# /type method
# /effect ""
# //parameters
#	prefix  +multiple
# //returns
{
	my $this = shift(\@ARGUMENTS);

	$this->[ATR_TRUSTED_PREFIXES]->append_if_distinct(@ARGUMENTS);
	$this->[ATR_CHECKED_PACKAGES] = {};
	return;
}

sub add_required_methods
# /type method
# /effect ""
# //parameters
#	method_name  +multiple
# //returns
{
	my $this = shift(\@ARGUMENTS);

	push($this->[ATR_REQUIRED_METHODS], @ARGUMENTS);
	$this->[ATR_CHECKED_PACKAGES] = {};
	return;
}

#FIXME: unused and broken
#sub is_trusted_name
## method (<this>, <pkg_name>) public
#{
#	my ($this, $pkg_name) = @ARGUMENTS;
#
#	if (exists($this->[ATR_CHECKED_PACKAGES]{$pkg_name}))
#	{
#		return(IS_TRUE);
#	}
#	unless ($pkg_name->matches_prefixes($this->[ATR_TRUSTED_PREFIXES]))
#	{
#		return(IS_FALSE);
#	}
#	$this->[ATR_CHECKED_PACKAGES]{$pkg_name} = 1;
#	return(IS_TRUE);
#}

#FIXME: duplicates too much of the overwritten method
sub provide
# /type method
# /effect "Replaces the supplied string with an instance."
# //parameters
#	pkg_name  +multiple  ::Personality::Abstract::Text
# //returns
{
	my $this = shift(\@ARGUMENTS);

	my $anchor = $this->lookup_prefix;
	my $pkg_symbol = $this->[ATR_PACKAGE_NAME]->value;
	foreach my $pkg_name (@ARGUMENTS)
	{
		next if ($prefixed_list_class->is_anchor_prefix(
			$pkg_name,
			$anchor,
			$pkg_symbol));

		my $package_name = $this->resolve($pkg_name, $anchor);
		my $PKG_NAME = $package_name->value;
		unless (exists($this->[ATR_CHECKED_PACKAGES]{$PKG_NAME}))
		{
			unless ($this->[ATR_TRUSTED_PREFIXES]
				->matches_as_prefixes($pkg_name->value))
			{
				$translated_errors->advocate(
					'illegal_package_prefix',
					[$PKG_NAME,
					join(', ', @{$this->[ATR_TRUSTED_PREFIXES]})]);
			}
			unless ($this->has_required_methods)
			{
				$translated_errors->advocate(
					'missing_method',
					[$PKG_NAME,
					join(', ', @{$this->[ATR_TRUSTED_PREFIXES]})]);
			}
			$this->[ATR_CHECKED_PACKAGES]{$PKG_NAME} = 1;
		}

		$pkg_name = $package_name;
	}
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.105
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"