#!perl
# 004-goal.t: test Data::Hopen::G::Goal
use rlib 'lib';
use HopenTest;
use Data::Hopen ':all';

use Capture::Tiny qw(capture_stderr);
use Test::Fatal;

use Data::Hopen::G::Goal;
use Data::Hopen::Scope::Hash;

# Creation
my $e = Data::Hopen::G::Goal->new(name=>'foo');
isa_ok($e, 'Data::Hopen::G::Goal');
is($e->name, 'foo', 'Name was set by constructor');
$e->name('bar');
is($e->name, 'bar', 'Name was set by accessor');

# Logging
my ($result, $logtext);
$VERBOSE=1;

$e->should_output(false);
$logtext = capture_stderr { $result = $e->run };
like $logtext, qr/without outputs/, '_run !should_output log text';
is_deeply $result, {}, '!should_output -> no outputs';

$e->should_output(true);
$logtext = capture_stderr { $result = $e->run };
like $logtext, qr/with outputs/, '_run should_output log text';

$VERBOSE=0;

# Running
my $scope = Data::Hopen::Scope::Hash->new->put(foo=>42);

$e->should_output(false);
$result = $e->run($scope);
is_deeply $result, {}, '!should_output with inputs -> no outputs';

$e->should_output(true);
$result = $e->run($scope);
is_deeply $result, {foo=>42}, 'should_output with inputs -> passthrough';

# Error conditions
like exception { Data::Hopen::G::Goal->new; },
    qr/Goals must have names/, 'anonymous goal throws';

done_testing();
