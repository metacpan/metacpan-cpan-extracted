use strict;
use warnings;
use Test::More;

use DBIO::Oracle::Test::Conformance;

# LIVE (karr k56). What the shared DDL table cannot show on Oracle because the
# case that holds it is refused as a whole, run as cases of the driver's own
# on the same runner (core ADR 0060, "driver-local cases"):
#
#   1. character(10): the size is read back as 10 and an 11-character value is
#      rejected -- the half of ddl-type-size-bit that the refused
#      bit column of that case hides;
#   2. a view whose definition quotes its names, written by hand, is created
#      as a view and selecting from it works (the shared ddl-view-declared
#      has the runner quote its definition and passes in t/73);
#   3. the quoted views of every shape of FROM and JOIN (alias, join, comma list)
#      are created as views: no heuristic of the driver turns a valid one down;
#   4. double, the base type, is a column of the server (BINARY_DOUBLE) and a
#      value goes through it -- it was written as DOUBLE, which Oracle rejects
#      (ORA-02000).
#
# Each is correct, with no refusal declared. Without DBIO_TEST_ORA_DSN the
# file skips.

{
  package T75::Conformance;
  use base 'DBIO::Oracle::Test::Conformance';

  sub conformance_refusals { {} }

  my $id = sub { +{ data_type => 'integer', is_nullable => 0 } };

  my @CASES = (
    {
      name => 'extra-character-size', since => 1, cards => [],
      subject => { source => 'Sized', column => 'c' },
      input => { sources => [ {
        name => 'Sized', table => 'sized75',
        columns => [ id => $id->(),
          c => { data_type => 'character', size => 10, is_nullable => 1 } ],
        primary_key => ['id'],
      } ] },
      expect => [
        { fact => { name => 'column_size', source => 'Sized', column => 'c', is => 10 } },
        { rejects => { source => 'Sized', create => { id => 1, c => 'x' x 11 } } },
      ],
    },
    {
      name => 'extra-quoted-view', since => 1, cards => [],
      subject => { source => 'BaseView' },
      input => { sources => [
        { name => 'Base', table => 'base75',
          columns => [ id => $id->(),
            name => { data_type => 'varchar', size => 20, is_nullable => 1 } ],
          primary_key => ['id'] },
        { name => 'BaseView', table => 'base_view75',
          columns => [ id => { data_type => 'integer' },
                       name => { data_type => 'varchar', size => 20 } ],
          view => { definition => 'SELECT "id" AS "id", "name" AS "name" FROM "base75"',
                    virtual => 0 } },
      ] },
      expect => [
        { fact => { name => 'object_kind', source => 'BaseView', is => 'view' } },
        { search_by => { source => 'Base', create => { id => 1, name => 'x' },
                         through => 'BaseView', column => 'name', value => 'x' } },
      ],
    },
    # Views whose definitions are fully quoted, in the shapes a heuristic for
    # "unquoted table names" once rejected: an alias after the table, a join, a
    # comma list. The driver does not read the SQL of a view; these are valid
    # and the view is created.
    (map {
      my ($suffix, $definition) = @$_;
      +{
        name => "extra-quoted-view-$suffix", since => 1, cards => [],
        subject => { source => 'NameView' },
        input => { sources => [
          { name => 'Artist', table => 'artist',
            columns => [ id => $id->(),
              name => { data_type => 'varchar', size => 20, is_nullable => 1 } ],
            primary_key => ['id'] },
          { name => 'Cd', table => 'cd',
            columns => [ id => $id->(), artist_id => { data_type => 'integer', is_nullable => 1 },
              title => { data_type => 'varchar', size => 20, is_nullable => 1 } ],
            primary_key => ['id'] },
          { name => 'NameView', table => 'name_view75',
            columns => [ name => { data_type => 'varchar', size => 20 } ],
            view => { definition => $definition, virtual => 0 } },
        ] },
        expect => [
          { fact => { name => 'object_kind', source => 'NameView', is => 'view' } },
        ],
      };
    }
      [ join  => 'SELECT a."name" AS "name" FROM "cd" cd JOIN "artist" a ON a."id" = cd."artist_id"' ],
      [ alias => 'SELECT "name" AS "name" FROM "artist" artist' ],
      [ comma => 'SELECT "artist"."name" AS "name" FROM "artist", "cd" cd WHERE cd."artist_id" = "artist"."id"' ],
    ),
    {
      name => 'extra-double', since => 1, cards => [],
      subject => { source => 'Dbl', column => 'd' },
      input => { sources => [ {
        name => 'Dbl', table => 'dbl75',
        columns => [ id => $id->(),
          d => { data_type => 'double', is_nullable => 1 } ],
        primary_key => ['id'],
      } ] },
      expect => [
        # DBD::Oracle hands a BINARY_DOUBLE over in Oracle's text form
        # (1.5E+000), which numifies to 1.5
        { read_back => { source => 'Dbl', create => { id => 1, d => 1.5 },
                         like => { d => qr/\A1\.5(?:E\+0+)?\z/ } } },
      ],
    },
  );

  sub cases { require Storable; return Storable::dclone([ @CASES ]) }
}

plan skip_all => 'Set $ENV{DBIO_TEST_ORA_DSN}, _USER and _PASS (and have DBD::Oracle) to run this test'
  unless T75::Conformance->conformance_live_available;

alarm 300;

my @results = T75::Conformance->results('DDL');
is scalar(@results), 6, 'the six cases ran';
for my $r (@results) {
  is $r->{status}, 'pass', "$r->{case}: correct"
    or diag $r->{message};
}

# The shared case itself, on the driver's real conformance class: no refusal
# declared, and the server creates the view the runner quoted and reads it.
{
  my ($r) = DBIO::Oracle::Test::Conformance->results('DDL', only => ['ddl-view-declared']);
  is $r->{status}, 'pass', 'ddl-view-declared: correct, not pending'
    or diag $r->{message};
}

# A view definition a user writes is the user's own SQL and goes to the server
# untouched: a real $schema->deploy of an unquoted one fails loudly with
# ORA-00942, the driver neither refuses nor rewrites it. (The shared case
# ddl-view-declared passes: the runner builds its definition from quoted
# identifiers, core's conformance_quote_ident, dbio k349 / karr k57.)
{
  package T75::Real::Schema;  use base 'DBIO::Schema';
  package T75::Real::Base;    use base 'DBIO::Core';
  package T75::Real::View;    use base 'DBIO::Core';

  T75::Real::Base->table('real75_base');
  T75::Real::Base->add_columns(id => { data_type => 'integer', is_nullable => 0 });
  T75::Real::Base->set_primary_key('id');

  T75::Real::View->table_class('DBIO::ResultSource::View');
  T75::Real::View->table('real75_view');
  T75::Real::View->result_source_instance->is_virtual(0);
  T75::Real::View->result_source_instance->view_definition('SELECT id FROM real75_base');
  T75::Real::View->add_columns(id => { data_type => 'integer' });

  T75::Real::Schema->register_class(Base => 'T75::Real::Base');
  T75::Real::Schema->register_class(View => 'T75::Real::View');
}

{
  my $schema = T75::Conformance->conformance_connect('T75::Real::Schema');
  my $dbh = $schema->storage->dbh;
  my $err;
  eval { $schema->deploy; 1 } or $err = "$@";
  like $err, qr/ORA-00942/, 'a real deploy of the unquoted view fails with ORA-00942';
  unlike $err, qr/refus/i, 'it is the server that answers, not a refusal of the driver';
  $dbh->do(q{DROP TABLE "real75_base" CASCADE CONSTRAINTS PURGE});
  $schema->storage->disconnect;
}

done_testing;
