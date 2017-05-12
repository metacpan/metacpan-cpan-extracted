$|=1;
print "1..10\n";

use Coro qw(:prio cede async current);

print "ok 1\n";

use Carp; $SIG{__DIE__} = sub { Carp::cluck $@ };#d#

(async { print "ok 2\n"; cede; cede; cede; print "ok 3\n" })->prio(10);
(async { print "ok 4\n" })->prio(2);
(async { print "ok 5\n" })->prio(PRIO_HIGH);
(async { print "ok 6\n" });
(async { print "ok 7\n" })->prio(PRIO_LOW);
(async { print "ok 8\n" })->prio(PRIO_IDLE);
(async { print "ok 9\n"; cede; print "ok 11\n" })->prio(-500);

current->prio(-100);
cede;
print "ok 10\n";
