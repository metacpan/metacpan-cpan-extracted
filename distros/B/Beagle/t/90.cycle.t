use Test::More;
use Beagle::Test;
eval { require Test::Memory::Cycle };
if ($@) {
    plan skip_all => 'no Test::Memory::Cycle';
    exit;
}

use Beagle::Handle;
Beagle::Test->init;
my $bh = Beagle::Handle->new();
Test::Memory::Cycle::memory_cycle_ok($bh, 'no memory cycle');
done_testing();
