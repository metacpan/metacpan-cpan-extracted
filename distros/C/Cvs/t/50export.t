use strict;
use Test;
use Cwd;
use File::Path;

plan test => 3;

use Cvs;
ok(1);
my $cvsroot = cwd().'/cvs';

my $cvs = new Cvs
(
    'cvs-test.export',
    cvsroot => $cvsroot
);
ok($cvs);

my $rv = $cvs->export('test', {date=>'now'})
  or die $cvs->error();
rmtree("cvs-test.export");
ok($rv);
