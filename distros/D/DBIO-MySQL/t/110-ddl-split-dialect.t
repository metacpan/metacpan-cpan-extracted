use strict;
use warnings;

use Test::More;

# OFFLINE test: this driver declares its SQL dialect, so the DDL splitter of
# core reads a backslash in a string literal the way MySQL and MariaDB do
# (karr k99, the follow-up of core karr k332).
#
# WHY: core cuts install and upgrade DDL into statements before it runs them
# (DBIO::Deploy::Base::_execute_ddl). In standard SQL a backslash inside '...'
# is a character; in MySQL and MariaDB it escapes the next one, so
# 'it\'s; fine' is ONE literal. Left to guess, the splitter takes both
# readings and cuts at every semicolon either of them sees -- here the
# standard one, which ends the literal at the escaped quote and finds the
# semicolon behind it. Declared, the splitter reads MySQL's way only.
#
# MEASURED against core (DBIO::SQL::Util, %DIALECT): 'mysql' differs from
# "not declared" in the backslash alone (nested comments and BEGIN ATOMIC are
# off, as they are undeclared). Backtick identifiers with a semicolon are read
# the same either way and are held here only as a control; the splitter has no
# reading for '#' comments, so none is claimed.
#
# Held: the hook answers `mysql` on the storage of both components and the
# statements _execute_ddl (install, upgrade, apply) hands the database are the
# whole ones. The same text split by a storage that declares nothing is NOT
# the whole ones, so the test cannot pass by the splitter being lenient.

use DBIO::MySQL::Storage;
use DBIO::MySQL::Storage::MariaDB;
use DBIO::MySQL::Deploy;
use DBIO::Deploy::Base;
use DBIO::Schema ();
use DBIO::Test::Storage;    # declares nothing

{
  package T110::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL');
}

{
  package T110::MariaSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL::MariaDB');
}

{
  # The handle _execute_ddl is given: it records what it is asked to run.
  package T110::DBH;
  sub new { bless { stmts => [] }, shift }
  sub do  { push @{ $_[0]{stmts} }, $_[1]; 1 }
}

# Not inside parentheses: there the splitter does not cut at all, whatever it
# reads, and the test would prove nothing.
my $ESCAPED  = q{ALTER TABLE `t` COMMENT = 'it\\'s; fine'};
my $TRAILING = q{ALTER TABLE `t` COMMENT = 'a\\\\'};
my $LATER    = q{ALTER TABLE `t` COMMENT = 'x;y'};
my $BACKTICK = q{ALTER TABLE `a;b` ADD COLUMN `c;d` integer};

my @WHOLE = ($ESCAPED, $TRAILING, $LATER, $BACKTICK);
my $DDL   = join(";\n", @WHOLE) . ";\n";

my $schema  = T110::Schema->connect('dbi:mysql:dbname=appdb;host=db.example', 'app', 's3cret');
my $storage = $schema->storage;

is($storage->_ddl_sql_dialect, 'mysql', 'the storage declares the mysql dialect');
is(DBIO::MySQL::Storage->_ddl_sql_dialect, 'mysql', '... on the class, as a fact about the engine');
is(DBIO::MySQL::Storage::MariaDB->_ddl_sql_dialect, 'mysql',
  '... and the MariaDB storage inherits it (MariaDB declares mysql)');

is_deeply([ DBIO::Deploy::Base::_split_ddl($storage, $DDL) ], \@WHOLE,
  '_split_ddl: an escaped quote with a semicolon behind it stays one literal');

{
  my $maria = T110::MariaSchema->connect('dbi:MariaDB:dbname=appdb;host=db.example', 'app', 's3cret')->storage;
  is_deeply([ DBIO::Deploy::Base::_split_ddl($maria, $DDL) ], \@WHOLE,
    '... the same through the MariaDB storage');
}

# Without the declaration the same text is cut wrong -- the test is red
# where the declaration is missing.
{
  my @undeclared = DBIO::Deploy::Base::_split_ddl('DBIO::Test::Storage', $DDL);
  isnt(join("\0", @undeclared), join("\0", @WHOLE),
    'the same text split by a storage that declares nothing is not the whole statements');
}

{
  my $dbh = T110::DBH->new;
  DBIO::MySQL::Deploy->new(schema => $schema)->_execute_ddl($dbh, $DDL);
  is_deeply($dbh->{stmts}, \@WHOLE,
    '_execute_ddl hands the database the whole statements, one do per statement');
}

done_testing;
