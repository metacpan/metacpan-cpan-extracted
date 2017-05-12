use strict;
use warnings;

use Test::More tests => 6;
use Test::MockObject;

use IO::Handle;

use Archive::Ar::Libarchive;

my $mock = new Test::MockObject;
my $ar;

$mock->set_false('read');
local *Archive::Ar::Libarchive::read;
*Archive::Ar::Libarchive::read = sub { return $mock->read(); };

$ar = Archive::Ar::Libarchive->new();
isa_ok $ar, 'Archive::Ar::Libarchive', 'object';
ok !$mock->called('read'), 'read not called if new with no options';

$ar = Archive::Ar::Libarchive->new('myfilename');
is $ar, undef, 'new fails if read fails';
ok $mock->called('read'), 'read called if new with filename';
$mock->clear();

$ar = new Archive::Ar::Libarchive(*STDIN);
ok $mock->called('read'), 'read called if new with file glob';
$mock->clear();

$ar = new Archive::Ar::Libarchive(IO::Handle->new());
ok $mock->called('read'), 'read called if new with file handle';
$mock->clear();
