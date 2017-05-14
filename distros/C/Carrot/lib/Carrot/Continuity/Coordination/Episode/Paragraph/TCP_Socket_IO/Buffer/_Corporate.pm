package Carrot::Continuity::Coordination::Episode::Paragraph::TCP_Socket_IO::Buffer::_Corporate
# /type class
# /instances none
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	sub BST_PAUSED()
	# /type constant  /inheritable
	{ -1 }

	sub BST_CLOSED()
	# /type constant  /inheritable
	{ 0 }

	sub BST_OPEN()
	# /type constant  /inheritable
	{ 1 }


	sub FLOW_STOP()
	# /type constant  /inheritable
	{ -1 }

	sub FLOW_NOCHANGE()
	# /type constant  /inheritable
	{ 0 }

	sub FLOW_START()
	# /type constant  /inheritable
	{ 1 }

# =--------------------------------------------------------------------------= #

sub is_closed
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return($_[THIS][ATR_STATE] == BST_CLOSED);
}

sub close
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_STATE] = BST_CLOSED;
	splice($this->[ATR_CHUNKS]);
	$this->[ATR_SIZE] = 0;

	return;
}

sub has_data
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_SIZE]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.37
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
