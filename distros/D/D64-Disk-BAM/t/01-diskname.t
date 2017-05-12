#########################
use strict;
use warnings;
use Capture::Tiny qw(capture_stderr);
use Test::More tests => 20;
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
        my ($convert, $disk_name) = @_;
        my $diskBAM = D64::Disk::BAM->new();
        my $stderr = capture_stderr {
            $diskBAM->disk_name($convert, $disk_name);
        };
        return $diskBAM;
    }
}
#########################
{
    BEGIN { use_ok(q{D64::Disk::BAM}) };
}
#########################
{
    can_ok(q{D64::Disk::BAM}, 'disk_name');
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $disk_name = $diskBAM->disk_name(1, 'abcdefghijklmn');
    is(petscii_to_ascii($disk_name), 'abcdefghijklmn', q{disk_name - set disk name (length = 14 bytes, with PETSCII conversion)});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $disk_name;
    my $stderr = capture_stderr {
        $disk_name = $diskBAM->disk_name(0, ascii_to_petscii('abcdefghijklmn'));
    };
    is($disk_name, 'abcdefghijklmn', q{disk_name - set disk name (length = 14 bytes, without PETSCII conversion)});
    like($stderr, qr/^\QDisk name to be set contains 14 bytes: "abcdefghijklmn"\E/, q{disk_name - set disk name (length = 14 bytes, without PETSCII conversion)});
}
#########################
{
    my $diskBAM = get_named_bam_object(1, 'abcdefghijklmn');
    my $disk_name = $diskBAM->disk_name(1);
    is($disk_name, 'abcdefghijklmn', q{disk_name - get disk name (length = 14 bytes, with PETSCII conversion)});
}
#########################
{
    my $diskBAM = get_named_bam_object(1, 'abcdefghijklmn');
    my $disk_name = $diskBAM->disk_name(0);
    is(petscii_to_ascii($disk_name), 'abcdefghijklmn', q{disk_name - get disk name (length = 14 bytes, without PETSCII conversion)});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $disk_name = $diskBAM->disk_name(1, 'abcdefghijklmno');
    is(petscii_to_ascii($disk_name), 'abcdefghijklmno', q{disk_name - set disk name (length = 15 bytes, with PETSCII conversion)});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $disk_name;
    my $stderr = capture_stderr {
        $disk_name = $diskBAM->disk_name(0, ascii_to_petscii('abcdefghijklmno'));
    };
    is($disk_name, 'abcdefghijklmno', q{disk_name - set disk name (length = 15 bytes, without PETSCII conversion)});
    like($stderr, qr/^\QDisk name to be set contains 15 bytes: "abcdefghijklmno"\E/, q{disk_name - set disk name (length = 15 bytes, without PETSCII conversion)});
}
#########################
{
    my $diskBAM = get_named_bam_object(1, 'abcdefghijklmno');
    my $disk_name = $diskBAM->disk_name(1);
    is($disk_name, 'abcdefghijklmno', q{disk_name - get disk name (length = 15 bytes, with PETSCII conversion)});
}
#########################
{
    my $diskBAM = get_named_bam_object(1, 'abcdefghijklmno');
    my $disk_name = $diskBAM->disk_name(0);
    is(petscii_to_ascii($disk_name), 'abcdefghijklmno', q{disk_name - get disk name (length = 15 bytes, without PETSCII conversion)});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $disk_name = $diskBAM->disk_name(1, 'abcdefghijklmnop');
    is(petscii_to_ascii($disk_name), 'abcdefghijklmnop', q{disk_name - set disk name (length = 16 bytes, with PETSCII conversion)});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $disk_name = $diskBAM->disk_name(0, ascii_to_petscii('abcdefghijklmnop'));
    is($disk_name, 'abcdefghijklmnop', q{disk_name - set disk name (length = 16 bytes, without PETSCII conversion)});
}
#########################
{
    my $diskBAM = get_named_bam_object(1, 'abcdefghijklmnop');
    my $disk_name = $diskBAM->disk_name(1);
    is($disk_name, 'abcdefghijklmnop', q{disk_name - get disk name (length = 16 bytes, with PETSCII conversion)});
}
#########################
{
    my $diskBAM = get_named_bam_object(1, 'abcdefghijklmnop');
    my $disk_name = $diskBAM->disk_name(0);
    is(petscii_to_ascii($disk_name), 'abcdefghijklmnop', q{disk_name - get disk name (length = 16 bytes, without PETSCII conversion)});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $disk_name;
    my $stderr = capture_stderr {
        $disk_name = $diskBAM->disk_name(1, 'abcdefghijklmnopq');
    };
    is(petscii_to_ascii($disk_name), 'abcdefghijklmnop', q{disk_name - set disk name (length = 17 bytes, with PETSCII conversion)});
    like($stderr, qr/^\QDisk name to be set contains 17 bytes: "abcdefghijklmnopq"\E/, q{disk_name - set disk name (length = 17 bytes, with PETSCII conversion)});
}
#########################
{
    my $diskBAM = get_empty_bam_object();
    my $disk_name;
    my $stderr = capture_stderr {
        $disk_name = $diskBAM->disk_name(0, ascii_to_petscii('abcdefghijklmnopq'));
    };
    is($disk_name, 'abcdefghijklmnop', q{disk_name - set disk name (length = 17 bytes, without PETSCII conversion)});
    like($stderr, qr/^\QDisk name to be set contains 17 bytes: "abcdefghijklmnopq"\E/, q{disk_name - set disk name (length = 17 bytes, without PETSCII conversion)});
}
#########################
