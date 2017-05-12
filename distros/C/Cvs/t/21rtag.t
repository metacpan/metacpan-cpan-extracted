use strict;
use Test;
use Cwd;

plan test => 6;

use Cvs;
ok(1);

my $cvs = new Cvs cvsroot => cwd().'/cvs'
  or die $Cvs::ERROR;
ok($cvs);

my $result = $cvs->rtag("test_$$", 'test');
ok($result->success);

my $cvs2 = new Cvs 'cvs-test';

my $status = $cvs2->status('test.txt');
ok($status->tags, 3);

$result = $cvs->rtag("test_$$", 'test', {delete => 1});
ok($result->success);

$status = $cvs2->status('test.txt');
ok($status->tags, 2);
