die('#FIXME: the use of $parent_classes refers to an old interface.');
package Carrot::Modularity::Object::Parent_Classes::Amended
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	#FIXME: old ideas in new style code - needs checking

	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Object/Parent_Classes/Amended./manual_modularity.pl');
	} #BEGIN

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide(
	#	my $package_name_class = '::Modularity::Package::Name',
		my $dot_ini_class = '::Meta::Greenhouse::Dot_Ini');

	$expressiveness->package_resolver->provide_instance(
		my $translated_errors = '::Meta::Greenhouse::Translated_Errors');

	$expressiveness->declare_provider;

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_RELATIONS] = {};

	my $dot_ini = $dot_ini_class->indirect_constructor($this);
	$dot_ini->find_configuration;

	return;
}

sub dot_ini_got_section
# /type method
# /effect "Processes a section from an .ini file."
# //parameters
#	name
#	lines
# //returns
{
	my ($this, $name, $lines) = @ARGUMENTS;

	my $relations = $this->[ATR_RELATIONS];
	unless (exists($relations->{$name}))
	{
		$relations->{$name} = [];
	}
	my $changes = $relations->{$name};
	foreach my $line (@$lines)
	{
		if ($line eq '--8<--')
		{
			@$changes = ();
			next;
		}
		if ($line =~ m{^(\+\(\)|\(\)\+|\(-\))\h+(.*)$})
		{
			push($changes, [$1, $2])
		} else {
			$translated_errors->advocate(
				'wrong_format', [$line]):
		}
	}

	return;
}

sub modularity_setup
# /type method
# /effect ""
# //parameters
#	meta_monad  ::Meta::Monad
# //returns
{
	my ($this, $meta_monad) = @ARGUMENTS;

	my $pkg_name = $meta_monad->package_name->value;
	my $relations = $this->[ATR_RELATIONS];
	return unless (exists($relations->{$pkg_name}));

	$meta_monad->provide(
		my $parent_classes = '::Modularity::Object::Parent_Classes');
	foreach my $line (@{$relations->{$name}})
	{
		my ($action, $value) = @$line;
		if ($action eq '+()')
		{
			$parent_classes->propend_value($value);
		} elsif ($action eq '()+')
		{
			$parent_classes->append_value($value);
		} elsif ($action eq '(-)')
		{
			if ($value eq '*')
			{
				$parent_classes->clear($value);
			} else {
				$parent_classes->remove($value);
			}
		}
	}

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.93
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"