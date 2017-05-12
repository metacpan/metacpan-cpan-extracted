#
# $Id: 99pts_cleanup.t,v 11.1 2004/11/18 13:31:44 wpm Exp $
#
# (c) 2003-2004 Morgan Stanley and Co.
# See ..../src/LICENSE for terms of distribution.
#

# print STDERR Data::Dumper->Dump([$vos],['vos']);

use strict;
use English;
use Data::Dumper;

use vars qw(
	    $TestCounter
	    $TestTotal
	    $Loaded
	   );

BEGIN {
    require "./util/lib/parse_config";
}

BEGIN {
    $| = 1;
    if ( $AFS::Command::Tests::Config{AFS_COMMAND_DISABLE_TESTS} =~ /\bpts\b/ ) {
	$TestTotal = 0;
    } elsif ( $AFS::Command::Tests::Config{AFS_COMMAND_CELLNAME} eq 'your.cell.name' ) {
	$TestTotal = 1;
    } else {
	$TestTotal = 3;
    }
    print "1..$TestTotal\n";
}

END {print "not ok 1\n" unless $Loaded;}
use AFS::Command::PTS 1.99;
$Loaded = 1;
$TestCounter = 1;
print "ok $TestCounter\n";
$TestCounter++;

exit 0 unless $TestTotal > 1;

my $cell = $AFS::Command::Tests::Config{AFS_COMMAND_CELLNAME} || do {
    print "not ok $TestCounter..$TestTotal\n";
    die "Missing configuration variable AFS_COMMAND_CELLNAME\n";
};

my $ptsgroup = $AFS::Command::Tests::Config{AFS_COMMAND_PTS_GROUP} || do {
    print "not ok $TestCounter..$TestTotal\n";
    die "Missing configuration variable AFS_COMMAND_PTS_GROUP\n";
};

my $ptsuser = $AFS::Command::Tests::Config{AFS_COMMAND_PTS_USER} || do {
    print "not ok $TestCounter..$TestTotal\n";
    die "Missing configuration variable AFS_COMMAND_PTS_USER\n";
};

my $binary = $AFS::Command::Tests::Config{AFS_COMMAND_BINARY_PTS} || 'pts';

#
# If the constructor fails, we're doomed.
#
my $pts = AFS::Command::PTS->new
  (
   command		=> $binary,
  );
if ( ref $pts && $pts->isa("AFS::Command::PTS") ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die "Unable to instantiate AFS::Command::PTS object\n";
}

my $result = $pts->delete
  (
   nameorid		=> [ $ptsgroup, $ptsuser ],
   cell			=> $cell,
  );
if ( $result ) {
    print "ok $TestCounter\n";
    $TestCounter++;
} else {
    print "not ok $TestCounter..$TestTotal\n";
    die("Unable to delete pts entries:\n" .
	$pts->errors() .
	Data::Dumper->Dump([$pts],['pts']));
}

exit 0;

# END {
#     $TestCounter--;
#     warn "Total number of tests == $TestCounter\n";
# }
