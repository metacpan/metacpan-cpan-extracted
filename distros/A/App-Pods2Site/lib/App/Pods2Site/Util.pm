package App::Pods2Site::Util;

use strict;
use warnings;

our $IS_WINDOWS = $^O eq 'MSWin32'; 

use Exporter qw(import);
our @EXPORT_OK =
	qw
		(
			$IS_WINDOWS
			slashify
			readData
			writeData
			createSpinner
			writeUTF8File
			readUTF8File
			expandAts
		);

use JSON;

my $FILE_SEP = $IS_WINDOWS ? '\\' : '/';
my $DATAFILE = '.pods2site';
my $JSON = JSON->new()->utf8()->pretty()->canonical();
my @SPINNERPOSITIONS = ('|', '/', '-', '\\', '-');

# pass in a path and ensure it contains the native form of slash vs backslash
# (or force either one)
#
sub slashify
{
	my $s = shift;
	my $fsep = shift || $FILE_SEP;

	my $dblStart = $s =~ s#^[\\/]{2}##;
	$s =~ s#[/\\]+#$fsep#g;

	return $dblStart ? "$fsep$fsep$s" : $s;
}

sub writeData
{
	my $dir = shift;
	my $section = shift;
	my $data = shift;
	
	my $allData = readData($dir) || {};
	$allData->{$section} = $data;
	
	my $df = slashify("$dir/$DATAFILE");
	open (my $fh, '> :raw :bytes', $df) or die("Failed to open '$df': $!\n");
	print $fh $JSON->encode($allData);
	close($fh);  
}

sub readData
{
	my $dir = shift;
	my $section = shift;

	my $data;

	my $df = slashify("$dir/$DATAFILE");
	if (-f $df)
	{
		open (my $fh, '< :raw :bytes', $df) or die("Failed to open '$df': $!\n");
		my $buf;
		my $szExpected = -s $df;
		my $szRead = read($fh, $buf, -s $df);
		die("Failed to read from '$df': $!\n") unless ($szRead && $szRead == $szExpected); 
		close($fh);
		$data = $JSON->decode($buf);
		$data = $data->{$section} if $section;
	}

	return $data;
}

sub createSpinner
{
	my $args = shift;

	my $spinner = sub {};
	if (-t STDOUT && $args->isVerboseLevel(0) && !$args->isVerboseLevel(2))
	{
		my $pos = 0;
		$spinner = sub
			{
				print ".$SPINNERPOSITIONS[$pos++].\r";
				$pos = 0 if $pos > $#SPINNERPOSITIONS;
			};
	}
	
	return $spinner;
}

sub writeUTF8File
{
	my $file = shift;
	my $data = shift;
	
	open (my $fh, '> :encoding(UTF-8)', $file) or die("Failed to open '$file': $!\n");
	print $fh $data;
	close($fh);  
}

sub readUTF8File
{
	my $file = shift;
	
	open (my $fh, '< :encoding(UTF-8)', $file) or die("Failed to open '$file': $!\n");
	local $/ = undef;
	my $data = <$fh>;
	close($fh);  
	
	return $data;
}

# expand any array elements using '@xyz' as new line elements read from 'xyz'
# also, handle recursion where included files itself refers to further files
# possibly using relative paths
#
sub expandAts
{
	my $dirctx = shift;
	
	my @a;
	foreach my $e (@_)
	{
		if ($e =~ /^@(.+)/)
		{
			# if we find a filename use as-if its absolute, otherwise tack on
			# the current dir context
			#
			my $fn = $1;
			$fn = File::Spec->file_name_is_absolute($fn) ? $fn : "$dirctx/$fn";
			
			# recursively read file contents into the array
			# using the current files directory as the new dir context
			#
			push(@a, expandAts(dirname($fn), __readLines($fn)))
		}
		else
		{
			# just keep the value as-is
			#
			push(@a, $e);
		}
	}
	return @a;
}

# read all lines from a file and return as an array
# supports line continuation, e.g. a line with '\' at the end causes
# appending the line after etc, in order to create a single line.
#   - a line starting with '#' will be ignored as a comment
#   - all lines will be trimmed from space at each end
#   - an empty line will be ignored
#
sub __readLines
{
	my $fn = slashify(File::Spec->rel2abs(shift()));
	
	die("No such file: '$fn'\n") unless -f $fn;

	my @lines;
	open (my $fh, '<', $fn) or die("Failed to open '$fn': $!\n");
	my $line;
	while (defined($line = <$fh>))
	{
		chomp($line);
		
		# handle lines with line continuation
		# until no more continuation is found
		#
		if ($line =~ s#\\\s*$##)
		{
			# append lines...
			#
			$line .= <$fh>;
			
			# ...and repeat, unless we hit eof
			#
			redo unless eof($fh);
		}
		
		# if the resulting line is a comment line, ignore it
		#
		if ($line !~ /^\s*#/)
		{
			# ensure removing any  trailing line continuation is removed
			# (can happen if there is no extra line after a line continuation, just eof)
			#
			$line =~ s#\\\s*$##;
			
			# trim the ends, and add it - but only if it's not empty
			#
			$line = trim($line);
			push(@lines, $line) if $line;
		}
	}
	close($fh);
	
	return @lines;
}

1;
