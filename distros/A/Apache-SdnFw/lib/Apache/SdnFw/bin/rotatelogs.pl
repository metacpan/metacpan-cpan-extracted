#!/usr/bin/perl

# normally we should "use strict" but because of the
# way we do file handles below that would break this script
# so DONT USE STRICT HERE!

my $logdir = "/usr/local/apache/logs";

# clear root level logs, which we do not collect
`cat /dev/null >$logdir/access_log`;
`cat /dev/null >$logdir/error_log` if (-e "$logdir/error_log");

my %months = ("Jan" => "01", "Feb" => "02", "Mar" => "03", "Apr" => "04", "May" => "05", "Jun" => "06", "Jul" => "07", "Aug" => "08", "Sep" => "09", "Oct" => "10", "Nov" => "11", "Dec" => "12");

if (-d "$logdir") {
	opendir LD, "$logdir";
	while (my $dir = readdir LD) {
		next if ($dir =~ m/^\./); # skip hidden directories
		# rotate any logs we have here
		if (-d "$logdir/$dir") {
			if (-e "$logdir/$dir/access_log") {
				rotate_logs("$logdir/$dir",$dir);
			}
		}
	}
	close LD;
}

sub rotate_logs {
	my $dir = shift;
	my $sitecode = shift;

	if (-e "/data/$sitecode") {
		my %files;
		unless(-e "/data/$sitecode/archive") {
			mkdir "/data/$sitecode/archive", 0775;
		}
		if (-e "$dir/access_log") {
			open LF, "$dir/access_log";
			while (<LF>) {
				if (m#^\S+\s\S+\s\S+\s\[(\d+)/(\S+)/(\d+)#) {
					my $d = $1;
					my $m = $months{$2};
					my $y = $3;
					unless(defined($files{"$y$m$d"})) {
						unless(-e "/data/$sitecode/archive/$y-$m") {
							mkdir "/data/$sitecode/archive/$y-$m", 0775;
						}
						$files{"$y$m$d"} = "$y$m$d";
						open $files{"$y$m$d"}, "| gzip -c >/data/$sitecode/archive/$y-$m/access_log-$y-$m-$d.gz";
					}
					*STDOUT = "$y$m$d";
					print $_;
				}
			}
			close LF;
		}
		foreach my $f (keys %files) {
			close $files{$f};
		}
	}

	`cat /dev/null >$dir/access_log`;
	`cat /dev/null >$dir/error_log` if (-e "$dir/error_log");
}
