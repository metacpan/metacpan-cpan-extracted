#!/usr/bin/perl -w

use strict;

#TODO:
#- pull ROOT in from Cache::static Config
#- option for specifying threshold
#- options for using atime/ctime/mtime (if FS supports)

my $ROOT     = '/usr/local/Cache-Static';
my $THRESH   = 86400 * 30; #1 month
my $NOW      = time;
my $MAX_TIME = $NOW + 1;
my $VERBOSE  = 0;

my $bytes_deleted = 0;
my $files_deleted = 0;

prune_older($ROOT);

sub prune_older {
	my $dir = shift;
	opendir(DIR, $dir);
	foreach my $f (map { "$dir/$_" } grep(!/(\.|\.\.)/, readdir(DIR))) {
		if(-f $f) {
			#don't delete files named config or log* (log, log.1.gz, etc.)
			#note: config files can be 0 or 1 levels down dir tree
			next if ($f eq 'config' || $f =~ /^log/);
			my @t = stat($f);
			my $modtime = @t ? $t[9] : $MAX_TIME;
			if($modtime < ($NOW - $THRESH)) {
				my $file = $f;
				$file =~ s/^$ROOT//;
				my $size = $t[7];
				print "deleting old file: $file ($size bytes)\n" if($VERBOSE);
				if(unlink($f)) {
					$bytes_deleted += $size;
					$files_deleted++;
				} else {
					warn "can't delete file: $f\n"
				}
			}
		} elsif(-d $f) {
			prune_older($f);
		} else {
			warn "file is neither plain nor directory: $f\n";
		}
	}
	closedir(DIR);
}

print "$bytes_deleted bytes in $files_deleted files deleted\n";

