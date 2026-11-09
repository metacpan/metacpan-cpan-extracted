use strict;
use warnings;

use Test::More;
use Test::Exception;
use Scalar::Util qw(blessed refaddr);
use DBIO::Test;

# ADR 0034, write path. A plain hashref given as the value of a to-one
# relationship is the column values of the related row: it is reduced to this
# row's own columns (the foreign key) or refused -- whichever accessor type the
# relationship has -- and it is never handed on as if it were the related
# object. Nothing is looked up, created or changed in the related table for it.
#
# The two accessor types took two different wrong turns before (karr k287): a
# 'filter' relationship sent the hashref into the accessor's deflator, which
# died in perl ("Can't call method "isa" on unblessed reference"); a 'single'
# one resolved it and then cached the hashref as the related object, so the
# accessor returned a hashref and cascade_update called ->update on it.

my $schema  = DBIO::Test->init_schema;
my $storage = $schema->storage;
my $cd_rs   = $schema->resultset('CD');

my %related_row = (
  Artist => [ 7, 'seven', 13, undef ],
  Genre  => [ 7, 'seven' ],
);

# CD->artist and CD->very_long_artist_relationship are the same foreign key
# under the two accessor types; CD->genre is a second 'single' one.
my @cases = (
  { rel => 'artist',                        accessor => 'filter', fk => 'artist',  source => 'Artist', key => 'artistid' },
  { rel => 'very_long_artist_relationship', accessor => 'single', fk => 'artist',  source => 'Artist', key => 'artistid' },
  { rel => 'genre',                         accessor => 'single', fk => 'genreid', source => 'Genre',  key => 'genreid'  },
);

sub new_cd {
  $cd_rs->new_result({ cdid => 1, artist => 1, genreid => 1, title => 'Spoonful', year => 1999 });
}

sub stored_cd {
  $cd_rs->result_class->inflate_result($cd_rs->result_source, {
    cdid => 1, artist => 1, genreid => 1, title => 'Spoonful', year => 1999,
  });
}

sub related_row {
  my ($source, $id) = @_;
  my $rsrc = $schema->source($source);
  my ($pk) = $rsrc->primary_columns;
  return $rsrc->result_class->inflate_result($rsrc, { $pk => $id, name => "row $id" });
}

# What the row holds for the relationship, in either slot an accessor reads.
# Looks without touching: an entry that springs into existence here would be
# what the 'single' accessor returns from then on.
sub cached_for {
  my ($row, $rel) = @_;
  return map { exists $row->{$_}{$rel} ? $row->{$_}{$rel} : () }
    grep { $row->{$_} } qw(_relationship_data _inflated_column);
}

# The accessor fetches: answer the lookup with the row for key 7 and report what
# came back together with the statements it took.
sub fetch_through_accessor {
  my ($row, $case) = @_;
  my $table = $schema->source($case->{source})->name;
  $storage->reset_captured;
  $storage->mock(qr/FROM "?\Q$table\E"?/, [ $related_row{ $case->{source} } ]);
  my $got = $row->${\ $case->{rel} };
  my @selects = grep { $_->{op} eq 'select' } $storage->captured_queries;
  $storage->clear_mocks;
  return ($got, @selects);
}

sub is_related_row_seven {
  my ($row, $case, $what) = @_;

  is_deeply [ map { ref } grep { ! blessed $_ } cached_for($row, $case->{rel}) ], [],
    "$what: no unblessed value is kept as the related object";

  my ($got, @selects) = fetch_through_accessor($row, $case);
  ok blessed $got && $got->isa("DBIO::Test::Schema::$case->{source}"),
    "$what: the accessor returns a $case->{source} row"
      or diag 'got: ' . (defined $got ? (ref $got || $got) : 'undef');
  is eval { $got->get_column($case->{key}) }, 7,
    "$what: ... the one the new key points at";
  is_deeply [ map { $_->[1] } map { @{ $_->{bind} } } @selects ], [ 7 ],
    "$what: ... looked up by that key";
}

for my $case (@cases) {
  my ($rel, $fk, $key) = @{$case}{qw(rel fk key)};

  subtest "$case->{accessor} accessor ($rel)" => sub {
    is $cd_rs->result_source->relationship_info($rel)->{attrs}{accessor}, $case->{accessor},
      "fixture: $rel is a '$case->{accessor}' relationship";

    # --- set_inflated_columns, the hashref carries the key -------------------
    {
      my $cd = new_cd();
      lives_ok { $cd->set_inflated_columns({ $rel => { $key => 7 } }) }
        'set_inflated_columns takes a hashref carrying the related key';
      is $cd->get_column($fk), 7, 'the foreign key is set from it';
      is_related_row_seven($cd, $case, 'set_inflated_columns');
    }

    # --- set_inflated_columns, the hashref does not pin the key --------------
    {
      my $cd = new_cd();
      throws_ok { $cd->set_inflated_columns({ $rel => { name => 'no key in here' } }) }
        qr/Relationship '\Q$rel\E' does not resolve to a concrete column condition/,
        'set_inflated_columns refuses a hashref that does not resolve to the foreign key';
      is $cd->get_column($fk), 1, 'the foreign key is left as it was';
    }

    # --- update(), the hashref carries the key --------------------------------
    {
      my $cd = stored_cd();
      $storage->reset_captured;
      lives_ok { $cd->update({ $rel => { $key => 7 } }) }
        'update takes a hashref carrying the related key';

      my @written = grep { $_->{op} =~ /^(?:insert|update|delete|select)$/ } $storage->captured_queries;
      is scalar @written, 1, 'update sends one statement'
        or diag join "\n", map { $_->{sql} } @written;
      like $written[0]{sql}, qr/^UPDATE "?cd"? SET "?\Q$fk\E"? = \? WHERE "?cdid"? = \?$/,
        '... the UPDATE of the foreign key on this row -- nothing is created or looked up';
      is_deeply [ map { $_->[1] } @{ $written[0]{bind} } ], [ 7, 1 ],
        '... with the key from the hashref';

      is_related_row_seven($cd, $case, 'update');
    }

    # --- update(), the hashref does not pin the key ---------------------------
    {
      my $cd = stored_cd();
      $storage->reset_captured;
      throws_ok { $cd->update({ $rel => { name => 'no key in here' } }) }
        qr/Relationship '\Q$rel\E' does not resolve to a concrete column condition/,
        'update refuses a hashref that does not resolve to the foreign key';
      is_deeply [ grep { $_->{op} =~ /^(?:insert|update|delete)$/ } $storage->captured_queries ], [],
        '... and writes nothing';
      is $cd->get_column($fk), 1, 'the foreign key is left as it was';
    }

    # --- a related object the row held does not outlive the key change -------
    {
      my $cd  = stored_cd();
      my $old = related_row($case->{source}, 1);
      $cd->$rel($old);
      is refaddr($cd->$rel), refaddr($old), 'fixture: the row holds the related object for key 1';

      lives_ok { $cd->set_inflated_columns({ $rel => { $key => 7 } }) }
        'a hashref is taken on a row that holds a related object';
      is $cd->get_column($fk), 7, '... and moves the foreign key on';
      is_related_row_seven($cd, $case, 'after a held related object');
    }

    # --- counter-probe: a related object is taken and kept as before ---------
    {
      my $cd  = new_cd();
      my $obj = related_row($case->{source}, 9);
      $cd->set_inflated_columns({ $rel => $obj });
      is $cd->get_column($fk), 9, 'a related object still gives its key';

      $storage->reset_captured;
      is refaddr($cd->$rel), refaddr($obj), '... and is what the accessor returns';
      is_deeply [ $storage->captured_queries ], [], '... without a lookup';
    }

    # --- counter-probe: undef still dissolves the relationship ---------------
    {
      my $cd = new_cd();
      $cd->set_inflated_columns({ $rel => undef });
      is $cd->get_column($fk), undef, 'undef still nulls the foreign key';

      $storage->reset_captured;
      is $cd->$rel, undef, '... and the accessor returns undef';
      is_deeply [ $storage->captured_queries ], [], '... without a lookup';
    }
  };
}

# --- cascade_update never meets the hashref -----------------------------------
# CascadeActions::update calls ->update on whatever a touched 'single' accessor
# of a cascade_update relationship (has_one / might_have) returns.
for my $cascade (
  [ artwork           => { cd_id    => 1 } ],
  [ mandatory_artwork => { cd_id    => 1 } ],
  [ liner_notes       => { liner_id => 1 } ],
) {
  my ($rel, $values) = @$cascade;

  my $info = $cd_rs->result_source->relationship_info($rel);
  ok $info->{attrs}{cascade_update} && $info->{attrs}{accessor} eq 'single',
    "fixture: $rel is a 'single' relationship with cascade_update";

  my $cd = stored_cd();
  $storage->reset_captured;
  lives_ok { $cd->update({ title => 'Renamed', $rel => $values }) }
    "update with a hashref for $rel does not cascade into the hashref";

  is_deeply [ map { $_->{sql} } grep { $_->{op} =~ /^(?:insert|update|delete)$/ } $storage->captured_queries ],
    [ 'UPDATE cd SET "title" = ? WHERE "cdid" = ?' ],
    '... it updates this row, and nothing in the related table';
  is_deeply [ map { ref } grep { ! blessed $_ } cached_for($cd, $rel) ], [],
    '... and keeps no unblessed value as the related object';
}

# --- insert sees no phantom related entry --------------------------------------
# insert() opens a transaction when the row holds related entries to write after
# itself; a hashref left in the slot counted as one.
{
  my $cd = new_cd();
  $cd->set_inflated_columns({ genre => { genreid => 7 } });

  $storage->reset_captured;
  $cd->insert;
  is_deeply [ map { $_->{op} } $storage->captured_queries ], [ 'insert' ],
    'a row given a hashref for a relationship inserts as the one INSERT it is';
}

# --- the accessors called directly ----------------------------------------------
# The 'single' accessor hands its argument to set_from_related, so it resolves a
# hashref like set_inflated_columns does -- and must not keep it either.
{
  my $cd = new_cd();
  lives_ok { $cd->genre({ genreid => 7 }) } "the 'single' accessor takes a hashref carrying the related key";
  is $cd->get_column('genreid'), 7, 'the foreign key is set from it';
  is_related_row_seven($cd, $cases[2], "'single' accessor");
}

# The 'filter' accessor is a column inflator: its deflator takes a related row
# and nothing else. Anything else is refused by DBIO, not by perl. (Whether this
# accessor should resolve a hashref the way the 'single' one does is not decided
# here; what is pinned is that it is no perl-level error.)
for my $not_a_row ( { artistid => 7 }, [ 7 ] ) {
  my $what = ref $not_a_row;
  for my $via (
    [ "the 'filter' accessor"  => sub { $_[0]->artist($not_a_row) } ],
    [ 'set_inflated_column'    => sub { $_[0]->set_inflated_column(artist => $not_a_row) } ],
  ) {
    my ($name, $code) = @$via;
    my $cd = new_cd();
    throws_ok { $code->($cd) } 'DBIO::Exception',
      "$name refuses an unblessed $what with a DBIO exception";
    like $@, qr/isn't a DBIO::Test::Schema::Artist/, '... naming the class it takes';
    is $cd->get_column('artist'), 1, '... and leaves the foreign key as it was';
  }
}

done_testing;
