#!/usr/bin/env perl
use strict;
use warnings;
use rlib '../../lib';
use blib;

# These tests just minial operation and are run first so
# can fail, and is especially useful if run in a way were we
# automatically stop early since some the remaning tests are long
# and can be extensive.
# We test that we can load B::DeparseTree and don't break
# conventions that CPAN modules already use.

use Test::More;
note( "Testing B::DeparseTree $B::DeparseTree::VERSION" );

BEGIN {
use_ok( 'B::DeparseTree' );
}

ok(defined($B::DeparseTree::VERSION),
   "\$B::DeparseTree::VERSION number is set");


package B::DeparseTree::NameMangler {
    our @ISA = "B::DeparseTree";
    sub padname { SUPER::padname{@_} . '_groovy' }
}

my $nm = 'B::DeparseTree::NameMangler'->new;

my $info = $nm->coderef2text(sub { my($a, $b, $c) });
like  $info,
      qr/\$a_groovy, \$b_groovy, \$c_groovy/,
     'overriding padname works for renaming lexicals';

done_testing();
