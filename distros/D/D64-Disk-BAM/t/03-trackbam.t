#########################
use bytes;
use strict;
use warnings;
use Capture::Tiny qw(capture_stderr);
use Test::More tests => 42;
#########################
{
    BEGIN { use_ok(q{D64::Disk::BAM}) };
}
#########################
{
    sub get_empty_bam_object {
        my $sector_data = shift;
        my $diskBAM = D64::Disk::BAM->new($sector_data);
        return $diskBAM;
    }
}
#########################
{
    can_ok(q{D64::Disk::BAM}, 'num_free_sectors');
    can_ok(q{D64::Disk::BAM}, 'sector_used');
    can_ok(q{D64::Disk::BAM}, 'sector_free');
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $num_free_sectors = $diskBAM->num_free_sectors(1);
    is($num_free_sectors, 21, q{num_free_sectors - number of free sectors on track 1 of an empty disk image});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $num_free_sectors = $diskBAM->num_free_sectors(17);
    is($num_free_sectors, 21, q{num_free_sectors - number of free sectors on track 17 of an empty disk image});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $num_free_sectors = $diskBAM->num_free_sectors(18);
    is($num_free_sectors, 19, q{num_free_sectors - number of free sectors on track 18 of an empty disk image});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $num_free_sectors = $diskBAM->num_free_sectors(35);
    is($num_free_sectors, 17, q{num_free_sectors - number of free sectors on track 35 of an empty disk image});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $num_free_sectors;
    my $stderr = capture_stderr {
        $num_free_sectors = $diskBAM->num_free_sectors(0);
    };
    is($num_free_sectors, undef, q{num_free_sectors - number of free sectors on invalid track number});
    like($stderr, qr/^\QInvalid track number specified: 0\E/, q{num_free_sectors - unable to get the number of free sectors on invalid track});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $is_sector_used;
    my $stderr = capture_stderr {
        $is_sector_used = $diskBAM->sector_used(1, 21);
    };
    is($is_sector_used, undef, q{sector_used - check sector allocation on invalid sector number});
    like($stderr, qr/^\QInvalid sector number specified: 21\E/, q{sector_used - unable to check sector allocation on invalid sector});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $is_sector_used;
    my $stderr = capture_stderr {
        $is_sector_used = $diskBAM->sector_used(36, 1);
    };
    is($is_sector_used, undef, q{sector_used - check sector allocation on invalid track number});
    like($stderr, qr/^\QInvalid track number specified: 36\E/, q{sector_used - unable to check sector allocation on invalid track});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $is_sector_used = $diskBAM->sector_used(1, 0);
    is($is_sector_used, 0, q{sector_used - check sector allocation on valid sector number});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $is_sector_used = $diskBAM->sector_used(1, 0, 1);
    is($is_sector_used, 1, q{sector_used - allocate indicated sector number});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    $diskBAM->sector_used(1, 0, 1);
    my $is_sector_used = $diskBAM->sector_used(1, 0);
    is($is_sector_used, 1, q{sector_used - check if sector is used after allocation});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    $diskBAM->sector_used(1, 0, 1);
    $diskBAM->sector_used(1, 0, 0);
    my $is_sector_used = $diskBAM->sector_used(1, 0);
    is($is_sector_used, 0, q{sector_used - check if sector is used after deallocation});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    $diskBAM->sector_used(1, 0, 1);
    my $num_free_sectors = $diskBAM->num_free_sectors(1);
    is($num_free_sectors, 20, q{num_free_sectors - number of free sectors after allocation});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    $diskBAM->sector_used(1, 0, 1);
    $diskBAM->sector_used(1, 0, 0);
    my $num_free_sectors = $diskBAM->num_free_sectors(1);
    is($num_free_sectors, 21, q{num_free_sectors - number of free sectors after deallocation with sector_used});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    eval { $diskBAM->_increase_num_free_sectors(1); };
    like($@, qr/^\QInternal error! Unable to increase the number of free sectors on track 1 to 22, because it consists of 21 sectors only\E/, q{_increase_num_free_sectors - unable to increase the number of free sectors on already empty track});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $is_sector_used;
    my $stderr = capture_stderr {
        $diskBAM->sector_used(1, 0, 1);
        $is_sector_used = $diskBAM->sector_used(1, 0, 1);
    };
    is($is_sector_used, 1, q{sector_used - check sector allocation on repeated allocation});
    like($stderr, qr/^\QWarning! Allocating sector 0 on track 1, which is already in use\E/, q{sector_used - allocating sector which is already in use});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $is_sector_used;
    my $stderr = capture_stderr {
        $diskBAM->sector_used(1, 0, 1);
        $diskBAM->sector_used(1, 0, 0);
        $is_sector_used = $diskBAM->sector_used(1, 0, 0);
    };
    is($is_sector_used, 0, q{sector_used - check sector allocation on repeated deallocation});
    like($stderr, qr/^\QWarning! Deallocating sector 0 on track 1, which has been free before\E/, q{sector_used - deallocating sector which has been freed already});
}
#########################
{
    my $sector_data = 'AB';
    my $diskBAM;
    my $stderr = capture_stderr {
        $diskBAM = get_empty_bam_object($sector_data);
    };
    is($diskBAM, undef, q{_validate_bam_data - unable to create new BAM object based on empty sector data});
    like($stderr, qr/^\QFailed to validate the BAM sector data, expected the stream of 256 bytes but got 2 bytes\E/, q{_validate_bam_data - validation fails on empty sector data});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $sector_data = $diskBAM->get_bam_data();
    substr ($sector_data, 0x4c, 1) = chr 20;
    my $stderr = capture_stderr {
        $diskBAM = get_empty_bam_object($sector_data);
    };
    is($diskBAM, undef, q{_validate_bam_data - unable to create new BAM object with invalid number of empty sectors});
    like($stderr, qr/^\QFailed to validate the BAM sector data, invalid number of free sectors reported on track 19: claims 20 sectors free but track 19 has only 19 sectors\E/, q{_validate_bam_data - validation fails on invalid number of empty sectors});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $sector_data = $diskBAM->get_bam_data();
    substr ($sector_data, 0x4c, 1) = chr -1;
    my $stderr = capture_stderr {
        $diskBAM = get_empty_bam_object($sector_data);
    };
    is($diskBAM, undef, q{_validate_bam_data - unable to create new BAM object with negative number of empty sectors});
    like($stderr, qr/^\QFailed to validate the BAM sector data, invalid number of free sectors reported on track 19: claims \E\d+\Q sectors free but track 19 has only 19 sectors\E/, q{_validate_bam_data - validation fails on negative number of empty sectors});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $sector_data = $diskBAM->get_bam_data();
    substr ($sector_data, 0x00, 1) = chr 17;
    my $stderr = capture_stderr {
        $diskBAM = get_empty_bam_object($sector_data);
    };
    like($stderr, qr/^Warning! Track location of the first directory sector should be set to 18, but it is not: 17 found in the BAM sector data/, q{_validate_bam_data - validation warns on invalid track location of the directory});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $sector_data = $diskBAM->get_bam_data();
    substr ($sector_data, 0x01, 1) = chr 2;
    my $stderr = capture_stderr {
        $diskBAM = get_empty_bam_object($sector_data);
    };
    like($stderr, qr/^Warning! Sector location of the first directory sector should be set to 1, but it is not: 2 found in the BAM sector data/, q{_validate_bam_data - validation warns on invalid sector location of the directory});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $sector_data = $diskBAM->get_bam_data();
    substr ($sector_data, 0xa0, 2) = chr (1) . chr (2);
    my $stderr = capture_stderr {
        $diskBAM = get_empty_bam_object($sector_data);
    };
    like($stderr, qr/^Warning! Bytes at offsets \$A0-\$A1 of the BAM sector data are expected to be filled with \$A0, but they are not/, q{_validate_bam_data - validation warns on encountering sections supposed to be filled with $A0});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $sector_data = $diskBAM->get_bam_data();
    substr ($sector_data, 0xa7, 4) = chr (1) . chr (2) . chr(3) . chr(4);
    my $stderr = capture_stderr {
        $diskBAM = get_empty_bam_object($sector_data);
    };
    like($stderr, qr/^Warning! Bytes at offsets \$A7-\$AA of the BAM sector data are expected to be filled with \$A0, but they are not/, q{_validate_bam_data - validation warns on encountering sections supposed to be filled with $A0});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $sector_data = $diskBAM->get_bam_data();
    substr ($sector_data, 0x45, 1) = chr 128;
    my $stderr = capture_stderr {
        $diskBAM = get_empty_bam_object($sector_data);
    };
    is($diskBAM, undef, q{_validate_bam_data - unable to create new BAM object with incorrect bitmap of empty sectors});
    like($stderr, qr/^\QFailed to validate the BAM sector data, number of free sectors on track 17 (which is claimed to be 21) does not match free sector allocation (which seems to be 17)\E/, q{_validate_bam_data - validation fails on incorrect bitmap of empty sectors});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    $diskBAM->sector_used(1, 0, 1);
    $diskBAM->clear_bam();
    my $num_free_sectors = $diskBAM->num_free_sectors(1);
    is($num_free_sectors, 21, q{clear_bam - number of free sectors upon entire BAM data clearance});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    $diskBAM->sector_free(17, 1, 0);
    my $is_sector_free = $diskBAM->sector_free(17, 0);
    is($is_sector_free, 1, q{sector_free - check sector allocation on freeing sector number});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    $diskBAM->sector_free(17, 1, 0);
    my $is_sector_free = $diskBAM->sector_free(17, 1);
    is($is_sector_free, 0, q{sector_free - check sector allocation on using sector number});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    $diskBAM->sector_free(17, 0, 0);
    $diskBAM->sector_free(17, 1, 0);
    my $is_sector_free = $diskBAM->sector_free(19, 0, 0);
    is($is_sector_free, 0, q{sector_free - remove sector from the list of empty sectors});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    $diskBAM->sector_free(35, 0, 0);
    $diskBAM->sector_free(35, 16, 0);
    $diskBAM->sector_free(35, 16, 1);
    my $num_free_sectors = $diskBAM->num_free_sectors(35);
    is($num_free_sectors, 16, q{num_free_sectors - number of free sectors after deallocation with sector_free});
}
#########################
