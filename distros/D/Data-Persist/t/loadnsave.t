#!perl -T

use strict;
use warnings;
use Test::More tests => 4;

use File::Temp;
use Test::MockObject::Universal;
use Data::Persist;

my $tmpfile = File::Temp::->new();
my $dp = Data::Persist::->new({
    'logger' => Test::MockObject::Universal::->new(),
    'filename' => $tmpfile->filename(),
});

my $in = {
    'scalar' => 'SCALAR',
    'array' => [qw(this is an array)],
    'hash' => {
        'this' => 'is',
        'an' => 'hash',
    },
};

ok($dp->write($in),'Data written');
my $out;
ok($out = $dp->read(),'Data read');
is_deeply($in,$out,'Written data is depply read data');
ok(!$dp->read($tmpfile->filename().'.NOTEXISTING'),'Undef returned on non existing file');

