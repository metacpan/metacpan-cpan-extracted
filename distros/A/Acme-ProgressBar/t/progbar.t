use Test::More tests => 2;

use Acme::ProgressBar;
ok(progress { 1; },       "do-nothing progress bar");

# my $time = time;
ok(progress { sleep 1; } , "sleep(1) progress bar");
# my $taken = time - $time;
# ok($taken >= 10, "took at least ten seconds to run");
# ok($taken <= 20, "didn't run over ridiculously");
