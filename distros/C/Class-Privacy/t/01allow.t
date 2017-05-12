BEGIN { use lib 't'; print "1..3\n" }
use P;
my $p = P->new;
print "ok 1\n";
$p->set('q', 42);
print "ok 2\n";
print "ok 3\n" if $p->get('q') == 42;
