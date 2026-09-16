use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use Data::HashMap::Shared::SS;

# clear()'s arena stores are plain, so a compiler may order them either way, and
# a writer killed among them can leave an empty table, the bump back at the
# start, and free lists still naming blocks above it.  The first insert then
# pops a stale block, the bump later climbs over the same bytes, and two live
# entries share them.  An empty map owns no block, so its arena is reset whole
# whatever state the lists are in.
#
# This writes that state directly: the table and bump cleared, the free lists
# not.

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/clear.shm";
my $N    = 300;

{
    my $m = Data::HashMap::Shared::SS->new($path, 1024);
    $m->put(sprintf('old-%04d-padpadpad', $_), 'o' x 40) for 1 .. $N;
    $m->remove(sprintf('old-%04d-padpadpad', $_)) for grep { $_ % 2 } 1 .. $N;
}

# Header: table_cap @20, states_off @48, size @136, tombstones @140,
# arena_bump @160.  The free lists at 192.. are left as they are.
{
    open my $fh, '+<:raw', $path or die $!;
    read $fh, my $hdr, 256 or die "short header";
    ok grep({ $_ } unpack 'L16', substr $hdr, 192, 64), 'the fixture left blocks on the free lists';
    my $table_cap  = unpack 'L', substr $hdr, 20, 4;
    my $states_off = unpack 'Q', substr $hdr, 48, 8;
    seek $fh, $states_off, 0 or die $!;
    print $fh "\0" x $table_cap;
    seek $fh, 136, 0 or die $!;
    print $fh pack 'LL', 0, 0;
    seek $fh, 160, 0 or die $!;
    print $fh pack 'Q', 16;
    close $fh or die $!;
}

my $m = Data::HashMap::Shared::SS->new($path, 1024);
is $m->size, 0, 'the map reads as empty';

my %want = map { sprintf('new-%04d-padpadpad', $_) => sprintf('%04d', $_) x 10 } 1 .. $N;
my $stored = grep { $m->put($_, $want{$_}) } sort keys %want;
is $stored, $N, 'every insert was stored';

my @bad = grep { ($m->get($_) // '<missing>') ne $want{$_} } sort keys %want;
is scalar @bad, 0, 'and every value reads back intact, sharing bytes with no other'
    or diag sprintf '%d of %d damaged, first: %s', scalar @bad, $N, $bad[0];

done_testing;
