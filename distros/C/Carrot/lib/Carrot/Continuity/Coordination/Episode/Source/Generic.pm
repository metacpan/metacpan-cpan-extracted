package Carrot::Continuity::Coordination::Episode::Source::Generic
# /type class
# //parent_classes
#	[=component_pkg=]::_Corporate
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->class_names->provide(
		my $loop_class = '[=project_pkg=]::Loop',
		my $targets_class = '[=component_pkg=]::_Targets');

	my $loop = $loop_class->indirect_constructor;

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_TARGETS] = $targets_class->indirect_constructor;
	$loop->register($this);

	return;
}

sub dispatch
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	foreach my $target (@{$this->[ATR_TARGETS]->arrayref})
	{
		$target->hit;
	}
	return;
}

sub register
# /type method
# /effect ""
# //parameters
#	target
# //returns
#	::Personality::Abstract::Boolean
{
	$_[THIS][ATR_TARGETS]->add($_[SPX_TARGET]);
	return(IS_TRUE);
}

sub deregister
# /type method
# /effect ""
# //parameters
#	target
# //returns
#	::Personality::Abstract::Boolean
{
	return unless (defined($_[THIS][ATR_TARGETS]));
	$_[THIS][ATR_TARGETS]->remove($_[SPX_TARGET]);
	return(IS_TRUE);
}

#sub DESTROY
# /type method
# /effect ""
# //parameters
# //returns
#{
#	my ($this) = @ARGUMENTS;
#
#	if (defined($loop))
#	{
#		$loop->deregister($this);
#		$loop = IS_UNDEFINED;
#	}
#}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.63
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"