#!/home/johnl/bin/perl
#
#	@(#)$Id: fixin.pl,v 1.2 1992/01/06 14:45:19 johnl Exp $
#
#	FIXIN: from Programming Perl
#	Usage: fixin [-s] [file ...]

# Configuration
$does_hashbang = 1;		# Kernel recognises #!
$verbose = 1;			# Verbose by default

# Construct list of directories to search.
@absdirs = reverse grep(m!^/!, split(/:/, $ENV{'PATH'}, 999));

# Process command line arguments
if ($ARGV[0] eq '-s')
{
	shift;
	$verbose = 0;
}
die "Usage: $0 [-s] [file ...]\n" unless @ARGV || !-t;

@ARGV = '-' unless @ARGV;

# Process each file.
FILE: foreach $filename (@ARGV)
{
	open(IN, $filename) || ((warn "Can't process $filename: $!\n"), next);
	$_ = <IN>;
	next FILE unless /^#!/;		# Not a hash/bang file

	chop($cmd = $_);
	$cmd =~ s/^#! *//;
	($cmd, $arg) = split(' ', $cmd, 2);
	$cmd =~ s!^.*/!!;

	# Now look (in reverse) for interpreter in absolute path

	$found = '';
	foreach $dir (@absdirs)
	{
		if (-x "$dir/$cmd")
		{
			warn "Ignoring $found\n" if $verbose && $found;
			$found = "$dir/$cmd";
		}
	}

	# Figure out how to invoke interpreter on this machine

	if ($found)
	{
		warn "Changing $filename to $found\n" if $verbose;if ($does_hashbang)
		{
			$_ = "#!$found";
			$_ .= ' ' . $arg if $arg ne '';
			$_ .= "\n";
		}
		else
		{
			$_ = <<EOF;
:
eval 'exec $found $arg -S \$0 \${1+"\$@"}'
	if \$running_under_some_shell;
EOF
		}
	}
	else
	{
		warn "Can't find $cmd in PATH, $filename unchanged\n" if $verbose;
		next FILE;
	}

	# Make new file if necessary
	if ($filename eq '-') { select(STDOUT); }
	else
	{
		rename($filename, "$filename.bak") ||
			((warn "Can't modify $filename"), next FILE);
		open(OUT, ">$filename") ||
			die "Can't create new $filename: $!\n";
		($def, $ino, $mode) = stat IN;
		$mode = 0755 unless $dev;
		chmod $mode, $filename;
		select(OUT);
	}

	# Print the new #! line (or the equivalent) and copy the rest of the file.
	print;
	while (<IN>)
	{
		print;
	}
	close IN;
	close OUT;
}
