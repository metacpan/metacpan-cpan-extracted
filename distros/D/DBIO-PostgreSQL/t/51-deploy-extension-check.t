use strict;
use warnings;

use Test::More;
use Test::Exception;

use lib 'lib';
use DBIO::PostgreSQL::Deploy;

# karr k41 -- the actionable CREATE EXTENSION prerequisite check.
#
# WHY this test exists: a schema that declares pg_extensions('vector') and is
# deployed against a server without pgvector used to fail the temp-database
# deploy with a cryptic follow-on error ("type vector does not exist" from a
# later CREATE TABLE) instead of naming the extension. Deploy now probes
# pg_available_extensions before the DDL runs and dies with an actionable
# message. The message construction is a pure function and the check itself
# only needs a catalog answer, so both are testable offline with a mock.

# -----------------------------------------------------------------------
# 1. Pure message construction
# -----------------------------------------------------------------------

my $msg = DBIO::PostgreSQL::Deploy->_missing_extension_message('vector');
like($msg, qr/"vector"/, 'message names the missing extension');
like($msg, qr/CREATE EXTENSION vector;/, 'message names the fix');
like($msg, qr/not available on this server/, 'message says the extension is unavailable');

my $msg2 = DBIO::PostgreSQL::Deploy->_missing_extension_message(qw(vector postgis));
like($msg2, qr/"vector", "postgis"/, 'message lists every missing extension');
like($msg2, qr/CREATE EXTENSION postgis;/, 'fix lists every extension');

# -----------------------------------------------------------------------
# 2. The check itself, against a mocked catalog
# -----------------------------------------------------------------------

{
  package DeployExtCheck::DBH;
  sub new { my ($c, $avail) = @_; bless { avail => $avail }, $c }
  sub selectcol_arrayref { [ @{ $_[0]->{avail} } ] }
}
{
  package DeployExtCheck::Storage;
  sub new { my ($c, $dbh) = @_; bless { dbh => $dbh }, $c }
  sub dbh { $_[0]->{dbh} }
}
{
  package DeployExtCheck::Schema;
  sub new {
    my ($c, $storage, @exts) = @_;
    bless { storage => $storage, exts => \@exts }, $c;
  }
  sub pg_extensions { @{ $_[0]->{exts} } }
  sub storage { $_[0]->{storage} }
}

sub make_deploy {
  my ($avail, @declared) = @_;
  my $dbh     = DeployExtCheck::DBH->new($avail);
  my $storage = DeployExtCheck::Storage->new($dbh);
  my $schema  = DeployExtCheck::Schema->new($storage, @declared);
  return DBIO::PostgreSQL::Deploy->new(schema => $schema);
}

my $deploy = make_deploy([]);
lives_ok { $deploy->_check_extensions_available }
  'no declared extensions: check is a no-op (no catalog query)';

$deploy = make_deploy([qw(pgcrypto vector)], qw(pgcrypto vector));
lives_ok { $deploy->_check_extensions_available }
  'all declared extensions available: check passes';

$deploy = make_deploy([qw(pgcrypto)], qw(pgcrypto vector));
throws_ok { $deploy->_check_extensions_available }
  qr/"vector".*CREATE EXTENSION vector;/s,
  'missing extension: check dies with the actionable message';

# a DBIO::Exception, not a string (core ADR 0077, karr dbio k391): the Names
# list holds a refusal of the driver to be one
my $err = do { eval { $deploy->_check_extensions_available }; $@ };
isa_ok $err, 'DBIO::Exception', 'the refusal';
unlike ref($err), qr/Server/, '... and not a server error';

done_testing;
