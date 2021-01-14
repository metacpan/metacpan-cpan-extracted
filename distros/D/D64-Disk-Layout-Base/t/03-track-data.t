#########################
use File::Temp qw(tmpnam);
use Test::More tests => 5;
#########################
{
BEGIN { require_ok('D64::Disk::Layout::Base') };
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
my @track_data = $diskLayoutObj->track_data(1);
my $track_data = join '', map { sprintf "\$%02x", ord } @track_data;
is($track_data, '$00$00$00$00$00$00', 'track_data - read physical track data from disk image layout');
}
#########################
{
my $diskLayoutObj = D64::Disk::Layout::Base->new();
my $track_data = join '', map { chr ord $_ } split //, 'abcdef';
my @track_data = $diskLayoutObj->track_data(1, $track_data);
$track_data = join '', map { sprintf "\$%02x", ord } @track_data;
is($track_data, '$61$62$63$64$65$66', 'track_data - write physical track data into disk image layout');
}
#########################
{
my $diskLayoutObj = D64::Disk::Layout::Base->new();
my $track_data = join '', map { chr ord $_ } split //, 'abcd';
my $write_error;
open FH, '>', \$write_error;
*BACKUP = *STDERR;
*STDERR = *FH;
my @track_data = $diskLayoutObj->track_data(1, $track_data);
close FH;
*STDERR = *BACKUP;
$track_data = join '', map { sprintf "\$%02x", ord } @track_data;
is($track_data, '$61$62$63$64$00$00', 'track_data - write physical track data with less data than required');
}
#########################
{
my $diskLayoutObj = D64::Disk::Layout::Base->new();
my $track_data = join '', map { chr ord $_ } split //, '12345678';
my $write_error;
open FH, '>', \$write_error;
*BACKUP = *STDERR;
*STDERR = *FH;
my @track_data = $diskLayoutObj->track_data(1, $track_data);
close FH;
*STDERR = *BACKUP;
$track_data = join '', map { sprintf "\$%02x", ord } @track_data;
is($track_data, '$31$32$33$34$35$36', 'track_data - write physical track data with more data than required');
}
#########################
