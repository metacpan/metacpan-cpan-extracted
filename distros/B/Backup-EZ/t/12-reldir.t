#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use Backup::EZ;
use Data::Dumper;
use Test::More;

system("t/nuke.pl");
system("t/pave.pl");

my $ez;
eval {
	$ez = Backup::EZ->new(
						   conf         => 't/ezbackup_reldir.conf',
						   exclude_file => 'share/ezbackup_exclude.rsync',
						   dryrun       => 0
	);
};
ok($ez);

eval {
	$ez->backup
};
ok($@);


system("t/nuke.pl");
done_testing();
