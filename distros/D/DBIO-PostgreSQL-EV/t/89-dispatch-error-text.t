use strict;
use warnings;

use Test::More;

use DBIO::PostgreSQL::EV::Storage;

# EV::Pg's own croak ("not connected") is raised from XS and names the line of
# this library that called it; the caller gets the text and its newline (karr
# k88, as dbio-postgresql karr k120 for future_io). What carries no such place
# stays exactly as it is. The statement-level claims -- the Future fails with
# "not connected", the connection goes back -- are held by t/32, t/41, t/47.

my $s = bless {}, 'DBIO::PostgreSQL::EV::Storage';

is $s->_pg_dispatch_error("not connected at /usr/lib/perl5/DBIO/PostgreSQL/EV/Storage.pm line 1221.\n"),
  "not connected\n", 'the place of the call is dropped, the text and newline stay';

is $s->_pg_dispatch_error("not connected at /opt/my dir/Storage.pm line 7.\n"),
  "not connected\n", 'also a path with a blank';

is $s->_pg_dispatch_error("PQsendQueryParams failed: another command is already in progress\n"),
  "PQsendQueryParams failed: another command is already in progress\n",
  "libpq's own message carries no place and is left alone";

is $s->_pg_dispatch_error("cannot connect at host a at line 3 of the story\n"),
  "cannot connect at host a at line 3 of the story\n",
  'an " at " inside the text is not mistaken for a place';

is $s->_pg_dispatch_error("connection lost"), 'connection lost',
  'a text without a newline passes unchanged';

my $obj = bless {}, 'Some::Error';
is $s->_pg_dispatch_error($obj), $obj, 'an object passes unchanged';
is $s->_pg_dispatch_error(undef), undef, 'undef passes unchanged';

done_testing;
