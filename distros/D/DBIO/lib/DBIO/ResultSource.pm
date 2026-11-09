package DBIO::ResultSource;
# ABSTRACT: Metadata object describing a table, view, or query source

use strict;
use warnings;

our $VERSION = '0.900004';

use base qw/DBIO::ResultSource::RowParser DBIO::Base/;

use DBIO::ResultSet;

use DBIO::Carp;
use DBIO::Util 'UNRESOLVABLE_CONDITION';
use DBIO::Util qw(is_literal_value);
use Devel::GlobalDestruction;
use Try::Tiny;
use Scalar::Util qw/blessed weaken isweak/;
use Storable ();

use namespace::clean;

__PACKAGE__->mk_group_accessors(simple => qw/
  source_name name source_info
  _ordered_columns _columns _primaries _unique_constraints
  _relationships resultset_attributes
  column_info_from_storage
/);

__PACKAGE__->mk_group_accessors(component_class => qw/
  resultset_class
  result_class
/);

__PACKAGE__->mk_classdata( sqlt_deploy_callback => 'default_sqlt_deploy_hook' );


sub new {
  my ($class, $attrs) = @_;
  $class = ref $class if ref $class;

  my $new = bless { %{$attrs || {}} }, $class;
  $new->{resultset_class} ||= 'DBIO::ResultSet';
  $new->{resultset_attributes} = { %{$new->{resultset_attributes} || {}} };
  $new->{_ordered_columns} = [ @{$new->{_ordered_columns}||[]}];
  $new->{_columns} = { %{$new->{_columns}||{}} };
  $new->{_relationships} = { %{$new->{_relationships}||{}} };
  $new->{_index_declarations} = [ @{$new->{_index_declarations}||[]} ];
  $new->{name} ||= "!!NAME NOT SET!!";
  $new->{_columns_info_loaded} ||= 0;
  return $new;
}



sub add_columns {
  my ($self, @cols) = @_;
  $self->_ordered_columns(\@cols) unless $self->_ordered_columns;

  my @added;
  my $columns = $self->_columns;
  while (my $col = shift @cols) {
    my $column_info = {};
    if ($col =~ s/^\+//) {
      $column_info = $self->column_info($col);
    }

    # If next entry is { ... } use that for the column info, if not
    # use an empty hashref
    if (ref $cols[0]) {
      my $new_info = shift(@cols);
      %$column_info = (%$column_info, %$new_info);
    }
    push(@added, $col) unless exists $columns->{$col};
    $columns->{$col} = $column_info;
  }
  push @{ $self->_ordered_columns }, @added;
  return $self;
}


sub add_column { shift->add_columns(@_); } # DO NOT CHANGE THIS TO GLOB


sub has_column {
  my ($self, $column) = @_;
  return exists $self->_columns->{$column};
}


sub column_info {
  my ($self, $column) = @_;
  $self->throw_exception("No such column $column")
    unless exists $self->_columns->{$column};

  if ( ! $self->_columns->{$column}{data_type}
       and ! $self->{_columns_info_loaded}
       and $self->column_info_from_storage
       and my $stor = try { $self->storage } )
  {
    $self->{_columns_info_loaded}++;

    # try for the case of storage without table
    try {
      my $info = $stor->columns_info_for( $self->from );
      my $lc_info = { map
        { (lc $_) => $info->{$_} }
        ( keys %$info )
      };

      foreach my $col ( keys %{$self->_columns} ) {
        $self->_columns->{$col} = {
          %{ $self->_columns->{$col} },
          %{ $info->{$col} || $lc_info->{lc $col} || {} }
        };
      }
    };
  }

  return $self->_columns->{$column};
}


sub columns {
  my $self = shift;
  $self->throw_exception(
    "columns() is a read-only accessor, did you mean add_columns()?"
  ) if @_;
  return @{$self->{_ordered_columns}||[]};
}


sub columns_info {
  my ($self, $columns) = @_;

  my $colinfo = $self->_columns;

  if (
    grep { ! $_->{data_type} } values %$colinfo
      and
    ! $self->{_columns_info_loaded}
      and
    $self->column_info_from_storage
      and
    my $stor = try { $self->storage }
  ) {
    $self->{_columns_info_loaded}++;

    # try for the case of storage without table
    try {
      my $info = $stor->columns_info_for( $self->from );
      my $lc_info = { map
        { (lc $_) => $info->{$_} }
        ( keys %$info )
      };

      foreach my $col ( keys %$colinfo ) {
        $colinfo->{$col} = {
          %{ $colinfo->{$col} },
          %{ $info->{$col} || $lc_info->{lc $col} || {} }
        };
      }
    };
  }

  my %ret;

  if ($columns) {
    for (@$columns) {
      if (my $inf = $colinfo->{$_}) {
        $ret{$_} = $inf;
      }
      else {
        $self->throw_exception( sprintf (
          "No such column '%s' on source '%s'",
          $_,
          $self->source_name || $self->name || 'Unknown source...?',
        ));
      }
    }
  }
  else {
    %ret = %$colinfo;
  }

  return \%ret;
}


sub remove_columns {
  my ($self, @to_remove) = @_;

  my $columns = $self->_columns
    or return;

  my %to_remove;
  for (@to_remove) {
    delete $columns->{$_};
    ++$to_remove{$_};
  }

  $self->_ordered_columns([ grep { not $to_remove{$_} } @{$self->_ordered_columns} ]);
}


sub remove_column { shift->remove_columns(@_); } # DO NOT CHANGE THIS TO GLOB


sub set_primary_key {
  my ($self, @cols) = @_;

  my $colinfo = $self->columns_info(\@cols);
  for my $col (@cols) {
    carp_unique(sprintf (
      "Primary key of source '%s' includes the column '%s' which has its "
    . "'is_nullable' attribute set to true. This is a mistake and will cause "
    . 'various Result-object operations to fail',
      $self->source_name || $self->name || 'Unknown source...?',
      $col,
    )) if $colinfo->{$col}{is_nullable};
  }

  $self->_primaries(\@cols);

  $self->add_unique_constraint(primary => \@cols);
}


sub primary_columns {
  return @{shift->_primaries||[]};
}

# a helper method that will automatically die with a descriptive message if
# no pk is defined on the source in question. For internal use to save
# on if @pks... boilerplate
sub _pri_cols_or_die {
  my $self = shift;
  my @pcols = $self->primary_columns
    or $self->throw_exception (sprintf(
      "Operation requires a primary key to be declared on '%s' via set_primary_key",
      # source_name is set only after schema-registration
      $self->source_name || $self->result_class || $self->name || 'Unknown source...?',
    ));
  return @pcols;
}

# same as above but mandating single-column PK (used by relationship condition
# inference)
sub _single_pri_col_or_die {
  my $self = shift;
  my ($pri, @too_many) = $self->_pri_cols_or_die;

  $self->throw_exception( sprintf(
    "Operation requires a single-column primary key declared on '%s'",
    $self->source_name || $self->result_class || $self->name || 'Unknown source...?',
  )) if @too_many;
  return $pri;
}



sub sequence {
  my ($self,$seq) = @_;

  my @pks = $self->primary_columns
    or return;

  $_->{sequence} = $seq
    for values %{ $self->columns_info (\@pks) };
}



sub add_unique_constraint {
  my $self = shift;

  if (@_ > 2) {
    $self->throw_exception(
        'add_unique_constraint() does not accept multiple constraints, use '
      . 'add_unique_constraints() instead'
    );
  }

  my $cols = pop @_;
  if (ref $cols ne 'ARRAY') {
    $self->throw_exception (
      'Expecting an arrayref of constraint columns, got ' . ($cols||'NOTHING')
    );
  }

  my $name = shift @_;

  $name ||= $self->name_unique_constraint($cols);

  foreach my $col (@$cols) {
    $self->throw_exception("No such column $col on table " . $self->name)
      unless $self->has_column($col);
  }

  my %unique_constraints = $self->unique_constraints;
  $unique_constraints{$name} = $cols;
  $self->_unique_constraints(\%unique_constraints);
}


sub add_unique_constraints {
  my $self = shift;
  my @constraints = @_;

  if ( !(@constraints % 2) && grep { ref $_ ne 'ARRAY' } @constraints ) {
    # with constraint name
    while (my ($name, $constraint) = splice @constraints, 0, 2) {
      $self->add_unique_constraint($name => $constraint);
    }
  }
  else {
    # no constraint name
    foreach my $constraint (@constraints) {
      $self->add_unique_constraint($constraint);
    }
  }
}


sub name_unique_constraint {
  my ($self, $cols) = @_;

  my $name = $self->name;
  $name = $$name if (ref $name eq 'SCALAR');
  $name =~ s/ ^ [^\.]+ \. //x;  # strip possible schema qualifier

  return join '_', $name, @$cols;
}


sub unique_constraints {
  return %{shift->_unique_constraints||{}};
}


sub add_index_declaration {
  my ($self, $decl) = @_;

  $self->throw_exception('add_index_declaration() expects a hashref')
    unless ref $decl eq 'HASH';

  my $name = $decl->{name};
  $self->throw_exception('add_index_declaration(): the index needs a name')
    unless defined $name and length $name and !ref $name;

  my $cols = $decl->{columns};
  $cols = [ $cols ] if defined $cols and !ref $cols and length $cols;
  $self->throw_exception(
    "add_index_declaration(): index '$name' needs columns, a column name or an arrayref of them"
  ) unless ref $cols eq 'ARRAY'
    and @$cols
    and !grep { !defined $_ or ref $_ or !length $_ } @$cols;

  my $driver = $decl->{driver};
  if (defined $driver) {
    $self->throw_exception(
      "add_index_declaration(): index '$name': driver must be a hashref, driver => { pg => { ... } }"
    ) unless ref $driver eq 'HASH';
    my %known = map { $_ => 1 } $self->index_declaration_drivers;
    for my $drv (sort keys %$driver) {
      $self->throw_exception(
        "add_index_declaration(): index '$name': unknown driver block '$drv' "
        . "(accepted: " . join(', ', map "'$_'", $self->index_declaration_drivers) . ")"
      ) unless $known{$drv};
      $self->throw_exception(
        "add_index_declaration(): index '$name': driver block '$drv' must be a hashref"
      ) unless ref $driver->{$drv} eq 'HASH';
    }
  }

  my $entry = Storable::dclone({
    name    => $name,
    columns => $cols,
    unique  => (
      ($decl->{unique} or ($decl->{type} // '') =~ /^unique$/i) ? 1 : 0
    ),
    type    => $decl->{type},
    options => $decl->{options},
    driver  => $driver || {},
  });

  my $list = $self->{_index_declarations} ||= [];
  my ($pos) = grep { $list->[$_]{name} eq $name } 0 .. $#$list;
  if (defined $pos) {
    $list->[$pos] = $entry;
  }
  else {
    push @$list, $entry;
  }

  return;
}


sub index_declarations {
  my $self = shift;
  return map { Storable::dclone($_) } @{ $self->{_index_declarations} || [] };
}


sub index_declaration_drivers { qw(pg sqlite mysql oracle mssql sybase firebird clickhouse duckdb db2 informix) }


sub index_declarations_for {
  my ($self, $driver, $allowed) = @_;

  $self->throw_exception(
    "index_declarations_for(): '" . ($driver // 'undef') . "' is not a driver "
    . "name, expected one of "
    . join(', ', map "'$_'", $self->index_declaration_drivers)
  ) unless defined $driver and grep { $_ eq $driver } $self->index_declaration_drivers;
  $self->throw_exception(
    "index_declarations_for('$driver'): expects the allowed keys of the "
    . "driver block as an arrayref"
  ) unless ref $allowed eq 'ARRAY';

  my %allowed = map { $_ => 1 } @$allowed;
  my $label = $self->source_name;
  $label = $self->name unless defined $label;
  $label = 'source' if ref $label;

  my @out;
  for my $idx ($self->index_declarations) {
    my $blocks = $idx->{driver} || {};
    my $own    = $blocks->{$driver};

    if (!$own) {
      if (my @foreign = sort keys %$blocks) {
        $self->throw_exception(
          "$label: index '$idx->{name}' carries only the "
          . join(', ', map "'$_'", @foreign)
          . " block and none for '$driver'; declare $driver => { ... } "
          . "for it, or $driver => {} for the plain index"
        );
      }
    }
    else {
      for my $key (sort keys %$own) {
        next if $allowed{$key};
        $self->throw_exception(
          "$label: index '$idx->{name}': unknown key '$key' in its "
          . "'$driver' block (valid keys: "
          . join(', ', map "'$_'", sort keys %allowed) . ")"
        );
      }
    }
    push @out, $idx;
  }

  return @out;
}


sub unique_constraint_names {
  my ($self) = @_;

  my %unique_constraints = $self->unique_constraints;

  return keys %unique_constraints;
}


sub unique_constraint_columns {
  my ($self, $constraint_name) = @_;

  my %unique_constraints = $self->unique_constraints;

  $self->throw_exception(
    "Unknown unique constraint $constraint_name on '" . $self->name . "'"
  ) unless exists $unique_constraints{$constraint_name};

  return @{ $unique_constraints{$constraint_name} };
}


sub default_sqlt_deploy_hook {
  my $self = shift;

  my $class = $self->result_class;

  if ($class and $class->can('sqlt_deploy_hook')) {
    $class->sqlt_deploy_hook(@_);
  }
}

sub _invoke_sqlt_deploy_hook {
  my $self = shift;
  if ( my $hook = $self->sqlt_deploy_callback) {
    $self->$hook(@_);
  }
}



sub resultset {
  my $self = shift;
  $self->throw_exception(
    'resultset does not take any arguments. If you want another resultset, '.
    'call it on the schema instead.'
  ) if scalar @_;

  $self->resultset_class->new(
    $self,
    {
      try { %{$self->schema->default_resultset_attributes} },
      %{$self->{resultset_attributes}},
    },
  );
}


sub from { die 'Virtual method!' }


sub schema {
  if (@_ > 1) {
    $_[0]->{schema} = $_[1];
  }
  else {
    $_[0]->{schema} || do {
      my $name = $_[0]->{source_name} || '_unnamed_';
      my $err = 'Unable to perform storage-dependent operations with a detached result source '
              . "(source '$name' is not associated with a schema).";

      $err .= ' You need to use $schema->thaw() or manually set'
            . ' $DBIO::ResultSource::thaw_schema while thawing.'
        if $_[0]->{_detached_thaw};

      DBIO::Exception->throw($err);
    };
  }
}


sub storage { shift->schema->storage; }


sub add_relationship {
  my ($self, $rel, $f_source_name, $cond, $attrs) = @_;
  $self->throw_exception("Can't create relationship without join condition")
    unless $cond;
  $attrs ||= {};

  # Check foreign and self are right in cond
  if ( (ref $cond ||'') eq 'HASH') {
    $_ =~ /^foreign\./ or $self->throw_exception("Malformed relationship condition key '$_': must be prefixed with 'foreign.'")
      for keys %$cond;

    $_ =~ /^self\./ or $self->throw_exception("Malformed relationship condition value '$_': must be prefixed with 'self.'")
      for values %$cond;
  }

  my %rels = %{ $self->_relationships };
  $rels{$rel} = { class => $f_source_name,
                  source => $f_source_name,
                  cond  => $cond,
                  attrs => $attrs };
  $self->_relationships(\%rels);

  # No definition-time resolution of the related source (ADR 0054). Only the
  # local, self-contained checks above run here (join condition present;
  # foreign./self. prefixing). The related source named by $f_source_name is
  # deliberately NOT resolved at declaration time: relationships are declared
  # while the schema is still being composed, when the far side is routinely
  # not registered yet (forward and circular references are normal), and on a
  # standalone prototype source there is neither a schema nor storage to
  # resolve against. Resolution is lazy -- it happens on first use, when
  # related_source/_resolve_join run against a fully-composed schema.
  return $self;
}


# Through an array, not `return sort ...`: sort in scalar context is
# undefined, and the count is what this returned there all along.
sub relationships {
  my @rel_names = sort keys %{shift->_relationships};
  return @rel_names;
}


sub relationship_info {
  #my ($self, $rel) = @_;
  return shift->_relationships->{+shift};
}


sub has_relationship {
  #my ($self, $rel) = @_;
  return exists shift->_relationships->{+shift};
}


sub reverse_relationship_info {
  my ($self, $rel) = @_;

  my $rel_info = $self->relationship_info($rel)
    or $self->throw_exception("No such relationship '$rel'");

  my $ret = {};

  return $ret unless ((ref $rel_info->{cond}) eq 'HASH');

  my $stripped_cond = $self->__strip_relcond ($rel_info->{cond});

  my $registered_source_name = $self->source_name;

  # this may be a partial schema or something else equally esoteric
  my $other_rsrc = $self->related_source($rel);

  # Get all the relationships for that source that related to this source
  # whose foreign column set are our self columns on $rel and whose self
  # columns are our foreign columns on $rel
  foreach my $other_rel ($other_rsrc->relationships) {

    # only consider stuff that points back to us
    # "us" here is tricky - if we are in a schema registration, we want
    # to use the source_names, otherwise we will use the actual classes

    # the schema may be partial
    my $roundtrip_rsrc = try { $other_rsrc->related_source($other_rel) }
      or next;

    if ($registered_source_name) {
      next if $registered_source_name ne ($roundtrip_rsrc->source_name || '')
    }
    else {
      next if $self->result_class ne $roundtrip_rsrc->result_class;
    }

    my $other_rel_info = $other_rsrc->relationship_info($other_rel);

    # this can happen when we have a self-referential class
    next if $other_rel_info eq $rel_info;

    next unless ref $other_rel_info->{cond} eq 'HASH';
    my $other_stripped_cond = $self->__strip_relcond($other_rel_info->{cond});

    $ret->{$other_rel} = $other_rel_info if (
      $self->_compare_relationship_keys (
        [ keys %$stripped_cond ], [ values %$other_stripped_cond ]
      )
        and
      $self->_compare_relationship_keys (
        [ values %$stripped_cond ], [ keys %$other_stripped_cond ]
      )
    );
  }

  return $ret;
}

# all this does is removes the foreign/self prefix from a condition
sub __strip_relcond {
  +{
    map
      { map { /^ (?:foreign|self) \. (.+) $/x } ($_, $_[1]{$_}) }
      keys %{$_[1]}
  }
}

# Returns true if both sets of keynames are the same, false otherwise.
sub _compare_relationship_keys {
#  my ($self, $keys1, $keys2) = @_;
  return
    join ("\x00", sort @{$_[1]})
      eq
    join ("\x00", sort @{$_[2]})
  ;
}

# optionally takes either an arrayref of column names, or a hashref of already
# retrieved colinfos
# returns an arrayref of column names of the shortest unique constraint
# (matching some of the input if any), giving preference to the PK
sub _identifying_column_set {
  my ($self, $cols) = @_;

  my %unique = $self->unique_constraints;
  my $colinfos = ref $cols eq 'HASH' ? $cols : $self->columns_info($cols||());

  # always prefer the PK first, and then shortest constraints first
  USET:
  for my $set (delete $unique{primary}, sort { @$a <=> @$b } (values %unique) ) {
    next unless $set && @$set;

    for (@$set) {
      next USET unless ($colinfos->{$_} && !$colinfos->{$_}{is_nullable} );
    }

    # copy so we can mangle it at will
    return [ @$set ];
  }

  return undef;
}

sub _minimal_valueset_satisfying_constraint {
  my $self = shift;
  my $args = { ref $_[0] eq 'HASH' ? %{ $_[0] } : @_ };

  $args->{columns_info} ||= $self->columns_info;

  my $vals = $self->storage->_extract_fixed_condition_columns(
    $args->{values},
    ($args->{carp_on_nulls} ? 'consider_nulls' : undef ),
  );

  my $cols;
  for my $col ($self->unique_constraint_columns($args->{constraint_name}) ) {
    if( ! exists $vals->{$col} or ( $vals->{$col}||'' ) eq UNRESOLVABLE_CONDITION ) {
      $cols->{missing}{$col} = undef;
    }
    elsif( ! defined $vals->{$col} ) {
      $cols->{$args->{carp_on_nulls} ? 'undefined' : 'missing'}{$col} = undef;
    }
    else {
      # we need to inject back the '=' as _extract_fixed_condition_columns
      # will strip it from literals and values alike, resulting in an invalid
      # condition in the end
      $cols->{present}{$col} = { '=' => $vals->{$col} };
    }

    $cols->{fc}{$col} = 1 if (
      ( ! $cols->{missing} or ! exists $cols->{missing}{$col} )
        and
      keys %{ $args->{columns_info}{$col}{_filter_info} || {} }
    );
  }

  $self->throw_exception( sprintf ( "Unable to satisfy requested constraint '%s', missing values for column(s): %s",
    $args->{constraint_name},
    join (', ', map { "'$_'" } sort keys %{$cols->{missing}} ),
  ) ) if $cols->{missing};

  $self->throw_exception( sprintf (
    "Unable to satisfy requested constraint '%s', FilterColumn values not usable for column(s): %s",
    $args->{constraint_name},
    join (', ', map { "'$_'" } sort keys %{$cols->{fc}}),
  )) if $cols->{fc};

  if (
    $cols->{undefined}
      and
    !$ENV{DBIO_NULLABLE_KEY_NOWARN}
  ) {
    carp_unique ( sprintf (
      "NULL/undef values supplied for requested unique constraint '%s' (NULL "
    . 'values in column(s): %s). This is almost certainly not what you wanted, '
    . 'though you can set DBIO_NULLABLE_KEY_NOWARN to disable this warning.',
      $args->{constraint_name},
      join (', ', map { "'$_'" } sort keys %{$cols->{undefined}}),
    ));
  }

  return { map { %{ $cols->{$_}||{} } } qw(present undefined) };
}

# Returns the {from} structure used to express JOIN conditions
sub _resolve_join {
  my ($self, $join, $alias, $seen, $jpath, $parent_force_left) = @_;

  # we need a supplied one, because we do in-place modifications, no returns
  $self->throw_exception ('You must supply a seen hashref as the 3rd argument to _resolve_join')
    unless ref $seen eq 'HASH';

  $self->throw_exception ('You must supply a joinpath arrayref as the 4th argument to _resolve_join')
    unless ref $jpath eq 'ARRAY';

  $jpath = [@$jpath]; # copy

  if (not defined $join or not length $join) {
    return ();
  }
  elsif (ref $join eq 'ARRAY') {
    return
      map {
        $self->_resolve_join($_, $alias, $seen, $jpath, $parent_force_left);
      } @$join;
  }
  elsif (ref $join eq 'HASH') {

    my @ret;
    for my $rel (keys %$join) {

      my $rel_info = $self->relationship_info($rel)
        or $self->throw_exception("No such relationship '$rel' on " . $self->source_name);

      my $force_left = $parent_force_left;
      $force_left ||= lc($rel_info->{attrs}{join_type}||'') eq 'left';

      # the actual seen value will be incremented by the recursion
      my $as = $self->storage->relname_to_table_alias(
        $rel, ($seen->{$rel} && $seen->{$rel} + 1)
      );

      push @ret, (
        $self->_resolve_join($rel, $alias, $seen, [@$jpath], $force_left),
        $self->related_source($rel)->_resolve_join(
          $join->{$rel}, $as, $seen, [@$jpath, { $rel => $as }], $force_left
        )
      );
    }
    return @ret;

  }
  elsif (ref $join) {
    $self->throw_exception("No idea how to resolve join reftype ".ref $join);
  }
  else {
    my $count = ++$seen->{$join};
    my $as = $self->storage->relname_to_table_alias(
      $join, ($count > 1 && $count)
    );

    my $rel_info = $self->relationship_info($join)
      or $self->throw_exception("No such relationship $join on " . $self->source_name);

    my $rel_src = $self->related_source($join);
    return [ { $as => $rel_src->from,
               -rsrc => $rel_src,
               -join_type => $parent_force_left
                  ? 'left'
                  : $rel_info->{attrs}{join_type}
                ,
               -join_path => [@$jpath, { $join => $as } ],
               -is_single => !!(
                  (! $rel_info->{attrs}{accessor})
                    or
                  grep { $rel_info->{attrs}{accessor} eq $_ } (qw/single filter/)
                ),
               -alias => $as,
               -relation_chain_depth => ( $seen->{-relation_chain_depth} || 0 ) + 1,
             },
             scalar $self->_resolve_condition($rel_info->{cond}, $as, $alias, $join)
          ];
  }
}

# Determines whether a relation is dependent on an object from this source
# having already been inserted. Takes the name of the relationship and a
# hashref of columns of the related object.
sub _pk_depends_on {
  my ($self, $rel_name, $rel_data) = @_;

  my $relinfo = $self->relationship_info($rel_name);

  # don't assume things if the relationship direction is specified
  return $relinfo->{attrs}{is_foreign_key_constraint}
    if exists ($relinfo->{attrs}{is_foreign_key_constraint});

  my $cond = $relinfo->{cond};
  return 0 unless ref($cond) eq 'HASH';

  # map { foreign.foo => 'self.bar' } to { bar => 'foo' }
  my $keyhash = { map { my $x = $_; $x =~ s/.*\.//; $x; } reverse %$cond };

  # assume anything that references our PK probably is dependent on us
  # rather than vice versa, unless the far side is (a) defined or (b)
  # auto-increment
  my $rel_source = $self->related_source($rel_name);

  foreach my $p ($self->primary_columns) {
    if (exists $keyhash->{$p}) {
      unless (defined($rel_data->{$keyhash->{$p}})
              || $rel_source->column_info($keyhash->{$p})
                            ->{is_auto_increment}) {
        return 0;
      }
    }
  }

  return 1;
}

# True for a relationship that holds this row's foreign key (belongs_to): the
# related row exists before this one, so multi-create may look it up.
sub _relationship_depends_on {
  my ($self, $rel_name) = @_;

  my $relinfo = $self->relationship_info($rel_name);
  return $relinfo && $relinfo->{attrs}{is_depends_on} ? 1 : 0;
}

# The columns of this source a relationship with a hash condition sets on a
# row of this source, as the foreign key side of the condition names them.
# A condition of any other kind names none here: its columns are known only
# when it is resolved against a value.
sub _relationship_self_columns {
  my ($self, $rel_name) = @_;

  my $cond = ( $self->relationship_info($rel_name) || {} )->{cond};
  return () unless ref $cond eq 'HASH';

  return map { ! ref $_ && $_ =~ /^self\.(.+)/ ? $1 : () } values %$cond;
}

# Mass assignment (ADR 0071): throws for the first column of the list that is
# marked is_guarded.
sub _assert_columns_not_guarded {
  my ($self, @cols) = @_;

  my $columns = $self->_columns;
  for my $col (@cols) {
    $self->throw_exception(sprintf(
      "Column '%s' of source '%s' is guarded (is_guarded) and takes no value "
    . "from new_result, create, update(\\%%hash), update_or_create, populate or multi-create",
      $col, $self->source_name,
    )) if $columns->{$col} and $columns->{$col}{is_guarded};
  }

  return;
}

# Throws unless the relationship takes data in multi-create.
sub _assert_relationship_not_guarded {
  my ($self, $rel_name) = @_;

  my $relinfo = $self->relationship_info($rel_name);

  $self->throw_exception(sprintf(
    "Relationship '%s' of source '%s' is guarded (is_guarded) and takes no data in multi-create",
    $rel_name, $self->source_name,
  )) if $relinfo and $relinfo->{attrs}{is_guarded};

  return;
}

# Mass assignment (ADR 0071): the values the caller assigns ({ column =>
# value }) agree with the equality conditions of the resultset ({ column =>
# value }, undef for IS NULL): the same value, NULL for NULL. A condition that
# is not a plain value (a literal) is not compared.
sub _assert_scope_agrees {
  my ($self, $assigned, $scope) = @_;

  for my $col (sort keys %$assigned) {
    next unless exists $scope->{$col};

    my ($fixed, $got) = ($scope->{$col}, $assigned->{$col});
    next if ref $fixed;

    next if ! defined $fixed and ! defined $got;
    next if defined $fixed and defined $got and ! ref $got and $fixed eq $got;

    # the text names the column and whether a value or NULL is meant, never
    # a value: the values are the caller's and the condition's
    $self->throw_exception(sprintf(
      "create on a scoped resultset: '%s' is fixed to %s by the condition, got %s",
      $col,
      ! defined $fixed ? 'NULL' : 'a value',
      ! defined $got ? 'NULL'
        : ref $got ? 'a ' . ref($got) . ' value'
        : defined $fixed ? 'another value' : 'a value',
    ));
  }

  return;
}

sub _resolve_condition {
#  carp_unique sprintf
#    '_resolve_condition is a private method, and moreover is about to go '
#  . 'away. Please contact the development team at %s if you believe you '
#  . 'have a genuine use for this method, in order to discuss alternatives.',
#    help_url,
#  ;

#######################
### API Design? What's that...? (a backwards compatible shim, kill me now)

  my ($self, $cond, @res_args, $rel_name);

  # we *SIMPLY DON'T KNOW YET* which arg is which, yay
  ($self, $cond, $res_args[0], $res_args[1], $rel_name) = @_;

  # assume that an undef is an object-like unset (set_from_related(undef))
  my @is_objlike = map { ! defined $_ or length ref $_ } (@res_args);

  # turn objlike into proper objects for saner code further down
  for (0,1) {
    next unless $is_objlike[$_];

    if ( defined blessed $res_args[$_] ) {

      # but wait - there is more!!! WHAT THE FUCK?!?!?!?!
      if ($res_args[$_]->isa('DBIO::ResultSet')) {
        carp('Passing a resultset for relationship resolution makes no sense - invoking __gremlins__');
        $is_objlike[$_] = 0;
        $res_args[$_] = '__gremlins__';
      }
    }
    else {
      $res_args[$_] ||= {};

      # hate everywhere - have to pass in as a plain hash
      # pretending to be an object at least for now
      $self->throw_exception("Unsupported object-like structure encountered: $res_args[$_]")
        unless ref $res_args[$_] eq 'HASH';
    }
  }

  my $args = {
    condition => $cond,

    # where-is-waldo block guesses relname, then further down we override it if available
    (
      $is_objlike[1] ? ( rel_name => $res_args[0], self_alias => $res_args[0], foreign_alias => 'me',         self_result_object  => $res_args[1] )
    : $is_objlike[0] ? ( rel_name => $res_args[1], self_alias => 'me',         foreign_alias => $res_args[1], foreign_values      => $res_args[0] )
    :                  ( rel_name => $res_args[0], self_alias => $res_args[1], foreign_alias => $res_args[0]                                      )
    ),

    ( $rel_name ? ( rel_name => $rel_name ) : () ),
  };
#######################

  # now it's fucking easy isn't it?!
  my $rc = $self->_resolve_relationship_condition( $args );

  my @res = (
    ( $rc->{join_free_condition} || $rc->{condition} ),
    ! $rc->{join_free_condition},
  );

  # _resolve_relationship_condition always returns qualified cols even in the
  # case of join_free_condition, but nothing downstream expects this
  if ($rc->{join_free_condition} and ref $res[0] eq 'HASH') {
    $res[0] = { map
      { ($_ =~ /\.(.+)/) => $res[0]{$_} }
      keys %{$res[0]}
    };
  }

  # and more legacy
  return wantarray ? @res : $res[0];
}

# Keep this indefinitely. There is evidence of both CPAN and
# darkpan using it, and there isn't much harm in an extra var
# anyway.
our $UNRESOLVABLE_CONDITION = UNRESOLVABLE_CONDITION;
# YES I KNOW THIS IS EVIL
# it is there to save darkpan from themselves, since internally
# we are moving to a constant
Internals::SvREADONLY($UNRESOLVABLE_CONDITION => 1);

# Resolves the passed condition to a concrete query fragment and extra
# metadata
#
## self-explanatory API, modeled on the custom cond coderef:
# rel_name              => (scalar)
# foreign_alias         => (scalar)
# foreign_values        => (either not supplied, or a hashref, or a foreign ResultObject (to be ->get_columns()ed), or plain undef )
# self_alias            => (scalar)
# self_result_object    => (either not supplied or a result object)
# require_join_free_condition => (boolean, throws on failure to construct a JF-cond)
# infer_values_based_on => (either not supplied or a hashref, implies require_join_free_condition)
# condition             => (sqla cond struct, optional, defeaults to from $self->rel_info(rel_name)->{cond})
#
## returns a hash
# condition           => (a valid *likely fully qualified* sqla cond structure)
# identity_map        => (a hashref of foreign-to-self *unqualified* column equality names)
# join_free_condition => (a valid *fully qualified* sqla cond structure, maybe unset)
# inferred_values     => (in case of an available join_free condition, this is a hashref of
#                         *unqualified* column/value *EQUALITY* pairs, representing an amalgamation
#                         of the JF-cond parse and infer_values_based_on
#                         always either complete or unset)
#
sub _resolve_relationship_condition {
  my $self = shift;

  my $args = { ref $_[0] eq 'HASH' ? %{ $_[0] } : @_ };

  for ( qw( rel_name self_alias foreign_alias ) ) {
    $self->throw_exception("Mandatory argument '$_' to _resolve_relationship_condition() is not a plain string")
      if !defined $args->{$_} or length ref $args->{$_};
  }

  $self->throw_exception("Arguments 'self_alias' and 'foreign_alias' may not be identical")
    if $args->{self_alias} eq $args->{foreign_alias};

# TEMP
  my $exception_rel_id = "relationship '$args->{rel_name}' on source '@{[ $self->source_name ]}'";

  my $rel_info = $self->relationship_info($args->{rel_name})
# TEMP
#    or $self->throw_exception( "No such $exception_rel_id" );
    or carp_unique("Requesting resolution on non-existent relationship '$args->{rel_name}' on source '@{[ $self->source_name ]}': fix your code *soon*, as it will break with the next major version");

# TEMP
  $exception_rel_id = "relationship '$rel_info->{_original_name}' on source '@{[ $self->source_name ]}'"
    if $rel_info and exists $rel_info->{_original_name};

  $self->throw_exception("No practical way to resolve $exception_rel_id between two data structures")
    if exists $args->{self_result_object} and exists $args->{foreign_values};

  $self->throw_exception( "Argument to infer_values_based_on must be a hash" )
    if exists $args->{infer_values_based_on} and ref $args->{infer_values_based_on} ne 'HASH';

  $args->{require_join_free_condition} ||= !!$args->{infer_values_based_on};

  $args->{condition} ||= $rel_info->{cond};

  $self->throw_exception( "Argument 'self_result_object' must be an object inheriting from DBIO::Row" )
    if (
      exists $args->{self_result_object}
        and
      ( ! defined blessed $args->{self_result_object} or ! $args->{self_result_object}->isa('DBIO::Row') )
    )
  ;

#TEMP
  my $rel_rsrc;# = $self->related_source($args->{rel_name});

  if (exists $args->{foreign_values}) {
# TEMP
    $rel_rsrc ||= $self->related_source($args->{rel_name});

    if (defined blessed $args->{foreign_values}) {

      $self->throw_exception( "Objects supplied as 'foreign_values' ($args->{foreign_values}) must inherit from DBIO::Row" )
        unless $args->{foreign_values}->isa('DBIO::Row');

      carp_unique(
        "Objects supplied as 'foreign_values' ($args->{foreign_values}) "
      . "usually should inherit from the related ResultClass ('@{[ $rel_rsrc->result_class ]}'), "
      . "perhaps you've made a mistake invoking the condition resolver?"
      ) unless $args->{foreign_values}->isa($rel_rsrc->result_class);

      my $fvals = { $args->{foreign_values}->get_columns };

      # The very low level resolve_relationship_condition() deliberately contains
      # extra logic to ensure that it isn't passed garbage. Unfortunately we can
      # get into a situation where an object *has* extra columns on it, which
      # the interface of ->get_columns is obligated to return. In order not to
      # compromise the sanity checks within r_r_c, simply do a cleanup pass here.
      #
      # FIXME - perhaps this should warn, but that's a battle for another day
      #
      $args->{foreign_values} = { map {
        exists $fvals->{$_}
          ? ( $_ => $fvals->{$_} )
          : ()
      } $rel_rsrc->columns };
    }
    elsif (! defined $args->{foreign_values} or ref $args->{foreign_values} eq 'HASH') {
      my $ri = { map { $_ => 1 } $rel_rsrc->relationships };
      my $ci = $rel_rsrc->columns_info;
      ! exists $ci->{$_} and ! exists $ri->{$_} and $self->throw_exception(
        "Key '$_' supplied as 'foreign_values' is not a column on related source '@{[ $rel_rsrc->source_name ]}'"
      ) for keys %{ $args->{foreign_values} ||= {} };
    }
    else {
      $self->throw_exception(
        "Argument 'foreign_values' must be either an object inheriting from '@{[ $rel_rsrc->result_class ]}', "
      . "or a hash reference, or undef"
      );
    }
  }

  my $ret;

  if (ref $args->{condition} eq 'CODE') {

    my $cref_args = {
      rel_name => $args->{rel_name},
      self_resultsource => $self,
      self_alias => $args->{self_alias},
      foreign_alias => $args->{foreign_alias},
      ( map
        { (exists $args->{$_}) ? ( $_ => $args->{$_} ) : () }
        qw( self_result_object foreign_values )
      ),
    };

    # legacy - never remove these!!!
    $cref_args->{foreign_relname} = $cref_args->{rel_name};

    $cref_args->{self_rowobj} = $cref_args->{self_result_object}
      if exists $cref_args->{self_result_object};

    ($ret->{condition}, $ret->{join_free_condition}, my @extra) = $args->{condition}->($cref_args);

    # sanity check
    $self->throw_exception("A custom condition coderef can return at most 2 conditions, but $exception_rel_id returned extra values: @extra")
      if @extra;

    if (my $jfc = $ret->{join_free_condition}) {

      $self->throw_exception (
        "The join-free condition returned for $exception_rel_id must be a hash reference"
      ) unless ref $jfc eq 'HASH';

# TEMP
      $rel_rsrc ||= $self->related_source($args->{rel_name});

      my ($joinfree_alias, $joinfree_source);
      if (defined $args->{self_result_object}) {
        $joinfree_alias = $args->{foreign_alias};
        $joinfree_source = $rel_rsrc;
      }
      elsif (defined $args->{foreign_values}) {
        $joinfree_alias = $args->{self_alias};
        $joinfree_source = $self;
      }

      # FIXME sanity check until things stabilize, remove at some point
      $self->throw_exception (
        "A join-free condition returned for $exception_rel_id without a result object to chain from"
      ) unless $joinfree_alias;

      my $fq_col_list = { map
        { ( "$joinfree_alias.$_" => 1 ) }
        $joinfree_source->columns
      };

      exists $fq_col_list->{$_} or $self->throw_exception (
        "The join-free condition returned for $exception_rel_id may only "
      . 'contain keys that are fully qualified column names of the corresponding source '
      . "(it returned '$_')"
      ) for keys %$jfc;

      (
        length ref $_
          and
        defined blessed($_)
          and
        $_->isa('DBIO::Row')
          and
        $self->throw_exception (
          "The join-free condition returned for $exception_rel_id may not "
        . 'contain result objects as values - perhaps instead of invoking '
        . '->$something you meant to return ->get_column($something)'
        )
      ) for values %$jfc;

    }
  }
  elsif (ref $args->{condition} eq 'HASH') {

    # the condition is static - use parallel arrays
    # for a "pivot" depending on which side of the
    # rel did we get as an object
    my (@f_cols, @l_cols);
    for my $fc (keys %{$args->{condition}}) {
      my $lc = $args->{condition}{$fc};

      # FIXME STRICTMODE should probably check these are valid columns
      $fc =~ s/^foreign\.// ||
        $self->throw_exception("Invalid rel cond key '$fc'");

      $lc =~ s/^self\.// ||
        $self->throw_exception("Invalid rel cond val '$lc'");

      push @f_cols, $fc;
      push @l_cols, $lc;
    }

    # construct the crosstable condition and the identity map
    for  (0..$#f_cols) {
      $ret->{condition}{"$args->{foreign_alias}.$f_cols[$_]"} = { -ident => "$args->{self_alias}.$l_cols[$_]" };
      $ret->{identity_map}{$l_cols[$_]} = $f_cols[$_];
    };

    if ($args->{foreign_values}) {
      $ret->{join_free_condition}{"$args->{self_alias}.$l_cols[$_]"} = $args->{foreign_values}{$f_cols[$_]}
        for 0..$#f_cols;
    }
    elsif (defined $args->{self_result_object}) {

      for my $i (0..$#l_cols) {
        if ( $args->{self_result_object}->has_column_loaded($l_cols[$i]) ) {
          $ret->{join_free_condition}{"$args->{foreign_alias}.$f_cols[$i]"} = $args->{self_result_object}->get_column($l_cols[$i]);
        }
        else {
          $self->throw_exception(sprintf
            "Unable to resolve relationship '%s' from object '%s': column '%s' not "
          . 'loaded from storage (or not passed to new() prior to insert()). You '
          . 'probably need to call ->discard_changes to get the server-side defaults '
          . 'from the database.',
            $args->{rel_name},
            $args->{self_result_object},
            $l_cols[$i],
          ) if $args->{self_result_object}->in_storage;

          # FIXME - temporarly force-override
          delete $args->{require_join_free_condition};
          $ret->{join_free_condition} = UNRESOLVABLE_CONDITION;
          last;
        }
      }
    }
  }
  elsif (ref $args->{condition} eq 'ARRAY') {
    if (@{$args->{condition}} == 0) {
      $ret = {
        condition => UNRESOLVABLE_CONDITION,
        join_free_condition => UNRESOLVABLE_CONDITION,
      };
    }
    elsif (@{$args->{condition}} == 1) {
      $ret = $self->_resolve_relationship_condition({
        %$args,
        condition => $args->{condition}[0],
      });
    }
    else {
      # we are discarding inferred values here... likely incorrect...
      # then again - the entire thing is an OR, so we *can't* use them anyway
      for my $subcond ( map
        { $self->_resolve_relationship_condition({ %$args, condition => $_ }) }
        @{$args->{condition}}
      ) {
        $self->throw_exception('Either all or none of the OR-condition members must resolve to a join-free condition')
          if ( $ret and ( $ret->{join_free_condition} xor $subcond->{join_free_condition} ) );

        $subcond->{$_} and push @{$ret->{$_}}, $subcond->{$_} for (qw(condition join_free_condition));
      }
    }
  }
  else {
    $self->throw_exception ("Can't handle condition $args->{condition} for $exception_rel_id yet :(");
  }

  $self->throw_exception(ucfirst "$exception_rel_id does not resolve to a join-free condition fragment") if (
    $args->{require_join_free_condition}
      and
    ( ! $ret->{join_free_condition} or $ret->{join_free_condition} eq UNRESOLVABLE_CONDITION )
  );

  my $storage = $self->schema->storage;

  # we got something back - sanity check and infer values if we can
  my @nonvalues;
  if ( my $jfc = $ret->{join_free_condition} and $ret->{join_free_condition} ne UNRESOLVABLE_CONDITION ) {

    my $jfc_eqs = $storage->_extract_fixed_condition_columns($jfc, 'consider_nulls');

    if (keys %$jfc_eqs) {

      for (keys %$jfc) {
        # $jfc is fully qualified by definition
        my ($col) = $_ =~ /\.(.+)/;

        if (exists $jfc_eqs->{$_} and ($jfc_eqs->{$_}||'') ne UNRESOLVABLE_CONDITION) {
          $ret->{inferred_values}{$col} = $jfc_eqs->{$_};
        }
        elsif ( !$args->{infer_values_based_on} or ! exists $args->{infer_values_based_on}{$col} ) {
          push @nonvalues, $col;
        }
      }

      # all or nothing
      delete $ret->{inferred_values} if @nonvalues;
    }
  }

  # did the user explicitly ask
  if ($args->{infer_values_based_on}) {

    $self->throw_exception(sprintf (
      "Unable to complete value inferrence - custom $exception_rel_id returns conditions instead of values for column(s): %s",
      map { "'$_'" } @nonvalues
    )) if @nonvalues;


    $ret->{inferred_values} ||= {};

    $ret->{inferred_values}{$_} = $args->{infer_values_based_on}{$_}
      for keys %{$args->{infer_values_based_on}};
  }

  # add the identities based on the main condition
  # (may already be there, since easy to calculate on the fly in the HASH case)
  if ( ! $ret->{identity_map} ) {

    my $col_eqs = $storage->_extract_fixed_condition_columns($ret->{condition});

    my $colinfos;
    for my $lhs (keys %$col_eqs) {

      next if $col_eqs->{$lhs} eq UNRESOLVABLE_CONDITION;

# TEMP
      $rel_rsrc ||= $self->related_source($args->{rel_name});

      # there is no way to know who is right and who is left in a cref
      # therefore a full blown resolution call, and figure out the
      # direction a bit further below
      $colinfos ||= $storage->_resolve_column_info([
        { -alias => $args->{self_alias}, -rsrc => $self },
        { -alias => $args->{foreign_alias}, -rsrc => $rel_rsrc },
      ]);

      next unless $colinfos->{$lhs};  # someone is engaging in witchcraft

      if ( my $rhs_ref = is_literal_value( $col_eqs->{$lhs} ) ) {

        if (
          $colinfos->{$rhs_ref->[0]}
            and
          $colinfos->{$lhs}{-source_alias} ne $colinfos->{$rhs_ref->[0]}{-source_alias}
        ) {
          ( $colinfos->{$lhs}{-source_alias} eq $args->{self_alias} )
            ? ( $ret->{identity_map}{$colinfos->{$lhs}{-colname}} = $colinfos->{$rhs_ref->[0]}{-colname} )
            : ( $ret->{identity_map}{$colinfos->{$rhs_ref->[0]}{-colname}} = $colinfos->{$lhs}{-colname} )
          ;
        }
      }
      elsif (
        $col_eqs->{$lhs} =~ /^ ( \Q$args->{self_alias}\E \. .+ ) /x
          and
        ($colinfos->{$1}||{})->{-result_source} == $rel_rsrc
      ) {
        my ($lcol, $rcol) = map
          { $colinfos->{$_}{-colname} }
          ( $lhs, $1 )
        ;
        carp_unique(
          "The $exception_rel_id specifies equality of column '$lcol' and the "
        . "*VALUE* '$rcol' (you did not use the { -ident => ... } operator)"
        );
      }
    }
  }

  # FIXME - temporary, to fool the idiotic check in SQLMaker::_join_condition
  $ret->{condition} = { -and => [ $ret->{condition} ] }
    unless $ret->{condition} eq UNRESOLVABLE_CONDITION;

  $ret;
}


sub related_source {
  my ($self, $rel) = @_;
  if( !$self->has_relationship( $rel ) ) {
    $self->throw_exception("No such relationship '$rel' on " . $self->source_name);
  }

  # if we are not registered with a schema - just use the prototype
  # however if we do have a schema - ask for the source by name (and
  # throw in the process if all fails)
  if (my $schema = try { $self->schema }) {
    $schema->source($self->relationship_info($rel)->{source});
  }
  else {
    my $class = $self->relationship_info($rel)->{class};
    $self->ensure_class_loaded($class);
    $class->result_source_instance;
  }
}


sub related_class {
  my ($self, $rel) = @_;
  if( !$self->has_relationship( $rel ) ) {
    $self->throw_exception("No such relationship '$rel' on " . $self->source_name);
  }
  return $self->schema->class($self->relationship_info($rel)->{source});
}

my $global_phase_destroy;
sub DESTROY {
  ### NO detected_reinvoked_destructor check
  ### This code very much relies on being called multuple times

  return if $global_phase_destroy ||= in_global_destruction;

######
# !!! ACHTUNG !!!!
######
#
# Under no circumstances shall $_[0] be stored anywhere else (like copied to
# a lexical variable, or shifted, or anything else). Doing so will mess up
# the refcount of this particular result source, and will allow the $schema
# we are trying to save to reattach back to the source we are destroying.
# The relevant code checking refcounts is in ::Schema::DESTROY()

  # if we are not a schema instance holder - we don't matter
  return if(
    ! ref $_[0]->{schema}
      or
    isweak $_[0]->{schema}
  );

  # weaken our schema hold forcing the schema to find somewhere else to live
  # during global destruction (if we have not yet bailed out) this will throw
  # which will serve as a signal to not try doing anything else
  # however beware - on older perls the exception seems randomly untrappable
  # due to some weird race condition during thread joining :(((
  local $@;
  eval {
    weaken $_[0]->{schema};

    # if schema is still there reintroduce ourselves with strong refs back to us
    if ($_[0]->{schema}) {
      my $srcregs = $_[0]->{schema}->source_registrations;
      for (keys %$srcregs) {
        next unless $srcregs->{$_};
        $srcregs->{$_} = $_[0] if $srcregs->{$_} == $_[0];
      }
    }

    1;
  } or do {
    $global_phase_destroy = 1;
  };

  return;
}

# Schema instance to (re)attach to while thawing. Localized by
# $schema->thaw / $schema->dclone (see DBIO::Schema); left unset for a
# schema-less Storable::dclone, which then resolves a detached source.
our $thaw_schema;

sub STORABLE_freeze {
  my ($self) = @_;

  # A ResultSource is not serialized directly (it may carry CODErefs in
  # relationship definitions and a schema backref). Freeze only the minimal
  # identity needed to re-resolve the canonical source on thaw.
  Storable::nfreeze({
    source_moniker => $self->source_name,
    _frozen_from_class => $self->{_detached_thaw}
      ? $self->result_class
      : $self->schema->class($self->source_name),
  });
}


sub STORABLE_thaw {
  my ($self, $cloning, $ice) = @_;

  my $frozen = Storable::thaw($ice);
  my $moniker = $frozen->{source_moniker};
  my $from_class = $frozen->{_frozen_from_class};

  DBIO::Util::assert_class_name($from_class);

  my $resolved;
  if ($thaw_schema) {
    DBIO::Exception->throw(
      "Thaw failed - class '$from_class' is not the result class of a source registered on the schema"
    ) unless grep { $_ and $_->result_class eq $from_class }
      values %{ $thaw_schema->source_registrations };

    $resolved = $thaw_schema->source($moniker);
  }
  elsif ($from_class->isa('DBIO::ResultSourceProxy') and my $rs = $from_class->result_source_instance) {
    # A class-level result source only counts as a resolution channel if it
    # holds an actual schema *instance*. A schema *class name* is not good
    # enough: that is what compose_namespace leaves on the composed result
    # classes, and such a source has no storage, so resolving through it hands
    # out a half-attached source that blows up with an obscure "method call on
    # an undefined value" the first time anything storage-dependent runs.
    my $leaked_schema = try { $rs->schema };

    if (blessed $leaked_schema) {
      $resolved = $leaked_schema->source($moniker);
    }
    else {
      # Detached: metadata still works, every storage-dependent operation
      # throws a pointed exception naming $schema->thaw / $thaw_schema. Copy
      # rather than brand the shared class-level source itself.
      $resolved = bless {
        %$rs,
        schema => undef,
        source_name => $moniker,
        _detached_thaw => 1,
      }, ref $rs;
    }
  }
  else {
    DBIO::Exception->throw(
      "Thaw failed - original result class '$from_class' does not exist on this system"
    );
  }

  %$self = %$resolved;
}


sub throw_exception {
  my $self = shift;

  $self->{schema}
    ? $self->{schema}->throw_exception(@_)
    : DBIO::Exception->throw(@_)
  ;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ResultSource - Metadata object describing a table, view, or query source

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  # Create a table based result source, in a result class.

  package MyApp::Schema::Result::Artist;
  use base qw/DBIO::Core/;

  __PACKAGE__->table('artist');
  __PACKAGE__->add_columns(qw/ artistid name /);
  __PACKAGE__->set_primary_key('artistid');
  __PACKAGE__->has_many(cds => 'MyApp::Schema::Result::CD');

  1;

  # Create a query (view) based result source, in a result class
  package MyApp::Schema::Result::Year2000CDs;
  use base qw/DBIO::Core/;

  __PACKAGE__->load_components('InflateColumn::DateTime');
  __PACKAGE__->table_class('DBIO::ResultSource::View');

  __PACKAGE__->table('year2000cds');
  __PACKAGE__->result_source_instance->is_virtual(1);
  __PACKAGE__->result_source_instance->view_definition(
      "SELECT cdid, artist, title FROM cd WHERE year ='2000'"
      );

See F<t/101source.t> for a runnable example.

=head1 DESCRIPTION

A ResultSource describes the database object behind a result class: usually a
table, sometimes a view, and occasionally another query-like source.

This class is a base class for various specialised types of result
sources, for example L<DBIO::ResultSource::Table>. Table is the
default result source type, so one is created for you when defining a
result class as described in the synopsis above.

More specifically, the L<DBIO::Core> base class pulls in the
L<DBIO::ResultSourceProxy> component, which defines
the L<table|DBIO::ResultSourceProxy/table> method.
When called, C<table> creates and stores an instance of
L<DBIO::ResultSource::Table>. Luckily, to use tables as result
sources, you usually do not need to think about any of this machinery.

Result sources representing select queries, or views, can also be
created, see L<DBIO::ResultSource::View> for full details.

=head2 Finding result source objects

As mentioned above, a result source instance is created and stored for
you when you define a
L<Result Class|DBIO::Manual::Glossary/Result Class>.

You can retrieve the result source at runtime in the following ways:

=over

=item From a Schema object:

   $schema->source($source_name);

=item From a Result object:

   $result->result_source;

=item From a ResultSet object:

   $rs->result_source;

=back

=head1 METHODS

=head2 new

  $class->new();

  $class->new({attribute_name => value});

Creates a new ResultSource object.  Not normally called directly by end users.

=head2 add_columns

=over

=item Arguments: @columns

=item Return Value: L<$result_source|/new>

=back

  $source->add_columns(qw/col1 col2 col3/);

  $source->add_columns('col1' => \%col1_info, 'col2' => \%col2_info, ...);

  $source->add_columns(
    'col1' => { data_type => 'integer', is_nullable => 1, ... },
    'col2' => { data_type => 'text',    is_auto_increment => 1, ... },
  );

Adds columns to the result source. If supplied colname => hashref
pairs, uses the hashref as the L</column_info> for that column. Repeated
calls of this method will add more columns, not replace them.

The column names given will be created as accessor methods on your
L<Result|DBIO::Manual::ResultClass> objects. You can change the name of the accessor
by supplying an L</accessor> in the column_info hash.

If a column name beginning with a plus sign ('+col1') is provided, the
attributes provided will be merged with any existing attributes for the
column, with the new attributes taking precedence in the case that an
attribute already exists. Using this without a hashref
(C<< $source->add_columns(qw/+col1 +col2/) >>) is legal, but useless --
it does the same thing it would do without the plus.

The contents of the column_info are not set in stone. The following
keys are currently recognised/used by DBIO:

=over 4

=item accessor

   { accessor => '_name' }

   # example use, replace standard accessor with one of your own:
   sub name {
       my ($self, $value) = @_;

       die "Name cannot contain digits!" if($value =~ /\d/);
       $self->_name($value);

       return $self->_name();
   }

Use this to set the name of the accessor method for this column. If unset,
the name of the column will be used.

=item data_type

   { data_type => 'integer' }

This contains the column type. It is automatically filled if you generate
your classes with L<DBIO::Generate> (via L<dbiogen>).

Currently there is no standard set of values for the data_type. Use
whatever your database supports.

=item size

   { size => 20 }

The length of your column, if it is a column type that can have a size
restriction. This is currently only used to create tables from your
schema, see L<DBIO::Schema/deploy>.

   { size => [ 9, 6 ] }

For decimal or float values you can specify an ArrayRef in order to
control precision, assuming your database's producer supports it.

=item is_nullable

   { is_nullable => 1 }

Set this to a true value for a column that is allowed to contain NULL
values, default is false. This is currently only used to create tables
from your schema, see L<DBIO::Schema/deploy>.

=item is_auto_increment

   { is_auto_increment => 1 }

Set this to a true value for a column whose value is somehow
automatically set, defaults to false. This is used to determine which
columns to empty when cloning objects using
L<DBIO::Row/copy>. It is also used by
L<DBIO::Schema/deploy>.

=item is_numeric

   { is_numeric => 1 }

Set this to a true or false value (not C<undef>) to explicitly specify
if this column contains numeric data. This controls how set_column
decides whether to consider a column dirty after an update: if
C<is_numeric> is true a numeric comparison C<< != >> will take place
instead of the usual C<eq>

If not specified the storage class will attempt to figure this out on
first access to the column, based on the column C<data_type>. The
result will be cached in this attribute.

=item is_foreign_key

   { is_foreign_key => 1 }

Set this to a true value for a column that contains a key from a
foreign table, defaults to false. This is currently only used to
create tables from your schema, see L<DBIO::Schema/deploy>.

=item is_guarded

   { is_guarded => 1 }

Set this to a true value for a column that no hash of values takes: a
hashref given to L<DBIO::ResultSet/new_result>, L<DBIO::ResultSet/create>,
L<DBIO::Row/update>, L<DBIO::ResultSet/update_or_create>,
L<DBIO::ResultSet/populate> or a multi-create structure throws when it
assigns this column, also when a relationship value of the hash sets it as
foreign key. The accessor, L<DBIO::Row/set_column> and C<update> without a
hash set it. A value the resultset's own condition holds is inherited, it is
no assignment of the caller's. Defaults to false.

=item default_value

   { default_value => \'now()' }

Set this to the default value which will be inserted into a column by
the database. Can contain either a value or a function (use a
reference to a scalar e.g. C<\'now()'> if you want a function). This
is currently only used to create tables from your schema, see
L<DBIO::Schema/deploy>.

See the note on L<DBIO::Row/new> for more information about possible
issues related to db-side default values.

=item sequence

   { sequence => 'my_table_seq' }

Set this on a primary key column to the name of the sequence used to
generate a new key value. If not specified, DBIO will attempt to
retrieve the name of the sequence from the database automatically.

=item retrieve_on_insert

  { retrieve_on_insert => 1 }

For every column where this is set to true, DBIO will retrieve the RDBMS-side
value upon a new row insertion (normally only the autoincrement PK is
retrieved on insert). C<INSERT ... RETURNING> is used automatically if
supported by the underlying storage, otherwise an extra SELECT statement is
executed to retrieve the missing data.

=item auto_nextval

   { auto_nextval => 1 }

Set this to a true value for a column whose value is retrieved automatically
from a sequence or function (if supported by your Storage driver.) For a
sequence, if you do not use a trigger to get the nextval, you have to set the
L</sequence> value as well.

Also set this for MSSQL columns with the 'uniqueidentifier'
L<data_type|DBIO::ResultSource/data_type> whose values you want to
automatically generate using C<NEWID()>, unless they are a primary key in which
case this will be done anyway.

A storage that can do neither -- its engine has no sequences, and the column
is not a GUID column of a storage that generates GUIDs
(L<DBIO::Storage::DBI::UniqueIdentifier>) -- refuses to insert a row that
leaves such a column out: it throws an exception naming the column and the
storage class, before anything is sent to the database. Give the column a
value, or do not set C<auto_nextval>. Literal SQL does not count as a value
here: where the value comes from a sequence, the fetched value replaces it.

=item extra

Arbitrary extra non-generic data to add to the column. For example:
C<< extra => { unsigned => 1 } >> is used by the MySQL producer to set an
integer column to unsigned.

=back

=head2 add_column

=over

=item Arguments: $colname, \%columninfo?

=item Return Value: 1/0 (true/false)

=back

  $source->add_column('col' => \%info);

Add a single column and optional column info. Uses the same column
info keys as L</add_columns>.

=head2 add_columns

Adds one or more columns (and optional column metadata) to the result source.

See the C<add_column>/C<add_columns> documentation above for supported
metadata keys and merge behavior.

=head2 add_column

Convenience wrapper for adding a single column definition via L</add_columns>.

=head2 remove_column

Convenience wrapper for removing a single column via L</remove_columns>.

=head2 resultset

Returns a new resultset instance for this source, seeded with schema defaults
and source-level C<resultset_attributes>.

=head2 STORABLE_thaw

The L<Storable> hook that turns the frozen identity of a source back into the
source. Thaw only data of your own, from a source you trust -- Storable
creates objects of whatever class the data names. The class the data names
is checked: it is a class name, and with a schema (L<DBIO::Schema/thaw>,
L<DBIO::Schema/dclone>) it is the result class of one of the schema's
registered sources; without a schema it is a loaded result class (a DBIO::ResultSourceProxy).

=head2 has_column

=over

=item Arguments: $colname

=item Return Value: 1/0 (true/false)

=back

  if ($source->has_column($colname)) { ... }

Returns true if the source has a column of this name, false otherwise.

=head2 column_info

=over

=item Arguments: $colname

=item Return Value: Hashref of info

=back

  my $info = $source->column_info($col);

Returns the column metadata hashref for a column, as originally passed
to L</add_columns>. See L</add_columns> above for information on the
contents of the hashref.

=head2 columns

=over

=item Arguments: none

=item Return Value: Ordered list of column names

=back

  my @column_names = $source->columns;

Returns all column names in the order they were declared to L</add_columns>.

=head2 columns_info

=over

=item Arguments: \@colnames ?

=item Return Value: Hashref of column name/info pairs

=back

  my $columns_info = $source->columns_info;

Like L</column_info> but returns information for the requested columns. If
the optional column-list arrayref is omitted it returns info on all columns
currently defined on the ResultSource via L</add_columns>.

=head2 remove_columns

=over

=item Arguments: @colnames

=item Return Value: not defined

=back

  $source->remove_columns(qw/col1 col2 col3/);

Removes the given list of columns by name, from the result source.

B<Warning>: Removing a column that is also used in the sources primary
key, or in one of the sources unique constraints, B<will> result in a
broken result source.

=head2 remove_column

=over

=item Arguments: $colname

=item Return Value: not defined

=back

  $source->remove_column('col');

Remove a single column by name from the result source, similar to
L</remove_columns>.

B<Warning>: Removing a column that is also used in the sources primary
key, or in one of the sources unique constraints, B<will> result in a
broken result source.

=head2 set_primary_key

=over 4

=item Arguments: @cols

=item Return Value: not defined

=back

Defines one or more columns as primary key for this source. Must be
called after L</add_columns>.

Additionally, defines a L<unique constraint|/add_unique_constraint>
named C<primary>.

Note: you normally do want to define a primary key on your sources
B<even if the underlying database table does not have a primary key>.
See
L<DBIO::Manual::Intro/The Significance and Importance of Primary Keys>
for more info.

=head2 primary_columns

=over 4

=item Arguments: none

=item Return Value: Ordered list of primary column names

=back

Read-only accessor which returns the list of primary keys, supplied by
L</set_primary_key>.

=head2 sequence

Manually define the correct sequence for your table, to avoid the overhead
associated with looking up the sequence automatically. The supplied sequence
will be applied to the L</column_info> of each L<primary_key|/set_primary_key>

=over 4

=item Arguments: $sequence_name

=item Return Value: not defined

=back

=head2 add_unique_constraint

=over 4

=item Arguments: $name?, \@colnames

=item Return Value: not defined

=back

Declare a unique constraint on this source. Call once for each unique
constraint.

  # For UNIQUE (column1, column2)
  __PACKAGE__->add_unique_constraint(
    constraint_name => [ qw/column1 column2/ ],
  );

Alternatively, you can specify only the columns:

  __PACKAGE__->add_unique_constraint([ qw/column1 column2/ ]);

This will result in a unique constraint named
C<table_column1_column2>, where C<table> is replaced with the table
name.

Unique constraints are used, for example, when you pass the constraint
name as the C<key> attribute to L<DBIO::ResultSet/find>. Then
only columns in the constraint are searched.

Throws an error if any of the given column names do not yet exist on
the result source.

=head2 add_unique_constraints

=over 4

=item Arguments: @constraints

=item Return Value: not defined

=back

Declare multiple unique constraints on this source.

  __PACKAGE__->add_unique_constraints(
    constraint_name1 => [ qw/column1 column2/ ],
    constraint_name2 => [ qw/column2 column3/ ],
  );

Alternatively, you can specify only the columns:

  __PACKAGE__->add_unique_constraints(
    [ qw/column1 column2/ ],
    [ qw/column3 column4/ ]
  );

This will result in unique constraints named C<table_column1_column2> and
C<table_column3_column4>, where C<table> is replaced with the table name.

Throws an error if any of the given column names do not yet exist on
the result source.

See also L</add_unique_constraint>.

=head2 name_unique_constraint

=over 4

=item Arguments: \@colnames

=item Return Value: Constraint name

=back

  $source->table('mytable');
  $source->name_unique_constraint(['col1', 'col2']);
  # returns
  'mytable_col1_col2'

Return a name for a unique constraint containing the specified
columns. The name is created by joining the table name and each column
name, using an underscore character.

For example, a constraint on a table named C<cd> containing the columns
C<artist> and C<title> would result in a constraint name of C<cd_artist_title>.

This is used by L</add_unique_constraint> if you do not specify the
optional constraint name.

=head2 unique_constraints

=over 4

=item Arguments: none

=item Return Value: Hash of unique constraint data

=back

  $source->unique_constraints();

Read-only accessor which returns a hash of unique constraints on this
source.

The hash is keyed by constraint name, and contains an arrayref of
column names as values.

=head2 add_index_declaration

=over 4

=item Arguments: \%declaration

=item Return Value: not defined

=back

  $source->add_index_declaration({
    name    => 'artist_name_city',
    columns => ['name', 'city'],
    unique  => 1,
    driver  => { pg => { where => 'city IS NOT NULL' } },
  });

Declares a secondary index on this source. This is the one canonical place
for index declarations: L<DBIO::Cake/idx> and
L<DBIO::ResultSourceProxy/indices> fill it, and a driver reads it back with
L</index_declarations>.

The keys are

=over 4

=item name

Required. The index name; a second declaration with the same name replaces
the first one at its position.

=item columns

Required. A column name or an arrayref of column names. A single name is
promoted to a one-element arrayref.

=item unique

True for a unique index. A C<type> that matches C<unique> (any case) sets it
as well.

=item type

Optional, kept as given.

=item options

Optional, kept as given.

=item driver

Optional hashref of per-driver blocks, keyed by driver name, each a hashref.
The accepted names are those of L</index_declaration_drivers>. A schema is
bound to one driver, so its driver reads its own block through
L</index_declarations_for>.

=back

The entry is stored as
C<< { name, columns => [...], unique => 0|1, type, options, driver => {...} } >>
with C<type> and C<options> C<undef> when not given.

Throws on a missing name, on missing or empty C<columns>, and on a
C<driver> that is not a hashref of hashrefs or names a driver other than
those of L</index_declaration_drivers>. The columns are not checked
against the source, so an index may be declared before its columns are.

=head2 index_declarations

=over 4

=item Arguments: none

=item Return Value: @declarations

=back

  for my $idx ($source->index_declarations) {
    # $idx->{name}, $idx->{columns}, $idx->{unique}, $idx->{driver}{pg}, ...
  }

The index declarations of this source, in declaration order, as the
canonical entries L</add_index_declaration> stores. The entries are copies:
changing them does not change the source.

=head2 index_declaration_drivers

=over 4

=item Arguments: none

=item Return Value: @driver_names

=back

The driver names an index declaration may carry a block for: C<pg>,
C<sqlite>, C<mysql>, C<oracle>, C<mssql>, C<sybase>, C<firebird>,
C<clickhouse>, C<duckdb>, C<db2>, C<informix>. This is the one list; L</add_index_declaration>,
L<DBIO::Cake/idx> and L</index_declarations_for> go by it.

=head2 index_declarations_for

=over 4

=item Arguments: $driver, \@allowed_keys

=item Return Value: @declarations

=back

  for my $idx ($source->index_declarations_for('sqlite', [qw(where expression)])) {
    my $own = $idx->{driver}{sqlite} || {};
    # build CREATE [UNIQUE] INDEX from $idx->{columns}, $idx->{unique}, $own
  }

The index declarations of this source for the driver C<$driver>, in
declaration order, as copies, like L</index_declarations>. This is the reader
a driver's DDL emitter uses: a schema is bound to one driver, and an index
declaration is driver-specific, so the entries are checked for that driver
before any index is emitted. It throws, naming the source, the index and the
driver, when

=over 4

=item *

an entry carries only the block of another driver and none of C<$driver>'s.
The row- or expression-defining part of it is not this driver's to guess;
an empty own block (C<< sqlite =E<gt> {} >>) says that the plain index is
wanted.

=item *

the entry's own block holds a key that is not in C<\@allowed_keys>.

=back

An entry without any driver block is a plain index and is returned as is.
C<$driver> must be one of L</index_declaration_drivers>.

=head2 unique_constraint_names

=over 4

=item Arguments: none

=item Return Value: Unique constraint names

=back

  $source->unique_constraint_names();

Returns the list of unique constraint names defined on this source.

=head2 unique_constraint_columns

=over 4

=item Arguments: $constraintname

=item Return Value: List of constraint columns

=back

  $source->unique_constraint_columns('myconstraint');

Returns the list of columns that make up the specified unique constraint.

=head2 sqlt_deploy_callback

=over

=item Arguments: $callback_name | \&callback_code

=item Return Value: $callback_name | \&callback_code

=back

  __PACKAGE__->sqlt_deploy_callback('mycallbackmethod');

   or

  __PACKAGE__->sqlt_deploy_callback(sub {
    my ($source_instance, $sqlt_table) = @_;
    ...
  } );

An accessor to set a callback to be called during deployment of
the schema via L<DBIO::Schema/deploy>.

B<DEPRECATED:> This callback was designed for legacy deployment and is a
no-op in core DBIO. It is retained for API compatibility but will not be
called by native Deploy implementations.

The callback can be set as either a code reference or the name of a
method in the current result class.

Defaults to L</default_sqlt_deploy_hook>.

Your callback will be passed the $source object representing the
ResultSource instance being deployed. The callback can be used to
manipulate the table object or add your own customised indexes.

=head2 default_sqlt_deploy_hook

This is the default deploy hook implementation which checks if your
current Result class has a C<sqlt_deploy_hook> method, and if present
invokes it B<on the Result class directly>. This is to preserve the
semantics of C<sqlt_deploy_hook> for backwards compatibility.

B<DEPRECATED:> This method is a no-op for native Deploy; it only
exists for API compatibility.

=head2 result_class

=over 4

=item Arguments: $classname

=item Return Value: $classname

=back

 use My::Schema::ResultClass::Inflator;
 ...

 use My::Schema::Artist;
 ...
 __PACKAGE__->result_class('My::Schema::ResultClass::Inflator');

Set the default result class for this source. You can use this to create
and use your own result inflator. See L<DBIO::ResultSet/result_class>
for more details.

Please note that setting this to something like
L<DBIO::ResultClass::HashRefInflator> will make every result unblessed
and make life more difficult.  Inflators like those are better suited to
temporary usage via L<DBIO::ResultSet/result_class>.

=head2 resultset

=over 4

=item Arguments: none

=item Return Value: L<$resultset|DBIO::ResultSet>

=back

Returns a resultset for the given source, freshly created on each call by

  $self->resultset_class->new($self, $self->resultset_attributes)

=head2 resultset_class

=over 4

=item Arguments: $classname

=item Return Value: $classname

=back

  package My::Schema::ResultSet::Artist;
  use base 'DBIO::ResultSet';
  ...

  # In the result class
  __PACKAGE__->resultset_class('My::Schema::ResultSet::Artist');

  # Or in code
  $source->resultset_class('My::Schema::ResultSet::Artist');

Set the class of the resultset. This is useful if you want to create your
own resultset methods. Create your own class derived from
L<DBIO::ResultSet>, and set it here. If called with no arguments,
this method returns the name of the existing resultset class, if one
exists.

=head2 resultset_attributes

=over 4

=item Arguments: L<\%attrs|DBIO::ResultSet/ATTRIBUTES>

=item Return Value: L<\%attrs|DBIO::ResultSet/ATTRIBUTES>

=back

  # In the result class
  __PACKAGE__->resultset_attributes({ order_by => [ 'id' ] });

  # Or in code
  $source->resultset_attributes({ order_by => [ 'id' ] });

Store a collection of resultset attributes, that will be set on every
L<DBIO::ResultSet> produced from this result source.

B<CAVEAT>: C<resultset_attributes> comes with its own set of issues and
bugs! While C<resultset_attributes> isn't deprecated per se, its usage is
not recommended!

Since relationships use attributes to link tables together, the "default"
attributes you set may cause unpredictable and undesired behavior.  Furthermore,
the defaults cannot be turned off, so you are stuck with them.

In most cases, what you should actually be using are project-specific methods:

  package My::Schema::ResultSet::Artist;
  use base 'DBIO::ResultSet';
  ...

  # BAD IDEA!
  #__PACKAGE__->resultset_attributes({ prefetch => 'tracks' });

  # GOOD IDEA!
  sub with_tracks { shift->search({}, { prefetch => 'tracks' }) }

  # in your code
  $schema->resultset('Artist')->with_tracks->...

This gives you the flexibility of not using it when you don't need it.

For more complex situations, another solution would be to use a virtual view
via L<DBIO::ResultSource::View>.

=head2 name

=over 4

=item Arguments: none

=item Result value: $name

=back

Returns the name of the result source, which will typically be the table
name. This may be a scalar reference if the result source has a non-standard
name.

=head2 source_name

=over 4

=item Arguments: $source_name

=item Result value: $source_name

=back

Set an alternate name for the result source when it is loaded into a schema.
This is useful if you want to refer to a result source by a name other than
its class name.

  package ArchivedBooks;
  use base qw/DBIO::Core/;
  __PACKAGE__->table('books_archive');
  __PACKAGE__->source_name('Books');

  # from your schema...
  $schema->resultset('Books')->find(1);

=head2 from

=over 4

=item Arguments: none

=item Return Value: FROM clause

=back

  my $from_clause = $source->from();

Returns an expression of the source to be supplied to storage to specify
retrieval from this source. In the case of a database, the required FROM
clause contents.

=head2 source_info

Stores a hashref of per-source metadata.  No specific key names
have yet been standardized, the examples below are purely hypothetical
and don't actually accomplish anything on their own:

  __PACKAGE__->source_info({
    "_tablespace" => 'fast_disk_array_3',
    "_engine" => 'InnoDB',
  });

=head2 schema

=over 4

=item Arguments: L<$schema?|DBIO::Schema>

=item Return Value: L<$schema|DBIO::Schema>

=back

  my $schema = $source->schema();

Sets and/or returns the L<DBIO::Schema> object to which this
result source instance has been attached to.

=head2 storage

=over 4

=item Arguments: none

=item Return Value: L<$storage|DBIO::Storage>

=back

  $source->storage->debug(1);

Returns the L<storage handle|DBIO::Storage> for the current schema.

=head2 add_relationship

=over 4

=item Arguments: $rel_name, $related_source_name, \%cond, \%attrs?

=item Return Value: 1/true if it succeeded

=back

  $source->add_relationship('rel_name', 'related_source', $cond, $attrs);

L<DBIO::Relationship> describes a series of methods which
create pre-defined useful types of relationships. Look there first
before using this method directly.

The relationship name can be arbitrary, but must be unique for each
relationship attached to this result source. 'related_source' should
be the name with which the related result source was registered with
the current schema. For example:

  $schema->source('Book')->add_relationship('reviews', 'Review', {
    'foreign.book_id' => 'self.id',
  });

The condition C<$cond> needs to be an L<SQL::Abstract>-style
representation of the join between the tables. For example, if you're
creating a relation from Author to Book,

  { 'foreign.author_id' => 'self.id' }

will result in the JOIN clause

  author me JOIN book foreign ON foreign.author_id = me.id

You can specify as many foreign => self mappings as necessary.

Valid attributes are as follows:

=over 4

=item join_type

Explicitly specifies the type of join to use in the relationship. Any
SQL join type is valid, e.g. C<LEFT> or C<RIGHT>. It will be placed in
the SQL command immediately before C<JOIN>.

=item proxy

An arrayref containing a list of accessors in the foreign class to proxy in
the main class. If, for example, you do the following:

  CD->might_have(liner_notes => 'LinerNotes', undef, {
    proxy => [ qw/notes/ ],
  });

Then, assuming LinerNotes has an accessor named notes, you can do:

  my $cd = CD->find(1);
  # set notes -- LinerNotes object is created if it doesn't exist
  $cd->notes('Notes go here');

=item accessor

Specifies the type of accessor that should be created for the
relationship. Valid values are C<single> (for when there is only a single
related object), C<multi> (when there can be many), and C<filter> (for
when there is a single related object, but you also want the relationship
accessor to double as a column accessor). For C<multi> accessors, an
add_to_* method is also created, which calls C<create_related> for the
relationship.

=back

Throws an exception if no join condition is supplied, or -- when the
condition is a hashref -- if its keys are not prefixed with C<foreign.>
or its values with C<self.>. These are the only checks performed here: the
related source named by C<$f_source_name> is B<not> resolved or validated at
this point. During schema construction the related source is routinely not
registered yet (forward and circular references are normal), so relationship
declarations are recorded as given and the related source is resolved lazily
on first use. See ADR 0054.

=head2 relationships

=over 4

=item Arguments: none

=item Return Value: L<@rel_names|DBIO::Relationship>

=back

  my @rel_names = $source->relationships();

Returns all relationship names for this source, sorted by name. The order is
the same in every process, so text written by walking the list (the foreign
keys of a C<CREATE TABLE>, say) does not change from one run to the next. In
scalar context, returns the number of relationships.

=head2 relationship_info

=over 4

=item Arguments: L<$rel_name|DBIO::Relationship>

=item Return Value: L<\%rel_data|DBIO::Relationship::Base/add_relationship>

=back

Returns a hash of relationship information for the specified relationship
name. The keys/values are as specified for L<DBIO::Relationship::Base/add_relationship>.

The following two keys of the returned hashref are a B<stable, public part of
the return contract> and may be relied upon by downstream consumers (for
example schema-introspecting tools that walk relationships):

=over 4

=item C<< $info->{source} >>

The fully-qualified target Result class of the relationship, as the string it
was registered with (e.g. C<MyApp::Schema::Result::CD>). This is the class on
the far side of the relationship, regardless of arity.

=item C<< $info->{attrs}{accessor} >>

The relationship arity marker. It is C<'multi'> for a C<has_many> (a one-to-many
relationship resolving to a resultset of zero or more rows). For a single-value
relationship (C<belongs_to>, C<has_one>, C<might_have>) it is a single-row
accessor type --- C<'filter'> for C<belongs_to>, or C<'single'> for the
C<has_one>/C<might_have> family. The reliable, contractual distinction is
C<'multi'> versus not-C<'multi'>: anything other than C<'multi'> denotes a
single-value relationship.

=back

=head2 has_relationship

=over 4

=item Arguments: L<$rel_name|DBIO::Relationship>

=item Return Value: 1/0 (true/false)

=back

Returns true if the source has a relationship of this name, false otherwise.

=head2 reverse_relationship_info

=over 4

=item Arguments: L<$rel_name|DBIO::Relationship>

=item Return Value: L<\%rel_data|DBIO::Relationship::Base/add_relationship>

=back

Looks through all the relationships on the source this relationship
points to, looking for one whose condition is the reverse of the
condition on this relationship.

A common use of this is to find the name of the C<belongs_to> relation
opposing a C<has_many> relation. For definition of these look in
L<DBIO::Relationship>.

The returned hashref is keyed by the name of the opposing
relationship, and contains its data in the same manner as
L</relationship_info>.

=head2 related_source

=over 4

=item Arguments: $rel_name

=item Return Value: $source

=back

Returns the result source object for the given relationship.

=head2 related_class

=over 4

=item Arguments: $rel_name

=item Return Value: $classname

=back

Returns the class name for objects in the given relationship.

=head2 throw_exception

See L<DBIO::Schema/"throw_exception">.

=head2 column_info_from_storage

=over

=item Arguments: 1/0 (default: 0)

=item Return Value: 1/0

=back

  __PACKAGE__->column_info_from_storage(1);

Enables the on-demand automatic loading of the above column
metadata from storage as necessary.  This is *deprecated*, and
should not be used.  It will be removed before 1.0.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
