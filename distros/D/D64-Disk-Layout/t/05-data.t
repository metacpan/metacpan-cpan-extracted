#########################
use D64::Disk::Layout;
use Test::Deep;
use Test::More tests => 2;
#########################
{
my $d64DiskLayoutObj = D64::Disk::Layout->new();
my $data = $d64DiskLayoutObj->data();
is($data, chr (0x00) x (683 * 256), 'data - fetch disk layout data as a scalar of 683 * 256 bytes');
}
#########################
{
my $d64DiskLayoutObj = D64::Disk::Layout->new();
my $data = $d64DiskLayoutObj->data();
substr $data, 0x00, 0x02, join '', map { chr } ( 0x11, 0x08 );
substr $data, 683 * 256 - 2, 0x02, join '', map { chr } ( 0xff, 0xff );
$d64DiskLayoutObj->data(data => $data);
is($data, chr (0x11) . chr (0x08) . chr (0x00) x (683 * 256 - 4) . chr (0xff) x 2, 'data - update disk layout providing 683 * 256 bytes of scalar data');
}
#########################
