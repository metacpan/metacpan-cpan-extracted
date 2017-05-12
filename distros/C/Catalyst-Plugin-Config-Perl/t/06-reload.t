use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use FindBin;
use lib "$FindBin::Bin/app3/lib";
BEGIN {
    chdir('app3');
    $ENV{CATALYST_HOME} = "$FindBin::Bin/app3";
}

use Catalyst::Test 'TestApp';
TestApp->config->{'Plugin::Config::Perl'}{file} = 'conf/custom.conf';
TestApp->setup;

my $cfg = TestApp->cfg;

ok(!$cfg->{s} && !$cfg->{a} && !$cfg->{h} && !$cfg->{local_here});
is($cfg->{custom}, "hello");

delete TestApp->config_initial->{'Plugin::Config::Perl'};
TestApp->config_reload;

$cfg = TestApp->cfg;
is($cfg->{local_here}, 1);
is($cfg->{s}, 123);
cmp_deeply($cfg->{a}, [1,2,3]);
cmp_deeply($cfg->{h}, {a => 100, b => 2, c => 3});
is($cfg->{finalize_flag}, 1, 'finalize called');

done_testing();

1;
