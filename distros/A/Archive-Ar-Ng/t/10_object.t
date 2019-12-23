use strict;
use warnings;

use Test::More tests => 6;
use Test::MockObject;

use IO::Handle;

use Archive::Ar;

my $mock = new Test::MockObject;
my $ar;

$mock->set_false('read');
local *Archive::Ar::read;
*Archive::Ar::read = sub { return $mock->read(); };

$ar = Archive::Ar->new();
isa_ok $ar, 'Archive::Ar', 'object';
ok !$mock->called('read'), 'read not called if new with no options';

$ar = Archive::Ar->new('myfilename');
is $ar, undef, 'new fails if read fails';
ok $mock->called('read'), 'read called if new with filename';
$mock->clear();

$ar = new Archive::Ar(*STDIN);
ok $mock->called('read'), 'read called if new with file glob';
$mock->clear();

$ar = new Archive::Ar(IO::Handle->new());
ok $mock->called('read'), 'read called if new with file handle';
$mock->clear();
