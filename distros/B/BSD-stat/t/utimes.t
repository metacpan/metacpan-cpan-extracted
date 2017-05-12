#
# $Id: utimes.t,v 1.31 2012/10/23 03:36:24 dankogai Exp $
#

use strict;
use warnings;
use BSD::stat;
use Test::More tests => 7;
use File::Spec;

my $target = File::Spec->catfile('t', "test$$");
my $symlink = File::Spec->catfile('t', "link$$");
open my $wfh, ">$target" or die "($target):$!";
my $when = 1234567898.765432;
ok utimes($when, $when, $target), "utimes($when, $when, $target)";
my $st = stat($target);
$when = 1234567890.987654;
ok utimes($when, $when, $wfh), "utimes($when, $when, $wfh)";
$st = stat($wfh);
close $wfh;

symlink $target, $symlink or die "symlink $target, $symlink : $!";
ok lutimes(0, 0, $symlink), "lutimes(0, 0, $symlink)";
is lstat($symlink)->mtime, 0, "lutimes() does touch $symlink";
is lstat($target)->mtime, 1234567890, "lutimes() leaves $target";

$when = 1234.5678;
ok lutimes($when, $when, $symlink), "lutimes($when, $when, $symlink)";
is lstat($symlink)->mtime, 1234, "lutimes() wrong sec on $symlink";
# some fs (like HFS+) does not have this field so test skipped
#is lstat($symlink)->mtimensec, 567800000, "lutimes() wrong nsec on $symlink";

unlink($target, $symlink) == 2 or die "unlink($target, $symlink):$!";
