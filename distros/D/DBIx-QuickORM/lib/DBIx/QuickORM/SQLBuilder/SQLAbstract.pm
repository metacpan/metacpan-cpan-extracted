package DBIx::QuickORM::SQLBuilder::SQLAbstract;
use strict;
use warnings;

our $VERSION = '0.000013';

use Carp qw/croak confess/;
use Sub::Util qw/set_subname/;
use Scalar::Util qw/blessed/;
use parent 'SQL::Abstract';

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::SQLBuilder';

sub new {
    my $class = shift;
    return $class->SUPER::new(bindtype => 'columns', @_);
}

BEGIN {
    for my $meth (qw/insert update select delete where/) {
        my $arg_meth = "_${meth}_args";
        my $new_meth = "qorm_${meth}";

        my $code = sub {
            my $self   = shift;
            my %params = @_;

            my $source = delete $params{source} or croak "No source provided";

            my @args = $self->$arg_meth(\%params);

            my ($stmt, @bind);
            if (blessed($source)) {
                croak "'$source' does not implement the 'DBIx::QuickORM::Role::Source' role" unless $source->DOES('DBIx::QuickORM::Role::Source');
                my $moniker = $source->source_db_moniker;
                ($stmt, @bind) = $self->$meth($moniker, @args);
            }
            else {
                ($stmt, @bind) = $self->$meth($source, @args);
            }

            my $param = 1;
            @bind = map { my ($f, $v) = @{$_}; +{param => $param++, value => $v, type => 'field', field => $f} } @bind;

            if (my $limit = $params{limit}) {
                $stmt .= " LIMIT ?";
                push @bind => {param => $param++, value => $limit, type => 'limit'};
            }

            return {statement => $stmt, bind => \@bind, source => $source};
        };

        no strict 'refs';
        *$new_meth = set_subname $new_meth => $code;
    }
}

sub qorm_upsert {
    my $self = shift;
    my %params = @_;

    my $data = delete $params{insert} // delete $params{update};

    my $sql = $self->qorm_insert(%params, insert => $data);

    my $pk = $params{source}->primary_key;
    confess "upsert cannot be used on a table without a primary key" unless $pk && @$pk;

    my $changes = { %$data };
    my $where = { map {$_ => delete $changes->{$_}} @$pk };

    my $binds = $sql->{bind} //= [];
    my $counter = @$binds + 1;

    my $returning = "";
    my $statement = $sql->{statement};
    $returning = $1 if $statement =~ s/\s+(returning.*)$//is;

    my $conf = $params{dialect}->upsert_statement($pk);
    for my $field (sort keys %$changes) {
        $conf .= " $field = ?";
        push @$binds => {
            field => $field,
            value => $changes->{$field},
            type  => 'field',
            param => $counter++,
        };
    }

    $sql->{statement} = "$statement $conf $returning";

    return $sql;
}

sub _insert_args {
    my $self = shift;
    my ($params) = @_;

    confess "insert() with a 'limit' clause is not currently supported"     if $params->{limit};
    confess "insert() with an 'order_by' clause is not currently supported" if $params->{order_by};

    my $values = $params->{insert} // croak "'insert' is required";
    my $returning = $params->{returning};

    $values = $self->_format_insert_and_update_data($values);

    return ($values, $returning ? {returning => $returning} : ());
}

sub _delete_args {
    my $self = shift;
    my ($params) = @_;

    confess "delete() with a 'limit' clause is not currently supported"     if $params->{limit};
    confess "delete() with an 'order_by' clause is not currently supported" if $params->{order_by};

    my $where = $params->{where} // undef;
    my $returning = $params->{returning};

    return ($where, $returning ? {returning => $returning} : ());
}

sub _update_args {
    my $self = shift;
    my ($params) = @_;

    my $values    = $params->{update} or croak "'update' is required";
    my $returning = $params->{returning};

    $values = $self->_format_insert_and_update_data($values);

    return ($values, $params->{where}, $returning ? {returning => $returning} : ());
}

sub _select_args {
    my $self = shift;
    my ($params) = @_;

    my $fields = $params->{fields} or croak "'fields' is required";
    my $where  = $params->{where};
    my $order  = $params->{order_by};

    return ($fields, $where, $order);
}

sub _where_args {
    my $self = shift;
    my ($params) = @_;

    my $where = $params->{where};
    my $order = $params->{order_by};

    return ($where, $order);
}

sub qorm_and {
    my $self = shift;
    my ($a, $b) = @_;
    return +{'-and' => [$a, $b]}
}

sub qorm_or {
    my $self = shift;
    my ($a, $b) = @_;
    return +{'-or' => [$a, $b]}
}

sub _format_insert_and_update_data {
    my $self = shift;
    my ($data) = @_;

    $data = { map { $_ => {'-value' => $data->{$_}} } keys %$data };

    return $data;
}

1;

__END__

our $IN_TARGET = 0;
sub _render_insert_clause_target {
    my $self = shift;

    local $IN_TARGET = 1;

    $self->SUPER::_render_insert_clause_target(@_);
}

sub _render_ident {
    my $self = shift;
    my (undef, $ident) = @_;

    unless ($IN_TARGET) {
        if (my $s = $self->{source}) {
            if (my $db_name = $s->field_db_name($ident->[0])) {
                $ident->[0] = $db_name;
            }
        }
    }

    $self->SUPER::_render_ident(@_);
}

 -value => HASH    should work, no need for this
sub _expand_insert_value {
    my ($self, $v) = @_;

    my $k = $SQL::Abstract::Cur_Col_Meta;

    if (my $s = $self->{source}) {
        my $r = ref($v);
        if ($r eq 'HASH' || $r eq 'ARRAY') {
            if (my $type = $s->field_type($k)) {
                return +{-bind => [$k, $v]};
            }
        }
    }

    return $self->SUPER::_expand_insert_value($v);
}
