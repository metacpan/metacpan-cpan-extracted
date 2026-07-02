use strict; use warnings; use Test::More;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
plan skip_all => 'Linux required' unless $^O eq 'linux';
use Fcntl qw(F_GETFD FD_CLOEXEC);

use Data::SpatialHash::Shared;

# The memfd and eventfd are CLOEXEC, so they do not leak into exec'd children.

my $s  = Data::SpatialHash::Shared->new_memfd('cloexec-test', 100, 0, 1.0);
my $fd = $s->memfd;
$s->eventfd;
my $efd = $s->fileno;

open my $mfh, '+<&=', $fd  or die "fdopen memfd: $!";
open my $efh, '+<&=', $efd or die "fdopen eventfd: $!";
ok fcntl($mfh, F_GETFD, 0) & FD_CLOEXEC, 'memfd fd is CLOEXEC';
ok fcntl($efh, F_GETFD, 0) & FD_CLOEXEC, 'eventfd fd is CLOEXEC';

# Proof it does not leak: an exec'd child cannot open the fd number (it was
# closed on exec). Child exits 1 if it could open the fd, 0 if it could not.
my $out = qx{$^X -e 'exit(open(my \$f, "+<&=$fd") ? 1 : 0)'};
is $? >> 8, 0, "memfd (fd $fd) is closed in an exec'd child -- no fd leak";

done_testing;
