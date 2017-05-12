use Test::More tests=>19;
use Test::Exception;

use App::SimpleScan::Substitution::Line;

my $line_obj;
dies_ok { $line_obj = new App::SimpleScan::Substitution::Line } "No argument";
like $@, qr/No line supplied/, "error msg right";

$line_obj = new App::SimpleScan::Substitution::Line "this is a <test> <line>";
isa_ok $line_obj, "App::SimpleScan::Substitution::Line";

is_deeply [$line_obj->fixed()], [], "nothing fixed by default";

dies_ok { $line_obj->fix() } "die if no key for fix";
like $@, qr/No variable supplied/, "right message";

dies_ok { $line_obj->fix('bar') } "die if no value for fix";
like $@, qr/No value supplied/, "right message";

$line_obj->fix(line=>'zrog');
is_deeply [$line_obj->fixed()], [qw(line zrog)], "got fixed var";
is $line_obj->fixed('line'), 'zrog', "got fixed value";

$line_obj->fix('test' => 'quux');
$line_obj->unfix('line');
is_deeply [$line_obj->fixed], [qw(test quux)], 'unfixed properly';

my $clone = $line_obj->clone();
isa_ok $clone, "App::SimpleScan::Substitution::Line";
is $clone->line, $line_obj->line, "line cloned";
is_deeply [$clone->fixed], [$line_obj->fixed], 'fixed cloned';
is "$clone", "$line_obj", "stringified value cloned";

$line_obj->no_fixed();
is_deeply [$line_obj->fixed], [], 'no_fix deletes all';

is $line_obj->line(), "this is a <test> <line>", "line() works";
is "$line_obj", "this is a <test> <line>", "quote overload works";

$line_obj->line('greeble zorch');
is "$line_obj", "greeble zorch", "line() updates";

