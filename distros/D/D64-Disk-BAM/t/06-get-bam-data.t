#########################
use bytes;
use strict;
use warnings;
use D64::Disk::BAM;
use Test::More tests => 1;
#########################
{
my $diskBAM = D64::Disk::BAM->new();
$diskBAM->disk_name(1, 'name');
$diskBAM->disk_id(1, 'id');
# Allocate BAM sector:
my $bam_track = 0x12;
my $bam_sector = 0x00;
$diskBAM->sector_used($bam_track, $bam_sector, 1);
# Allocate first directory sector:
my $directory_first_track = $diskBAM->directory_first_track();
my $directory_first_sector = $diskBAM->directory_first_sector();
$diskBAM->sector_used($directory_first_track, $directory_first_sector, 1);
my $sector_data = $diskBAM->get_bam_data();
my $bam_data = join '', map { chr hex } qw(
12 01 41 00 15 ff ff 1f 15 ff ff 1f 15 ff ff 1f
15 ff ff 1f 15 ff ff 1f 15 ff ff 1f 15 ff ff 1f
15 ff ff 1f 15 ff ff 1f 15 ff ff 1f 15 ff ff 1f
15 ff ff 1f 15 ff ff 1f 15 ff ff 1f 15 ff ff 1f
15 ff ff 1f 15 ff ff 1f 11 fc ff 07 13 ff ff 07
13 ff ff 07 13 ff ff 07 13 ff ff 07 13 ff ff 07
13 ff ff 07 12 ff ff 03 12 ff ff 03 12 ff ff 03
12 ff ff 03 12 ff ff 03 12 ff ff 03 11 ff ff 01
11 ff ff 01 11 ff ff 01 11 ff ff 01 11 ff ff 01
4e 41 4d 45 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0
a0 a0 49 44 a0 32 41 a0 a0 a0 a0 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
);
is($sector_data, $bam_data, 'get_bam_data - get the BAM sector data');
}
#########################
