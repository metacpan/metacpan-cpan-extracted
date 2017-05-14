package Carrot::Individuality::Controlled::Named_Data::Monad
# /type class
# //parent_classes
#	::Individuality::Controlled::_Corporate::Monad
# //parameters
#	inheritance  ::Modularity::Object::Inheritance::ISA_Occupancy
# /capability "Share a hash across all (!) children and a parent."
{
	my ($inheritance) = @ARGUMENTS;

	use strict;
	use warnings 'FATAL' => 'all';

#	my $expressiveness = Carrot::individuality;

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	meta_monad  ::Meta::Monad
#	data
# //returns
{
	my ($this, $meta_monad, $data) = @ARGUMENTS;

	$this->[ATR_PERL_ISA] = $meta_monad->parent_classes->perl_isa;
	$this->[ATR_DATA] = $data;

	return;
}

my $name_lookup = \&name_lookup;
sub name_lookup
# /type method
# /effect ""
# //parameters
#	seen
#	name
# //returns
#	?
{
	my ($this, $seen, $name) = @ARGUMENTS;

	return( exists($this->[ATR_DATA]{$name})
		? $this->[ATR_DATA]{$name}
		: $inheritance->first_defined_skip_seen(
			$this->[ATR_PERL_ISA],
			$name_lookup,
			$seen,
			$name));
}

sub provide
# /type method
# /effect "Replaces the supplied string with an instance."
# //parameters
#	name  +multiple
# //returns
{
	my $this = shift(\@ARGUMENTS);

	foreach my $name (@ARGUMENTS)
	{
		my $data = $this->name_lookup($this->initially_seen, $name);
		unless (defined($data))
		{
			die("No data for '$name'.");
		}
		$name = $data;
	}
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.59
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"