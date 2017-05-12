#########################
use Test::More tests => 9;
#########################
{
unlink('__temp__.d64');
}
#########################
{
package D64::MyLayout;
use base qw(D64::Disk::Layout::Base);
our $bytes_per_sector = 4;
our @sectors_per_track = (3, 3, 2, 2, 2);
sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    bless $self, $class;
}
}
#########################
{
my $diskLayoutObj = D64::MyLayout->new();
is(ref $diskLayoutObj, 'D64::MyLayout', 'new - create unformatted disk image layout derived from base class');
}
#########################
{
my $diskLayoutObj = D64::MyLayout->new();
my $saveOK = $diskLayoutObj->save_as('__temp__.d64');
$diskLayoutObj = D64::MyLayout->new('__temp__.d64');
my $sector_count = '';
my $bytes_count = 0;
my $num_tracks = $diskLayoutObj->num_tracks();
for (my $track = 1; $track <= $num_tracks; $track++) {
    my $num_sectors = $diskLayoutObj->num_sectors($track);
    $sector_count .= $num_sectors;
    for (my $sector = 0; $sector < $num_sectors; $sector++) {
        my @sector_data = $diskLayoutObj->sector_data($track, $sector);
        $bytes_count += scalar @sector_data;
    }
}
is("$sector_count/$bytes_count", '33222/48', 'new - read disk image data from file');
unlink('__temp__.d64');
}
#########################
{
my $diskLayoutObj = D64::MyLayout->new();
my $num_tracks = $diskLayoutObj->num_tracks();
cmp_ok($num_tracks, '==', 5, 'num_tracks - get number of tracks available for use');
}
#########################
{
my $diskLayoutObj = D64::MyLayout->new();
my $num_sectors = $diskLayoutObj->num_sectors(2);
cmp_ok($num_sectors, '==', 3, 'num_sectors - get number of sectors per track information');
}
#########################
{
my $diskLayoutObj = D64::MyLayout->new();
my @sector_data = $diskLayoutObj->sector_data(1, 0);
my $sector_data = join '', map { sprintf "\$%02x", ord } @sector_data;
is($sector_data, '$00$00$00$00', 'sector_data - read physical sector data from disk image into array');
}
#########################
{
my $diskLayoutObj = D64::MyLayout->new();
my $sector_data = $diskLayoutObj->sector_data(1, 0);
$sector_data =~ s/\x00/\$00/g;
is($sector_data, '$00$00$00$00', 'sector_data - read physical sector data from disk image into scalar');
}
#########################
{
my $diskLayoutObj = D64::MyLayout->new();
my $sector_data = join '', map { chr ord $_ } split //, 'wxyz';
my @sector_data = $diskLayoutObj->sector_data(1, 1, $sector_data);
$sector_data = join '', map { sprintf "\$%02x", ord } @sector_data;
is($sector_data, '$77$78$79$7a', 'sector_data - write physical sector data into disk image from scalar');
}
#########################
{
my $diskLayoutObj = D64::MyLayout->new();
my @sector_data = map { chr ord $_ } split //, '1234';
my $sector_data = $diskLayoutObj->sector_data(1, 1, @sector_data);
$sector_data =~ s/(.)/sprintf "\$%02x", ord $1/eg;
is($sector_data, '$31$32$33$34', 'sector_data - write physical sector data into disk image from array');
}
#########################
{
my $diskLayoutObj = D64::MyLayout->new();
my $filename = '__temp__.d64';
my $saveOK = $diskLayoutObj->save_as($filename);
my $mtime_create = (stat($filename))[9];
sleep 2;
$diskLayoutObj = D64::MyLayout->new($filename);
$saveOK = $diskLayoutObj->save();
my $mtime_modify = (stat($filename))[9];
cmp_ok($mtime_create, '!=', $mtime_modify, 'save - overwrite file loaded during object instance initialization');
unlink($filename);
}
#########################
