package DBIx::Class::Sims::Runner;

use 5.010_001;

use strictures 2;

use DDP;

use Data::Compare qw( Compare );
use Hash::Merge qw( merge );
use Scalar::Util qw( blessed reftype );
use String::Random qw( random_regex );

use DBIx::Class::Sims::Util ();

###### FROM HERE ######
# These are utility methods to help navigate the rel_info hash.
my $is_fk = sub { return exists $_[0]{attrs}{is_foreign_key_constraint} };
my $short_source = sub {
  (my $x = $_[0]{source}) =~ s/.*:://;
  return $x;
};

# ribasushi says: at least make sure the cond is a hashref (not guaranteed)
my $self_fk_cols = sub { map {/^self\.(.*)/; $1} values %{$_[0]{cond}} };
my $self_fk_col  = sub { ($self_fk_cols->(@_))[0] };
my $foreign_fk_cols = sub { map {/^foreign\.(.*)/; $1} keys %{$_[0]{cond}} };
my $foreign_fk_col  = sub { ($foreign_fk_cols->(@_))[0] };
###### TO HERE ######

sub new {
  my $class = shift;
  my $self = bless {@_}, $class;
  $self->initialize;
  return $self;
}

sub initialize {
  my $self = shift;

  $self->{is_fk} = {};
  foreach my $name ( $self->schema->sources ) {
    my $source = $self->schema->source($name);

    $self->{reqs}{$name} //= {};
    foreach my $rel_name ( $source->relationships ) {
      my $rel_info = $source->relationship_info($rel_name);

      if ($is_fk->($rel_info)) {
        $self->{reqs}{$name}{$rel_name} = 1;
        $self->{is_fk}{$name}{$_} = 1 for $self_fk_cols->($rel_info);
      }
    }
  }

  $self->{created}    = {};
  $self->{duplicates} = {};

  $self->{create_stack} = [];

  return;
}

sub has_item {
  my $self = shift;
  my ($name, $item) = @_;

  foreach my $comp (@{$self->{create_stack}}) {
    next unless $name eq $comp->[0];
    next unless Compare($item, $comp->[1]);
    return 1;
  }
  return;
}
sub add_item {
  my $self = shift;
  my ($name, $item) = @_;
  push @{$self->{create_stack}}, [ $name, MyCloner::clone($item) ];
}
sub remove_item {
  my $self = shift;
  my ($name, $item) = @_;
  pop @{$self->{create_stack}};
}

sub schema { shift->{schema} }
sub driver { shift->schema->storage->dbh->{Driver}{Name} }
sub datetime_parser { shift->schema->storage->datetime_parser }

sub create_search {
  my $self = shift;
  my ($rs, $name, $cond) = @_;

  my $source = $self->schema->source($name);
  my %cols = map { $_ => 1 } $source->columns;
  my $search = {
    (map {
      $_ => $cond->{$_}
    } grep {
      # Make sure this column exists and is an actual value. Assumption is that
      # a non-reference is a value and a reference is a sims-spec.
      exists $cols{$_} && !reftype($cond->{$_})
    } keys %$cond)
  };
  $rs = $rs->search($search);

  # This section needs to be rethought.
  # 1. There are no tests that fail when it's commented out
  # 2. Keeping it in breaks the test in t/parent_child_parent.t named
  #     "Auto-generate other children of parent by amount"
  # 3. It's unclear if the functionality is even desirable.
  # The goal of this section looked to be to find the best match, including any
  # parentage. The best element in the tree of parentage is a good goal, but it
  # does require that we have converted the FK relationships first. We need a
  # test before this section can be re-enabled.
  #
  # In any case, it definitely won't be in this form.
  #foreach my $rel_name ($source->relationships) {
  #  next unless exists $cond->{$rel_name};
  #  next unless reftype($cond->{$rel_name}) eq 'HASH';
  #
  #  my %search = map {
  #    ;"$rel_name.$_" => $cond->{$rel_name}{$_}
  #  } grep {
  #    # Nested relationships are automagically handled. q.v. t/t5.t
  #    !ref $cond->{$rel_name}{$_}
  #  } keys %{$cond->{$rel_name}};
  #
  #  $rs = $rs->search(\%search, { join => $rel_name });
  #}

  return $rs;
}

sub fix_fk_dependencies {
  my $self = shift;
  my ($name, $item) = @_;

  # 1. If we have something, then:
  #   a. If it's a scalar, then, COND = { $fk => scalar }
  #   b. Look up the row by COND
  #   c. If the row is not there, then $create_item->($fksrc, COND)
  # 2. If we don't have something and the column is non-nullable, then:
  #   a. If rows exists, pick a random one.
  #   b. If rows don't exist, $create_item->($fksrc, {})
  my %child_deps;
  my $source = $self->schema->source($name);
  foreach my $rel_name ( $source->relationships ) {
    my $rel_info = $source->relationship_info($rel_name);
    unless ( $is_fk->($rel_info) ) {
      if ($item->{$rel_name}) {
        $child_deps{$rel_name} = delete $item->{$rel_name};
      }
      next;
    }

    next unless $self->{reqs}{$name}{$rel_name};

    my $col = $self_fk_col->($rel_info);
    my $fkcol = $foreign_fk_col->($rel_info);

    my $fk_name = $short_source->($rel_info);
    my $rs = $self->schema->resultset($fk_name);

    my $cond;
    my $proto = delete($item->{$rel_name}) // delete($item->{$col});
    if ($proto) {
      # Assume anything blessed is blessed into DBIC.
      if (blessed($proto)) {
        $cond = { $fkcol => $proto->$fkcol };
      }
      # Assume any hashref is a Sims specification
      elsif (ref($proto) eq 'HASH') {
        $cond = $proto
      }
      # Assume any unblessed scalar is a column value.
      elsif (!ref($proto)) {
        $cond = { $fkcol => $proto };
      }
      # Use a referenced row
      elsif (ref($proto) eq 'SCALAR') {
        my ($table, $idx) = ($$proto =~ /(.+)\[(\d+)\]$/);
        unless ($table && defined $idx) {
          die "Unsure what to do about $name->$rel_name():" . np($proto);
        }
        unless (exists $self->{rows}{$table}) {
          die "No rows in $table to reference\n";
        }
        unless (exists $self->{rows}{$table}[$idx]) {
          die "Not enough ($idx) rows in $table to reference\n";
        }

        $cond = { $fkcol => $self->{rows}{$table}[$idx]->$fkcol };
      }
      else {
        die "Unsure what to do about $name->$rel_name():" . np($proto);
      }
    }

    my $col_info = $source->column_info($col);
    if ( $cond ) {
      $rs = $self->create_search($rs, $fk_name, $cond);
    }
    elsif ( $col_info->{is_nullable} ) {
      next;
    }
    else {
      $cond = {};
    }

    my $meta = delete $cond->{__META__} // {};

    #warn "Looking for $name->$rel_name(".np($cond).")\n";

    my $parent;
    unless ($meta->{create}) {
      $parent = $rs->search(undef, { rows => 1 })->first;
    }
    unless ($parent) {
      $parent = $self->create_item($fk_name, $cond);
    }
    $item->{$col} = $parent->get_column($fkcol);
  }

  return \%child_deps;
}

{
  my %pending;
  my %added_by;
  sub are_columns_equal {
    my $self = shift;
    my ($src, $row, $compare) = @_;
    foreach my $col ($self->schema->source($src)->columns) {
      next if $self->{is_fk}{$src}{$col};

      next unless exists $row->{$col};
      return unless exists $compare->{$col};
      return if $compare->{$col} ne $row->{$col};
    }
    return 1;
  };

  sub add_child {
    my $self = shift;
    my ($src, $fkcol, $row, $adder) = @_;
    # If $row has the same keys (other than parent columns) as another row
    # added by a different parent table, then set the foreign key for this
    # parent in the existing row.
    foreach my $compare (@{$self->{spec}{$src}}) {
      next if exists $added_by{$adder} && exists $added_by{$adder}{$compare};
      if ($self->are_columns_equal($src, $row, $compare)) {
        $compare->{$fkcol} = $row->{$fkcol};
        return;
      }
    }

    push @{$self->{spec}{$src}}, $row;
    $added_by{$adder} //= {};
    $added_by{$adder}{$row} = !!1;
    $pending{$src} = 1;
  }

  sub has_pending { keys %pending != 0; }
  sub delete_pending { delete $pending{$_[1]}; }
  sub clear_pending { %pending = (); }
}

sub find_by_unique_constraints {
  my $self = shift;
  my ($name, $item) = @_;

  my $source = $self->schema->source($name);
  my @uniques = map {
    [ $source->unique_constraint_columns($_) ]
  } $source->unique_constraint_names();

  my $rs = $self->schema->resultset($name);
  my $searched = {};
  foreach my $unique (@uniques) {
    # If there are specified values for all the columns in a specific unqiue constraint ...
    next if grep { ! exists $item->{$_} } @$unique;

    # ... then add that to the list of potential values to search.
    my %criteria;
    foreach my $colname (@{$unique}) {
      my $value = $item->{$colname};
      my $classname = blessed($value);
      if ( $classname && $classname->isa('DateTime') ) {
        $value = $self->datetime_parser->format_datetime($value);
      }

      $criteria{$colname} = $value;
    }
    
    $rs = $rs->search(\%criteria);
    $searched = merge($searched, \%criteria);
  }

  return unless keys %$searched;
  my $row = $rs->search(undef, { rows => 1 })->first;
  if ($row) {
    push @{$self->{duplicates}{$name}}, {
      criteria => $searched,
      found    => { $row->get_columns },
    };
    return $row;
  }
  return;
}

sub fix_child_dependencies {
  my $self = shift;
  my ($name, $row, $child_deps) = @_;

  # 1. If we have something, then:
  #   a. If it's not an array, then make it an array
  # 2. If we don't have something,
  #   a. Make an array with an empty item
  #   XXX This is more than one item would be supported
  # In all cases, make sure to add { $fkcol => $row->get_column($col) } to the
  # child's $item
  my $source = $self->schema->source($name);
  foreach my $rel_name ( $source->relationships ) {
    my $rel_info = $source->relationship_info($rel_name);
    next if $is_fk->($rel_info);
    next unless $child_deps->{$rel_name} // $self->{reqs}{$name}{$rel_name};

    my $col = $self_fk_col->($rel_info);
    my $fkcol = $foreign_fk_col->($rel_info);

    my $fk_name = $short_source->($rel_info);

    my @children;
    if ($child_deps->{$rel_name}) {
      my $n = DBIx::Class::Sims::Util->normalize_aoh($child_deps->{$rel_name});
      unless ($n) {
        die "Don't know what to do with $name->{$rel_name}\n\t".np($row);
      }
      @children = @{$n};
    }
    else {
      @children = ( ({}) x $self->{reqs}{$name}{$rel_name} );
    }

    # Need to ensure that $child_deps >= $self->{reqs}

    foreach my $child (@children) {
      $child->{$fkcol} = $row->get_column($col);
      $self->add_child($fk_name, $fkcol, $child, $name);
    }
  }
}

my %types = (
  numeric => {( map { $_ => 1 } qw(
    tinyint smallint mediumint bigint
    int integer int1 int2 int3 int4 int8 middleint
    bool boolean
  ))},
  decimal => {( map { $_ => 1 } qw(
    float float4 float8
    real
    double
    decimal dec
    numeric
    fixed
  ))},
  string => {( map { $_ => 1 } qw(
    char varchar varchar2
    binary varbinary
    text tinytext mediumtext longtext long
    blob tinyblob mediumblob longblob
  ))},
  # These will be unhandled
  #datetime => [qw(
  #  date
  #  datetime
  #  timestamp
  #  year
  #)],
  #unknown => [qw(
  #  enum set bit json
  #  geometry point linestring polygon
  #  multipoint multilinestring multipolygon geometrycollection
  #)],
);

sub fix_columns {
  my $self = shift;
  my ($name, $item) = @_;

  my $source = $self->schema->source($name);

  my %is = (
    in_pk => sub {
      my $n = shift;
      grep {
        $_ eq $n
      } $source->primary_columns;
    },
    in_uk => sub {
      my $n = shift;
      grep {
        $_ eq $n
      } map {
        $source->unique_constraint_columns($_)
      } $source->unique_constraint_names;
    },
  );
  foreach my $type (keys %types) {
    $is{$type} = sub {
      my $t = shift;
      return exists $types{$type}{$t};
    };
  }

  foreach my $col_name ( $source->columns ) {
    my $sim_spec;
    if ( exists $item->{$col_name} ) {
      # This is the original way of specifying an override with a HASHREFREF.
      # Reflection has realized it was an unnecessary distinction to a parent
      # specification. Either it's a relationship hashref or a simspec hashref.
      # We can never have both. It will be deprecated.
      if ((reftype($item->{$col_name}) // '') eq 'REF' &&
        (reftype(${$item->{$col_name}}) // '') eq 'HASH' ) {
        warn "DEPRECATED: Use a regular HASHREF for overriding simspec. HASHREFREF will be removed in a future release.";
        $sim_spec = ${ delete $item->{$col_name} };
      }
      elsif ((reftype($item->{$col_name}) // '') eq 'HASH') {
        $sim_spec = delete $item->{$col_name};
      }
      # Pass the value along to DBIC - we don't know how to deal with it.
      else {
        next;
      }
    }

    my $info = $source->column_info($col_name);

    $sim_spec //= $info->{sim};
    if ( ref($sim_spec // '') eq 'HASH' ) {
      if ( exists $sim_spec->{null_chance} && $info->{is_nullable} ) {
        # Add check for not a number
        if ( rand() < $sim_spec->{null_chance} ) {
          $item->{$col_name} = undef;
          next;
        }
      }

      if (exists $sim_spec->{values}) {
        $sim_spec->{value} = delete $sim_spec->{values};
      }

      if ( ref($sim_spec->{func} // '') eq 'CODE' ) {
        $item->{$col_name} = $sim_spec->{func}->($info);
      }
      elsif ( exists $sim_spec->{value} ) {
        if (ref($sim_spec->{value} // '') eq 'ARRAY') {
          my @v = @{$sim_spec->{value}};
          $item->{$col_name} = $v[rand @v];
        }
        else {
          $item->{$col_name} = $sim_spec->{value};
        }
      }
      elsif ( $sim_spec->{type} ) {
        my $meth = $self->{parent}->sim_type($sim_spec->{type});
        if ( $meth ) {
          $item->{$col_name} = $meth->($info, $sim_spec, $self);
        }
        else {
          warn "Type '$sim_spec->{type}' is not loaded";
        }
      }
      else {
        if ( $is{numeric}->($info->{data_type})) {
          my $min = $sim_spec->{min} // 0;
          my $max = $sim_spec->{max} // 100;
          $item->{$col_name} = int(rand($max-$min))+$min;
        }
        elsif ( $is{decimal}->($info->{data_type})) {
          my $min = $sim_spec->{min} // 0;
          my $max = $sim_spec->{max} // 100;
          $item->{$col_name} = rand($max-$min)+$min;
        }
        elsif ( $is{string}->($info->{data_type})) {
          my $min = $sim_spec->{min} // 1;
          my $max = $sim_spec->{max} // $info->{data_length} // $info->{size} // $min;
          $item->{$col_name} = random_regex(
            '\w' . "{$min,$max}"
          );
        }
      }
    }
    # If it's not nullable, doesn't have a default value and isn't part of a
    # primary key (could be auto-increment) or part of a unique key or part of a
    # foreign key, then generate a value for it.
    elsif (
      !$info->{is_nullable} &&
      !exists $info->{default_value} &&
      !$is{in_pk}->($col_name) &&
      !$is{in_uk}->($col_name) &&
      !$self->{is_fk}{$name}{$col_name}
    ) {
      if ( $is{numeric}->($info->{data_type})) {
        my $min = 0;
        my $max = 100;
        $item->{$col_name} = int(rand($max-$min))+$min;
      }
      elsif ( $is{decimal}->($info->{data_type})) {
        my $min = 0;
        my $max = 100;
        $item->{$col_name} = rand($max-$min)+$min;
      }
      elsif ( $is{string}->($info->{data_type})) {
        my $min = 1;
        my $max = $info->{data_length} // $info->{size} // $min;
        $item->{$col_name} = random_regex(
          '\w' . "{$min,$max}"
        );
      }
      else {
        die "ERROR: $name\.$col_name is not nullable, but I don't know how to handle $info->{data_type}\n";
      }
    }
  }

  # Oracle does not allow the "INSERT INTO x DEFAULT VALUES" syntax that DBIC
  # wants to use. Therefore, find a PK column and set it to NULL. If there
  # isn't one, complain loudly.
  if ($self->driver eq 'Oracle' && keys(%$item) == 0) {
    my @pk_columns = grep {
      $is{in_pk}->($_)
    } $source->columns;

    die "Must specify something about some column or have a PK in Oracle"
      unless @pk_columns;

    # This will work even if there are multiple columns in the PK.
    $item->{$pk_columns[0]} = undef;
  }
}

sub create_item {
  my $self = shift;
  my ($name, $item) = @_;

  # If, in the current stack of in-flight items, we've attempted to make this
  # exact item, die because we've obviously entered an infinite loop.
  if ($self->has_item($name, $item)) {
    die "ERROR: $name (".np($item).") was seen more than once\n";
  }
  $self->add_item($name, $item);

  $self->fix_columns($name, $item);

  my $source = $self->schema->source($name);
  $self->{hooks}{preprocess}->($name, $source, $item);

  my $child_deps = $self->fix_fk_dependencies($name, $item);

  #warn "Creating $name (".np($item).")\n";
  my $row = $self->find_by_unique_constraints($name, $item);
  unless ($row) {
    $row = eval {
      $self->schema->resultset($name)->create($item);
    }; if ($@) {
      my $e = $@;
      warn "ERROR Creating $name (".np($item).")\n";
      die $e;
    }
    # This tracks everything that was created, not just what was requested.
    $self->{created}{$name}++;
  }

  $self->fix_child_dependencies($name, $row, $child_deps);

  $self->{hooks}{postprocess}->($name, $source, $row);

  $self->remove_item($name, $item);

  return $row;
}

sub run {
  my $self = shift;

  return $self->schema->txn_do(sub {
    $self->{rows} = {};
    while (1) {
      foreach my $name ( @{$self->{toposort}} ) {
        next unless $self->{spec}{$name};

        while ( my $item = shift @{$self->{spec}{$name}} ) {
          my $row = $self->create_item($name, $item);

          if ($self->{initial_spec}{$name}{$item}) {
            push @{$self->{rows}{$name} //= []}, $row;
          }
        }

        $self->delete_pending($name);
      }

      last unless $self->has_pending();
      $self->clear_pending();
    }

    return $self->{rows};
  });
}

1;
__END__
