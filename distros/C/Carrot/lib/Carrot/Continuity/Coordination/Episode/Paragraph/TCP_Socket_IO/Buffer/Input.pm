package Carrot::Continuity::Coordination::Episode::Paragraph::TCP_Socket_IO::Buffer::Input
# /type class
# //parent_classes
#	[=component_pkg=]::_Corporate
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $customized_settings = '::Individuality::Controlled::Customized_Settings');

	$customized_settings->provide_plain_value(
		my $maximum_buffer_size = 'maximum_buffer_size',
		my $separate_chunk_size = 'separate_chunk_size');

	# to a file using sendfile

# =--------------------------------------------------------------------------= #

sub FEED_MORE() { -1 }
sub FEED_ABORT() { 0 }
sub FEED_SUCCESS() { 1 }

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	protocol
# //returns
{
	my ($this, $protocol) = @ARGUMENTS;

	$this->[ATR_CHUNKS] = [];
	$this->[ATR_STATE] = BST_OPEN;
	$this->[ATR_SIZE] = 0;
	$this->[ATR_OFFLOAD] = IS_UNDEFINED;
	$this->[ATR_PROTOCOL] = $protocol;

	return;
}

sub read_buffer
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	return if ($this->[ATR_STATE] == BST_CLOSED);
	if (($#{$this->[ATR_CHUNKS]} == ADX_NO_ELEMENTS)
	or (length($this->[ATR_CHUNKS][ADX_LAST_ELEMENT]) > $separate_chunk_size))
	{
		push($this->[ATR_CHUNKS], '');
	}
	return(\$this->[ATR_CHUNKS][ADX_LAST_ELEMENT]);
}

sub process_data
# /type method
# /effect ""
# //parameters
#	amount
# //returns
#	Mica::Projection::Flow_Control
{
	my ($this, $amount) = @ARGUMENTS;

	return(FLOW_STOP) if ($this->[ATR_STATE] == BST_CLOSED);
	$this->[ATR_SIZE] += $amount;
# $is_fresh = $n == 0 handled in TCP_Socket_IO

	my $chunks = $this->[ATR_CHUNKS];
	while ($#$chunks > ADX_NO_ELEMENTS)
	{
		my $rc = $this->[ATR_PROTOCOL]->feed($chunks->[ADX_FIRST_ELEMENT]);
		last if ($#$chunks == ADX_NO_ELEMENTS);
		$this->[ATR_SIZE] -= length($chunks->[ADX_FIRST_ELEMENT]);
		shift(@$chunks);
		if ($rc == FEED_ABORT)
		{
			$this->close;
			return(FLOW_STOP);
		} elsif ($rc == FEED_MORE)
		{
			next;
		} elsif ($rc == FEED_SUCCESS)
		{
			last;
		}
	}

	return($this->pause($this->[ATR_SIZE] > $maximum_buffer_size));
}

sub pause
# /type method
# /effect ""
# //parameters
#	test_result
# //returns
#	Mica::Projection::Flow_Control
{
	my ($this, $test_result) = @ARGUMENTS;

	return(FLOW_STOP) if ($this->[ATR_STATE] == BST_CLOSED);
	if ($test_result > 0)
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
#	version 1.1.63
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"