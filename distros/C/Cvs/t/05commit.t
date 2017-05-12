use strict;
use Test;
use Cwd;
use Data::Dumper;

plan test => 5;

use Cvs;
ok(1);

my $cvs = new Cvs 'cvs-test';
ok($cvs);

open(FILE, "> $ENV{PWD}/cvs-test/test.txt")
	or die "Cannot open file `$ENV{PWD}/cvs-test/test.txt': $!";
print FILE "$$ Cvs commit test";
close FILE;

my $commit = $cvs->commit({ recursive => 0, message => 'test commit', }, 'test.txt');
ok($commit->success());

my $old = $commit->old_revision;
ok($old);
my $new = $commit->new_revision;
ok($new);
