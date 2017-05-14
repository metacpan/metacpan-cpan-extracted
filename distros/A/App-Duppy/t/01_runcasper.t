use Test::More;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use App::Duppy;
use File::Which;

plan skip_all => 'Casperjs is not installed on your system' unless (which('casperjs'));

my $duppy =
  App::Duppy->new_with_options(
    test => ["$Bin/../t/fixtures/casper_working_ex.json"] );
like $duppy->run_casper(1), qr/PASS 8 tests executed/,
  'And our casperjs tests pass like a boss';
done_testing;

