package Carrot::Personality::Valued::File::Name::Type::Regular::Content::UTF8_wBOM
# /type class
# /capability "Manage content for Unicode text files with BOM as magic."
{
	use strict;
	use warnings 'FATAL' => 'all';
	use open qw(:encoding(utf8));

	BEGIN {
		require('Carrot/Personality/Valued/File/Name/Type/Regular/Content/UTF8_wBOM./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide(
		my $cursor_class = '::Personality::Reflective::Iterate::Array::Cursor');

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $fatal_syscalls = '::Meta::Greenhouse::Fatal_Syscalls',
		my $translated_errors = '::Meta::Greenhouse::Translated_Errors');

	my $utf8_bom = "\x{feff}"; # used as UTF-8 file magic

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

		binmode($file, ':utf8');
		$fatal_syscalls->read($file, my $first_character, 1);
		unless ($first_character eq $utf8_bom)
		{
			seek($file, 0, 0);
		}

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

		binmode($file, ':utf8');
		$fatal_syscalls->truncate($file, 0);
		$fatal_syscalls->print2($file, $utf8_bom, $_[SPX_BUFFER]);
		$fatal_syscalls->close($file);
		return(IS_TRUE);

	} or $translated_errors->escalate(
		'named_file_operation',
		[$$this],
		$EVAL_ERROR);

	return;
}

sub read_lines
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	$_[THIS]->read_into(my $buffer);
	return([split(qr{(?:\012|\015\012?)}, $buffer, PKY_SPLIT_RETURN_FULL_TRAIL)]);
}

sub line_cursor
# /type method
# /effect ""
# //parameters
#	line
# //returns
#	::Personality::Abstract::Instance
{
	return($cursor_class->indirect_constructor(
		       $_[THIS]->read_lines,
		       $_[SPX_LINE]));
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.137
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
