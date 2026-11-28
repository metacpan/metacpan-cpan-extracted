package DBIx::QuickORM::SQLBuilder::SQLAbstract;
use strict;
use warnings;

our $VERSION = '0.000031';

use Carp qw/croak/;
use Scalar::Util qw/blessed/;
use SQL::Abstract 2.000001;

use DBIx::QuickORM::Value();
use DBIx::QuickORM::WhereBuilder::SQLAbstract();

use Object::HashBase qw{
    +sqla
};

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::SQLBuilder';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::SQLBuilder::SQLAbstract - The default SQL builder.

=head1 DESCRIPTION

The builder handles use unless the ORM is given another. It fulfils
L<DBIx::QuickORM::Role::SQLBuilder> with L<SQL::Abstract> 2.x for the
C<where>, C<having>, and order, and writes everything else itself.

The C<WHERE> is built by the request's C<where_builders>, the first whose
C<can_build_where> is true (see L<DBIx::QuickORM::Role::WhereBuilder>). When
no builder can, it croaks. Without C<where_builders> it is built as below, by
L<DBIx::QuickORM::WhereBuilder::SQLAbstract>.

A C<where> uses L<SQL::Abstract>'s syntax with its C<columns> bind type.
Binds inside literal SQL are C<[$name, $value]> pairs, as in
C<< \["age > ?", [age => 40]] >>. The name decides how the value is bound
when it is a field of the table. A name with a dot is read as qualified
(C<table.field>).

C<having> uses the C<where> syntax, and C<order_by> L<SQL::Abstract>'s order
syntax.

C<limit> and C<offset> must be non-negative integers and are written into the
SQL. An C<offset> without a C<limit> gets the largest limit every supported
database accepts.

Value markers (L<DBIx::QuickORM::Value>) may be values anywhere in a C<where>.
An C<sql> marker becomes L<SQL::Abstract> literal SQL with its binds,
C<< \[$sql, @binds] >>. The others become binds of the field they are under,
resolved when the SQL runs.

As with any L<SQL::Abstract> literal, an C<sql> marker directly under a field
supplies its own operator: C<< {hits => sql('= 2 + ?', 5)} >>, or
C<< {hits => {'=' => sql('2 + ?', 5)}} >>. Markers inside L<SQL::Abstract>'s
own literal SQL are left to its binds.

=head1 SYNOPSIS

    my $orm = DBIx::QuickORM->new(..., sql_builder => 'DBIx::QuickORM::SQLBuilder::SQLAbstract');

    my ($sql, $binds) = $orm->sql_builder->select(
        $source,
        $dialect,
        where => {name => 'bob'},
        limit => 10,
    );

=head1 PUBLIC METHODS

=over 4

=item $builder = DBIx::QuickORM::SQLBuilder::SQLAbstract->new

A new builder. It takes no arguments.

=item ($sql, \@binds) = $builder->select($source, $dialect, %request)

=item ($sql, \@binds) = $builder->count($source, $dialect, where => $where)

=item ($sql, \@binds) = $builder->update($source, $dialect, \%values, where => $where)

=item ($sql, \@binds) = $builder->delete($source, $dialect, where => $where)

=item $where = $builder->combine_where(op => $op, left => $left, right => $right)

As L<DBIx::QuickORM::Role::SQLBuilder> describes. Each croaks on a request
key it does not know.

A C<select> that adds nothing to a query source returns the query as it is.

C<update> croaks without a hashref of at least one value. An C<sql> marker as
a value is written into the SQL.

C<combine_where> returns C<< {-and => [$left, $right]} >> or C<< {-or =>
[$left, $right]} >>, and croaks on any other C<op>. A plain-string side is
raw SQL, as a C<where>.

A side that is wholly literal SQL, a plain string, an C<sql> marker, or
C<< \[...] >>, is wrapped in parentheses, so an C<OR> in it stays grouped.
Literal SQL you nest inside C<-and> or C<-or> yourself is not touched.

A side that is undef, an empty string, or an empty hash or array matches
every row: under C<and> the other side is returned as it is, and under C<or>
the result is C<{}>.

=back

=cut

my %SELECT  = map { $_ => 1 } qw/fields where where_builders order_by limit offset group_by having/;
my %WHERE   = map { $_ => 1 } qw/where where_builders/;
my %COMBINE = map { $_ => 1 } qw/op left right/;

# Agent Note: the largest signed 64-bit integer, a limit PostgreSQL, SQLite, DuckDB, and the MySQL family all accept.
my $NO_LIMIT = '9223372036854775807';

sub select {
    my $self = shift;
    my ($source, $dialect, %request) = @_;
    $self->_check(select => \%SELECT, \%request);

    my @given = grep { defined $request{$_} } keys %request;
    if (!@given and my @query = $source->query_sql) {
        return @query;
    }

    my ($fields, $field_binds) = $self->_fields($dialect, $request{fields});
    my $computed = $self->_having_computed($dialect, @request{qw/fields having/});
    my ($sql, $binds) = $self->_from("SELECT $fields FROM", $source, $dialect, (map { ($_ => $request{$_}) } qw/where where_builders group_by having order_by/), computed => $computed);
    unshift @$binds => @$field_binds;

    my ($limit, $offset) = map { $self->_count_arg($_, $request{$_}) } qw/limit offset/;
    $limit //= $NO_LIMIT if defined $offset;
    $sql .= " LIMIT $limit"   if defined $limit;
    $sql .= " OFFSET $offset" if defined $offset;

    return ($sql, $binds);
}

sub count {
    my $self = shift;
    my ($source, $dialect, %request) = @_;
    $self->_check(count => \%WHERE, \%request);
    return $self->_from('SELECT COUNT(*) AS count FROM', $source, $dialect, %request);
}

sub update {
    my $self = shift;
    my ($source, $dialect, $values, %request) = @_;
    $self->_check(update => \%WHERE, \%request);
    croak "update() needs a hashref of at least one value" unless ref($values) eq 'HASH' && %$values;

    my (@set, @binds);
    for my $field (sort keys %$values) {
        my ($sql, @value_binds) = $self->_value($field, $values->{$field});
        push @set   => $dialect->quote_identifier($field) . " = $sql";
        push @binds => @value_binds;
    }

    my ($from,  $from_binds)  = $source->from_sql($dialect);
    my ($where, $where_binds) = $self->_where_clause($source, $dialect, @request{qw/where where_builders/});
    return ("UPDATE $from SET " . join(', ' => @set) . $where, [@$from_binds, @binds, @$where_binds]);
}

sub delete {
    my $self = shift;
    my ($source, $dialect, %request) = @_;
    $self->_check(delete => \%WHERE, \%request);
    return $self->_from('DELETE FROM', $source, $dialect, %request);
}

sub combine_where {
    my $self   = shift;
    my %params = @_;
    $self->_check(combine_where => \%COMBINE, \%params);

    my ($op, $left, $right) = @params{qw/op left right/};
    croak "combine_where() takes op 'and' or 'or'" unless defined($op) && $op =~ m/^(?:and|or)\z/;

    my $empty = sub { my $r = ref($_[0]); !defined($_[0]) || ($r eq 'HASH' && !%{$_[0]}) || ($r eq 'ARRAY' && !@{$_[0]}) || ($r eq '' && $_[0] eq '') };
    return {}     if $op eq 'or' && ($empty->($left) || $empty->($right));
    return $right if $empty->($left);
    return $left  if $empty->($right);
    return {"-$op" => [map { $self->_group($_) } $left, $right]};
}

=pod

=over 4

=item $sqla = $builder->sqla($dialect)

The L<SQL::Abstract> for the dialect's quote character, made on first use.

=back

=cut

sub sqla {
    my $self      = shift;
    my ($dialect) = @_;
    my $q         = $dialect->quote_char;
    return $self->{+SQLA}->{$q} //= SQL::Abstract->new(quote_char => $q, name_sep => '.', bindtype => 'columns');
}

=pod

=over 4

=item $where = $builder->convert_where($where)

A copy of C<$where> with every value marker, at any depth, in the form
L<SQL::Abstract> takes.

A marker holding undef becomes a plain undef, so it gives C<IS NULL> (or
C<IS NOT NULL> under C<!=>) as a plain undef does.

=back

=cut

sub convert_where {
    my $self    = shift;
    my ($where) = @_;
    my $type    = ref($where) or return $where;

    if (blessed($where)) {
        return $where             unless $where->isa('DBIx::QuickORM::Value');
        return undef              unless $where->kind eq 'sql' || defined $where->value;    # so SQL::Abstract writes IS NULL
        return {-value => $where} unless $where->kind eq 'sql';
        return \[$where->value, map { [undef, $_] } @{$where->binds}];
    }

    return {map { ($_ => $self->convert_where($where->{$_})) } keys %$where} if $type eq 'HASH';
    return [map { $self->convert_where($_) } @$where]                        if $type eq 'ARRAY';
    return $where;
}

=head1 PRIVATE METHODS

=over 4

=item $builder->_check($method, \%known, \%request)

Croaks naming every request key not in C<%known>.

=back

=cut

sub _check {
    my $self = shift;
    my ($method, $known, $request) = @_;
    my @unknown = sort grep { !$known->{$_} } keys %$request;
    croak "Unknown request key(s) for $method(): " . join(', ' => @unknown) if @unknown;
}

=pod

=over 4

=item ($sql, \@binds) = $builder->_from($prefix, $source, $dialect, where => $where, where_builders => \@chain, group_by => \@fields, having => $having, order_by => $order, computed => \%computed)

C<$prefix>, the source's C<FROM> part, then the C<WHERE>, C<GROUP BY>,
C<HAVING>, and C<ORDER BY> for the clauses given. With C<computed> (from
C<_having_computed>), the C<HAVING> writes those names as their SQL.

=back

=cut

sub _from {
    my $self = shift;
    my ($prefix, $source, $dialect, %clauses) = @_;

    my $sqla = $self->sqla($dialect);
    my ($from, $from_binds)   = $source->from_sql($dialect);
    my ($where, $where_binds) = $self->_where_clause($source, $dialect, @clauses{qw/where where_builders/});
    my $sql = "$prefix $from$where";

    $sql .= ' GROUP BY ' . join(', ' => map { $self->_name($dialect, $_) } @{$clauses{group_by}}) if $clauses{group_by};

    my $having_sqla = $clauses{computed} ? $self->_computed_sqla($dialect, $clauses{computed}) : $sqla;
    my ($having, @having_binds) = $having_sqla->where($self->convert_where($clauses{having}));
    $having =~ s/^ WHERE / HAVING /;
    my ($order, @order_binds) = $sqla->where(undef, $clauses{order_by});

    return ("$sql$having$order", [@$from_binds, @$where_binds, @having_binds, @order_binds]);
}

=pod

=over 4

=item ($sql, \@binds) = $builder->_where_clause($source, $dialect, $where, \@chain)

The C<WHERE> clause, with a leading space, or an empty string, from the first
where builder in C<@chain> that can build it, or
L<DBIx::QuickORM::WhereBuilder::SQLAbstract> without a chain. Croaks when
none can. An undef or empty-string C<where> asks no builder.

=back

=cut

my @DEFAULT_CHAIN = ('DBIx::QuickORM::WhereBuilder::SQLAbstract');

sub _where_clause {
    my $self = shift;
    my ($source, $dialect, $where, $chain) = @_;
    return ('', []) unless defined($where) && (ref($where) || length($where));

    for my $builder (@{$chain // \@DEFAULT_CHAIN}) {
        next unless $builder->can_build_where($where);
        my ($sql, $binds) = $builder->build_where($where, $source, $dialect);
        return (length($sql) ? " WHERE $sql" : '', $binds);
    }

    croak "No where builder can build this where: " . (ref($where) || $where);
}

=pod

=over 4

=item ($sql, \@binds) = $builder->_fields($dialect, $fields)

The select list: C<*> for undef, or the names of an arrayref quoted as
C<_name> does. For a hashref, each expression (a field name, an C<sql()>
marker, or C<FUNC(field)> from C<[$func, $field]>, the field C<*> left
unquoted) C<AS> its quoted name, sorted by name.

=back

=cut

sub _fields {
    my $self = shift;
    my ($dialect, $fields) = @_;

    return ('*',                                                       []) unless $fields;
    return (join(', ' => map { $self->_name($dialect, $_) } @$fields), []) if ref($fields) eq 'ARRAY';

    my (@sql, @binds);
    for my $name (sort keys %$fields) {
        my ($sql, @expr_binds) = $self->_expr($dialect, $fields->{$name});
        push @sql   => "$sql AS " . $dialect->quote_identifier($name);
        push @binds => @expr_binds;
    }

    return (join(', ' => @sql), \@binds);
}

=pod

=over 4

=item ($sql, @binds) = $builder->_expr($dialect, $expr)

One computed column's SQL: a field name, an C<sql()> marker, or
C<FUNC(field)> from C<[$func, $field]>, the field C<*> left unquoted.

=back

=cut

sub _expr {
    my $self = shift;
    my ($dialect, $expr) = @_;
    return $self->_value(undef, $expr)                                                            if $self->_is_sql($expr);
    return ("$expr->[0](" . ($expr->[1] eq '*' ? '*' : $self->_name($dialect, $expr->[1])) . ')') if ref($expr) eq 'ARRAY';
    return ($self->_name($dialect, $expr));
}

=pod

=over 4

=item \%computed = $builder->_having_computed($dialect, $fields, $having)

Each computed column's SQL and binds, C<< {$name => [$sql, @binds]} >>, an
C<sql()> column's in parentheses, for a C<having> to name. Undef when there
is no C<having>, no computed columns, or the dialect's C<having_uses_alias>
is true.

=item $sqla = $builder->_computed_sqla($dialect, \%computed)

An L<SQL::Abstract> like C<sqla>'s that writes each name in C<%computed> as
that column's SQL.

=back

=cut

sub _having_computed {
    my $self = shift;
    my ($dialect, $fields, $having) = @_;
    return undef unless defined($having) && ref($fields) eq 'HASH' && %$fields;
    return undef if $dialect->having_uses_alias;
    my %computed;
    for my $name (keys %$fields) {
        my ($sql, @binds) = $self->_expr($dialect, $fields->{$name});
        $sql = "($sql)" if $self->_is_sql($fields->{$name});                # sql() may hold a low-precedence operator
        $computed{$name} = [$sql, @binds];
    }
    return \%computed;
}

sub _computed_sqla {
    my $self = shift;
    my ($dialect, $computed) = @_;

    my $sqla = SQL::Abstract->new(quote_char => $dialect->quote_char, name_sep => '.', bindtype => 'columns');
    $sqla->wrap_expander(
        ident => sub {
            my ($orig) = @_;
            return sub {
                my ($sqla, $type, $ident) = @_;
                my $name = ref($ident) ? join('.' => @$ident) : $ident;
                if (my $expr = $computed->{$name}) {
                    return {-literal => [@$expr]};    # the SQL, then its binds, already [undef, $value] pairs
                }
                return $orig ? $sqla->$orig($type, $ident) : {-ident => ref($ident) ? $ident : [split m/\./, $ident, -1]};
            };
        },
    );

    return $sqla;
}

=pod

=over 4

=item $sql = $builder->_name($dialect, $name)

A field name quoted through the dialect, a dot separating a qualifier.

=back

=cut

sub _name {
    my $self = shift;
    my ($dialect, $name) = @_;
    return join '.' => map { $dialect->quote_identifier($_) } split m/\./, $name, -1;
}

=pod

=over 4

=item $n = $builder->_count_arg($name, $value)

The value, or undef for undef. Croaks unless it is a non-negative integer.

=back

=cut

sub _count_arg {
    my $self = shift;
    my ($name, $value) = @_;
    return undef                                                 unless defined $value;
    croak "'$name' must be a non-negative integer, got '$value'" unless $value =~ m/^\d+\z/;
    return $value;
}

=pod

=over 4

=item ($sql, @binds) = $builder->_value($field, $value)

C<?> and the bind for one value, or an C<sql> marker's SQL and binds.

=back

=cut

sub _value {
    my $self = shift;
    my ($field, $value) = @_;
    return ('?',           [$field => $value]) unless $self->_is_sql($value);
    return ($value->value, map { [undef, $_] } @{$value->binds});
}

=pod

=over 4

=item $bool = $builder->_is_sql($value)

True for an C<sql> marker.

=back

=cut

sub _is_sql { blessed($_[1]) && $_[1]->isa('DBIx::QuickORM::Value') && $_[1]->kind eq 'sql' ? 1 : 0 }

=pod

=over 4

=item $side = $builder->_group($side)

A side of C<combine_where> in parentheses when the whole side is literal SQL:
a plain string, an C<sql> marker, or C<< \[$sql, @binds] >>. Any other side
is returned as it is. Nothing inside a side is touched.

=back

=cut

sub _group {
    my $self = shift;
    my ($side) = @_;
    return \["( $side )"] unless ref($side);
    return DBIx::QuickORM::Value::sql("( " . $side->value . " )", @{$side->binds}) if $self->_is_sql($side);
    return $side unless ref($side) eq 'REF' && ref($$side) eq 'ARRAY';
    my ($sql, @binds) = @$$side;
    return \["( $sql )", @binds];
}

1;

__END__

=head1 SOURCE

The source code repository for DBIx-QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
