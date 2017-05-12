
use Cwd;
use File::Basename;

use Test::More tests => 15;
require_ok('Blosxom::Include');

my $test = '';
$test = "t/" if -d "t/plugins";
die "missing plugins dir '${test}plugins'" unless -d "${test}plugins";

$ENV{BLOSXOM_CONFIG_FILE} = getcwd . "/${test}config/blosxom.conf";

ok(eval { require "${test}plugins/testplugin" }, "require testplugin ok");
is($testplugin::package, 'package1', "\$testplugin::package is $testplugin::package");
is(testplugin::get_lexical(), 'lexical1', "\$lexical is " . testplugin::get_lexical());

ok(eval { require "${test}plugins/testplugin3" }, "require testplugin3 ok");
is($testplugin3::package, 'package3', "\$testplugin3::package is $testplugin3::package");
is(testplugin3::get_lexical(), 'lexical3', "\$lexical3 is " . testplugin::get_lexical());

# Handle lexical mask warning
my $my_warning = 0;
local $SIG{'__WARN__'} = sub { 
  if ($_[0] =~ m/"my" variable \$lexical masks earlier declaration/) {
    $my_warning = 1;
  } else {
    warn $_[0];
  }
};

ok(eval { require "${test}plugins/testplugin2" }, "require testplugin2 ok");
is($testplugin2::package, 'package2', "\$testplugin2::package is $testplugin2::package");
is(testplugin2::get_lexical(), 'lexical2', "\$lexical is " . testplugin2::get_lexical());
is($my_warning, 1, "'my' variable mask warning issued");

ok(eval { require "${test}plugins/testplugin4" }, "require testplugin4 ok");
is($testplugin4::package, 'package4', "\$testplugin4::package is $testplugin4::package");
is(testplugin4::get_lexical(), 'lexical4', "\$lexical is " . testplugin4::get_lexical());
is($my_warning, 1, "'my' variable mask warning issued");

