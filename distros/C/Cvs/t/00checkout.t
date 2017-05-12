use strict;
use Test;
use Cwd;
use File::Path;

plan test => 3;

use Cvs;
ok(1);
my $cvsroot = cwd().'/cvs';

rmtree("cvs-test");
my $cvs = new Cvs
(
    'cvs-test',
    cvsroot => $cvsroot
);
ok($cvs);

my $rv = $cvs->checkout('test')
  or die $cvs->error();
ok($rv);
