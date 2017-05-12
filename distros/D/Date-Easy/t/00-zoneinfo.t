# Not really a unit test, but a way to see information about the timezone a given test machine is
# running under.  This is most useful in CPAN Testers reports.
#
# Thanks to Andreas Koenig for coming up with the idea for this:
# http://www.nntp.perl.org/group/perl.cpan.testers.discuss/2016/03/msg3801.html

use Test::Most 0.25;
use POSIX qw< strftime >;

my $FAIL_STRING = "CANNOT DETERMINE";


my $zonefile = zonefile();
my $info = zoneinfo($zonefile);

diag '';
diag '#' x 40;
diag "TIMEZONE INFORMATION:";
diag '';
diag "     Local Time: " . localtime;
diag "Zone Specifiers: " . strftime("%Z %z", localtime);
diag "       Zonefile: $zonefile";
diag "  Zonefile Info: $info";
diag '#' x 40;

plan skip_all => 'Informational Only';


# This is probably only going to work on Unix-like systems.
# Thus, it's not particularly worth going all File::Spec on it.
sub zonefile
{
	return $ENV{TZ} if defined $ENV{TZ};			# respect environment override
	my $file_pointer = '/etc/timezone';
	if (-r $file_pointer)
	{
		my $z;
		open(IN, $file_pointer) and $z = <IN> and close(IN);
		chomp $z;
		return $z;
	}
	return $FAIL_STRING;
}

# Again, this is probably only going to work on Unix-y machines.
# Therefore we're not going to try but so hard to find `file`.
sub zoneinfo
{
	# First try: in case $PATH is empty or severely impoverished.
	my $file_cmd = '/usr/bin/file';
	# If it's not there, maybe it'll just be in $PATH.
	$file_cmd = 'file' unless -x $file_cmd;

	# Now we have to find the file to run it on.
	# This is usually a symlink to the proper file.
	my $timezonefile = '/etc/localtime';
	unless (-r $timezonefile)
	{
		# Okay, let's see if we can find it ourselves.
		my $zonefile = shift;
		# If we couldn't find the name of the zonefile, we're done.
		return $FAIL_STRING if $zonefile eq $FAIL_STRING;
		# We have a few places to look.  See:
		# http://stackoverflow.com/questions/3896587/are-linuxs-timezone-files-always-in-usr-share-zoneinfo
		my $found = 0;
		foreach ($ENV{TZDIR}, qw< /usr/share/zoneinfo /usr/lib/zoneinfo >)
		{
			if ($_ and -d $_)
			{
				$timezonefile = "$_/$zonefile";
				$found = 1;
				last;
			}
		}
		# If we found it, make sure we can read it.
		# Otherwise, just give up.
		if ($found)
		{
			return $FAIL_STRING unless -r $timezonefile;
		}
		else
		{
			return $FAIL_STRING;
		}
	}

	# Okay, we either know where `file` is or are just going to trust $PATH.
	# And we have a readable location for the time zone file.
	my $info = `$file_cmd $timezonefile 2>&1`;
	if ($?)
	{
		# Didn't work, for whatever reason.  Just give up.
		return $FAIL_STRING;
	}
	else
	{
		# Don't need the filename.
		$info =~ s/^.*:\s*//;
		# Put a linebreak in there; it's a very long string.
		# Extra spaces are just to keep stuff lined up.
		$info =~ s/(seconds,)\s*/"$1\n" . ' ' x length("Zone Specifiers: ")/e;
		return $info;
	}
}
