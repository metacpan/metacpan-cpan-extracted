use strict;

use lib  ('./blib','../blib', './lib', '../lib');

eval {
    require Test::More;
};
if ($@) {
    $|++;
    print "1..0 # Skipped: Test::More required for testing distribution\n";
    exit;
}
eval {
    require Test::Distribution;
};
if ($@) {
    Test::More::plan( skip_all => 'Test::Distribution not installed' );
}
Test::Distribution->import('only' => [qw(prereq description)]);
