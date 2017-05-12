#!/usr/bin/perl -w
use strict;
use warnings FATAL => 'all';
use Linux::Unshare qw(unshare_ns);

use File::Slurp;
use File::Temp qw(tempdir);
use File::Path qw(mkpath);
use File::Basename qw(dirname);

unshare_ns() and die;

my @mf = read_file('MANIFEST');
my $td = tempdir('/tmp/swit_root_XXXXXX', CLEANUP => 1);
for my $f (@mf) {
	chomp $f;
	mkpath $td . "/" . dirname($f);
	system("cp -a $f $td/$f") and die $f;
}
chdir $td;
system("chmod -R o-rwx *") and die;
system("mount --bind /tmp /usr/local/share/perl/5.10.0/Apache") and die;
system("perl Makefile.PL") or system("make") or system("make", @ARGV);
chdir '/';
