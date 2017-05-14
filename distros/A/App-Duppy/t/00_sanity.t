use Test::More; 
use FindBin qw/$Bin/; 
use lib "$Bin/../lib";
use App::Duppy; 
use File::Which;
plan skip_all => 'Casperjs is not installed on your system' unless (which('casperjs'));

my $duppy = App::Duppy->new_with_options(test => ["$Bin/../t/fixtures/casper_ex.json"]);
isa_ok($duppy,'App::Duppy');
can_ok($duppy,'run_casper');
# we just check that we were able to call casperjs
like  $duppy->run_casper(1) , qr(Invalid test path), 'return value from casper_js is ok';

done_testing;
