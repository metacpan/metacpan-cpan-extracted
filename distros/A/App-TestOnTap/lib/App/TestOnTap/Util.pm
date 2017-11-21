package App::TestOnTap::Util;

use strict;
use warnings;

use POSIX qw(strftime getcwd);
use File::Basename;
use File::Spec;

our $IS_WINDOWS = $^O eq 'MSWin32';
our $IS_PACKED = $ENV{PAR_0} ? 1 : 0;
our $FILE_SEP = $IS_WINDOWS ? '\\' : '/';
our $SHELL_ARG_DELIM = $IS_WINDOWS ? '"' : "'";

use Exporter qw(import);
our @EXPORT_OK =
	qw
		(
			slashify
			trim
			stringifyTime
			ensureArray
			expandAts
			runprocess
			$IS_WINDOWS
			$IS_PACKED
			$FILE_SEP
			$SHELL_ARG_DELIM
		);

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

# trim off any ws at front/end of a string
#
sub trim
{
	my $s = shift;

	$s =~ s/^\s+|\s+$//g if defined($s);

	return $s;
}

# turn an epoch time into a compact ISO8601 UTC string
#
sub stringifyTime
{
	my $tm = shift;
	
	# deal with possible hires timings and
	# convert the raw timestamps to strings
	#
	my $subsecs = '';
	if ($tm =~ m#\.#)
	{
		$tm =~ s#^([^\.]+)\.(.*)#$1#;
		$subsecs = ".$2";
	}
	
	return strftime("%Y%m%dT%H%M%S${subsecs}Z", gmtime($tm));
}

# ensure we end up with an array or undef
# input can be:
#   undef
# 	an array
#   a space-separared string
#   a newline-separated string
# 
sub ensureArray
{
	my $data = shift || [];
	
	return
		(ref($data) eq 'ARRAY')
			? $data
			: ($data =~ m#\n#)
				? [ split("\n", $data) ]
				: [ split(' ', $data) ];
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
			
			if ($line)
			{
				# expand any ${envvar} in the line
				#
				while ($line =~ m#\$\{([^}]+)\}#)
				{
					my $ev = $1;
					die("No environment variable '$ev' in '$line'\n") unless exists($ENV{$ev});
					$line =~ s#\$\{\Q$ev\E\}#$ENV{$ev}#;
				}
				
				# line is ready
				#
				push(@lines, $line);
			}
		}
	}
	close($fh);
	
	return @lines;
}

sub runprocess
{
	my $cb = shift;
	my $wd = shift;
	my @argv = @_;
	
	my $cwd = getcwd();
	chdir($wd) || die("Failed to change directory to '$wd': $!\n");

	$_ = "$SHELL_ARG_DELIM$_$SHELL_ARG_DELIM" foreach (@argv);
	my $cmdline = join(' ', @argv);
	
	open(my $fh, '-|', "$cmdline 2>&1") || die("Failed to run '$cmdline': $!\n");
	while (my $line = <$fh>)
	{
		$cb->($line);
	}
	close($fh);
	my $xit = $? >> 8;

	chdir($cwd) || die("Failed to change directory back to '$cwd': $!\n");
	
	return $xit;
}

1;
