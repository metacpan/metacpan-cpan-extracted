# ABSTRACT: NoBindVars error text names the placeholder statement, not the values
use strict;
use warnings;

use Test::More;

use DBIO::Test;
use DBIO::Storage::DBI::NoBindVars;

# ADR 0075. What this file claims: a storage that writes the bind values into
# the statement (NoBindVars) still throws the statement in placeholder form
# and the number of values -- "VALUES (?, ?) with 2 bind values" -- not the
# interpolated statement; the hook _mask_error_values gets the values that
# were written into it, for _prep_for_execute and for _prep_rendered_for_execute.
#
# THE SUBSTITUTION: the mock runs no statement, so a stub statement handle
# fails through $storage->_dbi_handle_error with the text an engine writes.

my @calls;

{
  package T::QDbh;
  sub new { bless { storage => $_[1] }, $_[0] }
  sub quote { my $v = $_[1]; $v =~ s/'/''/g; "'$v'" }
  sub prepare_cached { T::QSth->new($_[0]{storage}) }
  sub prepare        { T::QSth->new($_[0]{storage}) }
  sub errstr { '' }

  package T::QSth;
  sub new { bless { storage => $_[1] }, $_[0] }
  sub bind_param { 1 }
  sub errstr { '' }
  sub execute {
    $_[0]{storage}->_dbi_handle_error(
      q{duplicate key: Key (name)=(geheim-pk) exists},
      { Statement => 'ignored', NUM_OF_PARAMS => 0 },
    );
  }

  package T::NBV;
  use mro 'c3';
  our @ISA = ('DBIO::Storage::DBI::NoBindVars', 'DBIO::Test::Storage');
  sub _get_dbh { $_[0]{qdbh} ||= T::QDbh->new($_[0]) }
  sub _prepare_sth { my ($self, $dbh, $sql) = @_; $dbh->prepare($sql) }
  sub _adjust_bind_values { $_[2] }
  sub _mask_error_values {
    my ($self, @args) = @_;
    push @calls, [ @args ];
    return $self->next::method(@args);
  }
}

my $schema  = DBIO::Test->init_schema(no_deploy => 1);
my $storage = $schema->storage;
bless $storage, 'T::NBV';
$storage->disable_sth_caching(1);
my $source = $schema->source('Artist');

sub run_and_fail {
  my ($sql, $bind) = @_;
  @calls = ();
  eval { $storage->_dbh_execute($storage->_get_dbh, $sql, $bind, []) };
  return "$@";
}

# _prep_for_execute
{
  my ($sql, $bind) = $storage->_prep_for_execute(
    'insert', $source, [ { name => 'geheim-pk', rank => 7 } ],
  );
  like $sql, qr/'geheim-pk'/, 'the statement run has the value written in';
  is scalar @$bind, 0, '... and no binds left';

  my $err = run_and_fail($sql, $bind);
  like $err, qr/VALUES \(\?, \?\)" with 2 bind values\]/,
    'the text names the placeholder statement and the number of values';
  unlike $err, qr/geheim-pk/, '... and no value, in the text of the engine either';
  is_deeply [ sort @{ $calls[0][1] } ], [ sort 'geheim-pk', 7 ],
    'the hook gets the values that were written into the statement';
  like $calls[0][2], qr/VALUES \(\?, \?\)/, '... and the statement in placeholder form';
}

# _prep_rendered_for_execute
{
  my ($sql, $bind) = $storage->_prep_rendered_for_execute(
    'SELECT 1 WHERE x = ?', [ [ {}, 'geheim-pk' ] ],
  );
  is $sql, q{SELECT 1 WHERE x = 'geheim-pk'}, 'the rendered statement has the value written in';

  my $err = run_and_fail($sql, $bind);
  like $err, qr/\Q[for Statement "SELECT 1 WHERE x = ?" with 1 bind value]\E/,
    'the text names the placeholder statement and one value';
  unlike $err, qr/geheim-pk/, '... and no value';
  is_deeply $calls[0][1], ['geheim-pk'], 'the hook gets the value';
}

# a statement that was not interpolated keeps its form
{
  my $err = run_and_fail('SELECT 1', []);
  like $err, qr/\Q[for Statement "SELECT 1" with 0 bind values]\E/, 'no values, no change';
}

done_testing;
