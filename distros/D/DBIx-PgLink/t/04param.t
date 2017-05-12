use strict;
use Test::More tests => 19;
use Test::Exception;

BEGIN {
  use lib 't';
  use_ok('PgLinkTestUtil');
  use_ok('DBIx::PgLink::Local');
}

ok(pg_dbh, 'pg_dbh defined');

sub placeholders_ok {
  my $q = shift;
  my $exp_q = shift;
  my $exp_p = shift;
  my $tmp = $q;
  my @g = DBIx::PgLink::Local::st::_find_placeholders($tmp);
  is($tmp, $exp_q, "replace placeholders in $q");
  is_deeply(\@g, $exp_p, "find placeholders in $q");
}

placeholders_ok('SELECT 1', 'SELECT 1', []);
placeholders_ok('SELECT $1', 'SELECT $1', ['1']);
placeholders_ok('SELECT ?', 'SELECT $1', ['1']);
placeholders_ok('SELECT a,b,c FROM t WHERE a=$2 and b>$1',
                'SELECT a,b,c FROM t WHERE a=$2 and b>$1', 
                ['1', '2']
);
placeholders_ok('SELECT a,b,c FROM t WHERE a=? and b>?',
                'SELECT a,b,c FROM t WHERE a=$1 and b>$2', 
                ['1', '2']
);
# false parameter
placeholders_ok(q/SELECT '?' as foo/, q/SELECT '$1' as foo/, ['1']);
placeholders_ok(q/SELECT 'foo' as "bar?"/, q/SELECT 'foo' as "bar$1"/, ['1']);
placeholders_ok(q/SELECT 'foo' as "bar" --what?/, q/SELECT 'foo' as "bar" --what$1/, ['1']);

