use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use FindBin;
use lib "$FindBin::Bin/app1/lib";
BEGIN {
    chdir('app1');
    $ENV{CATALYST_HOME} = "$FindBin::Bin/app1";
}

use Catalyst::Test 'TestApp';
TestApp->setup;

my $cfg = TestApp->cfg;

is(ref $cfg->{home}, 'Path::Class::Dir', 'home exists');
is(ref $cfg->{root}, 'Path::Class::Dir', 'root exists');
is($cfg->{s}, 1, 'config processed');
cmp_deeply($cfg->{a}, [1,2,3], 'config processed');
cmp_deeply($cfg->{h}, {a => 1, b => 2, c => 3}, 'config processed');
is($cfg->{finalize_flag}, 1, 'finalize called');
is($cfg->{dev}, 1);
is(TestApp->dev, 1);

done_testing();

1;
