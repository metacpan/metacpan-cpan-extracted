#!/usr/bin/perl

use strict;
use warnings;
use boolean qw(true);

use App::OpenVZ::BCWatch;
use File::Spec;
use File::Temp ':POSIX';
use FindBin qw($Bin);
use Test::More tests => 2;

my $input_file = File::Spec->catfile($Bin, 'data', 'user_beancounters');
my $data_file = tmpnam();

open(my $fh, '<', $input_file) or die "Cannot open $input_file: $!\n";
my $output = do { local $/; <$fh> };
close($fh);

my $watch = App::OpenVZ::BCWatch->new(
    input_file => $input_file,
    data_file  => $data_file,
    _tests     => true,
);
$watch->_get_data_running;
$watch->_put_data_file;
$watch->_get_data_file;

$watch->{data}{104}{kmemsize}->[0]->{failcnt}++;
$watch->{data}{106}{kmemsize}->[0]->{failcnt}++;

$watch->_compare_data;

my @expected = map { chomp; $_ } split /==\n/, do { local $/; <DATA> };

foreach my $i (0 .. $#{$watch->{tests}->{report}}) {
    is_deeply(
        [ split /\n/, $watch->{tests}->{report}->[$i] ],
        [ split /\n/, $expected[$i] ],
        sprintf("basic output %d", $i + 1),
    );
}

__DATA__
Old:                          New:
----                          ----
Uid: 104                      Uid: 104
Res: kmemsize                 Res: kmemsize
Held: 2623183                 Held: 2623183
Maxheld: 3739217              Maxheld: 3739217
Barrier: 268435455            Barrier: 268435455
Limit: 268435455              Limit: 268435455
Failcnt: 0                  * Failcnt: 1
==
Old:                          New:
----                          ----
Uid: 106                      Uid: 106
Res: kmemsize                 Res: kmemsize
Held: 1834376                 Held: 1834376
Maxheld: 3718847              Maxheld: 3718847
Barrier: 22231449             Barrier: 22231449
Limit: 24454593               Limit: 24454593
Failcnt: 4                  * Failcnt: 5
