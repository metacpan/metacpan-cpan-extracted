#########################
use D64::Disk::Layout;
use Test::Deep;
use Test::More tests => 2;
#########################
{
my $d64DiskLayoutObj = D64::Disk::Layout->new();
my @track_layouts = $d64DiskLayoutObj->tracks();
ok(@track_layouts == 35, 'track - fetch disk layout data as an array of 35 arrays of sector objects');
cmp_deeply([ map { scalar grep { ref $_ eq 'D64::Disk::Layout::Sector' } @{$_} } @track_layouts ], \@D64::Disk::Layout::sectors_per_track, 'fetch disk layout data as an array of arrays of sector objects allocated by their respective track numbers');
}
#########################
