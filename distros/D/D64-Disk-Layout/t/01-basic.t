#########################
use Test::Deep;
use Test::More tests => 10;
use File::Temp qw(tmpnam);
#########################
{
BEGIN { require_ok('D64::Disk::Layout') };
}
#########################
{
my $d64DiskLayoutObj = D64::Disk::Layout->new();
is(ref $d64DiskLayoutObj, 'D64::Disk::Layout', 'new - create empty unformatted D64 disk image layout without sector data');
}
#########################
{
my $d64DiskLayoutObj = D64::Disk::Layout->new();
my @sector_count = ();
my $bytes_count = 0;
for (my $track = 1; $track <= 35; $track++) {
    my $num_sectors = $d64DiskLayoutObj->num_sectors($track);
    push @sector_count, $num_sectors;
    for (my $sector = 0; $sector < $num_sectors; $sector++) {
        my @sector_data = $d64DiskLayoutObj->sector_data($track, $sector);
        $bytes_count += scalar @sector_data;
    }
}
cmp_deeply({ bytes_count => $bytes_count, sector_count => \@sector_count }, { bytes_count => 174848, sector_count => [21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 19, 19, 19, 19, 19, 19, 19, 18, 18, 18, 18, 18, 18, 17, 17, 17, 17, 17] }, 'new - create empty unformatted D64 disk image layout with sector data');
}
#########################
{
my $d64DiskLayoutObj = D64::Disk::Layout->new();
is($d64DiskLayoutObj->num_tracks(), 35, 'num_tracks - get number of tracks available')
}
#########################
{
my $d64DiskLayoutObj = D64::Disk::Layout->new();
my $save_error;
open FH, '>', \$save_error;
*BACKUP = *STDERR;
*STDERR = *FH;
my $saveOK = $d64DiskLayoutObj->save();
close FH;
*STDERR = *BACKUP;
ok(! $saveOK, 'save - unable to save D64 disk layout object created as an empty disk image');
}
#########################
{
my $filename = tmpnam() . '.d64';
my $d64DiskLayoutObj = D64::Disk::Layout->new();
my $saveOK = $d64DiskLayoutObj->save_as($filename);
ok($saveOK, 'save_ok - save D64 disk layout data to file with specified name');
unlink($filename);
}
#########################
{
my $d64DiskLayoutObj = D64::Disk::Layout->new();
my @sector_data = $d64DiskLayoutObj->sector_data(1, 0);
my $sector_data = join '', map { sprintf "\$%02x", ord } @sector_data;
is($sector_data, '$00' x 256, 'sector_data - read physical sector data from D64 disk image layout');
}
#########################
{
my $d64DiskLayoutObj = D64::Disk::Layout->new();
my $sector_data = join '', map { chr ord $_ } split //, 'xy' x 128;
my @sector_data = $d64DiskLayoutObj->sector_data(1, 1, $sector_data);
$sector_data = join '', map { sprintf "\$%02x", ord } @sector_data;
is($sector_data, '$78$79' x 128, 'sector_data - write physical sector data into D64 disk image layout');
}
#########################
{
my $d64DiskLayoutObj = D64::Disk::Layout->new();
my $sector_data = join '', map { chr ord $_ } split //, 'a';
my $write_error;
open FH, '>', \$write_error;
*BACKUP = *STDERR;
*STDERR = *FH;
my @sector_data = $d64DiskLayoutObj->sector_data(1, 1, $sector_data);
close FH;
*STDERR = *BACKUP;
$sector_data = join '', map { sprintf "\$%02x", ord } @sector_data;
is($sector_data, '$61' . '$00' x 255, 'sector_data - write physical sector data with less data than required');
}
#########################
{
my $d64DiskLayoutObj = D64::Disk::Layout->new();
my $sector_data = join '', map { chr ord $_ } split //, '123' x 86;
my $write_error;
open FH, '>', \$write_error;
*BACKUP = *STDERR;
*STDERR = *FH;
my @sector_data = $d64DiskLayoutObj->sector_data(1, 1, $sector_data);
close FH;
*STDERR = *BACKUP;
$sector_data = join '', map { sprintf "\$%02x", ord } @sector_data;
is($sector_data, '$31$32$33' x 85 . '$31', 'sector_data - write physical sector data with more data than required');
}
#########################
