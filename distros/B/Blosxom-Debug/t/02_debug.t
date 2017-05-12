
use Test::More tests => 3;

my $debug_level = 2;

my $prefix = '';
$prefix = 't/' if -d 't';

my $testplugin = "${prefix}testplugin";

die "cannot find testplugin $testplugin" 
  unless -f $testplugin;

# Setup a warn handler to count debug messages
my @warn = ();
BEGIN { $SIG{'__WARN__'} = sub { push @warn, $_[0] } }

$ENV{BLOSXOM_DEBUG_LEVEL} = $debug_level;
ok(require $testplugin, 'require testplugin ok');
ok(testplugin->start(), 'testplugin start() ok');
is(scalar @warn, $debug_level, "$debug_level debug messages found");

