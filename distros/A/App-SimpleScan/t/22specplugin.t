use Test::More tests=>7;
use FindBin;
use lib "$FindBin::Bin";

use_ok qw(App::SimpleScan);
use_ok qw(App::SimpleScan::TestSpec);


my $ss = new App::SimpleScan;
ok $ss->can('plugins'), "plugins method available";
isa_ok [$ss->plugins()],"ARRAY", "returns right thing";
ok( (grep { /TestExpand/ } $ss->plugins), "test plugin there");

ok exists $ss->{Expander}, "plugin installed instance variable";
can_ok $ss, qw(expander);
