#########################
use strict;
use warnings;
use Test::More tests => 5;
#########################
{
BEGIN { use_ok('D64::Disk::Dir', qw(:all)) };
}
#########################
{
BEGIN { use_ok('D64::Disk::Dir::Entry', qw(:all)) };
}
#########################
{
BEGIN { use_ok('D64::Disk::Dir::Iterator', qw(:all)) };
}
#########################
{
my $d64DiskDirObj = D64::Disk::Dir->new();
is(ref $d64DiskDirObj, 'D64::Disk::Dir', 'new D64::Disk::Dir - create empty object without loading disk directory');
}
#########################
{
my $d64DiskDirObj = D64::Disk::Dir->new();
my $iter = D64::Disk::Dir::Iterator->new($d64DiskDirObj);
is(ref $iter, 'D64::Disk::Dir::Iterator', 'new D64::Disk::Dir::Iterator - create empty iterator without dir entries');
}
#########################
