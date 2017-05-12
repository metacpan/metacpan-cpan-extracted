#########################
use strict;
use warnings;
use Capture::Tiny qw(capture_stderr);
use Test::More tests => 28;
use Text::Convert::PETSCII qw/:convert/;
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
        my ($disk_id, $dos_type) = @_;
        my $full_disk_id = join '', map { chr ord } split //, ascii_to_petscii($disk_id);
        # Avoid 'Invalid PETSCII code at position 3 of converted text string: "0xa0"' warning:
        $full_disk_id .= chr 0x20;
        $full_disk_id .= join '', map { chr ord } split //, ascii_to_petscii($dos_type);
        my $diskBAM = D64::Disk::BAM->new();
        $diskBAM->full_disk_id(0, $full_disk_id);
        return $diskBAM;
    }
}
#########################
{
    BEGIN { use_ok(q{D64::Disk::BAM}) };
}
#########################
{
    can_ok(q{D64::Disk::BAM}, 'disk_id');
    can_ok(q{D64::Disk::BAM}, 'full_disk_id');
    can_ok(q{D64::Disk::BAM}, 'dos_type');
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $disk_id = $diskBAM->disk_id(1, 'A0');
    is(petscii_to_ascii($disk_id), 'A0', q{disk_id - set disk ID (valid length, with PETSCII conversion)});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $disk_id = $diskBAM->disk_id(0, ascii_to_petscii('A1'));
    is($disk_id, 'A1', q{disk_id - set disk ID (valid length, without PETSCII conversion)});
}
#########################
{
    my $diskBAM = get_named_bam_object('A2', '2A');
    my $disk_id = $diskBAM->disk_id(1);
    is($disk_id, 'A2', q{disk_id - get disk ID (valid length, with PETSCII conversion)});
}
#########################
{
    my $diskBAM = get_named_bam_object('A3', '2A');
    my $disk_id = $diskBAM->disk_id(0);
    is(petscii_to_ascii($disk_id), 'A3', q{disk_id - get disk ID (valid length, without PETSCII conversion)});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $disk_id;
    my $stderr = capture_stderr {
        $disk_id = $diskBAM->disk_id(0, ascii_to_petscii('A'));
    };
    is($disk_id, 'A', q{disk_id - set disk ID (too short length, check stored value)});
    like($stderr, qr/^\QDisk ID to be set contains 1 bytes: "A"\E/, q{disk_id - set disk ID (too short length, check issued warning)});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $disk_id;
    my $stderr = capture_stderr {
        $disk_id = $diskBAM->disk_id(0, ascii_to_petscii('A44'));
    };
    is($disk_id, 'A4', q{disk_id - set disk ID (too long length, check stored value)});
    like($stderr, qr/^\QDisk ID to be set contains 3 bytes: "A44"\E/, q{disk_id - set disk ID (too long length, check issued warning)});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $full_disk_id = $diskBAM->full_disk_id(1, 'BFUL0');
    is(petscii_to_ascii($full_disk_id), 'BFUL0', q{full_disk_id - set full disk ID (valid length, with PETSCII conversion)});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $full_disk_id = $diskBAM->full_disk_id(0, ascii_to_petscii('BFUL1'));
    is($full_disk_id, 'BFUL1', q{full_disk_id - set full disk ID (valid length, without PETSCII conversion)});
}
#########################
{
    my $diskBAM = get_named_bam_object('B2', '2A');
    my $full_disk_id = $diskBAM->full_disk_id(1);
    is($full_disk_id, 'B2 2A', q{full_disk_id - get full disk ID (valid length, with PETSCII conversion)});
}
#########################
{
    my $diskBAM = get_named_bam_object('B3', '2A');
    my $full_disk_id = $diskBAM->full_disk_id(0);
    is(petscii_to_ascii($full_disk_id), 'B3 2A', q{full_disk_id - get full disk ID (valid length, without PETSCII conversion)});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $full_disk_id;
    my $stderr = capture_stderr {
        $full_disk_id = $diskBAM->full_disk_id(0, ascii_to_petscii('BFUL'));
    };
    is($full_disk_id, 'BFUL', q{full_disk_id - set full disk ID (too short length, check stored value)});
    like($stderr, qr/^\QFull disk ID to be set contains 4 bytes: "BFUL"\E/, q{full_disk_id - set full disk ID (too short length, check issued warning)});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $full_disk_id;
    my $stderr = capture_stderr {
        $full_disk_id = $diskBAM->full_disk_id(0, ascii_to_petscii('BFUL44'));
    };
    is($full_disk_id, 'BFUL4', q{full_disk_id - set full disk ID (too long length, check stored value)});
    like($stderr, qr/^\QFull disk ID to be set contains 6 bytes: "BFUL44"\E/, q{full_disk_id - set full disk ID (too long length, check issued warning)});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $dos_type = $diskBAM->dos_type(1, 'C0');
    is(petscii_to_ascii($dos_type), 'C0', q{dos_type - set DOS type (valid length, with PETSCII conversion)});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $dos_type = $diskBAM->dos_type(0, ascii_to_petscii('C1'));
    is($dos_type, 'C1', q{dos_type - set DOS type (valid length, without PETSCII conversion)});
}
#########################
{
    my $diskBAM = get_named_bam_object('ID', 'C2');
    my $dos_type = $diskBAM->dos_type(1);
    is($dos_type, 'C2', q{dos_type - get DOS type (valid length, with PETSCII conversion)});
}
#########################
{
    my $diskBAM = get_named_bam_object('ID', 'C3');
    my $dos_type = $diskBAM->dos_type(0);
    is(petscii_to_ascii($dos_type), 'C3', q{dos_type - get DOS type (valid length, without PETSCII conversion)});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $dos_type;
    my $stderr = capture_stderr {
        $dos_type = $diskBAM->dos_type(0, ascii_to_petscii('C'));
    };
    is($dos_type, 'C', q{dos_type - set DOS type (too short length, check stored value)});
    like($stderr, qr/^\QDOS type to be set contains 1 bytes: "C"\E/, q{dos_type - set DOS type (too short length, check issued warning)});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $dos_type;
    my $stderr = capture_stderr {
        $dos_type = $diskBAM->dos_type(0, ascii_to_petscii('C44'));
    };
    is($dos_type, 'C4', q{dos_type - set DOS type (too long length, check stored value)});
    like($stderr, qr/^\QDOS type to be set contains 3 bytes: "C44"\E/, q{dos_type - set DOS type (too long length, check issued warning)});
}
#########################
