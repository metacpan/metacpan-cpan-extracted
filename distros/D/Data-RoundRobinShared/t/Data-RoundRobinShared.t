use Test::More tests => 4;

my @data = qw/one two three four five/;

use_ok('Data::RoundRobinShared');
require_ok('Data::RoundRobinShared');

our $rs = new Data::RoundRobinShared( key => 'Testm', data => [@data], simple_check => 1 );

ok('one' eq $rs->next,'->next Test');
ok('two' eq "$rs",'stringify Test');

$rs->remove;
