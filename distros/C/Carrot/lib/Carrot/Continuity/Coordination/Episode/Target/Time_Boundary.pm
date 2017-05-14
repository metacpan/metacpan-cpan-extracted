package Carrot::Continuity::Coordination::Episode::Target::Time_Boundary
# /type class
# //parent_classes
#	[=this_pkg=]::Constants
#	[=component_pkg=]::_Corporate
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $epoch_time = '::Individuality::Singular::Process::Epoch_Time',
		my $distinguished_exceptions = '::Individuality::Controlled::Distinguished_Exceptions',
		my $class_names = '::Individuality::Controlled::Class_Names');

	$class_names->provide_instance(
		my $source = '[=project_pkg=]::Source::Time');

	$distinguished_exceptions->provide(
		my $invalid_boundary_spec = 'invalid_boundary_spec');

	my $boundaries = {
		T_BOUNDARY_MINUTE => sub {
			my $time = $$epoch_time+60;
			return($time - ($time % 60));
		},
		T_BOUNDARY_HOUR => sub {
			my $time = $$epoch_time+3600;
			return($time - ($time % 3600));
		},
		T_BOUNDARY_DAY => sub {
			my $time = $$epoch_time+86400;
			return($time - ($time % 86400));
		},
	#	T_BOUNDARY_WEEK => sub { # FIXME: already depending on start of week
	#		my $time = $epoch_time+7*86400;
	#		return($time - ($time % 7*86400));
	#	},
	#	T_BOUNDARY_MONTH => ... FIXME
	#	T_BOUNDARY_YEAR => ... FIXME
	};

	my $default_name = 'evt_time_boundary';

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	that            ::Personality::Abstract::Instance
#	name
#	boundary
# //returns
{
	my ($this, $that, $name, $boundary) = @ARGUMENTS;

	if (length($boundary) > 1)
	{
		$boundary = $this->required_boundary_for_strftime($boundary);
	}

	my $callback = $this->create_callback($that, $default_name, $name);
	@$this = ($that, $callback, IS_UNDEFINED, IS_FALSE, $boundaries->{$boundary});
	return;
}

sub hit
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	my $rv = &{$this->[ATR_CALLBACK]}($this->[ATR_THAT], @ARGUMENTS);
	$this->reactivate;
	return($rv);
}

sub reactivate
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_VALUE] = $this->[ATR_DATA]->();

	if ($source->register($this, $this->[ATR_VALUE]))
	{
		$this->[ATR_ACTIVATED] = IS_TRUE;
	}
	return;
}

sub activate
# /type method
# /effect "Activates the main feature of the instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	return if ($this->[ATR_ACTIVATED]);
	$this->[ATR_VALUE] = $this->[ATR_DATA]->();
	if ($source->register($this, $this->[ATR_VALUE]))
	{
		$this->[ATR_ACTIVATED] = IS_TRUE;
	}
	return;
}

sub deactivate
# /type method
# /effect "Activates the main feature of the instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	return unless ($this->[ATR_ACTIVATED]);
	return unless (defined($source));
	if ($source->deregister($this, $this->[ATR_VALUE]))
	{
		$this->[ATR_ACTIVATED] = IS_FALSE;
	}
	return;
}

sub required_boundary_for_strftime
# /type method
# /effect ""
# //parameters
#	pattern
# //returns
#	?
{
	my ($this, $pattern) = @ARGUMENTS;

	if ($pattern =~ m{\%[cMRTxX]})
	{
		return(T_BOUNDARY_MINUTE);
	} elsif ($pattern =~ m{\%[HIkl]})
	{
		return(T_BOUNDARY_HOUR);
	} elsif ($pattern =~ m{\%[aAdDeFjuw]})
	{
		return(T_BOUNDARY_DAY);
#	} elsif ($pattern =~ m{\%[VW]})
#	{
#		return(T_BOUNDARY_WEEK);
#	} elsif ($pattern =~ m{\%[bBhm]})
#	{
#		return(T_BOUNDARY_MONTH);
#	} elsif ($pattern =~ m{\%[CGgyY]})
#	{
#		return(T_BOUNDARY_YEAR);
	}
	$invalid_boundary_spec->raise_exception(
		{'boundary' => $boundary},
		ERROR_CATEGORY_SETUP);
	return(IS_UNDEFINED);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.77
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"