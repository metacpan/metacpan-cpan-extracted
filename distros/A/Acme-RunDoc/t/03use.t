use Test::More tests => 1;
use Acme::RunDoc;

use lib "t";
use lib ".";

Acme::RunDoc->use('Local::TestModule');
my $pass = Local::TestModule->can('PASS');
ok($pass && $pass->());
