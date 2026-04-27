use strict;
use warnings;
use Test::More;
use POSIX ();
use Data::Stack::Shared;

# eventfd_set: attach an externally-created eventfd to an existing
# handle. Validates the "share one eventfd across multiple objects"
# pattern used by event-loop integrations.

eval { require Linux::FD::Event; 1 } or eval { require IO::Eventfd; 1 } or do {
    # Fall back to syscall directly via a Perl wrapper using POSIX
    # — but the simplest portable way is to derive an fd from a handle's
    # own eventfd, then dup() it for testing.
};

my $h = Data::Stack::Shared::Int->new(undef, 8);

# Create one eventfd via the module itself, then dup it to simulate
# an externally-created fd.
my $own_fd = $h->eventfd;
ok $own_fd >= 0, 'created internal eventfd';

my $dup_fd = POSIX::dup($own_fd);
ok defined $dup_fd && $dup_fd >= 0, 'POSIX::dup() succeeded';

# Now attach the dup as if it came from elsewhere. The previous internal
# fd should be closed (no leak) and fileno should return the new fd.
$h->eventfd_set($dup_fd);
is $h->fileno, $dup_fd, 'fileno reports the new fd';

# notify+consume should still work via the new fd
ok $h->notify, 'notify via attached fd';
my $val = $h->eventfd_consume;
ok defined($val) && $val == 1, 'eventfd_consume returns the count';

# Reattach with another dup — old one must be closed
my $dup_fd2 = POSIX::dup($dup_fd);
$h->eventfd_set($dup_fd2);
is $h->fileno, $dup_fd2, 'reattach updates fileno';

# Idempotent self-attach (same fd) is a no-op, no double-close
$h->eventfd_set($dup_fd2);
is $h->fileno, $dup_fd2, 'self-attach is no-op';

done_testing;
