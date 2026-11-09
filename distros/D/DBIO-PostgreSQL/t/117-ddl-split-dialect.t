use strict;
use warnings;

use Test::More;

# OFFLINE test: this driver declares its SQL dialect, so the DDL splitter of
# core reads PostgreSQL's forms as PostgreSQL does (karr k125, the follow-up
# of core karr k332).
#
# WHY: core cuts install and upgrade DDL into statements before it runs them
# (DBIO::Deploy::Base::_execute_ddl). Four things in PostgreSQL DDL cannot be
# told apart from a statement end by the text alone, and the splitter reads
# them PostgreSQL's way only when the storage says `postgresql`
# (DBIO::Storage::DBI::Capabilities/_ddl_sql_dialect):
#   * CREATE FUNCTION ... BEGIN ATOMIC ...; ...; END -- a routine body that
#     is a list of statements, with no dollar quote around it;
#   * /* a /* b; */ c; */ -- block comments nest in PostgreSQL only;
#   * CREATE RULE ... DO ALSO (a; b) -- the semicolon in the parentheses;
#   * 'a\' -- with standard_conforming_strings a backslash is a character, so
#     the literal ends there, and the literal after it with a semicolon in it
#     is a literal of its own.
# Undeclared, the splitter takes both readings of the backslash and not the
# first two. A driver that declares nothing hands the server half a function
# or cuts a comment in two: the install dies with a syntax error that reads
# like a bug in the DDL.
#
# What is held: the hook answers `postgresql` on the sync storage, and the
# statements that reach the database through _execute_ddl -- the path of
# install, upgrade and apply -- are the whole ones. The same text split
# without the declaration is NOT the whole ones, so the test cannot pass by
# the splitter being lenient.
#
# NOT HELD HERE: the async deploy. Core's DBIO::Storage::Async splits with
# _split_statements($ddl) and no options; see the card.

use DBIO::PostgreSQL::Storage;
use DBIO::PostgreSQL::Deploy;
use DBIO::Deploy::Base;
use DBIO::Schema ();

{
  package T117::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}

{
  # The handle _execute_ddl is given: it records what it is asked to run.
  package T117::DBH;
  sub new { bless { stmts => [] }, shift }
  sub do  { push @{ $_[0]{stmts} }, $_[1]; 1 }
}

my $BEGIN_ATOMIC = "CREATE FUNCTION add_one(a integer) RETURNS integer\n"
  . "  LANGUAGE sql\n"
  . "  BEGIN ATOMIC\n"
  . "    SELECT a + 1;\n"
  . "    SELECT (CASE WHEN a > 0 THEN 1 ELSE 2 END);\n"
  . "  END";
my $NESTED = "SELECT 1 /* outer /* inner; */ still outer; */ + 2";
my $RULE   = "CREATE RULE log_ins AS ON INSERT TO t DO ALSO "
  . "(INSERT INTO a VALUES (1); INSERT INTO b VALUES (2))";
my $BACKSLASH = q{SELECT 'C:\\'};
my $LATER     = q{SELECT 'a;b'};

my @WHOLE = ($BEGIN_ATOMIC, $NESTED, $RULE, $BACKSLASH, $LATER);
my $DDL   = join(";\n", @WHOLE) . ";\n";

my $schema  = T117::Schema->connect('dbi:Pg:dbname=appdb;host=db.example', 'app', 's3cret');
my $storage = $schema->storage;

is($storage->_ddl_sql_dialect, 'postgresql',
  'the storage declares the postgresql dialect');
is(DBIO::PostgreSQL::Storage->_ddl_sql_dialect, 'postgresql',
  '... on the class, as a fact about the engine');

# The splitter, asked the way core asks it.
is_deeply([ DBIO::Deploy::Base::_split_ddl($storage, $DDL) ], \@WHOLE,
  '_split_ddl: BEGIN ATOMIC, nested comment, DO ALSO (...; ...) and a backslash literal arrive whole');

# Without the declaration the same text is cut wrong -- the test fails where
# the declaration is missing.
{
  require DBIO::Test::Storage;    # declares nothing
  my @undeclared = DBIO::Deploy::Base::_split_ddl('DBIO::Test::Storage', $DDL);
  isnt(join("\0", @undeclared), join("\0", @WHOLE),
    'the same text split by a storage that declares nothing is not the whole statements');
}

# And through _execute_ddl, which is what install, upgrade and apply call.
{
  my $dbh = T117::DBH->new;
  my $deploy = DBIO::PostgreSQL::Deploy->new(schema => $schema);
  $deploy->_execute_ddl($dbh, $DDL);
  is_deeply($dbh->{stmts}, \@WHOLE,
    '_execute_ddl hands the database the whole statements, one do per statement');
}

done_testing;
