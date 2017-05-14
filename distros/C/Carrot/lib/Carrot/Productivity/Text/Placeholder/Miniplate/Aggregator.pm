package Carrot::Productivity::Text::Placeholder::Miniplate::Aggregator
# /type class
# //parent_classes
#	[=component_pkg=]::_Corporate
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $class_names = '::Individuality::Controlled::Class_Names');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_MINIPLATES] = [];

	return;
}

sub add_miniplate
# /type method
# /effect ""
# //parameters
#	pkg_names  +multiple  ::Personality::Abstract::Text
# //returns
{
	my $this = shift(\@ARGUMENTS);

	foreach my $miniplate (@ARGUMENTS)
	{
		if (ref($miniplate) eq '')
		{
			$class_names->provide_instance($miniplate);
		}
		push($this->[ATR_MINIPLATES], $miniplate);
	}
	return;
}

sub set_subject
# /type method
# /effect ""
# /parameters *
# //returns
{
	my $this = shift(\@ARGUMENTS);

	foreach my $miniplate (@{$this->[ATR_MINIPLATES]})
	{
		$miniplate->set_subject(@ARGUMENTS);
	}
	return;
}

sub find_call
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this, $placeholder) = @ARGUMENTS;

	foreach my $miniplate (@{$this->[ATR_MINIPLATES]})
	{
		my $collector = $miniplate->find_call($placeholder);
		return($collector) if (defined($collector));
	}
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.56
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"