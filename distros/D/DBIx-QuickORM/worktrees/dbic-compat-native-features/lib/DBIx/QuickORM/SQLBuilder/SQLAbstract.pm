package DBIx::QuickORM::SQLBuilder::SQLAbstract;
use strict;
use warnings;

our $VERSION = '0.000028';

use Carp qw/croak confess/;
use Sub::Util qw/set_subname/;
use Scalar::Util qw/blessed/;
use DBIx::QuickORM::Util qw/literal_write_value/;
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
C<source>. A C<limit> param appends a C<LIMIT ?> clause, and an C<offset>
param extends it to C<LIMIT ? OFFSET ?> (an offset without a limit croaks,
since not every dialect allows a bare OFFSET). A true C<distinct> param turns
a C<SELECT> into C<SELECT DISTINCT>. These methods are generated at compile
time.

=cut

BEGIN {
    for my $meth (qw/insert update select delete where/) {
        my $arg_meth = "_${meth}_args";
        my $new_meth = "qorm_${meth}";

        my $code = sub {
            my $self   = shift;
            my %params = @_;

            my $source = delete $params{source} or croak "No source provided";

            $self->_translate_params($source, \%params) if blessed($source);

            my @args = $self->$arg_meth(\%params);

            my ($stmt, @bind);
            if (blessed($source)) {
                croak "'$source' does not implement the 'DBIx::QuickORM::Role::Source' role" unless $source->DOES('DBIx::QuickORM::Role::Source');
                my $moniker = $source->source_db_moniker;
                # Emit the FROM target verbatim. With quote_char set,
                # SQL::Abstract would otherwise quote a plain-string moniker as
                # a single identifier, corrupting literal-source subqueries
                # ("( SELECT ... ) AS x") and join FROM fragments. A scalar ref
                # is passed through as literal SQL; join monikers are already
                # refs, so only wrap when one is not.
                my $from = ref($moniker) ? $moniker : \$moniker;
                ($stmt, @bind) = $self->$meth($from, @args);
            }
            else {
                ($stmt, @bind) = $self->$meth($source, @args);
            }

            # Not every dialect supports a bare OFFSET (MySQL requires a LIMIT
            # before it), so OFFSET is only emitted as part of "LIMIT ? OFFSET ?".
            croak "Cannot use 'offset' without a 'limit'"
                if defined($params{offset}) && !defined($params{limit});

            $stmt =~ s/^(\s*SELECT)\b/$1 DISTINCT/i if $params{distinct};

            # GROUP BY / HAVING / ORDER BY are appended here (only for select, and
            # in that SQL clause order) rather than left to SQL::Abstract's select(),
            # which would emit ORDER BY immediately after WHERE. Their binds are raw
            # [col, val] pairs like the where binds and are tagged together below, so
            # they land positionally between the where binds and the limit binds.
            if ($meth eq 'select') {
                if (defined(my $group = $params{group_by})) {
                    my ($gsql, @gbind) = $self->_group_by($group);
                    if (length $gsql) {
                        $stmt .= $gsql;
                        push @bind => @gbind;
                    }
                }

                if (defined(my $having = $params{having})) {
                    my ($hsql, @hbind) = $self->_recurse_where($having);
                    if (defined($hsql) && length($hsql)) {
                        $stmt .= $self->_sqlcase(' having ') . $hsql;
                        push @bind => @hbind;
                    }
                }

                if (defined(my $order = $params{order_by})) {
                    my ($osql, @obind) = $self->_order_by($order);
                    if (length $osql) {
                        $stmt .= $osql;
                        push @bind => @obind;
                    }
                }
            }

            my $param = 1;
            @bind = map { my ($f, $v) = @{$_}; +{param => $param++, value => $v, type => 'field', field => $f} } @bind;

            if (defined(my $limit = $params{limit})) {
                $stmt .= " LIMIT ?";
                push @bind => {param => $param++, value => $limit, type => 'limit'};

                if (defined(my $offset = $params{offset})) {
                    $stmt .= " OFFSET ?";
                    push @bind => {param => $param++, value => $offset, type => 'offset'};
                }
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
source's primary key, with the non-key fields as the update set. When every
field belongs to the primary key a no-op assignment is used as the update set
so the statement stays valid and still returns the row on conflict. Croaks if
the source has no primary key.

=cut

sub qorm_upsert {
    my $self = shift;
    my %params = @_;

    my $data = delete $params{insert} // delete $params{update};

    my $sql = $self->qorm_insert(%params, insert => $data);

    my $source = $params{source};
    my $pk = $source->primary_key;
    confess "upsert cannot be used on a table without a primary key" unless $pk && @$pk;

    my $changes = { %$data };
    delete $changes->{$_} for @$pk;

    my $binds = $sql->{bind} //= [];
    my $counter = @$binds + 1;

    my $returning = "";
    my $statement = $sql->{statement};
    $returning = $1 if $statement =~ s/\s+(returning.*)$//is;

    my $pk_db = [ map { $source->field_db_name($_) } @$pk ];
    my $dbh   = $params{dialect}->dbh;
    my $conf  = $params{dialect}->upsert_statement($pk_db);
    my @inject;
    for my $field (sort keys %$changes) {
        my $db_field = $source->field_db_name($field);
        # Quote the identifier in the appended SET clause so a crafted or
        # unknown column name cannot break out into raw SQL; this clause is
        # built after SQL::Abstract runs, so its quote_char never reaches it.
        # The bind spec keeps the raw db name because field_affinity/field_type
        # look it up unquoted.
        my $col = $dbh->quote_identifier($db_field);
        my $v   = $changes->{$field};

        # Mirror the literal handling in _format_insert_and_update_data so the
        # conflict-UPDATE half stays symmetric with the INSERT half: a scalar
        # ref is emitted as SQL, [\'sql ?', @binds] is emitted with its binds,
        # and everything else is bound as data.
        unless (literal_write_value($v)) {
            push @inject => "$col = ?";
            push @$binds => {field => $db_field, value => $v, type => 'field', param => $counter++};
            next;
        }

        if (ref($v) eq 'SCALAR') {
            push @inject => "$col = $$v";
            next;
        }

        my ($sql, @lits) = @$v;
        push @inject => "$col = $$sql";
        push @$binds => {field => $db_field, value => $_, type => 'field', param => $counter++} for @lits;
    }
    # When every field is part of the primary key there is nothing to update
    # on conflict, but the conflict clause still needs an assignment (and
    # 'DO NOTHING' would suppress the RETURNING row). Inject a no-op
    # assignment instead. The MySQL-family clause ('ON DUPLICATE KEY UPDATE')
    # needs VALUES() so MySQL still reports the row via last_insert_id.
    unless (@inject) {
        my $col = $dbh->quote_identifier($pk_db->[0]);
        push @inject => $conf =~ m/ON DUPLICATE KEY UPDATE/i ? "$col = VALUES($col)" : "$col = $col";
    }

    $conf .= " " . join(', ' => @inject);

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

    confess "insert() with a 'limit' clause is not currently supported"     if defined $params->{limit};
    confess "insert() with an 'offset' clause is not currently supported"   if defined $params->{offset};
    confess "insert() with an 'order_by' clause is not currently supported" if $params->{order_by};
    confess "insert() with a 'group_by' clause is not currently supported"  if $params->{group_by};
    confess "insert() with a 'having' clause is not currently supported"    if $params->{having};
    confess "insert() with 'distinct' set is not currently supported"       if $params->{distinct};

    my $values = $params->{insert} // croak "'insert' is required";
    my $returning = $params->{returning};

    $values = $self->_format_insert_and_update_data($values);

    return ($values, $returning ? {returning => $returning} : ());
}

sub _delete_args {
    my $self = shift;
    my ($params) = @_;

    confess "delete() with a 'limit' clause is not currently supported"     if defined $params->{limit};
    confess "delete() with an 'offset' clause is not currently supported"   if defined $params->{offset};
    confess "delete() with an 'order_by' clause is not currently supported" if $params->{order_by};
    confess "delete() with a 'group_by' clause is not currently supported"  if $params->{group_by};
    confess "delete() with a 'having' clause is not currently supported"    if $params->{having};
    confess "delete() with 'distinct' set is not currently supported"       if $params->{distinct};

    my $where = $params->{where} // undef;
    my $returning = $params->{returning};

    return ($where, $returning ? {returning => $returning} : ());
}

sub _update_args {
    my $self = shift;
    my ($params) = @_;

    confess "update() with a 'limit' clause is not currently supported"     if defined $params->{limit};
    confess "update() with an 'offset' clause is not currently supported"   if defined $params->{offset};
    confess "update() with an 'order_by' clause is not currently supported" if $params->{order_by};
    confess "update() with a 'group_by' clause is not currently supported"  if $params->{group_by};
    confess "update() with a 'having' clause is not currently supported"    if $params->{having};
    confess "update() with 'distinct' set is not currently supported"       if $params->{distinct};

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

    # ORDER BY (and GROUP BY / HAVING) are appended after the fact in qorm_select
    # so GROUP BY / HAVING can be slotted between WHERE and ORDER BY; do not hand
    # order_by to SQL::Abstract's select() here or it would emit ORDER BY too early.
    return ($fields, $where);
}

sub _where_args {
    my $self = shift;
    my ($params) = @_;

    my $where = $params->{where};
    my $order = $params->{order_by};

    return ($where, $order);
}

=pod

=item ($sql, @bind) = $builder->_group_by($group)

Render a C<GROUP BY> clause (with a leading space) for a column or an arrayref
of columns. A plain string is quoted as an identifier; a scalar ref is emitted
as literal SQL. Returns an empty string when there is nothing to group by.

=cut

sub _group_by {
    my $self = shift;
    my ($group) = @_;

    my @cols = ref($group) eq 'ARRAY' ? @$group : ($group);

    my (@parts, @bind);
    for my $col (@cols) {
        next unless defined $col;
        my $ref = ref $col;
        if ($ref eq 'SCALAR') {
            push @parts => $$col;                                   # literal SQL, verbatim
        }
        elsif ($ref eq 'REF' && ref($$col) eq 'ARRAY') {
            my ($csql, @cbind) = @{$$col};                          # \[ 'expr ?', @binds ]
            push @parts => $csql;
            push @bind  => map { [undef, $_] } @cbind;
        }
        else {
            push @parts => $self->_quote($col);                     # plain column -> quoted
        }
    }

    return ('') unless @parts;

    return ($self->_sqlcase(' group by ') . join(', ', @parts), @bind);
}

=pod

=item $cond = $builder->qorm_and($a, $b)

=item $cond = $builder->qorm_or($a, $b)

Combine two where-conditions with C<SQL::Abstract>'s C<-and> / C<-or>
operators. Undefined operands are dropped first, so combining onto an absent
condition (e.g. C<< $handle->and(...) >> before any C<where> is set) returns
the remaining condition alone rather than an empty-sided C<-and>/C<-or>.

=cut

sub qorm_and {
    my $self = shift;
    my @parts = grep { defined } @_;
    return undef    unless @parts;
    return $parts[0] if @parts == 1;
    return +{'-and' => \@parts};
}

sub qorm_or {
    my $self = shift;
    my @parts = grep { defined } @_;
    return undef    unless @parts;
    return $parts[0] if @parts == 1;
    return +{'-or' => \@parts};
}

=pod

=item $formatted = $builder->_format_insert_and_update_data(\%data)

Wrap each data value in a C<< { -value => ... } >> so C<SQL::Abstract> binds it
rather than interpreting a hashref or arrayref value as an operator expression.
Intentional SQL literals are the exception: a scalar ref (C<\'NOW()'>) is emitted
verbatim, and an arrayref whose first element is a scalar ref (C<[\'col + ?', $n]>)
becomes a literal-with-bind expression whose bind values keep the column's
affinity.

=back

=cut

sub _format_insert_and_update_data {
    my $self = shift;
    my ($data) = @_;

    my %out;
    for my $field (keys %$data) {
        my $v = $data->{$field};

        unless (literal_write_value($v)) {
            $out{$field} = {'-value' => $v};
            next;
        }

        # A bare scalar ref is literal SQL; SQL::Abstract emits it verbatim.
        if (ref($v) eq 'SCALAR') {
            $out{$field} = $v;
            next;
        }

        # [\'sql ?', @binds] -> SQL::Abstract's \[ $sql, [col => bind], ... ]
        # literal-with-bind form. With bindtype 'columns' each bind must be a
        # [column, value] pair, so tag every bind with this field so affinity
        # and deflation still apply.
        my ($sql, @binds) = @$v;
        $out{$field} = \[ $$sql, map { [$field => $_] } @binds ];
    }

    return \%out;
}

=pod

=head1 PRIVATE METHODS

These translate caller-facing ORM column names into database column names so
that generated SQL always uses database names. They build fresh structures and
never mutate the caller's data. Literal SQL (scalar refs and array-of-literal
refs) is left untouched, and unknown names pass through unchanged.

=over 4

=item $builder->_translate_params($source, \%params)

Rewrite the C<insert>, C<update>, C<where>, C<fields>, C<returning>, and
C<order_by> params in place (each replaced with a freshly built structure)
from ORM names to database names for the given source.

=cut

sub _translate_params {
    my $self = shift;
    my ($source, $params) = @_;

    return unless $source->source_has_aliases;

    $params->{insert}    = $self->_translate_data($source, $params->{insert})     if $params->{insert};
    $params->{update}    = $self->_translate_data($source, $params->{update})     if $params->{update};
    $params->{fields}    = $self->_translate_fields($source, $params->{fields})   if $params->{fields};
    $params->{returning} = $self->_translate_fields($source, $params->{returning}) if $params->{returning};
    $params->{where}     = $self->_translate_where($source, $params->{where})     if defined $params->{where};
    $params->{order_by}  = $self->_translate_order($source, $params->{order_by})  if defined $params->{order_by};
    # group_by translates like an order-by column list; having is a where-style
    # condition. Aggregate aliases are unknown to the source and pass through
    # unchanged, so a HAVING can reference them.
    $params->{group_by}  = $self->_translate_order($source, $params->{group_by})  if defined $params->{group_by};
    $params->{having}    = $self->_translate_where($source, $params->{having})    if defined $params->{having};

    return;
}

=pod

=item $db_name = $builder->_field_to_db($source, $name)

Translate a single field name to its database name, leaving references (literal
SQL) untouched.

=cut

sub _field_to_db {
    my $self = shift;
    my ($source, $name) = @_;
    return $name if ref $name;
    return $source->field_db_name($name);
}

=pod

=item $hash = $builder->_translate_data($source, \%data)

Return a new data hashref with its keys translated to database names.

=cut

sub _translate_data {
    my $self = shift;
    my ($source, $data) = @_;
    return $data unless ref($data) eq 'HASH';
    return { map { $source->field_db_name($_) => $data->{$_} } keys %$data };
}

=pod

=item $fields = $builder->_translate_fields($source, \@fields)

Return a new field-list arrayref with each plain-scalar field translated to its
database name.

=cut

sub _translate_fields {
    my $self = shift;
    my ($source, $fields) = @_;
    return $fields unless ref($fields) eq 'ARRAY';
    return [ map { $self->_field_to_db($source, $_) } @$fields ];
}

=pod

=item $where = $builder->_translate_where($source, $where)

Recursively walk a C<SQL::Abstract> where-structure, returning a new structure
with field-name hash keys translated to database names. A hash key is treated
as a field when the source recognizes it; logic operators (C<-and>, C<-or>,
C<-not>, ...) are recursed into. Operator-expression values under a field key
(e.g. C<< { '>' => 5 } >>) and value arrayrefs are left as-is.

=cut

sub _translate_where {
    my $self = shift;
    my ($source, $where) = @_;

    my $ref = ref $where;

    if ($ref eq 'HASH') {
        my %out;
        for my $key (keys %$where) {
            my $val = $where->{$key};
            if ($key =~ m/^-/) {
                $out{$key} = ref($val) ? $self->_translate_where($source, $val) : $self->_field_to_db($source, $val);
            }
            else {
                $out{$self->_field_to_db($source, $key)} = $val;
            }
        }
        return \%out;
    }

    if ($ref eq 'ARRAY') {
        return [ map { $self->_translate_where($source, $_) } @$where ];
    }

    return $where;
}

=pod

=item $order = $builder->_translate_order($source, $order_by)

Return a new C<order_by> structure with column names translated to database
names. Handles a bare column, an arrayref of columns, and the
C<< { -asc => ... } >> / C<< { -desc => ... } >> hash forms (where the column
lives in the value). Literal SQL refs are left untouched.

=back

=cut

sub _translate_order {
    my $self = shift;
    my ($source, $order) = @_;

    my $ref = ref $order;

    return $self->_field_to_db($source, $order) unless $ref;

    if ($ref eq 'ARRAY') {
        return [ map { $self->_translate_order($source, $_) } @$order ];
    }

    if ($ref eq 'HASH') {
        my %out;
        for my $key (keys %$order) {
            my $val = $order->{$key};
            if (ref($val) eq 'ARRAY') {
                $out{$key} = [ map { $self->_field_to_db($source, $_) } @$val ];
            }
            else {
                $out{$key} = $self->_field_to_db($source, $val);
            }
        }
        return \%out;
    }

    return $order;
}

1;

__END__

=head1 SOURCE

The source code repository for DBIx::QuickORM can be found at
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
