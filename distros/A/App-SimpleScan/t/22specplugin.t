use strict;
use warnings;

use Test::More;
use lib 't';

BEGIN {
  $^D = 1;
}

use App::SimpleScan;
use App::SimpleScan::Plugin::TestExpand;

my $ss = App::SimpleScan->new;
ok $ss->can('plugins'), "plugins method available";
isa_ok [$ss->plugins()],"ARRAY", "returns right thing";
ok grep { /TestExpand/ } $ss->plugins, "test plugin there";

ok exists $ss->{Expander}, "plugin installed instance variable";
can_ok $ss, qw(expander);

done_testing;
