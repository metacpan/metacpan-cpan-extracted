package Carrot::Continuity::Coordination::Episode::Target::_Corporate
# /type class
# /instances none
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $distinguished_exceptions = '::Individuality::Controlled::Distinguished_Exceptions');

	$distinguished_exceptions->provide(
		my $missing_target_callback = 'missing_target_callback',
		my $non_activated_target = 'non_activated_target');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	die('A dummy for the definition of attributes.');
	$this->[ATR_THAT] = IS_UNDEFINED;
	$this->[ATR_CALLBACK] = IS_UNDEFINED;
	$this->[ATR_VALUE] = IS_UNDEFINED;
	$this->[ATR_ACTIVATED] = IS_UNDEFINED;
	$this->[ATR_DATA] = IS_UNDEFINED;

	return;
}

sub is_activated
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return($_[THIS][ATR_ACTIVATED])
}

sub hit
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(&{$_[THIS][ATR_CALLBACK]}($_[THIS][ATR_THAT], @ARGUMENTS));
}

sub create_callback
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
#	default_name
#	name
# //returns
#	?
{
	my ($this, $that, $default_name, $name) = @ARGUMENTS;

	my $method;
	if (defined($name))
	{
		if (substr($name, 0, 1) eq '_')
		{
			$method = $default_name . $name;
		} else {
			$method = $name;
		}
	} else {
		$method = $default_name;
	}
	my $callback = $that->can($method);
	unless (defined($callback))
	{
		$missing_target_callback->raise_exception(
			{+HKY_DEX_BACKTRACK => $that,
			 'method' => $method,
			 'class' => $that->class_name},
			ERROR_CATEGORY_SETUP);
	}
	return($callback);
}

sub enforce_activation
# /type method
# /effect ""
# //parameters
# //returns
{
	if ($_[THIS][ATR_ACTIVATED] == 0)
	{
		$non_activated_target->raise_exception(
			{+HKY_DEX_BACKTRACK => $_[THIS],
			 'class' => $_[THIS]->class_name},
			ERROR_CATEGORY_SETUP);
	}
	return;
}

sub DESTROY
# /type method
# /effect ""
# //parameters
# //returns
{
	if (defined($_[THIS]))
	{
		$_[THIS]->deactivate;
	}
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}

__END__
sub intercept
# /type method
# /effect ""
# //parameters
# //returns
{
	$_[THIS][ATR_INTERCEPTED] = [];
	return;
}

sub drop_intercepted
# /type method
# /effect ""
# //parameters
# //returns
{
	$_[THIS][ATR_INTERCEPTED] = IS_UNDEFINED;
	return;
}

sub pass
# /type method
# /effect ""
# //parameters
# //returns
{
	return unless (defined($_[THIS][ATR_INTERCEPTED]));
	my $intercepted = $_[THIS][ATR_INTERCEPTED];
	$_[THIS][ATR_INTERCEPTED] = IS_UNDEFINED;
	foreach my $item (@$intercepted)
	{
		$_[THIS]->hit(@$item);
	}
	return;
}
# //revision_control
#	version 1.1.71
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"