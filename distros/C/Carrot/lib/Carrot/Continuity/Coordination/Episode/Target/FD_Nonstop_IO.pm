package Carrot::Continuity::Coordination::Episode::Target::FD_Nonstop_IO
# /type class
# //parent_classes
#	[=component_pkg=]::_Corporate
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->class_names->provide_instance(
		my $source = '[=project_pkg=]::Source::FD_Nonstop_IO');

	$expressiveness->distinguished_exceptions->provide(
		my $unsupported_file_class = 'unsupported_file_class');

	my $default_names = [
		'evt_fd_nonstop_read',
		'evt_fd_nonstop_write',
		'evt_fd_nonstop_exception',
		'evt_fd_nonstop_validate_fh'];

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	that            ::Personality::Abstract::Instance
#	name
#	file_handle
# //returns
{
	my ($this, $that, $name, $file_handle) = @ARGUMENTS;

	my $callbacks = [];
	foreach my $default_name (@$default_names)
	{
		my $callback = $this->create_callback(
			$that, $default_name, $name);
		push($callbacks, $callback);
	}

#FIXME: this is an assertion
	my $type = Scalar::Util::blessed($file_handle);
	unless ($type eq 'IO::Socket::INET')
	{
		$unsupported_file_class->raise_exception(
			{+HKY_DEX_BACKTRACK => $file_handle,
			 'class' => $type},
			ERROR_CATEGORY_SETUP);
	}
	@$this = ($that, $callbacks, $file_handle, IS_FALSE, fileno($file_handle));
	return;
}

sub hit
# /type method
# /effect ""
# //parameters
#	rwe
# //returns
#	?
{ # one out of four callbacks
	return($_[THIS][ATR_CALLBACK][$_[SPX_RWE]]->($_[THIS][ATR_THAT], @ARGUMENTS));
}

sub validate_fh
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_THAT]->validate($_[THIS][ATR_DATA]));
}

sub fd_ignore
# /type method
# /effect ""
# //parameters
#	rwe
# //returns
{
	$_[THIS]->enforce_activation if (ASSERTION_FLAG);
	$source->fd_ignore($_[SPX_RWE], $_[THIS][ATR_DATA]);
	return;
}

sub fd_ignore_read
# /type method
# /effect ""
# //parameters
# //returns
{
	$_[THIS]->enforce_activation if (ASSERTION_FLAG);
	$source->fd_ignore(PDX_SELECS_READ, $_[THIS][ATR_DATA]);
	return;
}

sub fd_ignore_write
# /type method
# /effect ""
# //parameters
# //returns
{
	$_[THIS]->enforce_activation if (ASSERTION_FLAG);
	$source->fd_ignore(PDX_SELECS_WRITE, $_[THIS][ATR_DATA]);
	return;
}

sub fd_watch
# /type method
# /effect ""
# //parameters
#	rwe
# //returns
{
	$_[THIS]->enforce_activation if (ASSERTION_FLAG);
	$source->fd_watch($_[SPX_RWE], $_[THIS][ATR_DATA]);
	return;
}

sub fd_watch_read
# /type method
# /effect ""
# //parameters
# //returns
{
	$_[THIS]->enforce_activation if (ASSERTION_FLAG);
	$source->fd_watch(PDX_SELECS_READ, $_[THIS][ATR_DATA]);
	return;
}
sub fd_watch_write
# /type method
# /effect ""
# //parameters
# //returns
{
	$_[THIS]->enforce_activation if (ASSERTION_FLAG);
	$source->fd_watch(PDX_SELECS_WRITE, $_[THIS][ATR_DATA]);
	return;
}

sub fd_watches
# /type method
# /effect ""
# //parameters
#	rwe
# //returns
{
	$_[THIS]->enforce_activation if (ASSERTION_FLAG);
	$source->fd_watches($_[SPX_RWE], $_[THIS][ATR_DATA]);
	return;
}

sub fd_ignore_all
# /type method
# /effect ""
# //parameters
# //returns
{
	$_[THIS]->enforce_activation if (ASSERTION_FLAG);
	$source->fd_ignore_all($_[THIS][ATR_DATA]);
	return;
}

sub fd_watch_all
# /type method
# /effect ""
# //parameters
# //returns
{
	$_[THIS]->enforce_activation if (ASSERTION_FLAG);
	$source->fd_watch_all($_[THIS][ATR_DATA]);
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
	if ($source->register($this, $this->[ATR_DATA]))
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
	if ($source->deregister($this, $this->[ATR_DATA]))
	{
		$this->[ATR_ACTIVATED] = IS_FALSE;
	}
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.76
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"