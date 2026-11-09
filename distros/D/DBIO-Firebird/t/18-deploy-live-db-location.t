use strict;
use warnings;
use Test::More;

# Offline: Deploy::_live_db_location must resolve host[/port] and the db
# directory from every DSN spelling DBD::Firebird accepts, because the temp
# database is created on that same server. A lost host makes create_database
# create the file on the client.

use DBIO::Firebird::Deploy;

{
  package Local::Storage; sub new { bless { ci => $_[1] }, $_[0] } sub connect_info { $_[0]{ci} }
  package Local::Schema;  sub new { bless { st => $_[1] }, $_[0] } sub storage { $_[0]{st} }
}

sub loc {
  my ($ci) = @_;
  my $schema = Local::Schema->new(Local::Storage->new($ci));
  my $d = bless { schema => $schema }, 'DBIO::Firebird::Deploy';
  no warnings qw(redefine once);
  local *DBIO::Firebird::Deploy::schema = sub { $_[0]{schema} };
  return [ $d->_live_db_location ];
}

my @cases = (
  [ 'host/port:/path in dbname'  => 'dbi:Firebird:dbname=db.example/3051:/data/x/t.fdb' => [ 'db.example/3051', '/data/x' ] ],
  [ 'host:/path in dbname'       => 'dbi:Firebird:dbname=db.example:/data/x/t.fdb'      => [ 'db.example',      '/data/x' ] ],
  [ 'host= and port= attributes' => 'dbi:Firebird:dbname=/data/x/t.fdb;host=db.example;port=3051' => [ 'db.example/3051', '/data/x' ] ],
  [ 'attributes, other order'    => 'dbi:Firebird:host=db.example;port=3051;db=/data/x/t.fdb'     => [ 'db.example/3051', '/data/x' ] ],
  [ 'hostname= without port'     => 'dbi:Firebird:database=/data/x/t.fdb;hostname=db.example'     => [ 'db.example',      '/data/x' ] ],
  [ 'host=h/port form'           => 'dbi:Firebird:dbname=/data/x/t.fdb;host=db.example/3051'      => [ 'db.example/3051', '/data/x' ] ],
  [ 'purely local path'          => 'dbi:Firebird:dbname=/data/x/t.fdb'                           => [ '',                '/data/x' ] ],
);

is_deeply(loc([ $_->[1], 'u', 'p' ]), $_->[2], $_->[0]) for @cases;
is_deeply(loc([ { dsn => $cases[2][1] } ]), $cases[2][2], 'hashref connect_info');

done_testing;
