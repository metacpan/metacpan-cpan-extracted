use strict;
use warnings;

use Test::More;
use DBI;
use FindBin;
use lib "$FindBin::Bin/lib";
use AseDatabase;
use DBIO::Sybase::Quote qw(quote_ident);

# LIVE (karr k92). The list of DBIO::Sybase::Quote is a measurement, and this
# file is where it is asked again, of the server it is run against. For every
# word of it:
#
#   1. written bare it is refused in at least one of the four places a name
#      goes -- CREATE TABLE w, CREATE TABLE t (w int), CREATE INDEX w ON t,
#      CREATE TABLE t (.., CONSTRAINT w PRIMARY KEY) -- with a syntax error
#      (Msg 102, 135, 136, 155, 156 or 11720), not with something else;
#   2. written as quote_ident writes it, [w], it is taken in all four.
#
# And the forms of a name that is no keyword: a blank, a ], a double quote,
# a name of 30 and of 31 characters go in as [name] and are
# stored as the name itself (sysobjects), a ] doubled; "name" is Msg 102 --
# why no double quotes (set quoted_identifier on is not the login's default).
#
# What no quoting reaches: a name that starts with # or @ (Msg 11717, 16366)
# and one with a dot (read as owner.name, Msg 2734) -- DBIO::Sybase::Quote
# refuses those itself, t/95 -- and one of 256 characters (Msg 103).
#
# The list itself comes from the server's catalog, master..spt_values rows of
# type 'W', plus the words a measurement found that the catalog does not name;
# the first checks below compare the two, in both directions.
#
# Runs in a throwaway database it creates and drops itself; needs a login
# allowed to CREATE DATABASE.

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_SYBASE_${_}" } qw/DSN USER PASS/};
plan skip_all => 'Set $ENV{DBIO_TEST_SYBASE_DSN}, _USER and _PASS to run this test.'
  unless $dsn && defined $user && defined $pass;

my $db = "dbio_k92_words_$$";
my $db_dsn = $dsn;
$db_dsn =~ s/\bdatabase=[^;]*/database=$db/i
  or $db_dsn .= ($dsn =~ /:$/ ? '' : ';') . "database=$db";

my $admin = DBI->connect($dsn, $user, $pass,
  { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
$admin->do('USE master');
$admin->do("CREATE DATABASE $db");
{
  # Without this a full log suspends the session instead of refusing the
  # statement (karr k69).
  local $admin->{syb_err_handler} = sub { $_[1] > 10 ? 1 : 0 };
  my $sth = $admin->prepare("exec sp_dboption '$db', 'abort tran on log full', true");
  $sth->execute;
  do { 1 while $sth->fetchrow_arrayref } while $sth->{syb_more_results};
}

my $ok = eval {
  my $dbh = DBI->connect($db_dsn, $user, $pass,
    { RaiseError => 0, PrintError => 0, AutoCommit => 1 });

  # undef when the server took it, else the number of its refusal
  my $try = sub {
    my $sql = shift;
    return defined $dbh->do($sql) ? undef : ( $dbh->err // 'unknown' );
  };

  $dbh->do('CREATE TABLE k92_t (id INT NOT NULL)');

  # the four places, for the name as written ($w); returns the refusals
  my $places = sub {
    my $w = shift;
    my %refused;
    my @steps = (
      [ table      => "CREATE TABLE $w (id INT NOT NULL)",                                  "DROP TABLE $w" ],
      [ column     => "CREATE TABLE k92_c ($w INT NOT NULL)",                               'DROP TABLE k92_c' ],
      [ index      => "CREATE INDEX $w ON k92_t (id)",                                      "DROP INDEX k92_t.$w" ],
      [ constraint => "CREATE TABLE k92_k (id INT NOT NULL, CONSTRAINT $w PRIMARY KEY (id))", 'DROP TABLE k92_k' ],
    );
    for my $step (@steps) {
      my ($place, $create, $drop) = @$step;
      if (defined( my $err = $try->($create) )) { $refused{$place} = $err }
      else                                      { $try->($drop) }
    }
    return \%refused;
  };

  my @words = DBIO::Sybase::Quote::keywords();
  cmp_ok scalar(@words), '>', 200, 'the list has ' . scalar(@words) . ' words';

  # The source of the list: the server's own catalog of its words, both
  # directions. A word the server names and the list lacks is a failure; a
  # word of the list the catalog lacks is kept (found refused by measurement)
  # and said.
  my %catalog = map { lc $_->[0] => 1 } @{ $dbh->selectall_arrayref(
    q{SELECT rtrim(name) FROM master..spt_values WHERE type = 'W'}) };
  my %listed = map { $_ => 1 } @words;
  cmp_ok scalar(keys %catalog), '>', 200, 'master..spt_values holds ' . scalar(keys %catalog) . ' words of type W';
  is_deeply [ sort grep { !$listed{$_} } keys %catalog ], [],
    'every word of the server\'s catalog is on the list';
  note 'on the list, not in the catalog (kept, found by measurement): '
     . join ' ', sort grep { !$catalog{$_} } @words;

  my (@bare_taken, @bracket_refused, @odd_refusal);
  my $n = 0;
  for my $w (@words) {
    my $bare = $places->($w);
    push @bare_taken, $w unless %$bare;
    push @odd_refusal, "$w: " . join ', ', map { "$_ $bare->{$_}" } sort keys %$bare
      if grep { $_ !~ /\A(?:102|135|136|155|156|11720)\z/ } values %$bare;

    my $quoted = $places->(quote_ident($w));
    push @bracket_refused, "$w: " . join ', ', map { "$_ $quoted->{$_}" } sort keys %$quoted
      if %$quoted;

    # the log of a 24 MB database is not for 200 words of DDL
    $admin->do("dump transaction $db with truncate_only") unless ++$n % 25;
  }
  is_deeply \@bare_taken, [], 'every word is refused bare in at least one place'
    or diag "taken bare in all four: @bare_taken";
  is_deeply \@odd_refusal, [], '... with a syntax error and nothing else'
    or diag map { "  $_\n" } @odd_refusal;
  is_deeply \@bracket_refused, [], 'every word is taken in brackets, in all four places'
    or diag map { "  $_\n" } @bracket_refused;

  # names that are no keyword
  for my $name ('my col', 'a]b', 'a"b', '1abc', 'x' x 30, 'x' x 31, 'Dummy') {
    my $label = length $name > 20 ? length($name) . ' characters' : $name;
    my $q = quote_ident($name);
    is $try->("CREATE TABLE $q (id INT NOT NULL)"), undef, "[$label]: CREATE TABLE $q is taken"
      or next;
    my ($stored) = $dbh->selectrow_array('SELECT name FROM sysobjects WHERE name = ?', undef, $name);
    is $stored, $name, '... and the table is stored under the name itself, without brackets';
    $try->("DROP TABLE $q");
  }
  is $try->('CREATE TABLE "dummy" (id INT NOT NULL)'), 102,
    'SERVER: "dummy" is Msg 102 without quoted_identifier -- why brackets';

  $dbh->disconnect;
  1;
};
my $err = $@;

eval { $admin->do('USE master') };
is AseDatabase::drop($admin, $db), '', "the database of this test, $db, is dropped";

die $err unless $ok;

done_testing;
