use Test::More tests => 5;

BEGIN { use_ok('Class::Multimethods::Pure') }

package A;
  sub new { bless { } => ref $_[0] || $_[0] }
package B;
  use base 'A';
package C;
  use base 'A';
package D;
  use base 'C';

package main;

{
    multi foo => qw<A> => sub {
        "Generic";
    };

    multi foo => any(qw<B D>) => sub {
        "B|D";
    };

    multi foo => subtype(qw<A>, sub { 0 }) => sub {
        "Never!";
    };

    is(foo(A->new), "Generic");
    is(foo(B->new), "B|D");
    is(foo(C->new), "Generic");
    is(foo(D->new), "B|D");
}



# vim: ft=perl :
