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

done_testing();

1;
