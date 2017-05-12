use Test::More tests=>4;

use_ok(qw(App::SimpleScan));
use_ok(qw(App::SimpleScan::Plugin::LinkCheck));

$app = new App::SimpleScan;

@output = qw(details == 1);
$string = "details == 1";

is_deeply [$app->_extract_quotelike_args($string)],
          \@output,
          "extracted properly";

@output = qw(details != 0);
$string = "details != 0";

is_deeply [$app->_extract_quotelike_args($string)],
          \@output,
          "extracted properly";
