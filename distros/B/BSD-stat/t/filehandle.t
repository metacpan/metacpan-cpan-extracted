#
# $Id: filehandle.t,v 1.21 2012/08/19 13:29:26 dankogai Exp $
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
use strict;
my $Debug = 0;
BEGIN { plan tests => 36 };

use BSD::stat;

my @lstat = lstat($0);

open F, $0 or die "$0:$!";
my @fstat1 = lstat(*F);
close F;

use FileHandle;
my $fh = FileHandle->new($0) or die "$0:$!";
my @fstat2 = lstat($fh);
undef $fh;

for my $i (0..$#lstat){
    ok($lstat[$i] == $fstat1[$i]);
    ok($lstat[$i] == $fstat2[$i]);
}
$Debug and warn join(",", @fstat1), "\n";
