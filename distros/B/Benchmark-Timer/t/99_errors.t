# ========================================================================
# t/99_errors.t - test fatal and warn error cases
# Andrew Ho (andrew@zeuscat.com)
#
# In this test we exercise fatal conditions and check that they really
# do die with an error status.
#
# This script is intended to be run as a target of Test::Harness.
#
# Last modified April 20, 2001
# ========================================================================

use strict;
use Test::More tests => 6;
use Benchmark::Timer;

# ------------------------------------------------------------------------
# Check fatal condition where you call stop() but start() has NEVER run

eval {
    my $t = Benchmark::Timer->new;
    $t->stop;
};

# 1
like($@, qr/must call/, 'Must call start first');

# ------------------------------------------------------------------------
# Check fatal out of sync condition

eval {
    my $t = Benchmark::Timer->new;
    $t->start('tag');
    $t->stop;
    $t->stop;
};

# 2
like($@, qr/out of sync/, 'Out of sync');

# ------------------------------------------------------------------------
# Check fatal bad skip argument handling

eval { my $t = Benchmark::Timer->new( skip => undef ) };

# 3
like($@, qr/argument skip/, 'Argument skip 1');

eval { my $t = Benchmark::Timer->new( skip => 'foo' ) };

# 4
like($@, qr/argument skip/, 'Argument skip 2');

eval { my $t = Benchmark::Timer->new( skip => -1 ) };

# 5
like($@, qr/argument skip/, 'Argument skip 3');

# ------------------------------------------------------------------------
# Check warning on unrecognized arguments

use vars qw($last_warning);
undef $last_warning;
{
    local $SIG{__WARN__} = sub { $last_warning = shift };
    my $weird_arg = '__this_is_not_a_valid_argument__';
    my $t = Benchmark::Timer->new( $weird_arg => undef );

    # 6
    like($last_warning, qr/skipping unknown/, 'Invalid argument');
}


# ========================================================================
__END__
