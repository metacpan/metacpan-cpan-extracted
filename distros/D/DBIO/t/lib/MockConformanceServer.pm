package MockConformanceServer;

# A "server" of a few dozen lines of Perl behind the seams of
# DBIO::Test::Conformance (ADR 0060): the tests of the Diff and Bind lists run
# the runner against it, without a driver and without a database. It keeps a
# model of the tables (declarations and rows), answers every case of the three
# lists correctly, and bends one thing at a time on request (%QUIRK).

use strict;
use warnings;

use base 'DBIO::Test::Conformance';

use DBIO::Test::Storage;
use DBIO::Diff::Base;
use DBIO::Deploy::Base;

our (%DB, %QUIRK, %REFUSALS, %AREAS, $THROUGH, %CALLS, $CLEANED_WITH);

sub reset_state {
  %DB = (); %QUIRK = (); %REFUSALS = (); %AREAS = (); %CALLS = ();
  $THROUGH = { DDL => 1, Diff => 1, Bind => 1 };
  $CLEANED_WITH = undef;
}

sub conformance_live_available { 1 }
sub conformance_refusals { \%REFUSALS }
sub conformance_refused_areas { \%AREAS }
sub conformance_answered_through { $THROUGH }

sub conformance_connect {
  my ($class, $schema_class) = @_;
  $schema_class->storage_type('DBIO::Test::Storage');
  return $schema_class->connect(sub { });
}

# the source as the server holds it for a result class a relationship names
sub _src_of_class {
  my ($schema, $class) = @_;
  my ($t) = grep { $_->{src}->result_class eq $class } values %DB;
  return $t ? $t->{src} : $schema->source($class);
}

# the source as the server holds it: what the last install or upgrade made of
# it, which differs from the schema's declaration when an upgrade did nothing
sub _src {
  my ($schema, $moniker) = @_;
  my $declared = $schema->source($moniker);
  my $t = $DB{ $declared->name };
  return $t ? $t->{src} : $declared;
}

sub _load_model {
  my ($schema) = @_;
  for my $moniker ($schema->sources) {
    my $src = $schema->source($moniker);
    next if $src->can('is_virtual') && $src->is_virtual;
    my $old = $DB{ $src->name };
    $DB{ $src->name } = {
      kind => ($src->isa('DBIO::ResultSource::View') ? 'view' : 'table'),
      src  => $src,
      rows => ($old ? $old->{rows} : []),
      seq  => ($old ? $old->{seq} : 0),
    };
  }
}

sub conformance_install {
  my ($class, $schema, $case) = @_;
  if (my $t = $QUIRK{throw}{ $case->{name} }) { $t->($schema, $case) }
  _load_model($schema);
}

# the upgrade: the model follows the target declaration, the rows follow the
# columns; a table the target does not know is gone
sub conformance_upgrade {
  my ($class, $schema, $to_class, $case) = @_;
  $CALLS{upgrade}++;
  if (my $t = $QUIRK{throw_upgrade}{ $case->{name} }) { $t->($schema, $case) }
  if (my $t = $QUIRK{throw_upgrade_any}) { $t->($schema, $case) }
  my $to = $class->conformance_connect($to_class);
  return $to if $QUIRK{upgrade_noop};   # a driver whose upgrade does nothing
  $class->_follow_target($to);
  return $to;
}

sub _follow_target {
  my ($class, $to) = @_;
  my %keep = map { $to->source($_)->name => 1 } $to->sources;
  delete $DB{$_} for grep { !$keep{$_} } keys %DB;
  _load_model($to);
  for my $moniker ($to->sources) {
    my $src = $to->source($moniker);
    my $t = $DB{ $src->name } or next;
    $t->{rows} = [] if $QUIRK{upgrade_drops_rows};
    my $info = $src->columns_info;
    for my $row (@{ $t->{rows} }) {
      delete $row->{$_} for grep { !exists $info->{$_} } keys %$row;
      for my $c ($src->columns) {
        my $i = $info->{$c};
        if (!exists $row->{$c}) {
          my $d = $i->{default_value};
          $row->{$c} = ref $d ? '2026-01-01 00:00:00' : $d;
        }
        $row->{$c} //= '' unless $i->{is_nullable};
      }
    }
  }
  return;
}

# the deploy object of the mock: a DBIO::Deploy::Base whose diff is the
# difference between the model and the target declaration, and which executes
# by letting the model follow the target. apply and upgrade are inherited.
sub conformance_deploy {
  my ($class, $schema, $to_class, $case) = @_;
  $CALLS{deploy}++;
  if (my $t = $QUIRK{throw_upgrade}{ $case->{name} }) { $t->($schema, $case) }
  if (my $t = $QUIRK{throw_upgrade_any}) { $t->($schema, $case) }
  my $to = $class->conformance_connect($to_class);
  my $deploy_class = $QUIRK{deploy_class} || 'MockConformanceServer::Deploy';
  return $deploy_class->new(schema => $to);
}

{
  package MockConformanceServer::Op;
  sub new { my ($c, %a) = @_; bless {%a}, $c }
  sub action  { $_[0]{action} }
  sub summary { $_[0]{summary} }
  sub as_sql  { $_[0]{sql} }

  package MockConformanceServer::Diff;
  our @ISA = ('DBIO::Diff::Base');
  sub _build_operations { $_[0]{ops} }

  package MockConformanceServer::Deploy;
  our @ISA = ('DBIO::Deploy::Base');
  sub _ddl_class        { 'Mock::DDL' }
  sub _introspect_class { 'Mock::Introspect' }
  sub _diff_class       { 'MockConformanceServer::Diff' }
  sub _build_target_model { {} }
  sub _introspect_current { {} }

  sub diff {
    my ($self) = @_;
    my $to = $self->schema;
    my %want = map { $to->source($_)->name => $to->source($_) } $to->sources;
    my @ops;
    for my $name (sort keys %MockConformanceServer::DB) {
      push @ops, MockConformanceServer::Op->new(
        action => 'drop', summary => "-table: $name", sql => "DROP TABLE $name;")
        unless $want{$name};
    }
    for my $name (sort keys %want) {
      my $t = $MockConformanceServer::DB{$name};
      my $cols = join ',', sort $want{$name}->columns;
      if (!$t) {
        push @ops, MockConformanceServer::Op->new(
          action => 'create', summary => "+table: $name", sql => "CREATE TABLE $name;");
      }
      elsif (join(',', sort $t->{src}->columns) ne $cols) {
        push @ops, MockConformanceServer::Op->new(
          action => 'alter', summary => "~table: $name", sql => "ALTER TABLE $name;");
      }
    }
    return MockConformanceServer::Diff->new(ops => \@ops);
  }

  sub _execute_diff {
    my ($self, $diff) = @_;
    $diff->as_sql;
    $MockConformanceServer::CALLS{executed}++;
    MockConformanceServer->_follow_target($self->schema);
    return 1;
  }
}

sub conformance_cleanup {
  my ($class, $schema, $case, $ns) = @_;
  $CLEANED_WITH = $schema;
  %DB = ();
}

sub conformance_diff_is_empty { $QUIRK{diff_nonempty} ? 0 : 1 }

sub _fks {
  my ($src) = @_;
  my %seen;
  for my $rel ($src->relationships) {
    my $info = $src->relationship_info($rel);
    next unless $info->{attrs}{is_foreign_key_constraint};
    my ($fk) = map { s/^self\.//r } values %{ $info->{cond} };
    $seen{ $info->{source} . '/' . $fk } ||= { rel => $rel, info => $info, column => $fk };
  }
  return values %seen;
}

sub _insert {
  my ($schema, $moniker, $vals) = @_;
  my $src = _src($schema, $moniker);
  my $t   = $DB{ $src->name }
    or die "no such table " . $src->name . "\n";
  die "cannot insert into a view\n" if $t->{kind} eq 'view';
  my $info = $src->columns_info;
  for my $c (keys %$vals) {
    die "no such column $c\n" unless exists $info->{$c};
  }
  my %row;
  for my $c ($src->columns) {
    my $i = $info->{$c};
    if (exists $vals->{$c})              { $row{$c} = $vals->{$c} }
    elsif (exists $i->{default_value}) {
      my $d = $i->{default_value};
      $row{$c} = ref $d ? '2026-01-01 00:00:00' : $d;
    }
    elsif ($i->{is_auto_increment})      { $row{$c} = ++$t->{seq} }
    else                                 { $row{$c} = undef }

    die "NOT NULL constraint failed: $c\n"
      if !defined $row{$c} and !$i->{is_nullable};
    die "value too long for column $c\n"
      if defined $row{$c} and !ref $i->{size} and defined $i->{size}
         and $i->{data_type} =~ /char/ and length $row{$c} > $i->{size};
    die "not an integer: $c\n"
      if defined $row{$c} and $i->{data_type} eq 'integer' and $row{$c} !~ /\A-?[0-9]+\z/;

    if (defined $row{$c}) {
      $row{$c} = undef if $QUIRK{empty_to_null} and $row{$c} eq '';
      $row{$c} = substr($row{$c}, 0, 4000) if $QUIRK{truncate_long} and length($row{$c}) > 4000;
      $row{$c} = 0 + $row{$c} if $QUIRK{numeric_float} and $i->{data_type} eq 'numeric';
      $row{$c} = 0 + $row{$c}
        if $QUIRK{digit_to_int} and $i->{data_type} =~ /\A(?:text|varchar)\z/ and $row{$c} =~ /\A[0-9]+\z/;
    }
  }
  my %uc = $src->unique_constraints;
  for my $name (sort keys %uc) {
    my @cols = @{ $uc{$name} };
    next if grep { !defined $row{$_} } @cols;
    for my $other (@{ $t->{rows} }) {
      die "unique constraint $name violated\n"
        unless grep { ($other->{$_} // '') ne $row{$_} } @cols;
    }
  }
  for my $fk (_fks($src)) {
    next unless defined $row{ $fk->{column} };
    my $parent = _src_of_class($schema, $fk->{info}{source});
    my ($pcol) = map { s/^foreign\.//r } keys %{ $fk->{info}{cond} };
    die "foreign key violated\n"
      unless grep { $_->{$pcol} eq $row{ $fk->{column} } }
             @{ $DB{ $parent->name }{rows} };
  }
  push @{ $t->{rows} }, { %row };
  return { %row };
}

sub conformance_create {
  my ($class, $schema, $moniker, $vals) = @_;
  $CALLS{create}++;
  return _insert($schema, $moniker, $vals);
}

sub conformance_populate {
  my ($class, $schema, $moniker, $rows) = @_;
  $CALLS{populate}++;
  _insert($schema, $moniker, $_) for @$rows;
  # a bug the Bind list must catch: the caller's rows are damaged
  if ($QUIRK{populate_mutates_rows}) {
    for my $r (@$rows) { $r->{ (sort keys %$r)[0] } = '?' }
  }
  return;
}

sub _rows_of {
  my ($schema, $moniker) = @_;
  my $src = _src($schema, $moniker);
  my $t = $DB{ $src->name } or die "no such table\n";
  return @{ $t->{rows} } unless $t->{kind} eq 'view';
  my ($base) = $src->view_definition =~ /\bFROM\s+"?(\w+)"?/i;
  return @{ $DB{$base}{rows} };
}

sub _same_value {
  my ($have, $want) = @_;
  return !defined $have && !defined $want if !defined $have or !defined $want;
  if ($QUIRK{loose_search}
      and $have =~ /\A-?[0-9.e]+\z/ and $want =~ /\A-?[0-9.e]+\z/) {
    return $have == $want;
  }
  return $have eq $want;
}

sub _matching {
  my ($schema, $moniker, $cond) = @_;
  my @rows = _rows_of($schema, $moniker);
  if (ref $cond eq 'REF') {
    # literal SQL: `col = ? ...` with one bind; the ?s in literals are not binds
    return () if $QUIRK{literal_miscount};
    my ($sql, $bind) = @{ $$cond };
    my ($col) = $sql =~ /\A\s*"?(\w+)"?\s*=\s*\?/ or die "mock cannot read literal SQL\n";
    return grep { _same_value($_->{$col}, $bind) } @rows;
  }
  for my $c (keys %$cond) {
    @rows = grep { _same_value($_->{$c}, $cond->{$c}) } @rows;
  }
  return @rows;
}

sub conformance_count {
  my ($class, $schema, $moniker, $cond) = @_;
  $CALLS{count}++;
  return scalar(my @r = _matching($schema, $moniker, $cond));
}

sub conformance_find {
  my ($class, $schema, $moniker, $cond) = @_;
  $CALLS{find}++;
  my ($row) = _matching($schema, $moniker, $cond);
  return $row ? { %$row } : undef;
}

sub conformance_update {
  my ($class, $schema, $moniker, $cond, $set) = @_;
  $CALLS{update}++;
  my @rows = _matching($schema, $moniker, $cond);
  for my $r (@rows) {
    for my $c (keys %$set) {
      $r->{$c} = $set->{$c};
      $r->{$c} = undef if $QUIRK{empty_to_null} and defined $r->{$c} and $r->{$c} eq '';
    }
  }
  # a bug the Bind list must catch: the caller's hash holds a placeholder
  if ($QUIRK{update_mutates_hash}) {
    $set->{$_} = '?' for keys %$set;
  }
  return scalar @rows;
}

sub conformance_delete {
  my ($class, $schema, $moniker, $cond) = @_;
  $CALLS{delete}++;
  my $src = _src($schema, $moniker);
  my $t = $DB{ $src->name };
  my (@gone, @keep);
  for my $r (@{ $t->{rows} }) {
    (grep { ($r->{$_} // '') ne $cond->{$_} } keys %$cond) ? push(@keep, $r) : push(@gone, $r);
  }
  $t->{rows} = \@keep;
  for my $child (map { $_->{src} } values %DB) {
    for my $fk (_fks($child)) {
      next unless _src_of_class($schema, $fk->{info}{source})->name eq $src->name;
      next unless ($fk->{info}{attrs}{on_delete} // '') =~ /cascade/i;
      my ($pcol) = map { s/^foreign\.//r } keys %{ $fk->{info}{cond} };
      my %dead = map { $_->{$pcol} => 1 } @gone;
      my $ct = $DB{ $child->name };
      $ct->{rows} = [ grep { !$dead{ $_->{ $fk->{column} } // '' } } @{ $ct->{rows} } ];
    }
  }
  return scalar @gone;
}

sub conformance_fact {
  my ($class, $schema, $name, $args) = @_;
  $CALLS{fact}++;
  my $t = $DB{ $args->{table} };
  return $t ? $t->{kind} : undef  if $name eq 'object_kind';
  return $t ? $args->{table} : undef if $name eq 'table_name';
  my $src = _src($schema, $args->{source});
  my $info = $src->columns_info;
  return $info->{ $args->{column} }{size}            if $name eq 'column_size';
  return [ $src->columns ]                           if $name eq 'column_names';
  return $info->{ $args->{column} }{is_auto_increment} ? 1 : 0
                                                     if $name eq 'column_auto_increment';
  return [ $src->primary_columns ]                   if $name eq 'primary_key_columns';
  return scalar(my @f = _fks($src))                  if $name eq 'foreign_key_count';
  my $want = join ',', @{ $args->{columns} || [] };
  if ($name eq 'unique_exists') {
    my %uc = $src->unique_constraints;
    return (grep { join(',', @$_) eq $want } values %uc) ? 1 : 0;
  }
  if ($name eq 'index_count') {
    my %sets;
    my %uc = $src->unique_constraints;
    $sets{ join ',', @$_ } = 1 for values %uc;
    $sets{ join ',', @{ $_->{columns} } } = 1 for $src->index_declarations;
    $sets{ $_->{column} } = 1 for _fks($src);
    return $sets{$want} ? 1 : 0;
  }
  die "mock does not know fact $name\n";
}

1;
