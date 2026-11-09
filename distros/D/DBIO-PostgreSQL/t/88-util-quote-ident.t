use strict;
use warnings;

use Test::More;

# OFFLINE test for karr k110 / k115 / k117: the one place in this driver that
# turns a name into a SQL identifier and a value into a SQL literal.
#
# WHY it exists: there was no such place. install_ddl quoted on shape alone
# and case-insensitively (the core helper), a second rule covered index
# columns only, table and schema names went in raw, and the diff classes used
# the model's "schema.table" hash key as SQL text. So "user" as a column, a
# Mixed-Case table and an apostrophe in a default each produced a statement
# the server refuses -- or, worse, accepts for a different object (MixedCase
# folded to mixedcase). The rule here is the server's own quote_ident(); the
# live half (t/91) holds it against a real server, this file pins the cases.

use DBIO::PostgreSQL::Util qw(quote_ident quote_qualified quote_literal quote_role);

# --- identifiers: bare only when the server would read them back unchanged --

is quote_ident($_), $_, "'$_' stays bare"
  for qw(users _x a1 role_type id email created_at t x_1_y);

# Key words of the "unreserved" class are ordinary names to the parser.
is quote_ident($_), $_, "unreserved key word '$_' stays bare"
  for qw(name value type key comment data year role admin action version schema index text public);

my %shape = (
  'Users'      => '"Users"',
  'MixedCase'  => '"MixedCase"',
  'USER'       => '"USER"',
  '1a'         => '"1a"',
  'a b'        => '"a b"',
  'a.b'        => '"a.b"',
  'uuid-ossp'  => '"uuid-ossp"',
  'x$y'        => '"x$y"',
  'a"b'        => '"a""b"',
  '"'          => '""""',
  "users\n"    => qq{"users\n"},
  "\x{e9}t\x{e9}" => qq{"\x{e9}t\x{e9}"},
);
is quote_ident($_), $shape{$_}, "'$_' is quoted for its shape"
  for sort keys %shape;

# Reserved words: the ones k115 named, which broke CREATE TABLE.
is quote_ident($_), qq{"$_"}, "reserved word '$_' is quoted"
  for qw(user order end desc default limit offset table check to from group select);

# The classes the old list left out. The server quotes these too: a column
# called "position" or "time" is written bare by nobody who asks it.
is quote_ident($_), qq{"$_"}, "col_name key word '$_' is quoted"
  for qw(position time timestamp values int integer varchar numeric interval row exists);
is quote_ident($_), qq{"$_"}, "type_func_name key word '$_' is quoted"
  for qw(left right full like binary verbose join is collation authorization);

for my $bad ([ undef, 'undef' ], [ '', 'empty' ], [ [], 'a reference' ], [ "a\0b", 'a NUL byte' ]) {
  ok !eval { quote_ident($bad->[0]); 1 }, "an identifier that is $bad->[1] is refused";
}

# --- qualified names: each part for itself, never taken apart at a dot ------

is quote_qualified('auth', 'users'),        'auth.users',          'two plain parts';
is quote_qualified('Auth', 'user'),         '"Auth"."user"',       'each part quoted on its own';
is quote_qualified('my.schema', 'tbl'),     '"my.schema".tbl',     'a dot inside a part stays inside it';
is quote_qualified('My.Schema', 'Mixed.Case'), '"My.Schema"."Mixed.Case"', '... on both sides';
is quote_qualified('users'),                'users',               'one part';
is quote_qualified('a', 'b', 'c'),          'a.b.c',               'three parts';
ok !eval { quote_qualified(); 1 },             'no part at all is refused';
ok !eval { quote_qualified('auth', undef); 1 }, 'an undefined part is refused, not dropped';
ok !eval { quote_qualified(undef, 'users'); 1 }, '... on either side';

# --- literals ---------------------------------------------------------------

my %literal = (
  'draft'  => q{'draft'},
  "it's"   => q{'it''s'},
  "''"     => q{''''''},
  "o'b'c"  => q{'o''b''c'},
  ''       => q{''},
  '0'      => q{'0'},
  'a\\b'   => q{'a\\b'},
  'a"b'    => q{'a"b'},
);
is quote_literal($_), $literal{$_}, "literal for <$_>"
  for sort keys %literal;
for my $bad ([ undef, 'undef' ], [ [], 'a reference' ], [ "a\0b", 'a NUL byte' ]) {
  ok !eval { quote_literal($bad->[0]); 1 }, "a literal that is $bad->[1] is refused";
}

# --- role lists -------------------------------------------------------------

# Measured on PostgreSQL 18.6: TO PUBLIC and TO CURRENT_USER work in any case,
# TO "PUBLIC" and TO "current_user" fail with 'role ... does not exist'. They
# are key words standing for a role, so quoting them changes what they mean.
is quote_role($_), $_, "role key word '$_' is written as given"
  for qw(PUBLIC public Public CURRENT_USER current_user CURRENT_ROLE SESSION_USER session_user);
is quote_role('app_user'), 'app_user',   'a plain role name stays bare';
is quote_role('AppUser'),  '"AppUser"',  'a Mixed-Case role name is quoted';
is quote_role('app user'), '"app user"', '... and one with a space';
is quote_role('user'),     '"user"',     'a role called "user" is a name, not the key word';
ok !eval { quote_role(undef); 1 }, 'an undefined role is refused';

done_testing;
