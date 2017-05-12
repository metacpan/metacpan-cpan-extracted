#########################
use bytes;
use strict;
use warnings;
use IO::Scalar;
use Test::More tests => 9;
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
    my $sh = new IO::Scalar;
    $diskBAM->print_out_disk_header($sh, 0);
    my $print_out = ${$sh->sref};
    my $expected_print_out = '0 "                "    2a';
    is($print_out, $expected_print_out, 'print out formatted disk header line from an empty BAM object using ASCII character set');
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $sh = new IO::Scalar;
    $diskBAM->print_out_disk_header($sh, 1);
    my $print_out = ${$sh->sref};
    my $expected_print_out = join '', map { chr hex } qw(30 20 12 22 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 22 20 20 20 20 32 41 92);
    is($print_out, $expected_print_out, 'print out formatted disk header line from an empty BAM object using PETSCII character set');
}
#########################
{
    my $diskBAM = get_named_bam_object(1, 'abcdefghijklmnop');
    my $sh = new IO::Scalar;
    $diskBAM->print_out_disk_header($sh, 0);
    my $print_out = ${$sh->sref};
    my $expected_print_out = '0 "abcdefghijklmnop" 20 2a';
    is($print_out, $expected_print_out, 'print out formatted disk header line from a valid BAM object using ASCII character set');
}
#########################
{
    my $diskBAM = get_named_bam_object(1, 'abcdefghijklmnop');
    my $sh = new IO::Scalar;
    $diskBAM->print_out_disk_header($sh, 1);
    my $print_out = ${$sh->sref};
    my $expected_print_out = join '', map { chr hex } qw(30 20 12 22 41 42 43 44 45 46 47 48 49 4a 4b 4c 4d 4e 4f 50 22 20 32 30 20 32 41 92);
    is($print_out, $expected_print_out, 'print out formatted disk header line from a valid BAM object using PETSCII character set');
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $sh = new IO::Scalar;
    $diskBAM->print_out_blocks_free($sh, 0);
    my $print_out = ${$sh->sref};
    my $expected_print_out = '664 blocks free.';
    is($print_out, $expected_print_out, 'print out number of free blocks line from an empty BAM object using ASCII character set');
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $sh = new IO::Scalar;
    $diskBAM->print_out_blocks_free($sh, 1);
    my $print_out = ${$sh->sref};
    my $expected_print_out = join '', map { chr hex } qw(36 36 34 20 42 4c 4f 43 4b 53 20 46 52 45 45 2e);
    is($print_out, $expected_print_out, 'print out number of free blocks line from an empty BAM object using PETSCII character set');
}
#########################
{
    my $diskBAM = get_named_bam_object(1, 'abcdefghijklmnop');
    my $sh = new IO::Scalar;
    $diskBAM->print_out_blocks_free($sh, 0);
    my $print_out = ${$sh->sref};
    my $expected_print_out = '662 blocks free.';
    is($print_out, $expected_print_out, 'print out number of free blocks line from a valid BAM object using ASCII character set');
}
#########################
{
    my $diskBAM = get_named_bam_object(1, 'abcdefghijklmnop');
    my $sh = new IO::Scalar;
    $diskBAM->print_out_blocks_free($sh, 1);
    my $print_out = ${$sh->sref};
    my $expected_print_out = join '', map { chr hex } qw(36 36 32 20 42 4c 4f 43 4b 53 20 46 52 45 45 2e);
    is($print_out, $expected_print_out, 'print out number of free blocks line from a valid BAM object using PETSCII character set');
}
#########################
