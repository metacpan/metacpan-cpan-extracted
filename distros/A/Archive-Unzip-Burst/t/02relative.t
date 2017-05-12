use Test::More tests => 5;
use Cwd;
BEGIN { use_ok('Archive::Unzip::Burst') };

chdir("t");
require 'testrun.pl';
testrun("foo.zip");
