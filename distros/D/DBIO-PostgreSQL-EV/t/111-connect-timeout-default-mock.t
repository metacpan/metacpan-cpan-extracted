use strict;
use warnings;
use Test::More;

# OFFLINE test: every connection this transport opens has a connect timeout
# (karr k101). libpq's own default waits for ever, and a pool spawn or the
# LISTEN connection would hold its caller for as long.
#
# Claims: a conninfo without connect_timeout gets connect_timeout=10; one that
# sets it keeps its value, however spelled or quoted; a URI is left alone; the
# connection the pool constructs is the one that gets it.

BEGIN {
  $INC{'EV/Pg.pm'} = 1;
  package EV::Pg;
  our @NEW;
  sub new { my ($c, %a) = @_; push @NEW, \%a; bless {}, $c }
}

use DBIO::PostgreSQL::EV::ConnectInfo qw( with_connect_timeout conninfo_string );
use DBIO::PostgreSQL::EV::Pool;

is with_connect_timeout('host=db1 dbname=app'), 'host=db1 dbname=app connect_timeout=10',
  'no connect_timeout: the default is added';
is with_connect_timeout('host=db1 connect_timeout=3'), 'host=db1 connect_timeout=3',
  'the user\'s value stays';
is with_connect_timeout("connect_timeout = '0' host=db1"), "connect_timeout = '0' host=db1",
  'also 0 (no timeout), quoted and with blanks around the =';
is with_connect_timeout("password='x connect_timeout=1' host=db1"),
  "password='x connect_timeout=1' host=db1 connect_timeout=10",
  'the text of a quoted value is no parameter';
is with_connect_timeout('postgresql://u@db1/app'), 'postgresql://u@db1/app', 'a URI is left alone';
is with_connect_timeout(conninfo_string({ connect_timeout => 5 })),
  'connect_timeout=5', 'a hash that sets it';
is with_connect_timeout(' '), 'connect_timeout=10', 'a blank conninfo';

DBIO::PostgreSQL::EV::Pool->_new_connection(conninfo => 'host=db1 dbname=app');
DBIO::PostgreSQL::EV::Pool->_new_connection(conninfo => 'host=db2 connect_timeout=2');
is_deeply [ map { $_->{conninfo} } @EV::Pg::NEW ],
  [ 'host=db1 dbname=app connect_timeout=10', 'host=db2 connect_timeout=2' ],
  'the connections the pool constructs carry the default, or the user\'s value';

done_testing;
