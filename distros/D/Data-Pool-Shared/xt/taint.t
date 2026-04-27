#!perl -T
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

# Taint mode: modules that accept user-provided path/name without
# untainting can silently corrupt. Verify that tainted input either
# works or is rejected cleanly.

use Data::Pool::Shared;

plan skip_all => "not running under -T" unless ${^TAINT};

# Env var value is always tainted under -T. memfd_create accepts a name
# (diagnostic-only — no security implication). Truncate to a safe length
# to stay within NAME_MAX.
my $tainted = substr($ENV{PATH} // "t", 0, 64);

my $p = Data::Pool::Shared->new_memfd($tainted, 4, 8);
ok $p, "new_memfd accepts tainted name";

my $s = $p->alloc;
$p->set($s, "\0" x 8);    # raw pool
ok defined $p->get($s), "ops work under taint mode";

done_testing;
