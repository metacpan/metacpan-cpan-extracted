package Carrot::Modularity::Package::Tabulator
# /type class
# /attribute_type ::Diversity::Attribute_Type::One_Anonymous::Hash
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Package/Tabulator./manual_modularity.pl');
	} #BEGIN

	require Carrot::Meta::Greenhouse::Named_RE;
	my $named_re = Carrot::Meta::Greenhouse::Named_RE->constructor;

	$named_re->provide(
		my $re_perl_pkg_last_element = 'perl_pkg_last_element');

	my $THIS = {
		'Carrot' => 'project',
		'Carrot::Individuality::Controlled' => 'component',
		'Carrot::Personality::Valued' => 'component',
	};
	bless($THIS, __PACKAGE__);

# =--------------------------------------------------------------------------= #

sub constructor
# /type class_method
# /effect "Constructs a new instance."
# //parameters
# //returns
#	::Personality::Abstract::Instance
{
	return($THIS);
}

sub add
# /type method
# /effect ""
# //parameters
#	meta_monad  ::Meta::Monad
#	component_pkgs   ::Personality::Abstract::Text
# //returns
{
	my ($this, $meta_monad, $component_pkgs) = @ARGUMENTS;

	my $pkg_name = $meta_monad->package_name->value;
	if (exists($this->{$pkg_name}) and ($this->{$pkg_name} ne 'project'))
	{
		die("$pkg_name is already defined as a project tabulator.");
	}
	$this->{$pkg_name} = 'project';
	foreach my $component_pkg (@$component_pkgs)
	{
		my $qualified_pkg = "$pkg_name$component_pkg";
		if (exists($this->{$qualified_pkg})
		and ($this->{$qualified_pkg} ne 'component'))
		{
			die("$pkg_name is already defined as a project component tabulator.");
		}
		$this->{$qualified_pkg} = 'component';
	}

	return;
}

sub by_pkg_name
# /type method
# /effect ""
# //parameters
#	pkg_name    ::Personality::Abstract::Text
#	type        ::Personality::Abstract::Text
# //returns
#	::Personality::Abstract::Text
{
	my ($this, $pkg_name, $type) = @ARGUMENTS;

	while ($pkg_name =~ s{$re_perl_pkg_last_element}{}o)
	{
		if (exists($this->{$pkg_name})
		and ($this->{$pkg_name} eq $type))
		{
			return($pkg_name);
		}
	}

	return(IS_UNDEFINED);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.142
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
