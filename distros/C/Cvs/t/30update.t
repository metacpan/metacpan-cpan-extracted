use strict;
use Test;
use Cwd;

plan test => 6;

use Cvs;
ok(1);

my $cvs = new Cvs 'cvs-test';
ok($cvs);

open(FILE, "> $ENV{PWD}/cvs-test/test.txt")
    or die "Cannot open file `$ENV{PWD}/cvs-test/test.txt': $!";
print FILE "test\n";
close(FILE);

my $result = $cvs->update();
my(@modified) = $result->modified();
ok(@modified, 1);
ok($modified[0] eq 'test.txt');

unlink("$ENV{PWD}/cvs-test/test.txt");
$result = $cvs->update();
ok($result->modified, 0);
ok($result->updated, 1);
