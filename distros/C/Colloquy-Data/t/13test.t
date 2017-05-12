print "ok\n";
chdir('t') if -d 't';

use strict;
use Test::More skip_all => 'no test data for v1.3 yet';
use lib qw(./lib ../lib);

#use Colloquy::Data qw(:all);
#my $datadir = "data1.3";
#my ($lists) = lists($datadir);
#my ($users) = users($datadir);


