#########################
use Test::More tests => 9;
#########################
{
BEGIN { require_ok('D64::Disk::Layout::Base') };
unlink('__temp__.d64');
}
#########################
{
my $diskLayoutObj = D64::Disk::Layout::Base->new();
is(ref $diskLayoutObj, 'D64::Disk::Layout::Base', 'new - create empty unformatted disk image layout without sector data');
}
#########################
{
no warnings;
$D64::Disk::Layout::Base::bytes_per_sector = 2;
@D64::Disk::Layout::Base::sectors_per_track = (3, 2, 1);
}
#########################
{
my $diskLayoutObj = D64::Disk::Layout::Base->new();
my $sector_count = '';
my $bytes_count = 0;
for (my $track = 1; $track <= 3; $track++) {
    my $num_sectors = $diskLayoutObj->num_sectors($track);
    $sector_count .= $num_sectors;
    for (my $sector = 0; $sector < $num_sectors; $sector++) {
        my @sector_data = $diskLayoutObj->sector_data($track, $sector);
        $bytes_count += scalar @sector_data;
    }
}
is("$sector_count/$bytes_count", '321/12', 'new - create empty unformatted disk image layout with sector data');
}
#########################
{
my $diskLayoutObj = D64::Disk::Layout::Base->new();
my $save_error;
open FH, '>', \$save_error;
*BACKUP = *STDERR;
*STDERR = *FH;
my $saveOK = $diskLayoutObj->save();
close FH;
*STDERR = *BACKUP;
ok(! $saveOK, 'save - unable to save disk layout object created as an empty disk image');
}
#########################
{
my $diskLayoutObj = D64::Disk::Layout::Base->new();
my $saveOK = $diskLayoutObj->save_as('__temp__.d64');
ok($saveOK, 'save_ok - save disk layout data to file with specified name');
unlink('__temp__.d64');
}
#########################
{
my $diskLayoutObj = D64::Disk::Layout::Base->new();
my @sector_data = $diskLayoutObj->sector_data(1, 0);
my $sector_data = join '', map { sprintf "\$%02x", ord } @sector_data;
is($sector_data, '$00$00', 'sector_data - read physical sector data from disk image layout');
}
#########################
{
my $diskLayoutObj = D64::Disk::Layout::Base->new();
my $sector_data = join '', map { chr ord $_ } split //, 'xy';
my @sector_data = $diskLayoutObj->sector_data(1, 1, $sector_data);
$sector_data = join '', map { sprintf "\$%02x", ord } @sector_data;
is($sector_data, '$78$79', 'sector_data - write physical sector data into disk image layout');
}
#########################
{
my $diskLayoutObj = D64::Disk::Layout::Base->new();
my $sector_data = join '', map { chr ord $_ } split //, 'a';
my $write_error;
open FH, '>', \$write_error;
*BACKUP = *STDERR;
*STDERR = *FH;
my @sector_data = $diskLayoutObj->sector_data(1, 1, $sector_data);
close FH;
*STDERR = *BACKUP;
$sector_data = join '', map { sprintf "\$%02x", ord } @sector_data;
is($sector_data, '$61$00', 'sector_data - write physical sector data with less data than required');
}
#########################
{
my $diskLayoutObj = D64::Disk::Layout::Base->new();
my $sector_data = join '', map { chr ord $_ } split //, '123';
my $write_error;
open FH, '>', \$write_error;
*BACKUP = *STDERR;
*STDERR = *FH;
my @sector_data = $diskLayoutObj->sector_data(1, 1, $sector_data);
close FH;
*STDERR = *BACKUP;
$sector_data = join '', map { sprintf "\$%02x", ord } @sector_data;
is($sector_data, '$31$32', 'sector_data - write physical sector data with more data than required');
}
#########################
