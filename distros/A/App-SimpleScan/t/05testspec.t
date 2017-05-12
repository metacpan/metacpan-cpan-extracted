use Test::More tests=>10;
use Test::Differences;

BEGIN {
  use_ok(qw(App::SimpleScan));
  use_ok(qw(App::SimpleScan::TestSpec));
}

can_ok("App::SimpleScan::TestSpec", qw(uri delim kind regex comment new as_tests app parse metaquote));

my $app = new App::SimpleScan;
App::SimpleScan::TestSpec->app($app);

my $raw = "http://search.yahoo.com/ /yahoo/ Y No comment";
my $spec = new App::SimpleScan::TestSpec($raw);
is $spec->app, $app, "Specs can find the app";
is $spec->raw, $raw, "Raw spec available";

$spec->parse;

$spec->uri("http://search.yahoo.com");
$spec->delim('/');
$spec->comment('No comment');
$spec->regex("yahoo");
$spec->flags("s");

is ($spec->uri, "http://search.yahoo.com", "uri accessor");
is ($spec->delim, "/", "delim accessor");
is ($spec->comment, "No comment", "comment accessor");
is ($spec->regex, "yahoo", "regex accessor");
is ($spec->flags, "s", "flags accessor");
