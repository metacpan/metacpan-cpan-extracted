use strict;
use Test;
use Cwd;

plan test => 6;

use Cvs;
ok(1);

my $cvs = new Cvs 'cvs-test';
ok($cvs);

my $result = $cvs->tag("test_$$");
ok($result->tagged, 1);

my $status = $cvs->status('test.txt');
ok($status->tags, 3);

$result = $cvs->tag("test_$$", {delete => 1});
ok($result->untagged, 1);

$status = $cvs->status('test.txt');
ok($status->tags, 2);
