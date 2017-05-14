package Carrot::Modularity::Package::Prefixed_List
# /type class
# /attribute_type ::One_Anonymous::Scalar
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Package/Prefixed_List./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $named_re = '::Meta::Greenhouse::Named_RE',
		my $translated_errors = '::Meta::Greenhouse::Translated_Errors',
		my $pkg_patterns = '::Modularity::Package::Patterns');

	Carrot::Meta::Greenhouse::Package_Loader::provide(
		my $pkg_hierarchy_class = '::Modularity::Package::Expander::Hierarchy',
		my $pkg_level_class = '::Modularity::Package::Expander::Level',
		my $pkg_shift_class = '::Modularity::Package::Expander::Shift',
		my $package_name_class = '::Modularity::Package::Name');

	$named_re->provide(
		my $pkg_delimiter_remove_trailing = 'pkg_delimiter_remove_trailing');

# =--------------------------------------------------------------------------= #

sub is_anchor_prefix
# /type method
# /effect ""
# //parameters
#	pkg_name        ::Personality::Abstract::Text
#	anchor          ::Personality::Abstract::Text
#	calling_pkg
# //returns
#	::Personality::Abstract::Boolean
{
	my ($this, $pkg_name, $anchor, $calling_pkg) = @ARGUMENTS;

	if ($pkg_patterns->is_relative_package_name($anchor))
	{
		$anchor = 'Carrot'.$anchor;
	}
	my $modified = $pkg_patterns->resolve_placeholders(
		$pkg_name, $calling_pkg);

	if ($pkg_name =~ s{$pkg_delimiter_remove_trailing}{}o) # is_anchor_prefix
#$pkg_name =~ s{::\z}{}s
	{
		if ($pkg_patterns->is_relative_package_name($pkg_name))
		{
			$pkg_name = 'Carrot'.$pkg_name;
		}
		$_[SPX_ANCHOR] = $pkg_name;
		return(IS_TRUE);

	} else {
		if ($pkg_patterns->is_relative_package_name($pkg_name))
		{
			$pkg_name = $anchor.$pkg_name;
			$modified = IS_TRUE;
		}
		if (Scalar::Util::readonly($_[SPX_PKG_NAME]))
		{
			$translated_errors->oppose(
				'lexical_required',
				[$pkg_name]);
		}
		$_[SPX_PKG_NAME] = $pkg_name if ($modified);
		return(IS_FALSE);
	}
}

sub resolved_package_names
# /type method
# /effect ""
# //parameters
#	pkg_names       ::Personality::Abstract::Text
#	anchor          ::Personality::Abstract::Text
#	calling_pkg
# //returns
#	?
{
	my ($this, $pkg_names, $anchor, $calling_pkg) = @ARGUMENTS;

	my $resolved = [];
	foreach my $pkg_name (@$pkg_names)
	{
		next if ($this->is_anchor_prefix(
				 $pkg_name,
				 $anchor,
				 $calling_pkg));
		if (my $pkg_level = $pkg_level_class->expands($pkg_name))
		{
			unshift($pkg_names, @{$pkg_level->expand});

		} elsif (my $pkg_hierarchy = $pkg_hierarchy_class->expands($pkg_name))
		{
			unshift($pkg_names, @{$pkg_hierarchy->expand});

		} elsif (my $pkg_shifter = $pkg_shift_class->expands($pkg_name))
		{
			unshift($pkg_names,
				@{$pkg_shifter->expand($calling_pkg)});
		} else {
			push($resolved,
				$package_name_class->constructor($pkg_name));
		}
	}

	return($resolved);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.273
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
