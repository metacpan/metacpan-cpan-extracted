use strict;
use warnings;
use Test::More;

eval "use Test::Pod::Coverage 1.04";
plan skip_all => 'Test::Pod::Coverage 1.04 required' if $@;
plan skip_all => 'set TEST_POD to enable this test' unless $ENV{TEST_POD};

# Internal parameter accessors and object slot accessors in Decode::Base
# are installed dynamically and are not part of the public API.
my $decode_base_private = qr/^(
    NPT|NP|NT|NC|PBIT|TBIT|CBIT|
    PT_TABLE_BIT|PT_TABLE_SIZE|
    C_TABLE_BIT|C_TABLE_SIZE|
    DICSIZE|MAXMATCH|THRESHOLD|
    pt|c|tree|bit|import
)$/x;

all_pod_coverage_ok({
    also_private => [ $decode_base_private ],
});
