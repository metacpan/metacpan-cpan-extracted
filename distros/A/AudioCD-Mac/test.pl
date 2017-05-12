#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..17\n"; }
END {print "not ok 1\n" unless $loaded;}
use AudioCD::Mac;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use strict;
my $cd = new AudioCD::Mac;
my $t;

printf "%sok 2%s\n",  $cd->volume(255) == 255  ? ('','') : ('not ', " ($^E)");

$t = '  (Now playing track 2 -- please wait 5 seconds)';
printf "%sok 3%s\n",  $cd->play(2)             ? ('','') : ('not ', " ($^E)");
printf "%sok 4%s\n",  $cd->status == CD_PLAY   ? ('',$t) : ('not ', " ($^E)");
printf "%sok 5%s\n",  ($cd->info)[0] == 2      ? ('','') : ('not ', " ($^E)");

$t = sprintf('  (Volume is %d)', $cd->volume);
printf "%sok 6%s\n",  $cd->volume == 255       ? ('',$t) : ('not ', " ($^E)");
sleep(5);

$t = '  (Now paused -- please wait 5 seconds)';
printf "%sok 7%s\n",  $cd->pause               ? ('','') : ('not ', " ($^E)");
printf "%sok 8%s\n",  $cd->status == CD_PAUSE  ? ('',$t) : ('not ', " ($^E)");
sleep(5);

printf "%sok 9%s\n",  $cd->volume(50) == 50    ? ('','') : ('not ', " ($^E)");

$t = '  (Now playing again -- please wait 5 seconds)';
printf "%sok 10%s\n", $cd->continue            ? ('','') : ('not ', " ($^E)");
printf "%sok 11%s\n", $cd->status == CD_PLAY   ? ('',$t) : ('not ', " ($^E)");

$t = sprintf('  (Volume is %d)', $cd->volume);
printf "%sok 12%s\n", $cd->volume == 50        ? ('',$t) : ('not ', " ($^E)");
sleep(5);

my @info = $cd->info;
$t = sprintf('  (Currently at track %d, %.2d:%.2d)', @info[0..2]);
printf "%sok 13%s\n", @info                    ? ('',$t) : ('not ', " ($^E)");

$t = '  (Now stopped)';
printf "%sok 14%s\n", $cd->stop                ? ('','') : ('not ', " ($^E)");
my $status = $cd->status;
printf "%sok 15%s\n", ($status == CD_FINISH || $status == CD_STOP)
                                               ? ('',$t) : ('not ', " ($^E)");

my(@discs);
if (do 'CDDB.pm') {  # sold separately
    my $cddb = new CDDB;
    printf "%sok 16%s\n", (my @toc = $cd->cddb_toc) ? ('','') : ('not ', " ($^E)");
    my @cddb_info = $cddb->calculate_id(@toc);
    @discs = $cddb->get_discs(@cddb_info[0, 3, 4]);
} else {
    print "No CDDB.pm found, skipping test 16.\n";
}

$t = "  (CD should be ejected now)";
printf "%sok 17%s\n", $cd->eject              ? ('',$t) : ('not ', " ($^E)");

if ($INC{'CDDB.pm'}) {
    print "You were probably listening to $discs[0]->[2]\n\n";
}
