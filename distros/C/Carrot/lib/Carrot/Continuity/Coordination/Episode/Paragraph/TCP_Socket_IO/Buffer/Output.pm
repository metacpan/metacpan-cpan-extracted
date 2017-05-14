package Carrot::Continuity::Coordination::Episode::Paragraph::TCP_Socket_IO::Buffer::Output
# /type class
# //parent_classes
#	[=component_pkg=]::_Corporate
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	sub BUF_CONTENT() { 0 };
	sub BUF_OFFSET() { 1 };
	sub BUF_LEFT() { 2 };
	sub BUF_IS_FILE() { 3 };

	my $empty_chunk = [IS_UNDEFINED, 0, 0, 0];

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_CHUNKS] = [];
	$this->[ATR_STATE] = BST_PAUSED;
	$this->[ATR_SIZE] = 0;

	return;
}

sub data
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	if (($this->[ATR_STATE] == BST_CLOSED)
	or ($#{$this->[ATR_CHUNKS]} == ADX_NO_ELEMENTS))
	{
		return([@$empty_chunk]);
	}
	return($_[THIS][ATR_CHUNKS][ADX_FIRST_ELEMENT]);
}

sub written
# /type method
# /effect ""
# //parameters
#	amount
# //returns
#	?
{
	my ($this, $amount) = @ARGUMENTS;

	my $chunks = $this->[ATR_CHUNKS];
	my $first_chunk = $chunks->[ADX_FIRST_ELEMENT];
	$first_chunk->[BUF_OFFSET] += $amount;
	$first_chunk->[BUF_LEFT] -= $amount;
	$this->[ATR_SIZE] -= $amount;
	if ($first_chunk->[BUF_LEFT] == 0)
	{
		if ($first_chunk->[BUF_IS_FILE])
		{
			close($first_chunk->[BUF_CONTENT]);
		}
		shift(@$chunks);
	}

	return($this->update);
}

sub add_file_handle
# /type method
# /effect ""
# //parameters
#	data
# //returns
#	Mica::Projection::Flow_Control
{
	my ($this) = @ARGUMENTS;

	return(FLOW_STOP) if ($this->[ATR_STATE] == BST_CLOSED);

	my $l = (stat($_[SPX_DATA]))[7];
	return(FLOW_NOCHANGE) if ($l == 0);
	push(@{$this->[ATR_CHUNKS]}, [$_[SPX_DATA], 0, $l, 1]);
	$this->[ATR_SIZE] += $l;

	return($this->update);
}

sub add_scalar
# /type method
# /effect ""
# //parameters
#	data
# //returns
#	Mica::Projection::Flow_Control
{
	my ($this) = @ARGUMENTS;

	return(FLOW_STOP) if ($this->[ATR_STATE] == BST_CLOSED);

	my $l = length(${$_[SPX_DATA]});
	return(FLOW_NOCHANGE) if ($l == 0);
	push(@{$this->[ATR_CHUNKS]}, [$_[SPX_DATA], 0, $l, 0]);
	$this->[ATR_SIZE] += $l;

	return($this->update);
}

sub update
# /type method
# /effect ""
# //parameters
# //returns
#	Mica::Projection::Flow_Control
{
	my ($this) = @ARGUMENTS;

	return(FLOW_STOP) if ($this->[ATR_STATE] == BST_CLOSED);
	if (($#{$this->[ATR_CHUNKS]} == ADX_NO_ELEMENTS)
	or ($this->[ATR_CHUNKS][ADX_LAST_ELEMENT][BUF_LEFT] == 0))
	{
		if ($this->[ATR_STATE] == BST_OPEN)
		{
			$this->[ATR_STATE] = BST_PAUSED;
			return(FLOW_STOP);
		}
	} else {
		if ($this->[ATR_STATE] == BST_PAUSED)
		{
			$this->[ATR_STATE] = BST_OPEN;
			return(FLOW_START);
		}
	}

	return(FLOW_NOCHANGE);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.61
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"