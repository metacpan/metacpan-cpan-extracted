use strict;
use Test;
use Cwd;

plan test => 11;

use Cvs;
ok(1);

my $cvs = new Cvs "cvs-test";
ok($cvs);

my $status = $cvs->status('test.txt');
ok($status->success);

my @tags = $status->tags();
ok(@tags, 2);
ok($tags[0], 'rs');
ok($status->tag_revision($tags[0]), '1.1.1');

ok(!$status->is_modified);
ok($status->is_up2date);

open(FILE, "> $ENV{PWD}/cvs-test/test.txt")
    or die "Cannot open file `$ENV{PWD}/cvs-test/test.txt': $!";
print FILE "test\n";
close(FILE);

$status = $cvs->status('test.txt', {multiple=>1})->first; # testing StatusList
ok($status);

ok($status->is_modified);
ok($status->is_up2date);
