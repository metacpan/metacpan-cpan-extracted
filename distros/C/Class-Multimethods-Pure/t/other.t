use Test::More tests => 3;

BEGIN { use_ok('Class::Multimethods::Pure') }

package A;
    sub new { bless {} => shift }
package B;
    use base 'A';
package C;
    use base 'A';
package D;
    use base 'B';
    use base 'C';

package main;

BEGIN {
    multi foo => qw<A A> => sub { "A A" };
    multi foo => qw<A B> => sub { "A B" };
    multi foo => qw<A C> => sub { "A C" };
    multi foo => qw<C C> => sub { "C C" };
}

is(foo(C->new, C->new), "C C", "ordering ambiguity");
ok(!eval { foo(A->new, D->new); 1 }, "A D should be ambiguous");


# vim: ft=perl :
