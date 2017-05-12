#########################
use bytes;
use strict;
use warnings;
use IO::Scalar;
use Test::More tests => 3;
#########################
{
    sub get_empty_bam_object {
        my $diskBAM = D64::Disk::BAM->new();
        return $diskBAM;
    }
}
#########################
{
    sub get_named_bam_object {
        my ($convert, $disk_name) = @_;
        my $diskBAM = D64::Disk::BAM->new();
        $diskBAM->disk_name($convert, $disk_name);
        $diskBAM->disk_id(1, '20');
        $diskBAM->sector_used(0x11, 0x00, 1);
        $diskBAM->sector_used(0x11, 0x01, 1);
        return $diskBAM;
    }
}
#########################
{
    BEGIN { use_ok(q{D64::Disk::BAM}) };
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    is($diskBAM->num_free_sectors('all'), 664, 'get number of free sectors on an entire disk from an empty BAM object');
}
#########################
{
    my $diskBAM = get_named_bam_object();
    is($diskBAM->num_free_sectors('all'), 662, 'get number of free sectors on an entire disk from a valid BAM object');
}
#########################
