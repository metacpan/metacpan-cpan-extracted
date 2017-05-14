package Carrot::Meta::Greenhouse::Shared_Subroutines
# /type library
# /capability "Manage additions to @ISA of a package"
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Meta/Greenhouse/Shared_Subroutines./manual_modularity.pl');
	} #BEGIN

	require Carrot::Meta::Greenhouse::Package_Loader;

	my $soon = {};
	my $upgrades = {};

# =--------------------------------------------------------------------------= #

sub add_package
# /type function
# /effect "Appends the given package names to @ISA"
# //parameters
#	pkg_name  +multiple  ::Personality::Abstract::Text
# //returns
{
	my $additional_parents = [@ARGUMENTS];
	my $pkg_name = [caller]->[RDX_CALLER_PACKAGE];
	Carrot::Meta::Greenhouse::Package_Loader::provide(@$additional_parents);
	{
		no strict 'refs';
		push(@{$pkg_name.'::ISA'}, @$additional_parents);
	}
	if (defined($upgrades))
	{
		if (exists($upgrades->{$pkg_name}))
		{
			die("Shared subroutines for '$pkg_name' already exist.");
		}
		$upgrades->{$pkg_name} = $additional_parents;
	}

	return;
}

sub upgrades
# /type function
# /effect "Appends the given package names to @ISA"
# //parameters
# //returns
#	?
{
	my $rv = $upgrades;
	$upgrades = IS_UNDEFINED;
	return($rv);
}

sub announce
# /type function
# /effect "Appends the given package names to @ISA"
# //parameters
# //returns
{
	my $pkg_name = [caller]->[RDX_CALLER_PACKAGE];
	return unless (exists($soon->{$pkg_name}));

	no strict 'refs';
	foreach my $target (@{$soon->{$pkg_name}})
	{
		push(@{$target.'::ISA'}, $pkg_name);
	}
	$soon->{$pkg_name} = IS_UNDEFINED;

	return;
}

sub add_package_soon
# /type function
# /effect "Appends the given package names to @ISA"
# //parameters
#	pkg_name  +multiple  ::Personality::Abstract::Text
# //returns
{
	my $target = [caller]->[RDX_CALLER_PACKAGE];

	my $pkg_name = $_[SPX_PKG_NAME];
	unless (exists($soon->{$pkg_name}))
	{
		$soon->{$pkg_name} = [];
	}
	unless (defined($soon->{$pkg_name}))
	{
		# This function is seldomly used, so that a hardcoded
		# English message isn't much of a loss.
		die("Soon comes too late for package '$pkg_name'.");
	}
	push($soon->{$pkg_name}, $target);

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.128
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
