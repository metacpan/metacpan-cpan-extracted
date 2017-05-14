package Carrot::Personality::Valued::File::Name::Type::Regular::Content::Raw
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Personality/Valued/File/Name/Type/Regular/Content/Raw./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $fatal_syscalls = '::Meta::Greenhouse::Fatal_Syscalls',
		my $translated_errors = '::Meta::Greenhouse::Translated_Errors');

# =--------------------------------------------------------------------------= #

sub read_into
# /type method
# /effect ""
# //parameters
#	buffer
# //returns
{
	my ($this) = @ARGUMENTS;

	print STDERR "READ_INTO $$this\n" if (TRACE_FLAG);
	eval {
		$fatal_syscalls->open(my $file, PKY_OPEN_MODE_READ, $$this);

		binmode($file) if (OS_NEEDS_BINMODE);

		$_[SPX_BUFFER] //= '';
		$fatal_syscalls->read(
			$file,
			$_[SPX_BUFFER],
			(stat($file))[RDX_STAT_SIZE]);

		$fatal_syscalls->close($file);
		return(IS_TRUE);

	} or $translated_errors->escalate(
		'named_file_operation',
		[$$this],
		$EVAL_ERROR);

	return;
}

sub overwrite_from
# /type method
# /effect ""
# //parameters
#	buffer
# //returns
{
	my ($this) = @ARGUMENTS;

	print STDERR "OVERWRITE_FROM $$this\n" if (TRACE_FLAG);
	eval {
		$fatal_syscalls->open(my $file, PKY_OPEN_MODE_WRITE, $$this);

		binmode($file) if (OS_NEEDS_BINMODE);

		$fatal_syscalls->truncate($file, 0);
		$fatal_syscalls->print($file, $_[SPX_BUFFER]);
		$fatal_syscalls->close($file);
		return(IS_TRUE);

	} or $translated_errors->escalate(
		'named_file_operation',
		[$$this],
		$EVAL_ERROR);

	return;
}

sub append_from
# /type method
# /effect ""
# //parameters
#	buffer
# //returns
{
	my ($this) = @ARGUMENTS;

	print STDERR "APPEND_FROM $$this\n" if (TRACE_FLAG);
	eval {
		$fatal_syscalls->open(my $file, PKY_OPEN_MODE_APPEND, $$this);

		binmode($file) if (OS_NEEDS_BINMODE);

		$fatal_syscalls->print($file, $_[SPX_BUFFER]);
		$fatal_syscalls->close($file);
		return(IS_TRUE);

	} or $translated_errors->escalate(
		'named_file_operation',
		[$$this]);
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.121
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
