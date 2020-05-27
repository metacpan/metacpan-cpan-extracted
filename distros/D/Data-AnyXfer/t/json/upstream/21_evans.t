#! perl

# adapted from a test by Martin Evans

use strict;
use warnings;

use Data::AnyXfer::JSON;
use Test::More $] < 5.008 ? (skip_all => "5.6") : (tests => 1);

my $data = ["\x{53f0}\x{6240}\x{306e}\x{6d41}\x{3057}",
            "\x{6c60}\x{306e}\x{30ab}\x{30a8}\x{30eb}"];
my $js = Data::AnyXfer::JSON->new->encode ($data);
my $j = new Data::AnyXfer::JSON;
my $object = $j->incr_parse ($js);

die "no object" if !$object;

eval { $j->incr_text };

ok (!$@, "$@");

