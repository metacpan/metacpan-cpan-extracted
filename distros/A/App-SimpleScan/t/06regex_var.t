use Test::More tests=>20;

BEGIN {
  use_ok(qw(App::SimpleScan));
  use_ok(qw( App::SimpleScan::TestSpec));
}
my $app = new App::SimpleScan;
App::SimpleScan::TestSpec->app($app);

my $spec;

$spec = 
  new App::SimpleScan::TestSpec("http://search.yahoo.com/ /yahoo/ Y No comment");

$spec->parse;
is $spec->regex, "yahoo", "right regex data";
is $spec->delim, "/", "proper delimiter";
is $spec->uri, "http://search.yahoo.com/", "right URI";
is $spec->kind, "Y", "right kind";
is $spec->comment, "No comment", "right comment";
ok !$spec->metaquote, "right metaquoting";

$spec = 
  new App::SimpleScan::TestSpec("http://search.yahoo.com/ m|yahoo</b>| TY /No comment/");

$spec->parse;
is $spec->regex, "yahoo</b>", "right regex data";
is $spec->delim, "|", "proper delimiter";
is $spec->uri, "http://search.yahoo.com/", "right URI";
is $spec->kind, "TY", "right kind";
is $spec->comment, "/No comment/", "right comment";
ok !$spec->metaquote, "right metaquoting";

$spec = 
  new App::SimpleScan::TestSpec("http://search.yahoo.com/ m|yahoo</b>| TY");

$spec->parse;
is $spec->regex, "yahoo</b>", "right regex data";
is $spec->delim, "|", "proper delimiter";
is $spec->uri, "http://search.yahoo.com/", "right URI";
is $spec->kind, "TY", "right kind";
is $spec->comment, "", "right comment";
ok !$spec->metaquote, "right metaquoting";



