#!/usr/bin/env perl
use strict;
use warnings;

=head1 DESCRIPTION

Test parsing of scalar types

=cut

use Test::More tests => 16;
use Symbol;

use Data::SExpression;

my $ds = Data::SExpression->new();

can_ok($ds, 'read');

is(scalar $ds->read('123'), 123, "Read int ok");
is(scalar $ds->read('-32'), -32, "Negative number ok");
is(scalar $ds->read('1.5'), 1.5, "Decimal ok");
is(scalar $ds->read('"Hello, World"'), "Hello, World", "Read string OK");
is(scalar $ds->read('"Hello, \"World\""'), "Hello, \"World\"", "Escaped backslashes OK");
is(scalar $ds->read('""'), "", "Empty string OK");
cmp_ok(scalar $ds->read('foobar'), "==", qualify_to_ref('foobar', 'main'), "Read symbol OK");
cmp_ok(scalar $ds->read('foo!'), "==", qualify_to_ref('foo!','main'), "Weird symbol OK");
is(scalar $ds->read(q{
;; A comment
7
}), 7, "Skipped comment");
is(scalar $ds->read('+'), qualify_to_ref('+'), "Read '+' symbol");
is(scalar $ds->read(q{
"foo
bar
"
}), "foo\nbar\n", "LF is OK");
is(scalar $ds->read(q{
"

"
}), "\n\n", "LF is OK (2)");
is(scalar $ds->read(q{
";; not comment"
}), ";; not comment", "comment in string OK");
is(scalar $ds->read(q{
"
; not comment
"
}), "\n; not comment\n", "comment in string OK (2)");

# Literal 0
is(scalar $ds->read(q{0}), 0);
