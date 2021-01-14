#########################
use D64::Disk::Layout;
use Test::Deep;
use Test::More tests => 4;
#########################
{
my $d64DiskLayoutObj = D64::Disk::Layout->new();
my @sector_layouts = $d64DiskLayoutObj->sectors();
ok(@sector_layouts == 683, 'sectors - fetch disk layout data as an array of 683 objects');
ok(grep { ref $_ ne 'D64::Disk::Layout::Sector' } @sector_layouts == 0, 'sectors - fetch disk layout data as a flattened array of sector objects');
}
#########################
{
my $d64DiskLayoutObj = D64::Disk::Layout->new();
my @sector_layouts = $d64DiskLayoutObj->sectors();
$_->ts_link(0x11, 0x08) for @sector_layouts;
$d64DiskLayoutObj->sectors(sectors => \@sector_layouts);
my @sector_data = ($d64DiskLayoutObj->sector_data(1, 0), $d64DiskLayoutObj->sector_data(35, 16));
my $sector_data = join '', map { sprintf "\$%02x", ord } @sector_data;
is($sector_data, ('$11$08' . '$00' x 254) x 2, 'sectors - update disk layout given an array of 683 sector objects');
}
#########################
{
my $d64DiskLayoutObj = D64::Disk::Layout->new();
my @sector_layouts = $d64DiskLayoutObj->sectors();
$sector_layouts[0]->ts_link(0x11, 0x08);
$d64DiskLayoutObj->sectors(sectors => [ @sector_layouts[0 .. 20] ]);
my @sector_data = ($d64DiskLayoutObj->sector_data(1, 0), $d64DiskLayoutObj->sector_data(35, 16));
my $sector_data = join '', map { sprintf "\$%02x", ord } @sector_data;
is($sector_data, '$11$08' . '$00' x 254 . '$00' x 256, 'update disk layout given an array of arbitrary sector objects');
}
#########################
