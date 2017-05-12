package DBIx::ActiveRecord::Arel;
use strict;
use warnings;
use Storable;

use DBIx::ActiveRecord::Arel::Column;
use DBIx::ActiveRecord::Arel::Where;
use DBIx::ActiveRecord::Arel::Join;
use DBIx::ActiveRecord::Arel::Order;
use DBIx::ActiveRecord::Arel::Value;
use DBIx::ActiveRecord::Arel::Native;
use DBIx::ActiveRecord::Arel::NakidWhere;
use DBIx::ActiveRecord::Arel::SubQuery;

use DBIx::ActiveRecord::Arel::Query::Select;
use DBIx::ActiveRecord::Arel::Query::Insert;
use DBIx::ActiveRecord::Arel::Query::Update;
use DBIx::ActiveRecord::Arel::Query::Delete;
use DBIx::ActiveRecord::Arel::Query::Count;

sub create {
    my ($self, $table_name) = @_;
    my $o = bless {
        table => $table_name,
        query => undef,
    }, $self;
    $o->{query} = DBIx::ActiveRecord::Arel::Query::Select->new($o);
    $o;
}

sub query {shift->{query}};
sub table {shift->{table}}
sub binds {shift->query->binds}
sub to_sql {shift->query->to_sql}
sub clone {Storable::dclone(shift)}

sub _col {
    my ($self, $name) = @_;
    $name = DBIx::ActiveRecord::Arel::Column->new($self, $name) if ref $name ne 'DBIx::ActiveRecord::Arel::Native';
    $name;
}

sub where {
    my $self = shift;
    my $statement = shift;
    my $o = $self->clone;
    $o->query->add_where(DBIx::ActiveRecord::Arel::NakidWhere->new($statement, \@_));
    $o;
}

sub _value2instance {
    my ($self, $value) = @_;
    return $value if ref $value eq 'DBIx::ActiveRecord::Arel::Native';
    return DBIx::ActiveRecord::Arel::SubQuery->new($value) if ref $value eq  'DBIx::ActiveRecord::Arel';
    DBIx::ActiveRecord::Arel::Value->new($value);
}

sub _add_where {
    my ($self, $operator, $key, $value) = @_;
    my $o = $self->clone;
    $value = $self->_value2instance($value);
    $o->query->add_where(DBIx::ActiveRecord::Arel::Where->new($operator, $self->_col($key), $value));
    $o;
}

sub eq {
    my ($self, $key, $value) = @_;
    $self->_add_where('=', $key, $value);
}

sub ne {
    my ($self, $key, $value) = @_;
    $self->_add_where('!=', $key, $value);
}

sub in {
    my ($self, $key, $value) = @_;
    $self->_add_where('IN', $key, $value);
}

sub not_in {
    my ($self, $key, $value) = @_;
    $self->_add_where('NOT IN', $key, $value);
}

sub null {
    my ($self, $key) = @_;
    $self->_add_where('IS NULL', $key);
}

sub not_null {
    my ($self, $key) = @_;
    $self->_add_where('IS NOT NULL', $key);
}

sub gt {
    my ($self, $key, $value) = @_;
    $self->_add_where('>', $key, $value);
}

sub lt {
    my ($self, $key, $value) = @_;
    $self->_add_where('<', $key, $value);
}

sub ge {
    my ($self, $key, $value) = @_;
    $self->_add_where('>=', $key, $value);
}

sub le {
    my ($self, $key, $value) = @_;
    $self->_add_where('<=', $key, $value);
}

sub like {
    my ($self, $key, $value) = @_;
    $self->_add_where('LIKE', $key, $value);
}

sub contains {
    my ($self, $key, $value) = @_;
    $self->like($key, "%$value%");
}

sub starts_with {
    my ($self, $key, $value) = @_;
    $self->like($key, "$value%");
}

sub ends_with {
    my ($self, $key, $value) = @_;
    $self->like($key, "%$value");
}

sub between {
    my ($self, $key, $value1, $value2) = @_;
    $self->ge($key, $value1)->le($key, $value2);
}

sub left_join {
    my ($self, $target, $opt) = @_;
    my $o = $self->clone;
    $o->query->merge_as($target->query);
    $o->query->add_join(DBIx::ActiveRecord::Arel::Join->new('LEFT JOIN', $self->_col($opt->{primary_key}), $target->_col($opt->{foreign_key})));
    $o;
}

sub inner_join {
    my ($self, $target, $opt) = @_;
    my $o = $self->clone;
    $o->query->merge_as($target->query);
    $o->query->add_join(DBIx::ActiveRecord::Arel::Join->new('INNER JOIN', $self->_col($opt->{foreign_key}), $target->_col($opt->{primary_key})));
    $o;
}

sub merge {
    my ($self, $arel) = @_;
    my $o = $self->clone;
    my $s = $arel->clone;
    $o->query->merge($s->query);
    $o;
}

sub select {
    my $self = shift;
    my $o = $self->clone;
    $o->query->add_select($self->_col($_)) for @_;
    $o;
}

sub limit {
    my ($self, $limit) = @_;
    my $o = $self->clone;
    $o->query->set_limit($limit);
    $o;
}

sub offset {
    my ($self, $offset) = @_;
    my $o = $self->clone;
    $o->query->set_offset($offset);
    $o;
}

sub lock {
    my ($self) = @_;
    my $o = $self->clone;
    $o->query->set_lock;
    $o;
}

sub group {
    my $self = shift;
    my $o = $self->clone;
    $o->query->add_group($o->_col($_)) for @_;
    $o;
}

sub asc {
    my $self = shift;
    my $o = $self->clone;
    $o->query->add_order(DBIx::ActiveRecord::Arel::Order->new('', $self->_col($_))) for @_;
    $o;
}

sub desc {
    my $self = shift;
    my $o = $self->clone;
    $o->query->add_order(DBIx::ActiveRecord::Arel::Order->new('DESC', $self->_col($_))) for @_;
    $o;
}

sub reorder {
    my $self = shift;
    my $o = $self->clone;
    $o->query->reset_order;
    $o;
}

sub reverse {
    my $self = shift;
    my $o = $self->clone;
    $o->query->reverse_order;
    $o;
}

sub as {
    my ($self, $alias) = @_;
    my $s = $self->clone;
    $s->query->add_as($s->table, $alias);
    $s;
}

sub insert {
    my ($self, $hash, $columns) = @_;
    my $o = $self->clone;
    $o->{query} = DBIx::ActiveRecord::Arel::Query::Insert->new($self, $hash, $columns);
    $o;
}

sub update {
    my ($self, $hash, $columns) = @_;
    my $o = $self->clone;
    $o->{query} = DBIx::ActiveRecord::Arel::Query::Update->new($self, $hash, $columns);
    $o;
}

sub delete {
    my ($self) = @_;
    my $o = $self->clone;
    $o->{query} = DBIx::ActiveRecord::Arel::Query::Delete->new($self);
    $o;
}

sub count {
    my ($self) = @_;
    my $o = $self->clone;
    $o->{query} = DBIx::ActiveRecord::Arel::Query::Count->new($self);
    $o;
}

1;
