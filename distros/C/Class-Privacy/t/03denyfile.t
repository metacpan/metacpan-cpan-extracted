BEGIN { use lib 't'; print "1..1\n" }
use P;
my $p = P->new;
package P; # Try cheating.
eval { $p->{q} = 42 };
print $@ =~ /Cannot dereference 'P' object/ ? "ok 1\n" : "not ok 1\n";
