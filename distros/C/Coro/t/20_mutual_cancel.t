$|=1;
print "1..10\n";

# when two coros cancel each other mutually,
# the slf function currently being executed needs to
# be cleaned up, otherwise the next slf call in the cleanup code
# will simply resume the previous call.
# in addition, mutual cancellation must be specially handled
# as currently, we sometimes cancel coros from another coro
# which must not be interrupted (see slf_init_cancel).

use Coro;

print "ok 1\n";

my ($a, $b);

sub xyz::DESTROY {
   print "ok 7\n";
   $b->cancel;
   print "ok 8\n";
}

$b = async {
   print "ok 3\n";
   cede;
   print "ok 6\n";
   $a->cancel;
   print "not ok 7\n";
};

$a = async {
   print "ok 4\n";
   my $x = bless \my $dummy, "xyz";
   cede;
   print "not ok 5\n";
};

print "ok 2\n";
cede;
print "ok 5\n";
cede;
print "ok 9\n";
cede;
print "ok 10\n";

