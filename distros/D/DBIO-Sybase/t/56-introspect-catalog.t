use strict;
use warnings;
use Test::More;

# Offline pin for DBIO::Sybase::Introspect reading the ASE SYSTEM CATALOG
# (karr k48). SAP ASE ships no INFORMATION_SCHEMA views -- met live on ASE 16.0
# SP02 as Msg 208 "INFORMATION_SCHEMA.TABLES not found" -- so every fetcher
# reads sysobjects / syscolumns / systypes / syscomments / sysindexes /
# sysreferences instead. The mock $dbh below answers by the catalog table a
# statement reads, with rows in the exact shape ASE 16.0 returned for the same
# objects in a live probe (status bits, auto-generated PK index name, the
# "DEFAULT  'x' " text of syscomments, nullable columns reporting their
# declared type through usertype). What is pinned is the model those rows turn
# into: the model is what DBIO::Sybase::Diff compares, and both sides of the
# test-deploy-and-compare are introspected, so any value that differs between
# two deployments of the same DDL (the PK index name) or that re-renders
# differently from what the DDL wrote (a default's quoting) is a phantom diff.

use DBIO::Sybase::Introspect;
use DBIO::Sybase::Diff;

{
  package Test::Sybase::CatalogDBH;
  sub new { my ($class, %rows) = @_; bless { rows => \%rows, sql => [], binds => [] }, $class }
  sub _rows_for {
    my ($self, $sql) = @_;
    push @{ $self->{sql} }, $sql;
    return $self->{rows}{references} if $sql =~ /\bsysreferences\b/i;
    return $self->{rows}{depends}    if $sql =~ /\bsysdepends\b/i;
    return $self->{rows}{indexes}    if $sql =~ /\bsysindexes\b/i;
    return $self->{rows}{defaults}   if $sql =~ /\bsyscomments\b/i && $sql =~ /cdefault/i;
    return $self->{rows}{viewtext}   if $sql =~ /\bsyscomments\b/i;
    return $self->{rows}{columns}    if $sql =~ /\bsyscolumns\b/i;
    return $self->{rows}{objects}    if $sql =~ /\bsysobjects\b/i;
    die "unexpected SQL: $sql";
  }
  sub selectall_arrayref {
    my ($self, $sql, $attr, @bind) = @_;
    push @{ $self->{binds} }, [@bind];
    return [ map { +{%$_} } @{ $self->_rows_for($sql) // [] } ];
  }
  sub selectcol_arrayref {
    my ($self, $sql, $attr, @bind) = @_;
    push @{ $self->{binds} }, [@bind];
    return [ map { $_->{text} } @{ $self->_rows_for($sql) // [] } ];
  }
  sub prepare { die "catalog fetchers use selectall_arrayref, not prepare: $_[1]" }
}

# Two deployments of the same schema: identical except for what ASE assigns
# itself -- the PK index name carries the object id.
sub catalog {
  my (%o) = @_;
  my $pk_name = $o{pk_name} // 'artist_5760020521';
  return Test::Sybase::CatalogDBH->new(
    objects => [
      { table_name => 'artist', object_type => 'U ' },
      { table_name => 'cd',     object_type => 'U ' },
      { table_name => 'v1',     object_type => 'V ' },
    ],
    columns => [
      { table_name => 'artist', column_name => 'id',    colid => 1, type_name => 'int',
        length => 4,  prec => undef, scale => undef, status => 128, cdefault => 0 },
      { table_name => 'artist', column_name => 'name',  colid => 2, type_name => 'varchar',
        length => 32, prec => undef, scale => undef, status => 0,   cdefault => 11 },
      { table_name => 'artist', column_name => 'note',  colid => 3, type_name => 'varchar',
        length => 16, prec => undef, scale => undef, status => 8,   cdefault => 0 },
      { table_name => 'artist', column_name => 'price', colid => 4, type_name => 'numeric',
        length => 6,  prec => 10,    scale => 2,     status => 8,   cdefault => 12 },
      { table_name => 'artist', column_name => 'made',  colid => 5, type_name => 'datetime',
        length => 8,  prec => undef, scale => undef, status => 0,   cdefault => 13 },
      { table_name => 'artist', column_name => 'big',   colid => 6, type_name => 'bigint',
        length => 8,  prec => undef, scale => undef, status => 8,   cdefault => 0 },
      { table_name => 'artist', column_name => 'uv',    colid => 7, type_name => 'univarchar',
        length => 20, prec => undef, scale => undef, status => 8,   cdefault => 0 },
      { table_name => 'artist', column_name => 't',     colid => 8, type_name => 'text',
        length => 16, prec => undef, scale => undef, status => 8,   cdefault => 0 },
      { table_name => 'cd', column_name => 'artist', colid => 1, type_name => 'int',
        length => 4, prec => undef, scale => undef, status => 0, cdefault => 0 },
      { table_name => 'cd', column_name => 'seq',    colid => 2, type_name => 'int',
        length => 4, prec => undef, scale => undef, status => 0, cdefault => 0 },
      { table_name => 'v1', column_name => 'id',     colid => 1, type_name => 'int',
        length => 4, prec => undef, scale => undef, status => 0, cdefault => 0 },
    ],
    defaults => $o{defaults} // [
      { table_name => 'artist', column_name => 'name',  text => "DEFAULT  'it''s' " },
      # what ASE 16.0 stores for `price NUMERIC(10,2) DEFAULT 0` (karr k55)
      { table_name => 'artist', column_name => 'price', text => "DEFAULT  0 " },
      # a long default spans syscomments rows; the fetch concatenates them
      { table_name => 'artist', column_name => 'made',  text => 'DEFAULT  get' },
      { table_name => 'artist', column_name => 'made',  text => 'date() ' },
    ],
    indexes => [
      { table_name => 'artist', index_name => $pk_name, indid => 1, status => 2066,
        k1 => 'id' },
      { table_name => 'artist', index_name => 'artist_name_idx', indid => 2, status => 2,
        k1 => 'name' },
      { table_name => 'artist', index_name => 'artist_multi', indid => 3, status => 0,
        k1 => 'note', k2 => 'big' },
      { table_name => 'cd', index_name => $o{cd_pk_name} // 'cd_7040025081', indid => 1,
        status => 2066, k1 => 'artist', k2 => 'seq' },
    ],
    references => [
      { table_name => 'cd', constraint_name => 'fk_cd_artist', ref_table_name => 'artist',
        keycnt => 1, fk1 => 'artist', rk1 => 'id' },
    ],
    viewtext => [
      { view_name => 'v1', colid2 => 1, colid => 1, text => 'CREATE VIEW v1 AS SELECT id, na' },
      { view_name => 'v1', colid2 => 1, colid => 2, text => 'me FROM artist' },
    ],
    # v1 reads from the table artist: a dependency, but not on a view
    depends => [
      { view_name => 'v1', depends_on => 'artist' },
    ],
  );
}

my $dbh   = catalog();
my $intro = DBIO::Sybase::Introspect->new(dbh => $dbh);
my $model = $intro->model;

# --- no INFORMATION_SCHEMA, only the ASE system catalog --------------------
my @sql = @{ $dbh->{sql} };
ok !(grep { /information_schema/i } @sql),
  'no statement touches INFORMATION_SCHEMA (ASE has none)';
ok( (grep { /\bsysobjects\b/i  } @sql), 'tables come from sysobjects' );
ok( (grep { /\bsystypes\b/i    } @sql), 'type names come from systypes' );
ok( (grep { /usertype/i        } @sql), 'systypes joined on usertype (declared type, not the nullable variant)' );
ok( (grep { /\bindex_col\s*\(/i } @sql), 'index columns come from index_col()' );
ok( (grep { /\bsysreferences\b/i } @sql), 'FKs come from sysreferences' );
ok( (grep { /sysquerymetrics/i } @sql), 'the system view sysquerymetrics is filtered out' );
ok !(grep { ($_->[0] // '') ne 'dbo' } @{ $dbh->{binds} }),
  'every catalog query is bound to the owner (schema) dbo';

# --- tables ---------------------------------------------------------------
is_deeply $model->{tables}, {
  artist => { table_name => 'artist', kind => 'table', schema => 'dbo' },
  cd     => { table_name => 'cd',     kind => 'table', schema => 'dbo' },
  v1     => { table_name => 'v1',     kind => 'view',  schema => 'dbo' },
}, 'sysobjects U/V -> table/view';

# --- columns --------------------------------------------------------------
my %c = map { $_->{column_name} => $_ } @{ $model->{columns}{artist} };
is_deeply [ map { $_->{column_name} } @{ $model->{columns}{artist} } ],
  [qw/id name note price made big uv t/], 'columns in colid order';

is $c{id}{data_type}, 'int', 'data_type is the systypes name';
is $c{id}{is_auto_increment}, 1, 'status & 0x80 -> identity';
is $c{id}{not_null}, 1, 'status without bit 8 -> not null';
is $c{note}{not_null}, 0, 'status & 8 -> nullable';
is $c{note}{is_auto_increment}, 0, 'no identity bit -> 0';
is $c{big}{data_type}, 'bigint', 'nullable bigint keeps its declared name (not intn)';

is $c{name}{size}, 32, 'varchar size is syscolumns.length';
is_deeply $c{price}{size}, [10, 2], 'numeric size is [prec, scale]';
is $c{uv}{size}, 10, 'univarchar size is characters (length / 2, UTF-16)';
ok !exists $c{id}{size}, 'int carries no size';
ok !exists $c{t}{size}, 'text carries no size (length 16 is the text pointer)';

# The default is stored the way DBIO::Sybase::DDL::sybase_default_clause needs
# to re-render it: a quoted literal as its bare value (the DDL quotes it again),
# anything else as a SQL expression (SCALAR ref, rendered verbatim).
is $c{name}{default_value}, "it's", "DEFAULT 'it''s' -> bare literal, '' unescaped";
# CLAIM REPLACED (karr k55): this read "DEFAULT '0' -> '0'" with the mock text
# DEFAULT  '0'  on the numeric column -- the text the pre-k55 DDL wrote, which
# ASE stores as a VARCHAR constant that fails every defaulted INSERT (Msg 257).
# The DDL now writes DEFAULT 0 there; the claim is that THAT text reads back as
# the plain literal '0' (not a SCALAR ref), so it compares equal to a Result
# class's default_value => 0. The legacy quoted text is pinned separately below.
is $c{price}{default_value}, '0', "numeric DEFAULT 0 -> plain literal '0'";
ok !ref $c{price}{default_value}, 'numeric DEFAULT 0 is a literal, not a SQL expression';
is ref $c{made}{default_value}, 'SCALAR', 'DEFAULT getdate() -> SQL expression (SCALAR ref)';
is ${ $c{made}{default_value} }, 'getdate()', 'multi-row syscomments text is concatenated';
is $c{note}{default_value}, undef, 'cdefault 0 -> no default';

use DBIO::Sybase::DDL qw(sybase_default_clause);
# A literal with an embedded quote re-renders as ASE stored it (karr k51):
# introspection turns '' back into ', the DDL doubles it again. Before k51 the
# DDL wrote DEFAULT 'it's' -- a statement ASE rejects, and a text the reverse
# direction could not have read back as the literal either.
is sybase_default_clause($c{name}{default_value}), " DEFAULT 'it''s'",
  'introspected literal with an embedded quote re-renders with it doubled';
# CLAIM REPLACED (karr k55): expected " DEFAULT '0'" before, called without the
# column type. The claim -- re-rendered as the DDL wrote it -- is unchanged;
# what the DDL writes for a numeric column is now unquoted, and the renderer
# needs the type to know that.
is sybase_default_clause($c{price}{default_value}, $c{price}{data_type}), ' DEFAULT 0',
  'introspected numeric literal re-renders as the DDL wrote it (unquoted)';
is sybase_default_clause($c{made}{default_value}), ' DEFAULT getdate()',
  'introspected expression re-renders unquoted';

# ... and the whole round trip, rendered text back through the reader: what
# the DDL writes for a literal is what introspection returns as that literal.
# ASE keeps the default text verbatim in syscomments (with its own spacing),
# so the rendered clause is fed back the way the catalog returns it.
for my $lit ("it's", "''", "a'b'c", 'plain') {
  (my $stored = DBIO::Sybase::DDL::sybase_default_clause($lit)) =~ s/\A\s+//;
  my $read = DBIO::Sybase::Introspect->new(dbh => catalog(defaults => [
    { table_name => 'artist', column_name => 'name', text => "$stored " },
  ]))->model;
  my ($name) = grep { $_->{column_name} eq 'name' } @{ $read->{columns}{artist} };
  is $name->{default_value}, $lit, "default <$lit> survives DDL -> syscomments -> introspect";
}

# The same round trip on a numeric column (karr k55), in the forms ASE stored
# verbatim for them live (ASE 16.0 SP02): sign, fraction without integer part,
# trailing zeros, exponent. Each comes back as the plain literal and renders
# the identical clause.
for my $lit ('0', '-1', '+.5', '2.50', '1.5e3') {
  (my $stored = sybase_default_clause($lit, 'numeric')) =~ s/\A\s+//;
  is $stored, "DEFAULT $lit", "numeric <$lit> rendered unquoted";
  my $read = DBIO::Sybase::Introspect->new(dbh => catalog(defaults => [
    { table_name => 'artist', column_name => 'price', text => "$stored " },
  ]))->model;
  my ($price) = grep { $_->{column_name} eq 'price' } @{ $read->{columns}{artist} };
  is $price->{default_value}, $lit, "numeric default <$lit> survives DDL -> syscomments -> introspect";
  ok !ref $price->{default_value}, "numeric default <$lit> reads back as a literal";
}

# A numeric column deployed before k55 carries the quoted text DEFAULT '0'.
# Reading it as the literal '0' would make it compare equal to the desired 0
# and hide a default that breaks every INSERT; it is kept as the SQL it is
# (a SCALAR ref, re-rendered verbatim) so the diff sees it and replaces it.
{
  my $read = DBIO::Sybase::Introspect->new(dbh => catalog(defaults => [
    { table_name => 'artist', column_name => 'price', text => "DEFAULT  '0' " },
  ]))->model;
  my ($price) = grep { $_->{column_name} eq 'price' } @{ $read->{columns}{artist} };
  is ref $price->{default_value}, 'SCALAR', "legacy numeric DEFAULT '0' -> SQL expression";
  is ${ $price->{default_value} }, "'0'", '... carrying the quoted text verbatim';
  is sybase_default_clause($price->{default_value}, 'numeric'), " DEFAULT '0'",
    '... which re-renders exactly as stored';
}

# A bare number on a NON-numeric column is not the literal a character column
# would have been deployed with (that is quoted); it stays the expression it is.
{
  my $read = DBIO::Sybase::Introspect->new(dbh => catalog(defaults => [
    { table_name => 'artist', column_name => 'name', text => "DEFAULT  0 " },
  ]))->model;
  my ($name) = grep { $_->{column_name} eq 'name' } @{ $read->{columns}{artist} };
  is ref $name->{default_value}, 'SCALAR', 'bare 0 on a varchar column stays an expression';
}

# --- PK from the PK-constraint index (sysindexes status & 2048) -----------
is $c{id}{is_pk}, 1, 'PK column flagged from the PK index';
is $c{id}{pk_position}, 1, 'pk_position 1';
is $c{name}{is_pk}, 0, 'non-PK column';
my %cd = map { $_->{column_name} => $_ } @{ $model->{columns}{cd} };
is_deeply [ $cd{artist}{pk_position}, $cd{seq}{pk_position} ], [1, 2],
  'composite PK positions follow index_col order';
is_deeply $intro->table_pk_info('cd'), [qw/artist seq/], 'table_pk_info (contract) from catalog';

# --- indexes --------------------------------------------------------------
my $ai = $model->{indexes}{artist};
is_deeply [ sort keys %$ai ], [ sort 'artist_5760020521', 'artist_name_idx', 'artist_multi' ],
  'indexes keyed by sysindexes name';
is $ai->{artist_5760020521}{origin}, 'pk', 'status & 2048 -> origin pk';
is $ai->{artist_5760020521}{is_unique}, 1, 'PK index unique';
is $ai->{artist_name_idx}{is_unique}, 1, 'status & 2 -> unique';
ok !defined $ai->{artist_name_idx}{origin}, 'plain unique index has no origin';
is $ai->{artist_multi}{is_unique}, 0, 'non-unique';
is_deeply $ai->{artist_multi}{columns}, [qw/note big/], 'index_col keys in order, NULL-terminated';
is_deeply $intro->table_uniq_info('artist'), [ [ artist_name_idx => ['name'] ] ],
  'table_uniq_info drops the PK index';

# --- foreign keys ---------------------------------------------------------
is_deeply $model->{foreign_keys}{cd}, [ {
  constraint_name => 'fk_cd_artist',
  from_columns    => ['artist'],
  to_table        => 'artist',
  to_columns      => ['id'],
  on_update       => 'NO ACTION',
  on_delete       => 'NO ACTION',
} ], 'sysreferences -> one FK per constraint; ASE has no referential actions';

# --- view definition ------------------------------------------------------
is $intro->view_definition('v1'), 'SELECT id, name FROM artist',
  'view text from syscomments, chunks joined, CREATE VIEW ... AS stripped';
is $intro->view_definition('artist'), undef, 'no view definition for a table';

is_deeply $model->{views}, {
  v1 => { view_name => 'v1', definition => 'SELECT id, name FROM artist', depends_on => [] },
}, 'model views: syscomments rows joined, head stripped; a table the view reads from is no view dependency';

# --- the round-trip invariant: two deployments of the same DDL diff empty --
{
  my $live   = DBIO::Sybase::Introspect->new(dbh => catalog())->model;
  my $target = DBIO::Sybase::Introspect->new(dbh => catalog(
    pk_name => 'artist_1234567890', cd_pk_name => 'cd_9876543210',
  ))->model;
  my $diff = DBIO::Sybase::Diff->new(source => $live, target => $target);
  ok !$diff->has_changes, 'same schema, different auto PK index names and fresh '
    . 'expression-default refs: no phantom diff'
    or diag $diff->as_sql;
}

done_testing;
