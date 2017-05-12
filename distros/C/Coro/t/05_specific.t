$|=1;
print "1..8\n";

use Coro::Specific;

# first test without coro

print "ok 1\n";

my $s1 = new Coro::Specific;
my $s2 = new Coro::Specific;

$$s1 = 5;
$$s2 = $$s1+5;

print (($$s2 == 10 ? "" : "not "), "ok 2\n");
print (($$s1 == $$s2-5 ? "" : "not "), "ok 3\n");

# now let coro inherit the first task

require Coro;

Coro::async(sub {
   print ((!defined $$s2 ? "" : "not "), "ok 5\n");
   $$s1 = 6;
   $$s2 = $$s1 + 6;
   $$s2++;
   Coro::cede();
   print (($$s2 == 13 ? "" : "not "), "ok 7\n");
});

print (($$s2 == 10 ? "" : "not "), "ok 4\n");
&Coro::cede;
print (($$s2 == 10 ? "" : "not "), "ok 6\n");
&Coro::cede;
print (($$s2 == 10 ? "" : "not "), "ok 8\n");


