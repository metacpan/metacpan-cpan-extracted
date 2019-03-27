use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Search

=abstract

Data-Object Regex Class

=synopsis

  use Data::Object::Search;

  my $result = Data::Object::Search->new([
    $regexp,
    $altered_string,
    $count,
    $last_match_end,
    $last_match_start,
    $named_captures,
    $initial_string
  ]);

=description

Data::Object::Search provides routines for introspecting the results of an
operation involving a regular expressions. These methods work on data whose
shape conforms to the tuple defined in the synopsis.

=cut

use_ok "Data::Object::Search";

ok 1 and done_testing;
