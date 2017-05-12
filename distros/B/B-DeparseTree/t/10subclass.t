#!./perl
use rlib '../lib';

# These tests are not necessarily normative, but until such time as we
# publicise an API for subclassing B::Deparse they can prevent us from
# gratuitously breaking conventions that CPAN modules already use.

use Test::More tests => 1;

use B::DeparseTree;

package B::DeparseTree::NameMangler {
  @ISA = "B::DeparseTree";
  sub padname { SUPER::padname{@_} . '_groovy' }
}

my $nm = 'B::DeparseTree::NameMangler'->new;

like  $nm->coderef2text(sub { my($a, $b, $c) }),
      qr/\$a_groovy, \$b_groovy, \$c_groovy/,
     'overriding padname works for renaming lexicals';
