use Test;
use Cwd;
use File::Path;

plan test => 4;

use Cvs;
ok(1);

my $cvsroot = cwd().'/cvs';
my $cvs = new Cvs('cvs-test', cvsroot => $cvsroot);
ok($cvs);

$cvs->checkout('test');

open(FILE, "> ./cvs-test/test.txt")
    or die "Cannot open file `./cvs-test/test.txt': $!";
print FILE "test\n";
close(FILE);

my $result = $cvs->release({force => 1, delete_after => 1});
ok(!-d "cvs-test");
ok($result->altered, 1);
