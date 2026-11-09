# ABSTRACT: An error text names the statement and the number of binds, never a bind value
use strict;
use warnings;

use Test::More;

use DBIO::Test;

# karr k386 (ADR 0075). What this file claims:
#   1. a statement refused through _dbh_execute throws a text with the
#      statement and "3 bind values", and none of the values -- not even
#      when the handle writes "with ParamValues:" itself (a handle with
#      ShowErrorStatement on);
#   2. the connect attribute ShowErrorStatement => 1 changes nothing: the
#      attributes handed to DBI carry it as 0;
#   3. the exception stays a DBIO::Exception::Server.
#
# THE SUBSTITUTION: the mock runs no statement, so a stub handle whose
# execute fails through $storage->_dbi_handle_error, with the text DBI writes
# for a handle that shows its error statement.

my @values = ('geheim', q{a', 2='b}, undef);
my $sql    = 'INSERT INTO artist (name, rank, note) VALUES (?, ?, ?)';

{
  package T::K386Sth;
  sub new { bless { storage => $_[1] }, $_[0] }
  sub bind_param { 1 }
  sub errstr { '' }
  sub execute {
    my $self = shift;
    $self->{storage}->_dbi_handle_error(
      q{DBD::Stub::st execute failed: duplicate key [for Statement "}
      . $sql . q{" with ParamValues: 1='geheim', 2='a'', 2=''b', 3=undef]},
      { Statement => $sql, NUM_OF_PARAMS => 3 },
    );
  }

  package T::K386Dbh;
  sub new { bless { storage => $_[1] }, $_[0] }
  sub prepare_cached { T::K386Sth->new($_[0]{storage}) }
  sub prepare        { T::K386Sth->new($_[0]{storage}) }
  sub errstr { '' }

  # the mock storage prepares without a handle; the real one goes through it
  package T::K386Storage;
  our @ISA = ('DBIO::Test::Storage');
  sub _prepare_sth { my ($self, $dbh, $sql) = @_; $dbh->prepare($sql) }
  sub _adjust_bind_values { $_[2] }
}

my $schema  = DBIO::Test->init_schema(no_deploy => 1);
my $storage = $schema->storage;
bless $storage, 'T::K386Storage';
$storage->disable_sth_caching(1);

my $dbh  = T::K386Dbh->new($storage);
my $bind = [ map { [ {}, $_ ] } @values ];

eval { $storage->_dbh_execute($dbh, $sql, $bind, [ (undef) x 3 ]) };
my $err  = $@;
my $text = "$err";

isa_ok $err, 'DBIO::Exception::Server', 'the refused statement';
like $text, qr/\Q[for Statement "$sql" with 3 bind values]\E/,
  'the text has the statement and the number of binds';
unlike $text, qr/\Q$_\E/, "the text does not hold $_"
  for 'geheim', q{a'}, q{2='b}, 'ParamValues';

# the number follows the statement: one bind is "1 bind value"
{
  local $storage->{_exec_in_flight} = [ 'SELECT 1 WHERE x = ?', ['v'] ];
  eval { $storage->_dbi_handle_error('boom', {}) };
  like "$@", qr/\Q[for Statement "SELECT 1 WHERE x = ?" with 1 bind value]\E/,
    'one bind reads "1 bind value"';
}

# a handle that knows no bind count does not make the handler warn
{
  package T::NoParams; sub TIEHASH { bless {}, shift }
  sub FETCH { my $k = $_[1]; warn "unrecognised attribute $k\n" if $k eq 'NUM_OF_PARAMS'; $k eq 'Statement' ? 'SELECT 1' : undef }
  package main;
  tie my %h, 'T::NoParams';
  my @w;
  local $SIG{__WARN__} = sub { push @w, @_ };
  eval { $storage->_dbi_handle_error('boom', \%h) };
  like "$@", qr/with 0 bind values/, 'a handle without a bind count reads 0 bind values';
  is scalar @w, 0, '... and the handler warns nothing';
}

# 2. the user's attribute is not taken
for my $given (1, 0) {
  my $s = DBIO::Test->init_schema(no_deploy => 1)->storage;
  my $info = $s->_normalize_connect_info([
    'dbi:Stub:', undef, undef, { ShowErrorStatement => $given },
  ]);
  my ($args, $attrs) = $s->_dbi_args_from_info($info);
  is $attrs->{ShowErrorStatement}, 0, "ShowErrorStatement => $given is 0 in the attributes";
  is $args->[-1]{ShowErrorStatement}, 0, "... and in what DBI->connect gets";
}

done_testing;
