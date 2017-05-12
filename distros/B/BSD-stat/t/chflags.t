#
# $Id: chflags.t,v 1.22 2012/08/21 10:06:12 dankogai Exp $
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
use strict;
my $Debug = 0;

use BSD::stat;
use File::Copy;

my $dummy = $0; $dummy =~ s,([^/]+)$,dummy,o;
copy($0, $dummy) or die "copy $0 -> $dummy failed!";
SKIP:{
    skip 'chflags() not supported', 5 unless chflags(UF_IMMUTABLE, $dummy);
    ok chflags(UF_IMMUTABLE, $dummy), "chflags(UF_IMMUTABLE, '$dummy')";
    is lstat($dummy)->flags, UF_IMMUTABLE,  "lstat('$dummy')->flags";
    ok !unlink($dummy), "unlink('$dummy') must fail";
    $Debug and warn $!;
    ok chflags(0, $dummy), "chflags(0, '$dummy')";
    ok unlink($dummy),     "unlink('$dummy') must work now";
}
unlink $dummy;
