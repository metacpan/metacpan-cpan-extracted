use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test;

# ADR 0071: mass assignment is checked where the caller's values enter. What
# ends up in the columns is what is checked: a value the caller passes (as a
# column, or through a relationship value that resolves to foreign key
# columns) may not contradict an equality of the resultset's condition, and may
# not name a column or a relationship marked is_guarded. Values inherited from
# the condition are no assignment of the caller's.
#
# Everything runs on the mock storage -- no real DB.
#   Artist: artistid, name, rank, charfield
#   CD:     cdid, artist, title, year, genreid, single_track

# one schema per scenario: a column or relationship marked is_guarded changes
# the (cloned) source of that schema only
sub fresh {
  my ($guard_cols, $guard_rels) = @_;
  my $schema = DBIO::Test->init_schema(no_deploy => 1);

  for my $spec (map { [ split /\./ ] } @{ $guard_cols || [] }) {
    my ($source, $col) = @$spec;
    my $rsrc = $schema->source($source);
    $rsrc->add_columns($col => { %{ $rsrc->column_info($col) }, is_guarded => 1 });
  }

  for my $spec (map { [ split /\./ ] } @{ $guard_rels || [] }) {
    my ($source, $rel) = @$spec;
    my $rsrc = $schema->source($source);
    my $info = $rsrc->relationship_info($rel);
    $rsrc->add_relationship(
      $rel, $info->{source}, $info->{cond}, { %{ $info->{attrs} }, is_guarded => 1 },
    );
  }

  return $schema;
}

# the text of a refused create names the column, never a value (ADR 0071)
sub values_absent {
  my $text = "$@";
  unlike $text, qr/\b\Q$_\E\b/, "the text holds no $_" for @_;
}

sub ops {
  my ($schema, $op, $table) = @_;
  return grep {
    $_->{op} eq $op and $_->{sql} =~ /\b(?:FROM|INTO|UPDATE)\s+"?\Q$table\E"?/i
  } $schema->storage->captured_queries;
}

sub fresh_storage {
  my ($schema) = @_;
  $schema->storage->clear_mocks;
  $schema->storage->reset_captured;
}

sub mock_artist { $_[0]->storage->mock_persistent(qr/FROM "artist"/i, [[ 7, 'Seven', 13, undef ]]) }
sub mock_cd     { $_[0]->storage->mock_persistent(qr/FROM "?cd"? "?me"?/i, [[ 1, 7, 'Old', '1999', undef, undef ]]) }

my $cd_new = { title => 'new cd', year => 2000 };

# --- 1. a value of the caller against an equality of the condition -----------
{
  my $schema = fresh();
  fresh_storage($schema);
  my $scoped = $schema->resultset('CD')->search({ artist => 7 });

  throws_ok { $scoped->new_result({ %$cd_new, artist => 999 }) }
    qr/create on a scoped resultset: 'artist' is fixed to a value by the condition, got another value/,
    'new_result: a value against the condition throws';
  values_absent(7, 999);

  throws_ok { $scoped->create({ %$cd_new, artist => 999 }) }
    qr/'artist' is fixed to a value by the condition, got another value/,
    'create: a value against the condition throws';
  values_absent(7, 999);
  is scalar(ops($schema, insert => 'cd')), 0, 'nothing was inserted';

  throws_ok { $scoped->create({ %$cd_new, artist => undef }) }
    qr/'artist' is fixed to a value by the condition, got NULL/,
    'undef contradicts a defined value of the condition';
  values_absent(7);

  throws_ok { $scoped->create({ %$cd_new, 'me.artist' => 999 }) }
    qr/'artist' is fixed to a value/,
    'the alias-qualified key is checked as well';
  values_absent(7);

  lives_ok { $scoped->create({ %$cd_new, artist => 7 }) }
    'create: the same value is allowed';
  my ($ins) = ops($schema, insert => 'cd');
  ok $ins && grep({ defined $_ && $_ eq '7' } map { ref $_ eq 'ARRAY' ? $_->[1] : $_ } @{ $ins->{bind} }), 'the row went in with the value of the condition'
    or diag explain [ $schema->storage->captured_queries ];

  fresh_storage($schema);
  lives_ok { $scoped->create($cd_new) } 'create without the scoped column runs';
  ($ins) = ops($schema, insert => 'cd');
  ok $ins && grep({ defined $_ && $_ eq '7' } map { ref $_ eq 'ARRAY' ? $_->[1] : $_ } @{ $ins->{bind} }),
    'the scoped column is inherited from the condition';
}

# --- 2. NULL ------------------------------------------------------------------
{
  my $schema = fresh();
  fresh_storage($schema);
  my $null_scope = $schema->resultset('CD')->search({ genreid => undef });

  lives_ok { $null_scope->create({ %$cd_new, artist => 1, genreid => undef }) }
    'condition IS NULL: undef is the same value';

  throws_ok { $null_scope->create({ %$cd_new, artist => 1, genreid => 3 }) }
    qr/'genreid' is fixed to NULL by the condition, got a value/,
    'condition IS NULL: a defined value contradicts';
  values_absent(3);
}

# --- 3. through the related object --------------------------------------------
{
  my $schema = fresh();
  fresh_storage($schema);
  mock_artist($schema);
  my $artist = $schema->resultset('Artist')->find(7);
  isa_ok $artist, 'DBIO::Row', 'an artist in storage';

  throws_ok { $artist->create_related('cds', { %$cd_new, artist => 999 }) }
    qr/'artist' is fixed to a value by the condition, got another value/,
    'create_related: the foreign key against the parent throws';
  values_absent(7, 999);

  throws_ok { $artist->new_related('cds', { %$cd_new, artist => 999 }) }
    qr/'artist' is fixed to a value by the condition, got another value/,
    'new_related: the foreign key against the parent throws';
  values_absent(7, 999);

  throws_ok { $artist->cds->create({ %$cd_new, artist => 999 }) }
    qr/'artist' is fixed to a value by the condition, got another value/,
    'create on the related resultset throws';
  values_absent(7, 999);

  lives_ok { $artist->new_related('cds', { %$cd_new, artist => 7 }) }
    'new_related: the same foreign key is allowed';

  fresh_storage($schema);
  lives_ok { $artist->create_related('cds', $cd_new) } 'create_related without the foreign key runs';
  my ($ins) = ops($schema, insert => 'cd');
  ok $ins && grep({ defined $_ && $_ eq '7' } map { ref $_ eq 'ARRAY' ? $_->[1] : $_ } @{ $ins->{bind} }),
    'the foreign key comes from the parent';

  # a not yet stored parent: the foreign key is the value of its column
  my $new_artist = $schema->resultset('Artist')->new_result({ artistid => 8, name => 'Eight' });
  throws_ok { $new_artist->new_related('cds', { %$cd_new, artist => 999 }) }
    qr/'artist' is fixed to a value/,
    'new_related of an unsaved parent: the foreign key against the parent throws';
  values_absent(8);
}

# --- 4. a relationship value resolves to columns of the condition --------------
{
  my $schema = fresh();
  fresh_storage($schema);
  mock_artist($schema);
  my $artist = $schema->resultset('Artist')->find(7);
  my $scoped = $schema->resultset('CD')->search({ artist => 7 });

  # the artist the relationship hash names exists: it is found, its key is the value
  my $mock_artist = sub {
    $schema->storage->clear_mocks;
    $schema->storage->mock(qr/FROM "artist"/i, [[ $_[0], "Artist $_[0]", 13, undef ]]);
  };

  $mock_artist->(5);
  throws_ok {
    $scoped->create({ %$cd_new, very_long_artist_relationship => { artistid => 5 } })
  } qr/'artist' is fixed to a value by the condition, got another value/,
    'a relationship named differently from the foreign key does not override the condition';
  values_absent(7, 5);

  $mock_artist->(5);
  throws_ok {
    $scoped->create({ %$cd_new, artist => { artistid => 5 } })
  } qr/'artist' is fixed to a value by the condition, got another value/,
    'a relationship named like the foreign key does not override it either';
  values_absent(7, 5);

  $mock_artist->(7);
  lives_ok {
    $scoped->create({ %$cd_new, very_long_artist_relationship => { artistid => 7 } })
  } 'a relationship value that resolves to the value of the condition is allowed';

  $schema->storage->reset_captured;
  throws_ok {
    $schema->resultset('CD')->search({ artist => 8 })->create({ %$cd_new, very_long_artist_relationship => $artist })
  } qr/'artist' is fixed to a value by the condition, got another value/,
    'a related object resolves to its key and is checked';
  values_absent(8, 7);
  is scalar(ops($schema, insert => 'cd')), 0, 'no cd was inserted';
}

# a related row that is created first: the foreign key is known when it is set
{
  my $schema = fresh();
  fresh_storage($schema);
  my $scoped = $schema->resultset('CD')->search({ artist => 7 });

  throws_ok {
    $scoped->create({ %$cd_new, very_long_artist_relationship => { name => 'Fresh', artistid => 5 } })
  } qr/'artist' is fixed to a value by the condition, got another value/,
    'a related row created along: its key is checked when it is set';
  values_absent(7, 5);
  ok !ops($schema, insert => 'cd'), 'the cd was not inserted';
}

# --- 5. populate in void context ----------------------------------------------
{
  my $schema = fresh();
  fresh_storage($schema);
  my $scoped = $schema->resultset('CD')->search({ artist => 7 });

  throws_ok {
    $scoped->populate([ { %$cd_new, artist => 7 }, { %$cd_new, artist => 999 } ]);
    1;
  } qr/'artist' is fixed to a value by the condition, got another value/,
    'populate (void): a value against the condition throws';
  values_absent(7, 999);
  is scalar(ops($schema, insert => 'cd')), 0, 'nothing was inserted';

  throws_ok {
    $scoped->populate([ [qw(title year artist)], [ 't', 2000, 999 ] ]);
    1;
  } qr/'artist' is fixed to a value by the condition, got another value/,
    'populate (void, column list): a value against the condition throws';
  values_absent(7, 999);

  throws_ok {
    $scoped->populate([ { %$cd_new, artist => 7 }, { %$cd_new } ]);
    1;
  } qr/'artist' is fixed to a value by the condition, got NULL/,
    'populate (void): a row without the column leaves NULL where the condition says 7';
  values_absent(7);

  lives_ok {
    $scoped->populate([ { %$cd_new, artist => 7 }, { %$cd_new, artist => 7 } ]);
    1;
  } 'populate (void): the same value is allowed';

  throws_ok {
    my @rows = $scoped->populate([ { %$cd_new, artist => 999 } ]);
  } qr/'artist' is fixed to a value by the condition, got another value/,
    'populate (list context): a value against the condition throws';
  values_absent(7, 999);
}

# --- 6. update_or_create / update_or_new: found row ---------------------------
{
  my $schema = fresh();
  fresh_storage($schema);
  mock_cd($schema);
  my $scoped = $schema->resultset('CD')->search({ artist => 7 });

  throws_ok {
    $scoped->update_or_create({ cdid => 1, artist => 999, title => 'x', year => 2000 }, { key => 'primary' })
  } qr/'artist' is fixed to a value by the condition, got another value/,
    'update_or_create: a value against the condition throws, found or not';
  values_absent(7, 999);
  is scalar(ops($schema, update => 'cd')), 0, 'the found row was not updated';

  throws_ok {
    $scoped->update_or_new({ cdid => 1, artist => 999, title => 'x', year => 2000 }, { key => 'primary' })
  } qr/'artist' is fixed to a value by the condition, got another value/,
    'update_or_new: the same';
  values_absent(7, 999);

  lives_ok {
    $scoped->update_or_create({ cdid => 1, artist => 7, title => 'x', year => 2000 }, { key => 'primary' })
  } 'update_or_create: the same value is allowed';
  is scalar(ops($schema, update => 'cd')), 1, 'the found row was updated';
}

# --- 7. is_guarded on a column, in every path ----------------------------------
{
  my $schema = fresh([ 'CD.year' ]);
  fresh_storage($schema);
  my $rs = $schema->resultset('CD');
  my $guarded = qr/column 'year' of source 'CD' is guarded/i;
  my $cd_data = { artist => 7, title => 'g', year => 2000 };

  throws_ok { $rs->new_result($cd_data) } $guarded, 'new_result';
  throws_ok { $rs->create($cd_data) } $guarded, 'create';
  throws_ok { $rs->find_or_create({ cdid => 5, %$cd_data }, { key => 'primary' }) } $guarded,
    'find_or_create (not found)';
  throws_ok { $rs->update_or_create({ cdid => 5, %$cd_data }, { key => 'primary' }) } $guarded,
    'update_or_create (not found)';

  mock_cd($schema);
  throws_ok { $rs->update_or_create({ cdid => 5, %$cd_data }, { key => 'primary' }) } $guarded,
    'update_or_create (found)';
  throws_ok { $rs->update_or_new({ cdid => 5, %$cd_data }, { key => 'primary' }) } $guarded, 'update_or_new (found)';
  throws_ok { $rs->populate([ $cd_data ]); 1 } $guarded, 'populate (void)';
  throws_ok { $rs->populate([ [qw(artist title year)], [ 7, 'g', 2000 ] ]); 1 } $guarded,
    'populate (void, column list)';
  throws_ok { my @r = $rs->populate([ $cd_data ]) } $guarded, 'populate (list)';
  is scalar(ops($schema, insert => 'cd')), 0, 'nothing was inserted by any of them';

  my $cd = $rs->find(1);
  throws_ok { $cd->update({ year => 2001 }) } $guarded, 'update(\%h)';
  throws_ok { $cd->update({ title => 'ok', year => 2001 }) } $guarded,
    'update(\%h) with other columns beside it';
  is scalar(ops($schema, update => 'cd')), 0, 'nothing was updated';

  lives_ok { $cd->year(2002) } 'the accessor sets it';
  lives_ok { $cd->set_column(year => 2003) } 'set_column sets it';
  is $cd->year, 2003, 'the value is there';
  lives_ok { $cd->update } 'update without a hash writes it';
  is scalar(ops($schema, update => 'cd')), 1, 'the row was updated';

  # multi-create
  throws_ok {
    $schema->resultset('Artist')->create({ name => 'Mass', cds => [ { title => 'c', year => 1999 } ] })
  } $guarded, 'multi-create of a has_many row';

  throws_ok {
    $schema->resultset('Track')->create({ title => 't', position => 1, cd => { artist => 7, title => 'c', year => 1999 } })
  } $guarded, 'multi-create of a belongs_to row';

  # what the condition holds is not an assignment of the caller's
  fresh_storage($schema);
  lives_ok { $rs->search({ year => 2000 })->create({ artist => 7, title => 'inherited' }) }
    'a guarded column inherited from the condition is allowed';

  # the lookup of update_or_create names the row, it assigns nothing
  my $schema2 = fresh([ 'CD.cdid' ]);
  fresh_storage($schema2);
  mock_cd($schema2);
  lives_ok {
    $schema2->resultset('CD')->update_or_create({ cdid => 1, title => 'renamed' })
  } 'update_or_create: a guarded column of the lookup is not an assignment';
  is scalar(ops($schema2, update => 'cd')), 1, 'the found row was updated';
  $schema2->storage->clear_mocks;
  throws_ok {
    $schema2->resultset('CD')->update_or_create({ cdid => 99, title => 'new', year => 1, artist => 1 }, { key => 'primary' })
  } qr/column 'cdid' of source 'CD' is guarded/i,
    'update_or_create: the guarded column is an assignment on the create path';
}

# --- 8. is_guarded on a foreign key: reached through a relationship ------------
{
  my $schema = fresh([ 'CD.artist' ]);
  fresh_storage($schema);
  mock_artist($schema);
  my $rs = $schema->resultset('CD');
  my $guarded = qr/column 'artist' of source 'CD' is guarded/i;
  my $artist = $schema->resultset('Artist')->find(7);

  throws_ok { $rs->create({ %$cd_new, artist => 5 }) } $guarded, 'the column itself';
  throws_ok {
    $rs->create({ %$cd_new, very_long_artist_relationship => { artistid => 5 } })
  } $guarded, 'a relationship hash that sets it as foreign key';
  throws_ok {
    $rs->new_result({ %$cd_new, very_long_artist_relationship => { name => 'Fresh' } })
  } $guarded, 'a relationship hash of a row to create';
  throws_ok {
    $rs->create({ %$cd_new, very_long_artist_relationship => $artist })
  } $guarded, 'a related object';
  throws_ok { $rs->create({ %$cd_new, artist => $artist }) } $guarded,
    'a related object under the name of the column';
  is scalar(ops($schema, insert => 'cd')) + scalar(ops($schema, insert => 'artist')), 0,
    'nothing was written';

  my $cd = $schema->resultset('CD')->new_result({ title => 'x', year => 1 });
  lives_ok { $cd->set_from_related(very_long_artist_relationship => $artist) }
    'set_from_related sets it';

  my $stored = do { mock_cd($schema); $rs->find(1) };
  throws_ok { $stored->update({ very_long_artist_relationship => $artist }) } $guarded,
    'update(\%h) with a related object';
  throws_ok { $stored->update({ very_long_artist_relationship => { artistid => 3 } }) } $guarded,
    'update(\%h) with a relationship hash';
  throws_ok { $stored->update({ artist => 3 }) } $guarded, 'update(\%h) with the column';

  # the foreign key the relationship hands to a child is the parent's, not an assignment
  fresh_storage($schema);
  lives_ok {
    $schema->resultset('Artist')->create({ name => 'Parent', cds => [ { title => 'c', year => 1999 } ] })
  } 'multi-create of a has_many row sets the guarded foreign key';
  my ($cd_ins) = ops($schema, insert => 'cd');
  ok $cd_ins, 'the cd was inserted';

  fresh_storage($schema);
  lives_ok { $artist->create_related('cds', $cd_new) } 'create_related sets the guarded foreign key';
  throws_ok { $artist->create_related('cds', { %$cd_new, artist => 7 }) } $guarded,
    'create_related with the foreign key as value';
}

# --- 9. is_guarded on a relationship -------------------------------------------
{
  my $schema = fresh(undef, [ 'CD.very_long_artist_relationship', 'Artist.cds' ]);
  fresh_storage($schema);
  mock_artist($schema);
  my $artist = $schema->resultset('Artist')->find(7);

  throws_ok {
    $schema->resultset('CD')->create({ %$cd_new, very_long_artist_relationship => { name => 'x' } })
  } qr/relationship 'very_long_artist_relationship' of source 'CD' is guarded/i,
    'multi-create through a guarded belongs_to';

  throws_ok {
    $schema->resultset('Artist')->create({ name => 'x', cds => [ { title => 'c', year => 1999 } ] })
  } qr/relationship 'cds' of source 'Artist' is guarded/i,
    'multi-create through a guarded has_many';

  throws_ok {
    local $SIG{__WARN__} = sub {};   # the belongs_to data falls back to create()
    $schema->resultset('CD')->populate([ { %$cd_new, very_long_artist_relationship => { name => 'x' } } ]); 1
  } qr/relationship 'very_long_artist_relationship' of source 'CD' is guarded/i,
    'populate (void) through a guarded relationship';

  fresh_storage($schema);
  lives_ok { $schema->resultset('Artist')->create({ name => 'plain' }) }
    'a row without the guarded relationship is created';
  lives_ok {
    $schema->resultset('CD')->create({ %$cd_new, artist => 7 })
  } 'the foreign key column stays assignable';
  lives_ok {
    $schema->resultset('CD')->create({ %$cd_new, very_long_artist_relationship => $artist })
  } 'a related object is no multi-create';
}

# --- 10. multi-create finds only through a belongs_to with a covered constraint -
{
  my $schema = fresh();
  fresh_storage($schema);
  mock_artist($schema);

  my $cd = $schema->resultset('CD')->create({ %$cd_new, artist => { artistid => 7 } });
  ok scalar(ops($schema, select => 'artist')), 'belongs_to, constraint covered: looked up';
  is scalar(ops($schema, insert => 'artist')), 0, 'the found artist is not created';
  is $cd->get_column('artist'), 7, 'the cd points at the found artist';

  fresh_storage($schema);
  $schema->resultset('CD')->create({ %$cd_new, artist => { charfield => 'x' } });
  is scalar(ops($schema, select => 'artist')), 0, 'belongs_to, no constraint covered: no lookup';
  is scalar(ops($schema, insert => 'artist')), 1, 'the artist is created';

  # a has_many row is created, whatever it names
  fresh_storage($schema);
  $schema->resultset('Artist')->create({
    name => 'Parent',
    cds  => [ { cdid => 4, title => 'c', year => 1999 } ],
  });
  is scalar(ops($schema, select => 'cd')), 0, 'has_many: no lookup of the row';
  is scalar(ops($schema, insert => 'cd')), 1, 'has_many: the row is created';

  # a might_have row is created, whatever it names
  fresh_storage($schema);
  $schema->storage->mock_persistent(qr/FROM "liner_notes"/i, [[ 3, 'old notes' ]]);
  $schema->resultset('CD')->create({
    %$cd_new, artist => 7, liner_notes => { liner_id => 3, notes => 'n' },
  });
  is scalar(ops($schema, select => 'liner_notes')), 0, 'might_have: no lookup of the row';
  is scalar(ops($schema, insert => 'liner_notes')), 1, 'might_have: the row is created';
}

# --- 11. many_to_many add_to_* follows the same rule ----------------------------
{
  my $schema = fresh();
  fresh_storage($schema);
  $schema->storage->mock_persistent(qr/FROM "?cd"? "?me"?/i, [[ 1, 7, 'Old', '1999', undef, undef ]]);
  my $cd = $schema->resultset('CD')->find(1);

  $schema->storage->mock_persistent(qr/FROM "producer"/i, [[ 5, 'Known' ]]);
  $schema->storage->reset_captured;
  my $found = $cd->add_to_producers({ producerid => 5 });
  ok scalar(ops($schema, select => 'producer')), 'add_to: a covered constraint is looked up';
  is scalar(ops($schema, insert => 'producer')), 0, 'add_to: the found producer is not created';

  fresh_storage($schema);
  $schema->storage->clear_mocks;
  $schema->storage->mock_persistent(qr/FROM "?cd"? "?me"?/i, [[ 1, 7, 'Old', '1999', undef, undef ]]);
  $cd->add_to_producers({ name => 'New' });
  is scalar(ops($schema, insert => 'producer')), 1, 'add_to: not found, the producer is created';
}

done_testing;
