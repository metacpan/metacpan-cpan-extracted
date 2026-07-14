package DBIO::Cake;
# ABSTRACT: DDL-like DSL for defining DBIO result classes

use strict;
use warnings;
use Scalar::Util ();

our @EXPORT;
our %EXPORT_TAGS;

my @col_types = qw(
  integer tinyint smallint bigint
  serial bigserial smallserial
  numeric decimal
  real float4 double float8 float
  char varchar
  text tinytext mediumtext longtext
  blob tinyblob mediumblob longblob bytea
  boolean bool
  date datetime timestamp time timetz timestamptz interval
  enum set uuid json jsonb xml hstore
  array
  money
  vector halfvec sparsevec bit varbit
  inet cidr macaddr macaddr8
  tsvector tsquery
  point line lseg box path polygon circle
  int4range int8range numrange tsrange tstzrange daterange
);

my @col_modifiers = qw(
  null auto_inc fk default unsigned on_create on_update
);

my @table_funcs = qw(
  table col primary_key unique
);

my @relationship_funcs = qw(
  belongs_to has_one has_many might_have many_to_many
  rel_one rel_many
);

my @cascade_funcs = qw(
  ddl_cascade dbic_cascade
);

my @other_funcs = qw(
  view idx
  col_created col_updated cols_updated_created
);

@EXPORT = (
  @col_types, @col_modifiers,
  @table_funcs, @relationship_funcs,
  @cascade_funcs, @other_funcs,
);

# Per-caller options storage
my %CALLER_OPTS;

sub import {
  my ($class, @args) = @_;
  my $caller = caller;

  # Parse import options
  my %opts = (
    autoclean => 1,
    inflate_datetime => 0,
    inflate_json => 0,
    inflate_jsonb => 0,
    retrieve_defaults => 0,
  );

  my @components;
  my $storage_class = 'DBIO::Storage::DBI';

  while (my $arg = shift @args) {
    if ($arg eq '-V2') {
      # default and only version, no-op
    }
    elsif ($arg =~ /^-(\w+)$/ && _resolve_driver_defaults($1)) {
      # Driver shortcut: -Pg, -MySQL, -SQLite etc.
      # Uses the DBIO::Storage::DBI driver registry to find the storage class,
      # calls cake_defaults() on it to get driver-recommended options.
      $storage_class = _resolve_driver_defaults($1);
      my %driver_opts = $storage_class->cake_defaults;
      @opts{keys %driver_opts} = values %driver_opts;
    }
    elsif ($arg eq '-inflate_datetime') {
      $opts{inflate_datetime} = 1;
    }
    elsif ($arg eq '-inflate_json') {
      $opts{inflate_json} = 1;
    }
    elsif ($arg eq '-inflate_jsonb') {
      $opts{inflate_jsonb} = 1;
    }
    elsif ($arg eq '-retrieve_defaults') {
      $opts{retrieve_defaults} = 1;
    }
    elsif ($arg eq '-autoclean') {
      $opts{autoclean} = 1;
    }
    elsif ($arg eq '-no_autoclean') {
      $opts{autoclean} = 0;
    }
  }

  $opts{_storage_class} = $storage_class;

  # Enable strict and warnings in caller
  strict->import;
  warnings->import;

  # Set up inheritance -- caller ISA DBIO::Core
  {
    no strict 'refs';
    unless ($caller->isa('DBIO::Core')) {
      require DBIO::Core;
      push @{"${caller}::ISA"}, 'DBIO::Core';
    }
  }

  # Always load Timestamp for col_created/col_updated/cols_updated_created
  push @components, 'Timestamp';

  # Collect components from the type registry based on active options
  my %seen_components;
  require DBIO::Storage::DBI;
  for my $type_name ($storage_class->all_type_names) {
    my $info = $storage_class->type_info($type_name) or next;
    for my $opt (@{ $info->{cake_options} || [] }) {
      if ($opts{$opt}) {
        $seen_components{$_}++ for @{ $info->{components} || [] };
        last;
      }
    }
  }
  push @components, keys %seen_components;

  $caller->load_components(@components);

  # Store per-caller options
  $CALLER_OPTS{$caller} = \%opts;

  # Export all DSL functions into the caller
  {
    no strict 'refs';
    for my $func (@EXPORT) {
      *{"${caller}::${func}"} = \&{$func};
    }
  }

  # Schedule namespace cleanup at end of caller's scope
  if ($opts{autoclean}) {
    require namespace::clean;
    namespace::clean->import(
      -cleanee => $caller,
      @EXPORT,
    );
  }
}

# --- Internal helpers ---

sub _resolve_driver_defaults {
  my ($driver_name) = @_;

  # Look up the storage class from the DBIO::Storage::DBI driver registry
  require DBIO::Storage::DBI;
  my $storage_class = DBIO::Storage::DBI->driver_storage_class($driver_name)
    or return;

  eval "require $storage_class; 1" or return;
  return $storage_class if $storage_class->can('cake_defaults');
  return;
}

sub _caller_class {
  # Walk up the call stack to find the result class (skip DBIO::Cake frames)
  my $i = 1;
  while (my $pkg = caller($i)) {
    return $pkg unless $pkg eq __PACKAGE__;
    $i++;
  }
  return caller(1);
}

sub _expand_col_options {
  my (@args) = @_;
  my %merged;

  while (@args) {
    my $key = shift @args;
    my $val = shift @args;

    if ($key =~ /^(.+?)\.(.+)$/) {
      # Dotted notation: e.g. extra.unsigned => 1 becomes { extra => { unsigned => 1 } }
      my ($outer, $inner) = ($1, $2);
      $merged{$outer} ||= {};
      $merged{$outer}{$inner} = $val;
    }
    else {
      $merged{$key} = $val;
    }
  }

  return %merged;
}

# --- Table declaration ---

sub table {
  my ($name) = @_;
  my $class = _caller_class();
  $class->table($name);
}

# --- Column declaration ---

sub col {
  my ($name, @options) = @_;
  my $class = _caller_class();

  # Scalar refs are shorthand for default values:
  #   col id => uuid \'gen_random_uuid()';
  #   col active => boolean \1;
  @options = map { ref $_ eq 'SCALAR' || ref $_ eq 'REF'
    ? (default_value => $_) : $_ } @options;

  my %info = _expand_col_options(@options);

  # Default: not nullable
  $info{is_nullable} = 0 unless exists $info{is_nullable};

  # If -retrieve_defaults is active and there is a default_value,
  # set retrieve_on_insert
  my $opts = $CALLER_OPTS{$class};
  if ($opts && $opts->{retrieve_defaults} && exists $info{default_value}) {
    $info{retrieve_on_insert} = 1 unless exists $info{retrieve_on_insert};
  }

  # Apply col_attrs from the type registry for active options
  if ($opts) {
    my $dt = $info{data_type} || '';
    my $storage_class = $opts->{_storage_class} || 'DBIO::Storage::DBI';
    if (my $type_info = $storage_class->type_info($dt)) {
      for my $opt (@{ $type_info->{cake_options} || [] }) {
        if ($opts->{$opt}) {
          my $attrs = $type_info->{col_attrs} || {};
          $info{$_} //= $attrs->{$_} for keys %$attrs;
          last;
        }
      }
    }
  }

  # Timestamp auto-behavior:
  #   col created_at => timestamp;                -> NOT NULL -> set_on_create
  #   col updated_at => timestamp on_update;      -> NOT NULL + on_update -> set_on_create + set_on_update
  #   col deleted_at => timestamp null;            -> nullable -> no auto-set
  #   col last_login => timestamp null, on_update; -> nullable + on_update -> only set_on_update
  my $dt = $info{data_type} || '';
  if ($dt =~ /^(?:datetime|timestamp|timestamp with(?:out)? time zone)$/) {
    if ($info{is_nullable}) {
      # Nullable: no set_on_create (NULL is fine for create)
      # set_on_update stays if explicitly requested
    } else {
      # NOT NULL: must have a value on create
      $info{set_on_create} = 1 unless exists $info{set_on_create};
      # If on_update was requested, set_on_create is already implied above
    }
  }

  # UUID auto-behavior: retrieve_on_insert so the driver-provided default
  # (e.g. gen_random_uuid()) comes back after INSERT
  if ($dt eq 'uuid' && !$info{is_nullable}) {
    $info{retrieve_on_insert} = 1 unless exists $info{retrieve_on_insert};
  }

  $class->add_columns($name => \%info);
}

# --- Column modifiers (return key-value pairs, pass through @_) ---
# The @_ passthrough enables comma-free DDL syntax:
#   col id => integer auto_inc;
# Perl parses this as integer(auto_inc()) -- auto_inc returns its pairs,
# which become @_ for integer, which passes them through.

sub null      { is_nullable => 1, @_ }
sub auto_inc  { is_auto_increment => 1, @_ }
sub fk        { is_foreign_key => 1, @_ }
sub unsigned  { 'extra.unsigned' => 1, @_ }
sub on_update { set_on_update => 1, @_ }
sub on_create { set_on_create => 1, @_ }

sub default {
  my $val = shift;
  return (default_value => $val, @_);
}

# --- Column type functions (return key-value pairs, pass through @_) ---

# Integers
sub integer    { data_type => 'integer', @_ }
sub tinyint    { data_type => 'tinyint', @_ }
sub smallint   { data_type => 'smallint', @_ }
sub bigint     { data_type => 'bigint', @_ }

# Serial (auto-increment integer shortcuts)
sub serial      { data_type => 'serial', is_auto_increment => 1, @_ }
sub bigserial   { data_type => 'bigserial', is_auto_increment => 1, @_ }
sub smallserial { data_type => 'smallserial', is_auto_increment => 1, @_ }

# Numeric
sub numeric {
  my $precision = shift if @_ && Scalar::Util::looks_like_number($_[0]);
  my $scale     = shift if defined $precision && @_ && Scalar::Util::looks_like_number($_[0]);
  data_type => 'numeric',
    (defined $precision ? (size => [defined $scale ? ($precision, $scale) : $precision]) : ()),
    @_;
}

sub decimal {
  my $precision = shift if @_ && Scalar::Util::looks_like_number($_[0]);
  my $scale     = shift if defined $precision && @_ && Scalar::Util::looks_like_number($_[0]);
  data_type => 'decimal',
    (defined $precision ? (size => [defined $scale ? ($precision, $scale) : $precision]) : ()),
    @_;
}

# Floats
sub real   { data_type => 'real', @_ }
sub float4 { data_type => 'real', @_ }
sub double { data_type => 'double precision', @_ }
sub float8 { data_type => 'double precision', @_ }

sub float {
  my $bits = shift if @_ && Scalar::Util::looks_like_number($_[0]);
  data_type => 'float', (defined $bits ? (size => $bits) : ()), @_;
}

# Strings
sub char {
  my $size = shift if @_ && Scalar::Util::looks_like_number($_[0]);
  data_type => 'char', size => ($size || 1), @_;
}

sub varchar {
  my $size = shift if @_ && Scalar::Util::looks_like_number($_[0]);
  data_type => 'varchar', size => ($size || 255), @_;
}

# Text
sub text       { data_type => 'text', @_ }
sub tinytext   { data_type => 'tinytext', @_ }
sub mediumtext { data_type => 'mediumtext', @_ }
sub longtext   { data_type => 'longtext', @_ }

# Binary
sub blob       { data_type => 'blob', @_ }
sub tinyblob   { data_type => 'tinyblob', @_ }
sub mediumblob { data_type => 'mediumblob', @_ }
sub longblob   { data_type => 'longblob', @_ }
sub bytea      { data_type => 'bytea', @_ }

# Boolean
sub boolean { data_type => 'boolean', @_ }
sub bool    { data_type => 'boolean', @_ }

# Date/Time
sub date { data_type => 'date', @_ }

sub datetime {
  my $tz = shift if @_ && !ref($_[0]) && $_[0] !~ /^[a-z_]+$/;
  data_type => 'datetime', (defined $tz ? (timezone => $tz) : ()), @_;
}

sub timestamp {
  my $tz = shift if @_ && !ref($_[0]) && $_[0] !~ /^[a-z_]+$/;
  data_type => 'timestamp', (defined $tz ? (timezone => $tz) : ()), @_;
}

sub time {
  my $tz = shift if @_ && !ref($_[0]) && $_[0] !~ /^[a-z_]+$/;
  data_type => 'time', (defined $tz ? (timezone => $tz) : ()), @_;
}

sub timetz      { data_type => 'time with time zone', @_ }
sub timestamptz { data_type => 'timestamp with time zone', @_ }
sub interval    { data_type => 'interval', @_ }

# Enum/Set -- all args are the allowed values (modifiers go outside via col)
sub enum {
  data_type => 'enum', extra => { list => [@_] };
}
sub set {
  data_type => 'set', extra => { list => [@_] };
}

# UUID
sub uuid { data_type => 'uuid', @_ }

# JSON
sub json  { data_type => 'json', @_ }
sub jsonb { data_type => 'jsonb', @_ }

# XML / hstore
sub xml    { data_type => 'xml', @_ }
sub hstore { data_type => 'hstore', @_ }

# Array (PostgreSQL)
sub array {
  my $type_info = shift;
  if (ref $type_info eq 'HASH') {
    return (data_type => 'ARRAY', %$type_info, @_);
  }
  # If called as array(text) where text() returns (data_type => 'text', ...),
  # extract the actual type name from the key-value pairs
  if ($type_info eq 'data_type' && @_) {
    my $actual_type = shift;
    return (data_type => $actual_type . '[]', @_);
  }
  return (data_type => $type_info . '[]', @_);
}

# Money
sub money { data_type => 'money', @_ }

# Vector / AI (pgvector)
sub vector {
  my $dims = shift if @_ && Scalar::Util::looks_like_number($_[0]);
  data_type => 'vector', (defined $dims ? (size => $dims) : ()), @_;
}

sub halfvec {
  my $dims = shift if @_ && Scalar::Util::looks_like_number($_[0]);
  data_type => 'halfvec', (defined $dims ? (size => $dims) : ()), @_;
}

sub sparsevec {
  my $dims = shift if @_ && Scalar::Util::looks_like_number($_[0]);
  data_type => 'sparsevec', (defined $dims ? (size => $dims) : ()), @_;
}

# Bit strings
sub bit {
  my $size = shift if @_ && Scalar::Util::looks_like_number($_[0]);
  data_type => 'bit', (defined $size ? (size => $size) : ()), @_;
}

sub varbit {
  my $size = shift if @_ && Scalar::Util::looks_like_number($_[0]);
  data_type => 'varbit', (defined $size ? (size => $size) : ()), @_;
}

# Network types (PostgreSQL)
sub inet     { data_type => 'inet', @_ }
sub cidr     { data_type => 'cidr', @_ }
sub macaddr  { data_type => 'macaddr', @_ }
sub macaddr8 { data_type => 'macaddr8', @_ }

# Full-text search (PostgreSQL)
sub tsvector { data_type => 'tsvector', @_ }
sub tsquery  { data_type => 'tsquery', @_ }

# Geometric types (PostgreSQL)
sub point   { data_type => 'point', @_ }
sub line    { data_type => 'line', @_ }
sub lseg    { data_type => 'lseg', @_ }
sub box     { data_type => 'box', @_ }
sub path    { data_type => 'path', @_ }
sub polygon { data_type => 'polygon', @_ }
sub circle  { data_type => 'circle', @_ }

# Range types (PostgreSQL)
sub int4range  { data_type => 'int4range', @_ }
sub int8range  { data_type => 'int8range', @_ }
sub numrange   { data_type => 'numrange', @_ }
sub tsrange    { data_type => 'tsrange', @_ }
sub tstzrange  { data_type => 'tstzrange', @_ }
sub daterange  { data_type => 'daterange', @_ }

# --- Keys / Constraints ---

sub primary_key {
  my (@cols) = @_;
  my $class = _caller_class();
  $class->set_primary_key(@cols);
}

sub unique {
  my @args = @_;
  my $class = _caller_class();

  if (@args == 1 && ref $args[0] eq 'ARRAY') {
    # unique \@cols -- anonymous unique constraint
    $class->add_unique_constraint($args[0]);
  }
  elsif (@args == 2 && !ref $args[0] && ref $args[1] eq 'ARRAY') {
    # unique $name => \@cols
    $class->add_unique_constraint($args[0] => $args[1]);
  }
  else {
    # Pass through
    $class->add_unique_constraint(@args);
  }
}

# --- Relationships ---

sub belongs_to {
  my ($name, $related, @rest) = @_;
  my $class = _caller_class();
  $class->belongs_to($name, $related, @rest);
}

sub has_one {
  my ($name, $related, @rest) = @_;
  my $class = _caller_class();
  $class->has_one($name, $related, @rest);
}

sub has_many {
  my ($name, $related, @rest) = @_;
  my $class = _caller_class();
  $class->has_many($name, $related, @rest);
}

sub might_have {
  my ($name, $related, @rest) = @_;
  my $class = _caller_class();
  $class->might_have($name, $related, @rest);
}

sub many_to_many {
  my ($name, $link, $foreign, @rest) = @_;
  my $class = _caller_class();
  $class->many_to_many($name, $link, $foreign, @rest);
}

# rel_one: belongs_to with LEFT JOIN (nullable FK convenience)
sub rel_one {
  my ($name, $related, $cond, @rest) = @_;
  my $class = _caller_class();
  my %attrs;
  %attrs = %{pop @rest} if @rest && ref $rest[-1] eq 'HASH';
  $attrs{join_type} = 'left';
  $class->belongs_to($name, $related, $cond, \%attrs);
}

# rel_many: has_many (already LEFT JOIN by default, but explicit)
sub rel_many {
  my ($name, $related, @rest) = @_;
  my $class = _caller_class();
  $class->has_many($name, $related, @rest);
}

# --- Cascade helpers ---

sub ddl_cascade {
  return (
    on_delete => 'CASCADE',
    on_update => 'CASCADE',
  );
}

sub dbic_cascade {
  return (
    cascade_delete => 1,
    cascade_copy   => 1,
  );
}

# --- Views ---

sub view {
  my ($name, $sql, %opts) = @_;
  my $class = _caller_class();

  $class->table_class('DBIO::ResultSource::View')
    unless $class->table_class->isa('DBIO::ResultSource::View');

  require DBIO::ResultSource::View;
  $class->table($name);
  $class->result_source_instance->view_definition($sql);

  if ($opts{depends_on}) {
    $class->result_source_instance->deploy_depends_on(
      ref $opts{depends_on} ? $opts{depends_on} : [$opts{depends_on}]
    );
  }
}

# --- Indexes ---

sub idx {
  my ($name, $fields, %options) = @_;
  my $class = _caller_class();

  my $source = $class->result_source_instance;
  my $indexes = $source->{_cake_indexes} ||= [];
  push @$indexes, {
    name   => $name,
    fields => $fields,
    %options,
  };

  $class->_install_index_hooks($source);
}

# --- Timestamp column helpers ---

sub col_created {
  my $name = shift || 'created_at';
  col($name, timestamp, @_);
}

sub col_updated {
  my $name = shift || 'updated_at';
  col($name, timestamp, on_update, @_);
}

sub cols_updated_created {
  col_created(@_);
  col_updated(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Cake - DDL-like DSL for defining DBIO result classes

=head1 VERSION

version 0.900002

=head1 SYNOPSIS

  package MyApp::Schema::Result::Artist;
  use DBIO::Cake;

  table 'artists';

  col id         => integer auto_inc;
  col name       => varchar(100);
  col bio        => text null;
  col active     => boolean default(1);
  col created_at => timestamp;
  col updated_at => timestamp on_update;

  primary_key 'id';
  unique artist_name => ['name'];

  has_many cds => 'MyApp::Schema::Result::CD', 'artist_id';

  1;

PostgreSQL-specific example:

  package MyApp::Schema::Result::User;
  use DBIO::Cake -inflate_json;

  table 'users';

  col id         => uuid;
  col name       => varchar(100);
  col role       => enum(qw( admin moderator user guest )), null;
  col metadata   => jsonb \"{}";
  col embedding  => vector(1536);
  col tags       => array(text), null;
  col tsv        => tsvector null;
  col created_at => timestamp;
  col updated_at => timestamp on_update;
  col deleted_at => timestamp null;

  primary_key 'id';
  idx user_tags => ['tags'], using => 'gin';

  1;

See F<t/cake_comprehensive.t> for a runnable example.

=head1 DESCRIPTION

DBIO::Cake is the most concise way to define DBIO result classes. It keeps the
same underlying schema metadata as vanilla L<DBIO::Core>, but replaces verbose
hashref-heavy declarations with a DDL-like DSL.

Use Cake when you want result classes to read like schema definitions without
changing how the rest of DBIO behaves.

When you C<use DBIO::Cake>, it automatically:

=over 4

=item * Enables C<strict> and C<warnings>

=item * Sets the calling class to inherit from L<DBIO::Core>

=item * Exports all DSL functions into the calling package

=item * Cleans up exported symbols after the scope ends (via L<namespace::clean>)

=back

=head1 COMMA-FREE SYNTAX

Cake supports a DDL-like comma-free syntax. All type functions and modifiers
pass C<@_> through, so Perl chains them via nested function calls:

  col id => integer auto_inc;     # parsed as: integer(auto_inc())
  col bio => text null;           # parsed as: text(null())
  col active => boolean default(1); # parsed as: boolean(default(1))

B<When you need a comma:> after a number or closing parenthesis, Perl needs
a comma before the next bareword:

  col name => varchar(100), null;   # comma after (100)
  col name => varchar 100, null;    # comma after 100

This matches L<DBIx::Class::ResultDDL> conventions.

=head1 IMPORT OPTIONS

  use DBIO::Cake;                            # defaults
  use DBIO::Cake -inflate_datetime;          # load InflateColumn::DateTime
  use DBIO::Cake -inflate_json;              # auto-inflate json/jsonb columns
  use DBIO::Cake -retrieve_defaults;         # set retrieve_on_insert for columns with defaults
  use DBIO::Cake -no_autoclean;              # don't clean up symbols

Multiple options can be combined:

  use DBIO::Cake -inflate_datetime, -inflate_json;

=head1 SMART DEFAULTS

Cake automatically sets sensible defaults based on column type and nullability.

=head2 Timestamp columns

The behavior depends on nullability and the C<on_update> modifier:

  col created_at => timestamp;                  # NOT NULL -> set_on_create
  col updated_at => timestamp on_update;        # NOT NULL -> set_on_create + set_on_update
  col deleted_at => timestamp null;             # nullable -> no auto-set
  col last_login => timestamp null, on_update;  # nullable -> only set_on_update

The logic: NOT NULL timestamp columns B<must> have a value on create, so
C<set_on_create> is implied. Nullable columns don't need a value on create,
so only explicit C<on_update> is applied.

This integrates with the L<DBIO::Timestamp> component built into DBIO core.

=head2 UUID columns

NOT NULL uuid columns automatically get C<retrieve_on_insert> so the
database-generated default (e.g. PostgreSQL's C<gen_random_uuid()>) is
retrieved after INSERT:

  col id => uuid;
  # -> retrieve_on_insert => 1

=head2 Scalar references as defaults

A scalar reference anywhere in a C<col> declaration is treated as a
C<default_value>. This is a shorthand for C<default(\...)>:

  col id      => uuid \"gen_random_uuid()";
  col active  => boolean \1;
  col created => timestamp \"now()";

  # equivalent to:
  col id      => uuid default(\"gen_random_uuid()");

For literal SQL defaults, use a reference to a string. For Perl-side defaults,
use C<default($value)> without a reference.

=head1 COLUMN TYPES

All type functions return flat key-value lists and pass through C<@_>,
enabling the comma-free syntax.

=head2 Integer types

C<integer>, C<tinyint>, C<smallint>, C<bigint>

  col id    => integer auto_inc;
  col count => bigint;

=head2 Serial types (auto-increment shortcuts)

C<serial>, C<bigserial>, C<smallserial>

  col id => serial;   # integer + auto_inc in one

=head2 Numeric types

C<numeric($precision, $scale)>, C<decimal($precision, $scale)>

  col price => numeric(10, 2);

=head2 Floating point types

C<real> (alias: C<float4>), C<double> (alias: C<float8>), C<float($bits)>

=head2 String types

C<char($size)>, C<varchar($size)>

  col code => char(3);
  col name => varchar(100), null;

=head2 Text types

C<text>, C<tinytext>, C<mediumtext>, C<longtext>

  col bio => text null;

=head2 Binary types

C<blob>, C<tinyblob>, C<mediumblob>, C<longblob>, C<bytea>

=head2 Boolean

C<boolean> (alias: C<bool>)

  col active => boolean default(1);

=head2 Date/Time types

C<date>, C<datetime>, C<timestamp>, C<time>, C<timetz>, C<timestamptz>,
C<interval>

  col created_at => timestamp;             # auto set_on_create
  col updated_at => timestamp on_update;   # auto set_on_create + set_on_update
  col deleted_at => timestamp null;        # no auto-set
  col birthday   => date null;

=head2 Enum

C<enum(@values)>

  col role => enum(qw( admin moderator user guest ));

=head2 UUID

C<uuid>

  col id => uuid;   # auto retrieve_on_insert

=head2 JSON

C<json>, C<jsonb>

  col metadata => jsonb null;

With C<-inflate_json>, json/jsonb columns are automatically serialized.

=head2 Array (PostgreSQL)

C<array($type)>

  col tags => array(text), null;

=head2 Vector / AI (pgvector)

C<vector($dims)>, C<halfvec($dims)>, C<sparsevec($dims)>

  col embedding => vector(1536);

=head2 Full-text search (PostgreSQL)

C<tsvector>, C<tsquery>

=head2 Network types (PostgreSQL)

C<inet>, C<cidr>, C<macaddr>, C<macaddr8>

=head2 Geometric types (PostgreSQL)

C<point>, C<line>, C<lseg>, C<box>, C<path>, C<polygon>, C<circle>

=head2 Range types (PostgreSQL)

C<int4range>, C<int8range>, C<numrange>, C<tsrange>, C<tstzrange>, C<daterange>

=head2 Other

C<money>, C<xml>, C<hstore>, C<bit($size)>, C<varbit($size)>

=head1 COLUMN MODIFIERS

All modifiers return flat key-value lists and pass through C<@_>.

=head2 null

Marks the column as nullable.

  col bio => text null;

=head2 auto_inc

Marks the column as auto-increment.

  col id => integer auto_inc;

=head2 fk

Marks the column as a foreign key.

  col author_id => integer fk;

=head2 unsigned

Marks the column as unsigned (MySQL).

  col count => integer unsigned;

=head2 default($value)

Sets the default value.

  col active => boolean default(1);
  col created => timestamp default(\"now()");

=head2 on_create

Explicitly set C<set_on_create>. Normally not needed -- NOT NULL timestamp
columns get this automatically.

=head2 on_update

Set C<set_on_update> -- the column value is refreshed on every row update.

  col updated_at => timestamp on_update;

=head1 TABLE AND CONSTRAINT FUNCTIONS

=head2 table

  table 'my_table';

Sets the table name for this result class.

=head2 primary_key

  primary_key 'id';
  primary_key 'artist_id', 'cd_id';

Sets the primary key column(s).

=head2 unique

  unique \@cols;
  unique $name => \@cols;

Adds a unique constraint.

=head1 RELATIONSHIP FUNCTIONS

  belongs_to author => 'MyApp::Schema::Result::Author', 'author_id';
  has_one    isbn   => 'MyApp::Schema::Result::ISBN', 'book_id';
  has_many   books  => 'MyApp::Schema::Result::Book', 'author_id';
  might_have bio    => 'MyApp::Schema::Result::Bio', 'author_id';
  many_to_many roles => 'actor_roles', 'role';

=head2 rel_one

Like C<belongs_to> but forces C<join_type =E<gt> 'left'>.

=head2 rel_many

Alias for C<has_many>.

=head1 CASCADE HELPERS

=head2 ddl_cascade

Returns C<on_delete =E<gt> 'CASCADE', on_update =E<gt> 'CASCADE'> for use in
relationship attribute hashes.

=head2 dbic_cascade

Returns C<cascade_delete =E<gt> 1, cascade_copy =E<gt> 1>.

=head1 VIEW SUPPORT

=head2 view

  view 'my_view', 'SELECT * FROM artists WHERE active = 1';

Declares a view-based result source.

=head1 TIMESTAMP HELPERS

Shortcut functions for the most common timestamp column patterns.

=head2 col_created

  col_created;               # creates 'created_at' column
  col_created 'born_at';     # custom column name

Equivalent to C<col created_at =E<gt> timestamp>.

=head2 col_updated

  col_updated;               # creates 'updated_at' column
  col_updated 'modified_at'; # custom column name

Equivalent to C<col updated_at =E<gt> timestamp on_update>.

=head2 cols_updated_created

  cols_updated_created;      # creates both created_at + updated_at

Creates both timestamp columns in one call. The most common pattern --
just add this one line and you're done.

=head1 INDEX SUPPORT

=head2 idx

  idx name_idx => ['name'];
  idx composite_idx => ['last_name', 'first_name'], type => 'unique';
  idx tags_idx => ['tags'], using => 'gin';
  idx draft_only => ['key'],
      type => 'unique',
      pg   => { where => 'version IS NULL' };

Declares an index. Cake installs two hooks on the Result class so that
C<idx> works transparently in both deployment pipelines:

=over

=item * C<sqlt_deploy_hook> — B<DEPRECATED> hook for legacy
deployment. The C<options> key passes producer-specific options through.

=item * C<pg_indexes> — used by L<DBIO::PostgreSQL::DDL> when the schema
loads the C<PostgreSQL> component. The C<pg> key carries
PostgreSQL-specific options (C<where>, C<using>, C<with>, C<expression>)
and is passed through to the native PG DDL emitter.

=back

If the class already defines C<pg_indexes> by hand, those definitions
are preserved and Cake-declared indexes are merged on top.

=head3 PostgreSQL partial indexes

  idx agent_published => ['key', 'version'],
      type => 'unique',
      pg   => { where => 'version IS NOT NULL' };
  idx agent_draft => ['key'],
      type => 'unique',
      pg   => { where => 'version IS NULL' };

=head1 SEE ALSO

L<DBIO::Core>, L<DBIO::Candy>, L<DBIO::ResultSource>,
L<DBIx::Class::ResultDDL> (inspiration for Cake's syntax)

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
