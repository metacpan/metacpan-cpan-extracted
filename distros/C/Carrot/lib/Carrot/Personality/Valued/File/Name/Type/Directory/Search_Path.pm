package Carrot::Personality::Valued::File::Name::Type::Directory::Search_Path
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Personality/Valued/File/Name/Type/Directory/Search_Path./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide(
		my $array_class = '::Diversity::Attribute_Type::One_Anonymous::Array');

# =--------------------------------------------------------------------------= #

sub contains
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	my $dir_name = $_[SPX_NAME]->value;
	for (@{$_[THIS]}) {
		return(IS_TRUE) if ($_->value eq $dir_name);
	}
	return(IS_FALSE);
}

sub find_first
# /type method
# /effect ""
# //parameters
#	name
# //returns
#	?
{
	my ($this, $name) = @ARGUMENTS;

	foreach my $directory (@$this)
	{
		my $file_name = $directory->entry_if_exists($name);
		return($file_name) if (defined($file_name));
	}
	return(IS_UNDEFINED);
}

sub qualify_first
# /type method
# /effect ""
# //parameters
#	file_name       ::Personality::Valued::File::Name
# //returns
#	::Personality::Abstract::Boolean
{
	my ($this, $file_name) = @ARGUMENTS;

	foreach my $directory (@$this)
	{
		my $rv = $directory->qualify_file_if_exists($file_name);
		return(IS_TRUE) if ($rv);
	}
	return(IS_FALSE);
}

sub find_all
# /type method
# /effect ""
# //parameters
#	names
# //returns
#	?
{
	my ($this, $names) = @ARGUMENTS;

	my $file_names = $array_class->constructor;
	foreach my $directory (@$this)
	{
		foreach my $name (@$names)
		{
			my $file_name = $directory->entry_if_exists($name);
			next unless (defined($file_name));
			$file_names->append_value($file_name);
		}
	}
	return($file_names);
}

sub find_all_once
# /type method
# /effect ""
# //parameters
#	names
#	passage_counter
# //returns
#	?
{
	my ($this, $names, $passage_counter) = @ARGUMENTS;

	my $file_names = $array_class->constructor;
	foreach my $directory (@$this)
	{
		foreach my $name (@$names)
		{
			my $file_name = $directory->entry_if_exists($name);
			next unless (defined($file_name));
			next if ($passage_counter->was_seen_before($$file_name));
			$file_names->append_value($file_name);
		}
	}
	return($file_names);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.90
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
