use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::Deploy;
use DBIO::PostgreSQL::Storage;
use DBIO::Replicated::Storage;

# WHY: the temporary database of a diff must get the declared search_path even
# when the schema's storage is a DBIO::Replicated::Storage (karr k148). The
# replicated storage forwards a named list of methods and not
# _declared_search_path, so asking it directly finds nothing and the target
# would be built in the wrong schema. The hook is asked of the driver storage
# behind it (Deploy::Base::_driver_storage). This file claims: with a
# replicated storage in front, _execute_ddl still sets the declared path on a
# handle that is not the live one.

{
  package T166::Driver;
  our @ISA = ('DBIO::PostgreSQL::Storage');
  sub _declared_search_path { return ('tenant', 'public') }
  sub connection_schema { undef }
  sub txn_do { $_[1]->() }
}
{
  package T166::Master;
  sub new { my ($c, $s) = @_; bless { storage => $s }, $c }
  sub storage { $_[0]{storage} }
}
{
  # a replicated storage as the schema holds it: it does not answer
  # _declared_search_path itself
  package T166::Replicated;
  our @ISA = ('DBIO::Replicated::Storage');
  sub new { my ($c, %a) = @_; bless { %a }, $c }
  sub master { $_[0]{master} }
  sub dbh { $_[0]{live_dbh} }
}
{
  package T166::Dbh;
  sub new { bless { stmts => [] }, shift }
  sub do { push @{ $_[0]{stmts} }, $_[1]; 1 }
}
{
  package T166::Schema;
  sub new { bless { storage => $_[1] }, $_[0] }
  sub storage { $_[0]{storage} }
}

my $driver = T166::Driver->new;
my $repl   = T166::Replicated->new(
  master   => T166::Master->new($driver),
  live_dbh => T166::Dbh->new,
);
ok !$repl->can('_declared_search_path'),
  'the replicated storage does not answer _declared_search_path itself';

my $deploy = DBIO::PostgreSQL::Deploy->new(schema => T166::Schema->new($repl));
my $temp   = T166::Dbh->new;
eval { $deploy->_execute_ddl($temp, 'SELECT 1;') };

is_deeply [ grep { /search_path/ } @{ $temp->{stmts} } ],
  [ 'SET search_path TO tenant, public' ],
  'the declared path is set on the temporary handle behind a replicated storage'
  or diag $@;

done_testing;
