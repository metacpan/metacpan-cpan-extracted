BEGIN { use lib 't'; print "1..4\n" }
use Q;
print "ok 1\n";
my $q = Q->new;
$q->set('r', 42);
print "ok 2\n";
print "ok 3\n" if $q->get('r') == 42;
eval { $q->{r} = 42 };
print $@ =~ /Cannot dereference 'P' object/ ? "ok 4\n" : "not ok 4\n";
