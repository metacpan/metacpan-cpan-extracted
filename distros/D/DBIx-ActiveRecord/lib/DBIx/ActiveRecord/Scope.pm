package DBIx::ActiveRecord::Scope;
use strict;
use warnings;
use Carp;

use base qw/Exporter/;

our @ISA = qw/Exporter/;
my @delegates = qw/eq ne in not_in null not_null gt lt ge le like contains starts_with ends_with between where select limit offset lock group asc desc reorder reverse/;
our @EXPORT = (@delegates, qw/scoped_instance _scope _execute merge joins includes _includes _loads_includes update_all delete_all _is_relation/);

{
    no strict 'refs';
    foreach my $m (@delegates) {
        *{__PACKAGE__."::$m"} = sub {
            my $self = shift;
            my @args = @_;
            @args = map { $self->_is_relation($_) ? $_->{arel} : $_ } @args;
            $self->_scope($m, @args);
        };
    }
}

sub _is_relation {
    my ($self, $obj) = @_;
    return 0 if !ref $obj;
    return 0 if ref $obj eq 'HASH';
    return 0 if ref $obj eq 'ARRAY';
    return $obj->isa('DBIx::ActiveRecord::Relation');
}

sub _scope {
    my $self = shift;
    my $method = shift;
    my $s = $self->scoped;
    $s->{arel} = $s->{arel}->$method(@_);
    $s;
}

sub scoped_instance {
    my $self = shift;
    ref $self ? $self : $self->scoped;
}

sub update_all {
    my ($self, $sets) = @_;
    $self = $self->scoped;
    my $s = $self->{arel}->update($sets);
    my $sth = $self->{model}->dbh->prepare($s->to_sql);
    $sth->execute($s->binds) || croak $sth->errstr;
}

sub delete_all {
    my ($self) = @_;
    $self = $self->scoped;
    my $s = $self->{arel}->delete;
    my $sth = $self->{model}->dbh->prepare($s->to_sql);
    $sth->execute($s->binds) || croak $sth->errstr;
}

sub all {
    shift->_execute;
}

sub first {
    my $self = shift;
    my $s = $self->scoped_instance;
    my $org = $s->{arel}->clone;
    $s->{arel} = $s->{arel}->limit(1);
    my $r = $s->_execute;
    $s->{arel} = $org;
    @$r ? $r->[0] : undef;
}

sub last {
    my $self = shift;
    my $s = $self->scoped_instance;
    my $org = $s->{arel}->clone;
    $s->{arel} = $s->{arel}->limit(1)->reverse;
    my $r = $s->_execute;
    $s->{arel} = $org;
    @$r ? $r->[0] : undef;
}

sub _execute {
    my $self = shift;
    my $s = $self->scoped_instance;
    my $rs = $s->{model}->instantiates_by_relation($s);
    $s->_loads_includes($s->{_includes}, $rs);
    $rs;
}

sub _loads_includes {
    my ($self, $inc, $rs) = @_;
    foreach my $k (keys %$inc) {
        my $opt = $inc->{$k};
        my $model = $opt->{model};
        my $primary_key = $opt->{primary_key};
        my $foreign_key = $opt->{foreign_key};
        my %pkeys;
        my $search_key = $opt->{belongs_to} ? $primary_key : $foreign_key;
        my $my_key = $opt->{belongs_to} ? $foreign_key : $primary_key;
        my $s = $opt->{belongs_to} ? $model->unscoped : $model->scoped;
        my @keys = map {$_->$my_key} grep {$pkeys{$_->$my_key} = 1} @$rs;
        next if !keys %pkeys;
        my $ir = $s->in($search_key => \@keys)->all;
        $self->_loads_includes($opt->{_includes}, $ir) if $opt->{_includes};
        foreach my $r (@$rs) {
            my @r = grep {$r->$my_key eq $_->$search_key} @$ir;
            if ($opt->{one}) {
                $r->{associates_cache}->{$opt->{name}} = $r[0];
            } else {
                my $s = $model->eq($foreign_key => $r->$primary_key);
                $s->{cache}->{all} = \@r;
                $r->{associates_cache}->{$opt->{name}} = $s;
            }
        }
    }
}

sub merge {
    my ($self, $relation) = @_;
    my $s = $self->scoped;
    $s->{arel} = $s->{arel}->merge($relation->{arel});
    $s;
}

sub joins {
    my $self = shift;
    my $s = $self->scoped;
    my $model = $s->{model};
    my $arel = $s->{arel};
    foreach my $name (@_) {
        my $opt = $model->_global->{joins}->{$name} || croak "no relation!";
        my $m = $opt->{model};
        if ($opt->{belongs_to}) {
          $arel = $arel->merge($model->arel->inner_join($m->arel->as($name), $opt));
        } else {
          $arel = $arel->merge($model->arel->left_join($m->arel->as($name), $opt));
        }
        $model = $m;
    }
    $s->{arel} = $arel;
    $s;
}

sub includes {
    my $self = shift;
    my $s = $self->scoped;
    $s->{_includes} ||= {};
    my $inc = $s->{_includes};
    my $parent = $s->{model};
    my $h;
    foreach my $name (@_) {
        $inc->{$name} ||= {};
        $h = $inc->{$name};
        my $opt = $parent->_global->{joins}->{$name} || croak "no relation!";
        my $i = {%$opt, name => $name};
        map {$h->{$_} = $i->{$_}} keys %$i;
        $parent = $opt->{model};
        $h->{_includes} ||= {};
        $inc = $h->{_includes};
    }
    $s;
}

1;
