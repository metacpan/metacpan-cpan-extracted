use strict;
use warnings;
use Test::More;

# Offline test: what DBIO::PostgreSQL::Storage adds to the fields of a DBI
# error (karr k130).
#
# WHY: core raises a statement the handle refused as a
# DBIO::Exception::Server whose sqlstate, constraint, table and detail come
# from the storage's _dbi_error_fields($h). The base answers the sqlstate
# only; DBD::Pg knows the rest (pg_error_field), and a caller that tells a
# unique violation from a foreign key violation, and names the constraint,
# should not parse the server's text -- which depends on lc_messages.
#
# The handle is a mock: no DBI, no DSN, no server. Whether DBD::Pg answers at
# the time HandleError runs is held by t/123-dbi-error-fields-live.t.

use DBIO::PostgreSQL::Storage;

{
  package Mock::Dbh;
  sub new { my ($c, %a) = @_; bless { state => delete $a{state}, fields => \%a, asked => [] }, $c }
  sub state { $_[0]{state} }
  sub pg_error_field { my ($s, $n) = @_; push @{ $s->{asked} }, $n; $s->{fields}{$n} }
}

{
  # a statement handle: no pg_error_field of its own, its database handle has
  package Mock::Sth;
  sub new { my ($c, %a) = @_; bless { state => $a{state}, Database => $a{Database} }, $c }
  sub state { $_[0]{state} }
  sub FETCH { $_[0]{$_[1]} }
}

my $storage = bless {}, 'DBIO::PostgreSQL::Storage';

my %unique = (
  state      => '23505',
  constraint => 'artist_name_key',
  table      => 'artist',
  detail     => 'Key (name)=(x) already exists.',
);

is_deeply scalar eval { $storage->_dbi_error_fields(Mock::Dbh->new(%unique)) },
  { sqlstate => '23505', constraint => 'artist_name_key', table => 'artist',
    detail => 'Key (name)=(***) already exists.' },
  'a db handle: sqlstate, constraint, table and detail from pg_error_field'
  or diag $@;

my $dbh = Mock::Dbh->new(%unique);
is_deeply scalar eval { $storage->_dbi_error_fields(Mock::Sth->new(state => '23505', Database => $dbh)) },
  { sqlstate => '23505', constraint => 'artist_name_key', table => 'artist',
    detail => 'Key (name)=(***) already exists.' },
  'a statement handle: asked through its database handle'
  or diag $@;

# a field the server did not report is left out, as core's contract says
is_deeply scalar eval {
    $storage->_dbi_error_fields(Mock::Dbh->new(state => '40001', detail => ''))
  },
  { sqlstate => '40001' },
  'an unreported or empty field is left out'
  or diag $@;

# DBI's own "no SQLSTATE" stays no sqlstate, and nothing is invented
is_deeply scalar eval { $storage->_dbi_error_fields(Mock::Dbh->new(state => 'S1000')) },
  {}, 'S1000 gives no sqlstate and no fields'
  or diag $@;

# a handle that has no pg_error_field (not DBD::Pg's) is the base's answer
{
  package Mock::Plain;
  sub new { bless { state => $_[1] }, $_[0] }
  sub state { $_[0]{state} }
}
is_deeply scalar eval { $storage->_dbi_error_fields(Mock::Plain->new('42P01')) },
  { sqlstate => '42P01' },
  'a handle without pg_error_field: the base answer, no die'
  or diag $@;

is_deeply scalar eval { $storage->_dbi_error_fields(undef) }, {},
  'no handle: no fields, no die'
  or diag $@;

# the Server exception core builds from it carries them
{
  require DBIO::Exception::Server;
  my $e = DBIO::Exception::Server->new(message => "boom\n",
    %{ $storage->_dbi_error_fields(Mock::Dbh->new(%unique)) });
  is $e->constraint, 'artist_name_key', 'exception: constraint';
  is $e->table,      'artist',          'exception: table';
  like $e->detail, qr/already exists/,  'exception: detail';
}

done_testing;
