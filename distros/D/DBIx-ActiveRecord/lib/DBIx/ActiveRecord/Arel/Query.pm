package DBIx::ActiveRecord::Arel::Query;
use strict;
use warnings;

sub new {
    my ($self, $main) = @_;
    bless {
      main => $main,
      wheres => [],
      joins => [],
      binds => [],
      selects => [],
      group => [],
      order => [],
      limit => undef,
      offset => undef,
      lock => undef,
      as => {},
    }, $self;
}

sub _to_sql { die 'implement!' }
sub main {shift->{main}}
sub binds {@{shift->{binds}}}

sub add_as {
    my ($self, $table, $as) = @_;
    $self->{as}->{$table} = $as;
}

sub add_join {
    my ($self, $join) = @_;
    push @{$self->{joins}}, $join;
}

sub add_where {
    my ($self, $where) = @_;
    push @{$self->{wheres}}, $where;
}

sub add_select {
    my ($self, $select) = @_;
    push @{$self->{selects}}, $select;
}

sub add_group {
    my ($self, $group) = @_;
    push @{$self->{group}}, $group;
}

sub add_order {
    my ($self, $order) = @_;
    push @{$self->{order}}, $order;
}

sub set_limit {
    my ($self, $limit) = @_;
    $self->{limit} = $limit;
}

sub set_offset {
    my ($self, $offset) = @_;
    $self->{offset} = $offset;
}

sub set_lock {
    shift->{lock} = 1;
}

sub reset_order {
    shift->{order} = [];
}

sub reverse_order {
    my $self = shift;
    $_->reverse for @{$self->{order}};
}

sub merge {
    my ($self, $query) = @_;
    push @{$self->{wheres}}, @{$query->{wheres}};
    push @{$self->{selects}}, @{$query->{selects}};
    push @{$self->{group}}, @{$query->{group}};
    push @{$self->{order}}, @{$query->{order}};
    push @{$self->{joins}}, @{$query->{joins}};
    $self->merge_as($query);
}

sub merge_as {
    my ($self, $query) = @_;
    %{$self->{as}} = (%{$query->{as}}, %{$self->{as}});
}

sub build_where {
    my ($self) = @_;
    my @binds;
    my @where;

    foreach my $w (@{$self->{wheres}}) {
        my ($where, $binds) = $w->build;
        push @where, $where;
        push @binds, @$binds if $binds;
    }

    $self->{binds} = \@binds;
    join(' AND ', @where);
}

sub build_options {
    my $self = shift;

    my @sql;

    my $group = $self->build_group;
    push @sql, 'GROUP BY '.$group if $group;

    my $order = $self->build_order;
    push @sql, 'ORDER BY '.$order if $order;

    if ($self->{limit}) {
        push @sql, 'LIMIT ?';
        push @{$self->{binds}}, $self->{limit};
    }
    if ($self->{offset}) {
        push @sql, 'OFFSET ?';
        push @{$self->{binds}}, $self->{offset};
    }
    push @sql, 'FOR UPDATE' if $self->{lock};
    join (' ', @sql);
}

sub build_group {
    my $self = shift;
    my $g = $self->{group} || return;
    join(', ', map {$_->name} @$g);
}

sub build_order {
    my $self = shift;
    my $order = $self->{order} || return;
    join(', ', map {$_->build} @$order);
}

sub build_select {
    my ($self) = @_;
    my @select = map {$_->name} @{$self->{selects}};
    @select ? join(', ', @select) : $self->main->_col("*")->name;
}

sub build_join {
    my ($self) = @_;
    my @join = map {$_->build} @{$self->{joins}};
    join(" ", @join);
}

sub has_join {
    my $self = shift;
    !!@{$self->{joins}};
}

sub to_sql {
    my $self = shift;

    my $org_use_full_name = $DBIx::ActiveRecord::Arel::Column::USE_FULL_NAME;
    my $org_as = $DBIx::ActiveRecord::Arel::Column::AS;

    $DBIx::ActiveRecord::Arel::Column::USE_FULL_NAME = $self->has_join;
    $DBIx::ActiveRecord::Arel::Column::AS = $self->{as};

    my $sql = $self->_to_sql(@_);

    $DBIx::ActiveRecord::Arel::Column::USE_FULL_NAME = $org_use_full_name;
    $DBIx::ActiveRecord::Arel::Column::AS = $self->{as};

    $sql;
}

sub main_table_with_alias {
    my $self = shift;
    my $as = $DBIx::ActiveRecord::Arel::Column::AS;
    $as->{$self->main->table} ? $self->main->table." ".$as->{$self->main->table} : $self->main->table;
}

1;
