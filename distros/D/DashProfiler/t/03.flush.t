use strict;

use Test::More qw(no_plan);
use Config;

use DBI qw(dbi_time);
use Symbol qw(gensym);
use List::Util qw(sum min max);
$|=1;

use DashProfiler::Core;

my $flush_count = 0;

our ($dp, $sampler1, @ary);

$dp = DashProfiler::Core->new("flush", {
    flush_interval => 1_000_000,
    flush_hook => sub {
        my ($self, $dbi_profile_name) = @_;
        ++$flush_count;
        is $self, $main::dp; # avoid closure
        is $dbi_profile_name, undef;
        $self->reset_profile_data;
        return (42);
    }
});
ok($dp);

$sampler1 = $dp->prepare("c1");
ok($sampler1);

$sampler1->("c2");

is $flush_count, 0;
@ary = $dp->flush;
is @ary, 1;
is $ary[0], 42;
is $flush_count, 1;

@ary = $dp->flush_if_due; # not due
is @ary, 0;
is $flush_count, 1;

# typically we'll get 3 flushes here, but we might only get 2

1;
