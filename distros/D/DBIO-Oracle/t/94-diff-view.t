use strict;
use warnings;
use Test::More;

use DBIO::Oracle::Diff;
use DBIO::Oracle::Diff::View;

# OFFLINE (karr k65). The model carries the definition of a view (the
# `views` section, from all_views.text) and the diff writes CREATE OR REPLACE
# VIEW for a view that is new or whose definition changed, and DROP VIEW for
# one that is gone: views after the tables, drops before them. What Oracle
# rewrites when it stores a view is measured live (t/57, t/87) and named in the
# POD of DBIO::Oracle::Diff::View.

sub tbl  { return ($_[0] => { table_name => $_[0], kind => 'table', schema => 'U' }) }
sub vw   { return ($_[0] => { table_name => $_[0], kind => 'view',  schema => 'U' }) }
sub col  { return { column_name => $_[0], data_type => 'integer' } }
sub view { return ($_[0] => { view_name => $_[0], definition => $_[1] }) }

sub model {
  my (%m) = @_;
  return { indexes => {}, foreign_keys => {}, unique_constraints => {}, views => {}, %m };
}

sub stmts {
  my ($diff) = @_;
  return [ map { (my $s = $_) =~ s/;\z//; $s } grep { length } split /\n(?=CREATE |DROP |ALTER )/, $diff->as_sql ];
}

my $DEF = q{SELECT "id" FROM "base"};

# --- a new view -------------------------------------------------------------
{
  my $diff = DBIO::Oracle::Diff->new(
    source => model(tables => { tbl('base') }, columns => { base => [ col('id') ] }),
    target => model(
      tables  => { tbl('base'), vw('v') },
      columns => { base => [ col('id') ], v => [ col('id') ] },
      views   => { view(v => $DEF) },
    ),
  );
  is_deeply stmts($diff), [ qq{CREATE OR REPLACE VIEW "v" AS $DEF} ],
    'a new view is created with CREATE OR REPLACE VIEW and the definition of the model';
  is $diff->operations->[0]->summary, '+ view: v', '... summarised as a view';
}

# --- a changed view ---------------------------------------------------------
{
  my %t = (tables => { tbl('base'), vw('v') });
  my $diff = DBIO::Oracle::Diff->new(
    source => model(%t, columns => { base => [ col('id') ], v => [ col('id') ] },
                    views => { view(v => $DEF) }),
    target => model(%t, columns => { base => [ col('id') ], v => [ col('id'), col('x') ] },
                    views => { view(v => q{SELECT "id", "x" FROM "base"}) }),
  );
  is_deeply stmts($diff), [ q{CREATE OR REPLACE VIEW "v" AS SELECT "id", "x" FROM "base"} ],
    'a view whose definition changed is replaced; its columns are not altered one by one';
  is $diff->operations->[0]->summary, '~ view: v', '... summarised as a change';
}

# --- a dropped view ---------------------------------------------------------
{
  my $diff = DBIO::Oracle::Diff->new(
    source => model(tables => { tbl('base'), vw('v') }, columns => { base => [ col('id') ], v => [ col('id') ] },
                    views => { view(v => $DEF) }),
    target => model(tables => { tbl('base') }, columns => { base => [ col('id') ] }),
  );
  is_deeply stmts($diff), [ q{DROP VIEW "v"} ], 'a view that is gone is dropped';
  is $diff->operations->[0]->summary, '- view: v', '... summarised as a view';
}

# --- no change --------------------------------------------------------------
{
  my %same = (
    tables => { tbl('base'), vw('v') }, columns => { base => [ col('id') ], v => [ col('id') ] },
  );
  my $diff = DBIO::Oracle::Diff->new(
    source => model(%same, views => { view(v => "SELECT \"id\"\n   FROM \"base\"  ;") }),
    target => model(%same, views => { view(v => q{SELECT "id" FROM "base"}) }),
  );
  ok !$diff->has_changes, 'whitespace and a trailing semicolon are not a difference';

  $diff = DBIO::Oracle::Diff->new(
    source => model(%same, views => { view(v => q{SELECT "id" FROM "base" WHERE "n" = 'a  b'}) }),
    target => model(%same, views => { view(v => q{SELECT "id" FROM "base" WHERE "n" = 'a b'}) }),
  );
  ok $diff->has_changes, 'whitespace inside a string literal is a difference';

  $diff = DBIO::Oracle::Diff->new(
    source => model(%same, views => { view(v => q{SELECT "id" FROM "base"}) }),
    target => model(%same, views => { view(v => q{select "id" from "base"}) }),
  );
  ok $diff->has_changes, 'the rest is compared as written: a different case is a difference';
}

# --- order: drops before the tables, creates after them ----------------------
{
  my $diff = DBIO::Oracle::Diff->new(
    source => model(
      tables  => { tbl('old'), tbl('keep'), vw('gone') },
      columns => { old => [ col('id') ], keep => [ col('id') ], gone => [ col('id') ] },
      views   => { view(gone => q{SELECT "id" FROM "old"}) },
    ),
    target => model(
      tables  => { tbl('new'), tbl('keep'), vw('fresh') },
      columns => { new => [ col('id') ], keep => [ col('id') ], fresh => [ col('id') ] },
      views   => { view(fresh => q{SELECT "id" FROM "new"}) },
    ),
  );
  my @sql = map { (split /\n/, $_)[0] } map { $_->as_sql } @{ $diff->operations };
  my ($drop_view)   = grep { $sql[$_] =~ /^DROP VIEW/ } 0 .. $#sql;
  my ($drop_table)  = grep { $sql[$_] =~ /^DROP TABLE/ } 0 .. $#sql;
  my ($create_tbl)  = grep { $sql[$_] =~ /^CREATE TABLE/ } 0 .. $#sql;
  my ($create_view) = grep { $sql[$_] =~ /^CREATE OR REPLACE VIEW/ } 0 .. $#sql;
  ok $drop_view < $drop_table, 'a view is dropped before the tables are';
  ok $create_tbl < $create_view, 'a view is created after the tables are';
  is $create_view, $#sql, '... and after everything else';
}

# --- the column list of a view (karr k65) -------------------------------------
# CREATE VIEW v (a, b) AS ... keeps the names only in the columns of the view
# (all_views.text is the bare query), so the model holds them in COLUMN_ID
# order and the diff writes them, quoted as Oracle has them.
{
  my %t = (tables => { tbl('base'), vw('v') }, columns => { base => [ col('id') ], v => [ col('a'), col('b') ] });
  my $Q = q{SELECT "id", "name" FROM "base"};
  my $diff = DBIO::Oracle::Diff->new(
    source => model(tables => { tbl('base') }, columns => { base => [ col('id') ] }),
    target => model(%t, views => { v => { view_name => 'v', definition => $Q, columns => [ 'a', 'B"x' ] } }),
  );
  is_deeply stmts($diff), [ qq{CREATE OR REPLACE VIEW "v" ("a", "B""x") AS $Q} ],
    'a new view is written with its column list, the names quoted as the model spells them';

  my $same = sub { { v => { view_name => 'v', definition => $Q, columns => $_[0] } } };
  ok !DBIO::Oracle::Diff->new(
    source => model(%t, views => $same->([ 'a', 'b' ])), target => model(%t, views => $same->([ 'a', 'b' ])),
  )->has_changes, 'the same query and the same column list are no difference';

  $diff = DBIO::Oracle::Diff->new(
    source => model(%t, views => $same->([ 'a', 'b' ])), target => model(%t, views => $same->([ 'a', 'c' ])),
  );
  is_deeply stmts($diff), [ qq{CREATE OR REPLACE VIEW "v" ("a", "c") AS $Q} ],
    'only the column list changed: the view is replaced';

  $diff = DBIO::Oracle::Diff->new(
    source => model(%t, views => $same->([ 'a', 'b' ])), target => model(%t, views => $same->([ 'b', 'a' ])),
  );
  ok $diff->has_changes, '... the order of the names counts too';

  $diff = DBIO::Oracle::Diff->new(
    source => model(%t, views => $same->([ 'a', 'b' ])), target => model(%t, views => $same->(undef)),
  );
  ok !$diff->has_changes, 'a model without a column list (written by hand) is compared by its query only';
}

# --- refusals ---------------------------------------------------------------
{
  my $err = do { local $@; eval { DBIO::Oracle::Diff->new(
    source => model(tables => { tbl('base') }, columns => { base => [ col('id') ] }),
    target => model(tables => { tbl('base'), vw('v') },
                    columns => { base => [ col('id') ], v => [ col('id') ] }),
  )->operations; 1 } ? '' : $@ };
  like $err, qr/view v.*definition/s, 'a new view the model has no definition for is refused, naming it';

  # a view both models have needs its text on both sides (karr k65): the diff
  # neither guesses nor replaces it every time
  my %t = (tables => { tbl('base'), vw('v') }, columns => { base => [ col('id') ], v => [ col('id') ] });
  for my $case (
    [ 'unset',  {} ],
    [ 'undef',  { view(v => undef) } ],
    [ 'empty',  { view(v => '') } ],
  ) {
    my ($what, $views) = @$case;
    $err = do { local $@; eval { DBIO::Oracle::Diff->new(
      source => model(%t, views => $views),
      target => model(%t, views => { view(v => $DEF) }),
    )->operations; 1 } ? '' : $@ };
    like $err, qr/view v\b.*source.*definition/s, "a view with its text $what in the source model is refused, naming it";

    $err = do { local $@; eval { DBIO::Oracle::Diff->new(
      source => model(%t, views => { view(v => $DEF) }),
      target => model(%t, views => $views),
    )->operations; 1 } ? '' : $@ };
    like $err, qr/view v\b.*definition/s, "... and with its text $what in the target model";
  }

  my $diff = DBIO::Oracle::Diff->new(
    source => model(%t, views => {}),
    target => model(tables => { tbl('base') }, columns => { base => [ col('id') ] }),
  );
  is_deeply stmts($diff), [ q{DROP VIEW "v"} ], 'a view that is only dropped needs no text';

  $err = do { local $@; eval { DBIO::Oracle::Diff->new(
    source => model(tables => { tbl('x') }, columns => { x => [ col('id') ] }),
    target => model(tables => { vw('x') }, columns => { x => [ col('id') ] },
                    views => { view(x => $DEF) }),
  )->operations; 1 } ? '' : $@ };
  like $err, qr/x.*table.*view/s, 'a table that became a view is still refused';
}

# --- a view of another schema ------------------------------------------------
{
  my $diff = DBIO::Oracle::Diff->new(
    source => model(),
    target => model(tables => { 'OWNX.v' => { table_name => 'v', kind => 'view', schema => 'OWNX' } },
                    columns => { 'OWNX.v' => [ col('id') ] },
                    views => { view('OWNX.v' => q{SELECT 1 AS "id" FROM DUAL}) }),
  );
  is_deeply stmts($diff), [ q{CREATE OR REPLACE VIEW "OWNX"."v" AS SELECT 1 AS "id" FROM DUAL} ],
    'a view of another schema is written qualified';
}

# --- a view on a view (karr k65): the order is that of the dependency ----------
{
  my %t  = (tables => { tbl('base'), vw('a_top'), vw('b_mid'), vw('c_low') },
            columns => { base => [ col('id') ], a_top => [ col('id') ], b_mid => [ col('id') ], c_low => [ col('id') ] });
  my %vw = (
    a_top => { view_name => 'a_top', definition => q{SELECT "id" FROM "b_mid"}, depends_on => ['b_mid'] },
    b_mid => { view_name => 'b_mid', definition => q{SELECT "id" FROM "c_low"}, depends_on => ['c_low'] },
    c_low => { view_name => 'c_low', definition => q{SELECT "id" FROM "base"},  depends_on => [] },
  );
  my $names = sub { [ map { $_->view_name } @{ $_[0] } ] };

  my $diff = DBIO::Oracle::Diff->new(
    source => model(tables => { tbl('base') }, columns => { base => [ col('id') ] }),
    target => model(%t, views => \%vw),
  );
  is_deeply $names->([ grep { $_->isa('DBIO::Oracle::Diff::View') } @{ $diff->operations } ]),
    [ qw(c_low b_mid a_top) ],
    'new views are created in the order of their dependency, not of their names';

  $diff = DBIO::Oracle::Diff->new(
    source => model(%t, views => \%vw),
    target => model(tables => { tbl('base') }, columns => { base => [ col('id') ] }),
  );
  is_deeply $names->([ grep { $_->isa('DBIO::Oracle::Diff::View') } @{ $diff->operations } ]),
    [ qw(a_top b_mid c_low) ],
    'gone views are dropped dependents first';

  # the target decides the order of a replace: only edges between written views count
  my %src = (%vw, c_low => { %{ $vw{c_low} }, definition => q{SELECT "id" FROM "base" WHERE 1 = 1} });
  $diff = DBIO::Oracle::Diff->new(
    source => model(%t, views => \%src),
    target => model(%t, views => { %vw, a_top => { %{ $vw{a_top} }, definition => q{SELECT "id" FROM "b_mid" WHERE 1 = 1} } }),
  );
  is_deeply $names->([ grep { $_->isa('DBIO::Oracle::Diff::View') } @{ $diff->operations } ]),
    [ qw(a_top c_low) ],
    'changed views: a view that rests on one not written needs no edge';

  my $cyc = { %vw, c_low => { %{ $vw{c_low} }, depends_on => ['a_top'] } };
  my $err = do { local $@; eval { DBIO::Oracle::Diff->new(
    source => model(tables => { tbl('base') }, columns => { base => [ col('id') ] }),
    target => model(%t, views => $cyc),
  )->operations; 1 } ? '' : $@ };
  like $err, qr/cycle.*(?=.*a_top)(?=.*b_mid)(?=.*c_low)/s, 'a cycle of views is refused, naming them, before any statement';

  $err = do { local $@; eval { DBIO::Oracle::Diff->new(
    source => model(%t, views => $cyc),
    target => model(tables => { tbl('base') }, columns => { base => [ col('id') ] }),
  )->operations; 1 } ? '' : $@ };
  like $err, qr/cycle.*(?=.*a_top)(?=.*b_mid)(?=.*c_low)/s, '... also when the views are dropped';
}

# --- a view of another schema it rests on -------------------------------------
{
  my $diff = DBIO::Oracle::Diff->new(
    source => model(),
    target => model(
      tables  => { 'A.v' => { table_name => 'v', kind => 'view', schema => 'A' }, 'B.w' => { table_name => 'w', kind => 'view', schema => 'B' } },
      columns => { 'A.v' => [ col('id') ], 'B.w' => [ col('id') ] },
      views   => {
        'A.v' => { view_name => 'A.v', definition => q{SELECT 1 AS "id" FROM "B"."w"}, depends_on => ['B.w'] },
        'B.w' => { view_name => 'B.w', definition => q{SELECT 1 AS "id" FROM DUAL},    depends_on => [] },
      }),
  );
  is_deeply [ map { $_->view_name } @{ $diff->operations } ], [ 'B.w', 'A.v' ],
    'a view rests on a view of another schema: that one is created first';
}

done_testing;
