use Test::More tests=>2;
use App::SimpleScan;
my $app = new App::SimpleScan;

my $text     = qq('I am quoted with an escape\\.');
my $dequoted = qq(I am quoted with an escape\\.);
my @match = $app->expand_backticked($text);
is @match, 1, 'Should only be one result';
is $match[0], $dequoted, 'matched it right';
