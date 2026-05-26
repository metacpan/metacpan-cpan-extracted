package DBIx::QuickORM::SQLBuilder::SQLAbstract;
use strict;
use warnings;

our $VERSION = '0.000020';

use Carp qw/croak confess/;
use Sub::Util qw/set_subname/;
use Scalar::Util qw/blessed/;
use parent 'SQL::Abstract';

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::SQLBuilder';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::SQLBuilder::SQLAbstract - SQL builder backed by SQL::Abstract.

=head1 DESCRIPTION

An implementation of the SQL builder role (see
L<DBIx::QuickORM::Role::SQLBuilder>) built on top of L<SQL::Abstract>. It
takes ORM source objects and parameter hashes and produces statement-plus-bind
structures the ORM can execute.

For each of C<insert>, C<update>, C<select>, C<delete>, and C<where> it
provides a C<qorm_*> method that resolves the source to its db moniker, builds
the statement via the corresponding C<SQL::Abstract> method, and normalizes
the bind list into per-field bind specs. C<qorm_upsert> extends an insert with
a dialect-specific conflict clause.

=head1 SYNOPSIS

    my $builder = DBIx::QuickORM::SQLBuilder::SQLAbstract->new;

    my $sql = $builder->qorm_select(
        source => $source,
        fields => $fields,
        where  => \%where,
    );

    my ($statement, $bind) = @{$sql}{qw/statement bind/};

=cut

=pod

=head1 PUBLIC METHODS

=over 4

=item $builder = DBIx::QuickORM::SQLBuilder::SQLAbstract->new(%args)

Construct a builder. Forces C<SQL::Abstract>'s C<bindtype> to C<'columns'> so
binds carry their field names.

=cut

sub new {
    my $class = shift;
    return $class->SUPER::new(bindtype => 'columns', @_);
}

=pod

=item $sql = $builder->qorm_insert(source => $source, ...)

=item $sql = $builder->qorm_update(source => $source, ...)

=item $sql = $builder->qorm_select(source => $source, ...)

=item $sql = $builder->qorm_delete(source => $source, ...)

=item $sql = $builder->qorm_where(source => $source, ...)

Build a statement of the named kind for the given source. Each returns a
hashref with C<statement>, C<bind> (an arrayref of per-field bind specs), and
C<source>. A C<limit> param appends a C<LIMIT ?> clause. These methods are
generated at compile time.

=cut

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

=pod

=item $sql = $builder->qorm_upsert(source => $source, insert => \%data, ...)

Build an insert and append the dialect's upsert/conflict clause keyed on the
source's primary key, with the non-key fields as the update set. Croaks if the
source has no primary key.

=cut

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
    my @inject;
    for my $field (sort keys %$changes) {
        push @inject => "$field = ?";
        push @$binds => {
            field => $field,
            value => $changes->{$field},
            type  => 'field',
            param => $counter++,
        };
    }
    $conf .= " " . join(', ' => @inject) if @inject;

    $sql->{statement} = "$statement $conf $returning";

    return $sql;
}

=pod

=item @args = $builder->_insert_args(\%params)

=item @args = $builder->_update_args(\%params)

=item @args = $builder->_select_args(\%params)

=item @args = $builder->_delete_args(\%params)

=item @args = $builder->_where_args(\%params)

Translate the ORM parameter hash into the positional argument list the
corresponding C<SQL::Abstract> method expects. Insert and delete confess on
unsupported C<limit> / C<order_by> clauses.

=cut

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

=pod

=item $cond = $builder->qorm_and($a, $b)

=item $cond = $builder->qorm_or($a, $b)

Combine two where-conditions with C<SQL::Abstract>'s C<-and> / C<-or>
operators.

=cut

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

=pod

=item $formatted = $builder->_format_insert_and_update_data(\%data)

Wrap each value in a C<< { -value => ... } >> so C<SQL::Abstract> treats it as
a literal bind value rather than interpreting it.

=back

=cut

sub _format_insert_and_update_data {
    my $self = shift;
    my ($data) = @_;

    $data = { map { $_ => {'-value' => $data->{$_}} } keys %$data };

    return $data;
}

1;

=pod

=head1 SOURCE

The source code repository for DBIx::QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut

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
