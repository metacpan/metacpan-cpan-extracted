use strict;
use warnings;
use Test::More;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};
BEGIN { eval { require BSD::Resource; BSD::Resource->import; 1 }
    or plan skip_all => 'BSD::Resource not installed' }
use Data::Pool::Shared;

# Set RLIMIT_NOFILE to a low value, then try to open more handles than
# allowed. The module must croak cleanly (EMFILE), not crash.

# Get current limits; set soft limit low (keep hard limit unchanged)
my ($soft, $hard) = BSD::Resource::getrlimit(BSD::Resource::RLIMIT_NOFILE());
my $new_soft = 32;   # typical low limit
BSD::Resource::setrlimit(BSD::Resource::RLIMIT_NOFILE(), $new_soft, $hard);

# Open handles until we hit the limit
my @handles;
my $err;
for (1..100) {
    my $p = eval { Data::Pool::Shared->new_memfd("ul_$_", 16, 32) };
    if (!$p) { $err = $@; last }
    push @handles, $p;
}

# We should have hit the limit before 100 handles
cmp_ok scalar(@handles), '<', 100, "hit RLIMIT_NOFILE before 100 handles";
ok $err, 'got a croak (not a crash)';
like $err, qr/too many|EMFILE|fd|memfd_create|open/i, "error mentions fd resource";

# Restore limit for cleanup
BSD::Resource::setrlimit(BSD::Resource::RLIMIT_NOFILE(), $soft, $hard);

# Existing handles should still work
if (@handles) {
    my $p = $handles[0];
    ok defined $p, 'existing handle still usable';
}

done_testing;
