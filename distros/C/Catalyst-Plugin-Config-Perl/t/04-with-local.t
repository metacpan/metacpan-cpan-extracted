use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use FindBin;
use lib "$FindBin::Bin/app2/lib";
BEGIN {
    chdir('app2');
    $ENV{CATALYST_HOME} = "$FindBin::Bin/app2";
}

use Catalyst::Test 'TestApp';
TestApp->setup;

my $cfg = TestApp->cfg;

is($cfg->{local_here}, 1);
is($cfg->{s}, 123);
cmp_deeply($cfg->{a}, [1,2,3]);
cmp_deeply($cfg->{h}, {a => 100, b => 2, c => 3});
is($cfg->{dev}, undef);
is(TestApp->dev, undef);

done_testing();

1;
