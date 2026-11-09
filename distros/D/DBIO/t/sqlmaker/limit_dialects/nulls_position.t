use strict;
use warnings;

use Test::More;
use DBIO::Test ':DiffSQL';

# order_by => { -desc => $col, -nulls => 'last' } renders "col DESC NULLS LAST".
# Every limit dialect that takes the ORDER BY apart (and puts it back in
# another place, reversed or aliased) has to carry the NULLS position along:
# in the right block, with the direction it has there.

my $schema = DBIO::Test->init_schema(no_deploy => 1);
my $storage = $schema->storage;

my $C = join ', ', map { qq{"me"."$_"} } qw(cdid artist title year genreid single_track);

# each dialect is exercised through a sql maker whose apply_limit is that dialect
sub query_for {
  my ($dialect, $order, $rows, $offset) = @_;

  my $class = "NullsProbe::$dialect";
  {
    no strict 'refs';
    unless (@{"${class}::ISA"}) {
      @{"${class}::ISA"} = ('DBIO::SQLMaker');
      my $method = "_$dialect";
      *{"${class}::apply_limit"} = sub { shift->$method(@_) };
    }
  }
  $storage->sql_maker_class($class);
  delete $storage->{_sql_maker};

  my $q = $schema->resultset('CD')->search({}, {
    order_by => $order,
    rows => $rows,
    ($offset ? (offset => $offset) : ()),
  })->as_query;

  my ($sql, @bind) = @$$q;
  return ($sql, [ map { ref $_ ? $_->[1] : $_ } @bind ]);
}

my $desc_last = [ { -desc => 'me.title', -nulls => 'last' }, 'me.cdid' ];
my $asc_first = [ { -asc => 'me.title', -nulls => 'first' }, 'me.cdid' ];

# rows 5, offset 2 for $desc_last; rows 5, no offset for $asc_first
my %expected = (

  RowNumberOver => [
    [ $desc_last, 2, qq{( SELECT $C FROM ( SELECT $C, ROW_NUMBER() OVER( ORDER BY "me"."title" DESC NULLS LAST, "me"."cdid" ) AS "rno__row__index" FROM ( SELECT $C FROM cd "me" ) "me" ) "me" WHERE "rno__row__index" >= ? AND "rno__row__index" <= ? )}, [ 3, 7 ] ],
    [ $asc_first, 0, qq{( SELECT $C FROM ( SELECT $C, ROW_NUMBER() OVER( ORDER BY "me"."title" ASC NULLS FIRST, "me"."cdid" ) AS "rno__row__index" FROM ( SELECT $C FROM cd "me" ) "me" ) "me" WHERE "rno__row__index" >= ? AND "rno__row__index" <= ? )}, [ 1, 5 ] ],
  ],

  # inner order as given, middle order reversed (direction AND NULLS position), outer as given
  Top => [
    [ $desc_last, 2, qq{(SELECT $C FROM ( SELECT TOP 5 $C FROM ( SELECT TOP 7 $C FROM cd "me" ORDER BY "me"."title" DESC NULLS LAST, "me"."cdid" ) "me" ORDER BY "me"."title" ASC NULLS FIRST, "me"."cdid" DESC ) "me" ORDER BY "me"."title" DESC NULLS LAST, "me"."cdid")}, [] ],
    [ $asc_first, 0, qq{(SELECT TOP 5 $C FROM cd "me" ORDER BY "me"."title" ASC NULLS FIRST, "me"."cdid")}, [] ],
  ],

  FetchFirst => [
    [ $desc_last, 2, qq{(SELECT $C FROM ( SELECT $C FROM ( SELECT $C FROM cd "me" ORDER BY "me"."title" DESC NULLS LAST, "me"."cdid" FETCH FIRST 7 ROWS ONLY ) "me" ORDER BY "me"."title" ASC NULLS FIRST, "me"."cdid" DESC FETCH FIRST 5 ROWS ONLY ) "me" ORDER BY "me"."title" DESC NULLS LAST, "me"."cdid")}, [] ],
    [ $asc_first, 0, qq{(SELECT $C FROM cd "me" ORDER BY "me"."title" ASC NULLS FIRST, "me"."cdid" FETCH FIRST 5 ROWS ONLY)}, [] ],
  ],

  RowNum => [
    [ $desc_last, 2, qq{(SELECT $C FROM ( SELECT $C, ROWNUM AS "rownum__index" FROM ( SELECT $C FROM cd "me" ORDER BY "me"."title" DESC NULLS LAST, "me"."cdid" ) "me" WHERE ROWNUM <= ? ) "me" WHERE "rownum__index" >= ? )}, [ 7, 3 ] ],
    [ $asc_first, 0, qq{(SELECT $C FROM ( SELECT $C FROM cd "me" ORDER BY "me"."title" ASC NULLS FIRST, "me"."cdid" ) "me" WHERE ROWNUM <= ? )}, [ 5 ] ],
  ],

  # title is not nullable: the comparison stays plain, the NULLS position goes
  # into the ORDER BY of the emulation
  GenericSubQ => [
    [ $desc_last, 2, qq{( SELECT $C FROM ( SELECT $C FROM cd "me" ) "me" WHERE ( SELECT COUNT(*) FROM cd "rownum__emulation" WHERE ( ( "rownum__emulation"."title" > "me"."title" OR ( "me"."title" = "rownum__emulation"."title" AND "rownum__emulation"."cdid" < "me"."cdid" ) ) ) ) BETWEEN ? AND ? ORDER BY "me"."title" DESC NULLS LAST, "me"."cdid" ASC )}, [ 2, 6 ] ],
    [ $asc_first, 0, qq{( SELECT $C FROM ( SELECT $C FROM cd "me" ) "me" WHERE ( SELECT COUNT(*) FROM cd "rownum__emulation" WHERE ( ( "rownum__emulation"."title" < "me"."title" OR ( "me"."title" = "rownum__emulation"."title" AND "rownum__emulation"."cdid" < "me"."cdid" ) ) ) ) < ? ORDER BY "me"."title" ASC NULLS FIRST, "me"."cdid" ASC )}, [ 5 ] ],
  ],

  SkipFirst => [
    [ $desc_last, 2, qq{(SELECT SKIP ? FIRST ? $C FROM cd "me" ORDER BY "me"."title" DESC NULLS LAST, "me"."cdid")}, [ 2, 5 ] ],
    [ $asc_first, 0, qq{(SELECT FIRST ? $C FROM cd "me" ORDER BY "me"."title" ASC NULLS FIRST, "me"."cdid")}, [ 5 ] ],
  ],

  FirstSkip => [
    [ $desc_last, 2, qq{(SELECT FIRST ? SKIP ? $C FROM cd "me" ORDER BY "me"."title" DESC NULLS LAST, "me"."cdid")}, [ 5, 2 ] ],
    [ $asc_first, 0, qq{(SELECT FIRST ? $C FROM cd "me" ORDER BY "me"."title" ASC NULLS FIRST, "me"."cdid")}, [ 5 ] ],
  ],
);

for my $dialect (sort keys %expected) {
  for my $case (@{ $expected{$dialect} }) {
    my ($order, $offset, $want_sql, $want_bind) = @$case;
    my $label = "$dialect, " . ($offset ? 'with' : 'without') . ' offset';

    my ($sql, $bind) = eval { query_for($dialect, $order, 5, $offset) };
    if ($@) {
      fail("$label: $@");
      next;
    }
    is_same_sql($sql, $want_sql, "$label: NULLS position in the right block");
    is_deeply($bind, $want_bind, "$label: bind values");
  }
}

# GenericSubQ on a nullable column: an explicit NULLS position decides which
# side of the comparison counts as "before"; the default stays ASC = NULLs
# first, DESC = NULLs last.
{
  my $cmp = sub {
    my ($dir_op, $null_side) = @_;
    my ($main_null, $sub_null) = $null_side eq 'main'
      ? ('"me"."genreid" IS NULL AND "rownum__emulation"."genreid" IS NOT NULL')
      : ('"me"."genreid" IS NOT NULL AND "rownum__emulation"."genreid" IS NULL');
    return qq{( SELECT $C FROM ( SELECT $C FROM cd "me" ) "me" WHERE ( SELECT COUNT(*) FROM cd "rownum__emulation" WHERE ( ( ( ( $main_null ) OR ( "rownum__emulation"."genreid" $dir_op "me"."genreid" AND "me"."genreid" IS NOT NULL AND "rownum__emulation"."genreid" IS NOT NULL ) ) OR ( ( "me"."genreid" = "rownum__emulation"."genreid" OR ( "me"."genreid" IS NULL AND "rownum__emulation"."genreid" IS NULL ) ) AND "rownum__emulation"."cdid" < "me"."cdid" ) ) ) ) BETWEEN ? AND ? ORDER BY };
  };

  my @cases = (
    # order, want comparison, ORDER BY tail
    [ [ { -desc => 'me.genreid', -nulls => 'last' }, 'me.cdid' ],  $cmp->('>', 'main'), '"me"."genreid" DESC NULLS LAST, "me"."cdid" ASC )' ],
    [ [ { -desc => 'me.genreid', -nulls => 'first' }, 'me.cdid' ], $cmp->('>', 'sub'),  '"me"."genreid" DESC NULLS FIRST, "me"."cdid" ASC )' ],
    [ [ { -asc => 'me.genreid', -nulls => 'last' }, 'me.cdid' ],   $cmp->('<', 'main'), '"me"."genreid" ASC NULLS LAST, "me"."cdid" ASC )' ],
    [ [ { -asc => 'me.genreid', -nulls => 'first' }, 'me.cdid' ],  $cmp->('<', 'sub'),  '"me"."genreid" ASC NULLS FIRST, "me"."cdid" ASC )' ],
    [ [ { -asc => 'me.genreid' }, 'me.cdid' ],                     $cmp->('<', 'sub'),  '"me"."genreid" ASC, "me"."cdid" ASC )' ],
    [ [ { -desc => 'me.genreid' }, 'me.cdid' ],                    $cmp->('>', 'main'), '"me"."genreid" DESC, "me"."cdid" ASC )' ],
  );

  for my $case (@cases) {
    my ($order, $head, $tail) = @$case;
    my ($sql) = query_for('GenericSubQ', $order, 5, 2);
    is_same_sql($sql, $head . $tail, 'GenericSubQ nullable: ' . $tail);
  }
}

done_testing;
