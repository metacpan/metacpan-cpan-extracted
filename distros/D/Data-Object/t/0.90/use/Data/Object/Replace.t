use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Replace

=abstract

Data-Object Replace Class

=synopsis

  use Data::Object::Replace;

  my $result = Data::Object::Replace->new([
    $regexp,
    $altered_string,
    $count,
    $last_match_end,
    $last_match_start,
    $named_captures,
    $initial_string
  ]);

=description

Data::Object::Replace provides routines for introspecting the results of an
operation involving a regular expressions. These methods work on data whose
shape conforms to the tuple defined in the synopsis.

=cut

use_ok "Data::Object::Replace";

ok 1 and done_testing;
