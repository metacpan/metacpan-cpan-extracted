use 5.014;

use strict;
use warnings;

use Test::More;

=name

do

=abstract

Minimalist Perl Development Framework

=synopsis

  #!perl

  use do;

  my $phrase = do('cast', 'hello world');

  $phrase->titlecase->say;

=description

The "do" module is focused on simplicity and productivity. It encapsulates the
L<Data::Object> framework features, is minimalist, and is designed for
scripting.

=cut

use_ok "do";

ok 1 and done_testing;
