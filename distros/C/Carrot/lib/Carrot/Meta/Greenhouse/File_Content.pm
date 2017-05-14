package Carrot::Meta::Greenhouse::File_Content
# /type class
# /capability "Manages regular file content without any external help."
{
	use strict;
	use warnings 'FATAL' => 'all';
	use open qw(:encoding(utf8));

	BEGIN {
		require('Carrot/Meta/Greenhouse/File_Content./manual_modularity.pl');
	} #BEGIN
	my $utf8_bom = "\x{feff}";

# =--------------------------------------------------------------------------= #

sub read_into
# /type method
# /effect "Read the complete contents of a file into a buffer."
# //parameters
#	file_name
#	buffer
# //returns
{
	my ($this, $file_name) = @ARGUMENTS;

	print STDERR "READ_INTO $file_name\n" if (TRACE_FLAG);
	eval {
		open(my $file, PKY_OPEN_MODE_READ, $file_name) //
			die("open<: $OS_ERROR.");

		read($file, my $bom_candidate, 1) //
			die("read: $OS_ERROR.");

		unless ($bom_candidate eq $utf8_bom)
		{
			seek($file, 0, 0) ||
				die("seek: $OS_ERROR.");
		}

		$_[SPX_BUFFER] //= '';
		read($file, $_[SPX_BUFFER], (stat($file))[RDX_STAT_SIZE]) //
			die("read: $OS_ERROR.");

		close($file) ||
			die("close: $OS_ERROR.");
		return(IS_TRUE);

	} or die("$file_name: $EVAL_ERROR");

	return;
}

sub overwrite_from
# /type method
# /effect "Overwrite the contents of a file from a buffer."
# //parameters
#	file_name
#	buffer
# //returns
{
	my ($this, $file_name) = @ARGUMENTS;

	print STDERR "OVERWRITE_FROM $file_name\n" if (TRACE_FLAG);
	eval {
		open(my $file, PKY_OPEN_MODE_WRITE, $file_name) //
			die("open>: $OS_ERROR.");

		truncate($file, 0) //
			die("truncate: $OS_ERROR.");

		print {$file} $_[SPX_BUFFER] ||
			die("print: $OS_ERROR.");

		close($file) ||
			die("close: $OS_ERROR.");

		return(IS_TRUE);

	} or die("$file_name: $EVAL_ERROR");
	return;
}

sub append_from
# /type method
# /effect "Append to the contents of a file from a buffer."
# //parameters
#	file_name
#	buffer
# //returns
{
	my ($this, $file_name) = @ARGUMENTS;

	print STDERR "APPEND_FROM $file_name\n" if (TRACE_FLAG);
	eval {
		open(my $file, PKY_OPEN_MODE_APPEND, $file_name) //
			die("open>>: $OS_ERROR.");

		print {$file} $_[SPX_BUFFER] ||
			die("print: $OS_ERROR.");

		close($file) ||
			die("close: $OS_ERROR.");
		return(IS_TRUE);

	} or die("$file_name: $EVAL_ERROR");

	return;
}

sub read_lines
# /type method
# /effect "Read and split the complete contents of a file into an array."
# //parameters
#	file_name
# //returns
#	?
{
	$_[THIS]->read_into($_[SPX_FILE_NAME], my $buffer);
	my $lines = [split(qr{(?:\012|\015\012?)},
		$buffer,
		PKY_SPLIT_RETURN_FULL_TRAIL)];

	return($lines);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.64
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
