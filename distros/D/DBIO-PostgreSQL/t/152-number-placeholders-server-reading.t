use strict;
use warnings;

use Test::More;

use DBIO::PostgreSQL::Util qw(number_placeholders);

# The POD of DBIO::PostgreSQL::Util ("Where DBD::Pg reads less than the
# server") says number_placeholders reads these four forms as the server does,
# while DBD::Pg's own scanner does not (karr k121). This file holds the half
# that is ours: the numbering follows the server. The DBD::Pg half cannot be
# pinned offline (DBD::Pg counts only on a live prepare). It records the
# present reading; it does not test a fix, there is none to make here.

my @cases = (
  [ 'nested comment is one comment',
    q{SELECT /* a /* b ? */ c ? */ ?::int},
    q{SELECT /* a /* b ? */ c ? */ $1::int} ],
  [ 'lower case e-string: backslash-quote does not end it',
    q{SELECT e'it\'s ?', ?::int},
    q{SELECT e'it\'s ?', $1::int} ],
  [ 'carriage return ends a line comment',
    "SELECT 1 -- a ?\r, ?::int",
    "SELECT 1 -- a ?\r, \$1::int" ],
  [ 'a dollar inside an identifier opens no dollar quote',
    q{SELECT 1 AS a$b$, ?::int, 2 AS c$b$},
    q{SELECT 1 AS a$b$, $1::int, 2 AS c$b$} ],
);

for my $c (@cases) {
  my ($name, $in, $want) = @$c;
  is number_placeholders($in), $want, $name;
}

done_testing;
