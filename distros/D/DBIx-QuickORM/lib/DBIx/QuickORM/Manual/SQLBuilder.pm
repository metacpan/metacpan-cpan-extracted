package DBIx::QuickORM::Manual::SQLBuilder;
use strict;
use warnings;

our $VERSION = '0.000025';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Manual::SQLBuilder - Custom SQL builders.

=head1 DESCRIPTION

A B<SQL builder> is the component that turns a query handle's intent - a
source, a where-clause, a field list, ordering, limit, and the data to write -
into a SQL statement and its bind values. The ORM never hand-rolls statements
inline; every C<SELECT>, C<INSERT>, C<UPDATE>, C<DELETE>, and C<UPSERT> goes
through a builder.

Builders consume L<DBIx::QuickORM::Role::SQLBuilder>. The shipped
implementation, L<DBIx::QuickORM::SQLBuilder::SQLAbstract>, is built on
L<SQL::Abstract>. You can replace it - per handle or per connection - with any
object that satisfies the role.

This document covers where a builder fits in the query pipeline, the contract
the role defines, the statement-and-bind structure a builder returns, how the
SQL::Abstract builder implements that contract, how to plug a custom builder
in, and how to write one.

This is part of the L<DBIx::QuickORM::Manual>.

=head1 WHERE A BUILDER FITS

A L<DBIx::QuickORM::Handle> collects query state (source, where, limit,
order_by, fields, dialect) and, when it is time to run, calls the appropriate
C<qorm_*> method on its builder. The builder returns a hashref; the handle
prepares the statement, binds the values, and executes:

    handle state ---> builder->qorm_select(...) ---> { statement, bind, source }
                                                          |
                                       handle prepares + binds + executes

The handle picks its builder lazily: an explicit per-handle builder wins,
otherwise a builder carried by the where object (if it has a C<sql_builder>
method), otherwise the connection's C<default_sql_builder>. See
L<DBIx::QuickORM::Handle/sql_builder>.

The builder's job ends at producing the statement and bind specs. Value
B<deflation> (running a column's type/affinity conversion before binding) and
binary quoting happen in the handle when it binds, not in the builder. The
builder only needs to label each bind with the field it belongs to; the handle
does the rest.

=head1 THE BUILDER CONTRACT

L<DBIx::QuickORM::Role::SQLBuilder> requires seven methods and provides one.

=head2 REQUIRED METHODS

=over 4

=item $sql = $builder->qorm_select(%params)

=item $sql = $builder->qorm_insert(%params)

=item $sql = $builder->qorm_update(%params)

=item $sql = $builder->qorm_delete(%params)

=item $sql = $builder->qorm_where(%params)

Build a statement of the named kind. Each returns the statement-and-bind
structure described below.

=item $cond = $builder->qorm_and($a, $b)

=item $cond = $builder->qorm_or($a, $b)

Combine two where-conditions into one. The handle calls these when you chain
C<< $h->and(...) >> / C<< $h->or(...) >>. The return value is whatever your
builder accepts as a C<where> param - it is fed straight back into the next
build. It need not be SQL; for the SQL::Abstract builder it is a nested
hashref.

=back

=head2 PROVIDED METHODS

=over 4

=item $where = $builder->qorm_where_for_row($row)

Returns a where-clause that uniquely identifies a row. The role implements this
as C<< $row->primary_key_hashref >>, which is the right answer for any builder
that accepts a plain column/value hashref as a where. Override it if your
builder's where format differs.

=item $orm_row = $builder->qorm_row_to_orm($source, \%row)

Returns a new hashref with a fetched row's keys remapped from database column
names back to ORM names for the given source. Unknown keys pass through
unchanged. The role implements this with C<< $source->field_orm_name >>; the
handle calls it on rows it fetches so the row layer is uniformly ORM-keyed. See
L</COLUMN NAME TRANSLATION>.

=back

=head2 OPTIONAL: qorm_upsert

The role does not require C<qorm_upsert>, but the handle calls it when you
upsert. A builder that omits it simply cannot be used for upserts. See
L</UPSERT> below for the contract.

=head1 COLUMN NAME TRANSLATION

A column can use one name in the ORM and a different name in the database (its
C<db_name>). Everything a caller touches uses the ORM name; everything in
generated SQL must use the database name. Translation is the builder's
responsibility, and the contract is:

=over 4

=item *

B<Emit database names in all generated SQL.> Before handing field names to your
backend, translate them through the source: insert/update data keys, the field
list, the returning list, where-clause column references, order-by columns, and
(for upsert) the conflict and update-set columns. The source provides
C<< $source->field_db_name($name) >>, which maps either an ORM name or a
database name to the database name and is idempotent.

=item *

B<Return rows keyed by ORM name.> Fetched rows come back keyed by database
column name. The handle restores ORM names with C<qorm_row_to_orm> (which uses
C<< $source->field_orm_name >>), so a builder that follows the standard fetch
path gets this for free.

=item *

B<Never rewrite literal SQL.> A scalar-ref where, a C<< \['sql', @bind] >>
literal, or any column name the source does not recognize is passed through
untouched. Callers who write raw SQL use database names themselves.

=back

When ORM and database names are identical (the common case) every translation
is an identity, so a builder that ignores aliasing still works for non-aliased
schemas - but it will emit wrong SQL the moment a column is aliased. The
shipped SQL::Abstract builder implements the full contract; see
L</HOW THE SQL::ABSTRACT BUILDER WORKS>.

Because field binds end up labelled with the B<database> name (see
L</BIND SPECS>), and the source resolves type and affinity by either name, value
deflation at bind time keeps working without any extra handling.

=head1 THE PARAMETERS A BUILDER RECEIVES

The handle passes a flat key/value list. Which keys are present depends on the
operation; the relevant ones:

=over 4

=item source

The source object (a table, view, join, or literal). Required for every build.
It consumes L<DBIx::QuickORM::Role::Source>; the builder uses
C<< $source->source_db_moniker >> to name it in SQL, and (for upsert)
C<< $source->primary_key >>. The source is also passed straight back out in the
result so the handle can deflate binds against it.

=item where

The where-clause, in whatever format your builder accepts. Optional.

=item fields

The list of columns to fetch. Required for C<qorm_select>.

=item order_by

Ordering, builder-specific format. Optional.

=item limit

A row limit. Optional. See L</LIMIT>.

=item insert / update

The row data to write, a column-to-value hashref. C<qorm_insert> reads
C<insert>; C<qorm_update> reads C<update>.

=item returning

Columns to return from a writing statement (for dialects that support
C<RETURNING>). Optional.

=item dialect

The active L<DBIx::QuickORM::Dialect>. A builder mostly ignores it, but upsert
uses it for the dialect-specific conflict clause.

=back

=head1 THE STATEMENT-AND-BIND STRUCTURE

Every C<qorm_*> build method returns a hashref:

    {
        statement => "SELECT ... WHERE ... LIMIT ?",
        bind      => [ \%spec, \%spec, ... ],
        source    => $source,
    }

=over 4

=item statement

The SQL string, with C<?> placeholders.

=item source

The same source object that came in. The handle needs it to look up each
field's type and affinity when binding.

=item bind

An ordered arrayref of B<bind specs>, one per placeholder. Order is not what
positions a bind - the C<param> key does - but keeping them in order is good
manners.

=back

=head2 BIND SPECS

Each bind spec is a hashref. There are two kinds, distinguished by C<type>.

A B<field> bind carries a value that belongs to a column:

    {
        param => 1,           # 1-based placeholder position
        value => $value,      # the value to bind
        type  => 'field',
        field => 'name',      # the column this value is for
    }

The handle treats C<field> binds specially: it looks up the column's affinity
and type on the source and B<deflates> the value (e.g. encoding JSON, packing a
UUID, formatting a DateTime) before binding, and applies binary quoting when
the affinity is C<binary>. This is why a builder must label each value with its
field rather than deflating values itself.

The C<field> here is the B<database> column name (what the builder emitted into
the statement); the source resolves type and affinity by either ORM or database
name, so deflation works regardless of aliasing. See L</COLUMN NAME TRANSLATION>.

A B<limit> bind carries a raw scalar bound as-is, with no field, no deflation:

    {
        param => 5,
        value => $limit,
        type  => 'limit',
    }

Any C<type> other than C<field> is bound verbatim. If your builder needs to
emit a placeholder for something that must not go through column deflation
(a computed value, a literal you have already prepared), give it a non-C<field>
type.

=head1 LIMIT

The SQL::Abstract builder does not delegate C<LIMIT> to SQL::Abstract; it
appends C<" LIMIT ?"> to the finished statement and pushes a C<limit> bind.
A custom builder is free to handle limit however its backend prefers, as long
as the placeholder count in the statement matches the bind specs.

=head1 UPSERT

When you upsert, the handle calls C<qorm_upsert> with the same params as an
insert, plus the C<dialect>. The contract:

=over 4

=item *

Build the underlying C<INSERT> (the SQL::Abstract builder calls its own
C<qorm_insert>).

=item *

Split the data on the source's primary key: the key columns identify the
conflict, the non-key columns become the update set.

=item *

Ask the dialect for the conflict clause with
C<< $dialect->upsert_statement($pk) >> - this yields C<ON CONFLICT(...) DO
UPDATE SET> on SQLite/Postgres, C<ON DUPLICATE KEY UPDATE> on MySQL - then
append C<< "col = ?" >> assignments and their binds for each non-key column.

=item *

Preserve any trailing C<RETURNING> clause: pull it off before appending the
conflict clause and re-attach it at the end.

=back

Croak if the source has no primary key - there is nothing to conflict on.

=head1 HOW THE SQL::ABSTRACT BUILDER WORKS

L<DBIx::QuickORM::SQLBuilder::SQLAbstract> inherits from L<SQL::Abstract> and
consumes the role. Reading it is the fastest way to understand the contract in
practice; the shape:

=over 4

=item Construction

C<new> forces SQL::Abstract's C<bindtype> to C<'columns'>, so SQL::Abstract
hands back each bind as a C<[$field, $value]> pair. That field name is exactly
what the builder needs to label C<field> bind specs.

=item Generated build methods

C<qorm_insert>, C<qorm_update>, C<qorm_select>, C<qorm_delete>, and
C<qorm_where> are generated at compile time from a common template. Each one:

=over 4

=item *

Pulls C<source> out of the params and resolves it to its db moniker via
C<< $source->source_db_moniker >> (a blessed source is checked for the Source
role first; a plain string is passed through, which is handy in tests).

=item *

Translates ORM column names to database names (C<_translate_params>): the
insert/update data keys, field list, returning list, where-clause, and order-by
are each rewritten through the source. The where-walker translates a hash key
only when the source recognizes it as a field, so logic and comparison
operators pass through untouched and the rule survives new SQL::Abstract
operators; literal SQL is left alone. See L</COLUMN NAME TRANSLATION>.

=item *

Translates the ORM params into the positional argument list SQL::Abstract's
matching method wants, via a per-operation C<_*_args> helper (C<_select_args>,
C<_insert_args>, etc.). These helpers enforce per-operation rules - e.g. insert
and delete confess on C<limit>/C<order_by>, since SQL::Abstract has nowhere to
put them.

=item *

Calls the inherited SQL::Abstract method to get C<($statement, @bind)>.

=item *

Rewrites the C<@bind> pairs into C<field> bind specs with sequential C<param>
numbers.

=item *

Appends C<LIMIT ?> and a C<limit> bind if a C<limit> param was given.

=item *

Returns C<< { statement, bind, source } >>.

=back

=item Value wrapping

C<_format_insert_and_update_data> wraps each insert/update value in
C<< { -value => $v } >> so SQL::Abstract treats it as a literal bind rather than
trying to interpret a hash- or array-ref value as an operator/sub-query.

=item qorm_and / qorm_or

Return C<< { '-and' => [$a, $b] } >> / C<< { '-or' => [$a, $b] } >> - the
SQL::Abstract spellings for combining conditions.

=item qorm_upsert

Implements the L</UPSERT> contract on top of C<qorm_insert> and
C<< $dialect->upsert_statement >>.

=back

=head1 USING A CUSTOM BUILDER

=head2 Per handle

C<sql_builder> on a handle is a clone-setter: pass a builder and you get a new
handle that uses it. The original is unchanged.

    my $h2 = $h->sql_builder(My::SQLBuilder->new);
    my @rows = $h2->all;

This is the narrowest scope - one chain of queries.

=head2 Per connection

A connection takes a C<default_sql_builder> at construction; every handle made
from that connection falls back to it. If none is given, the connection lazily
builds a L<DBIx::QuickORM::SQLBuilder::SQLAbstract>.

    my $con = DBIx::QuickORM::Connection->new(
        orm                 => $orm,
        default_sql_builder => My::SQLBuilder->new,
    );

=head1 WRITING A CUSTOM BUILDER

A custom builder is any class that consumes the role and implements the seven
required methods. Optionally add C<qorm_upsert> for upsert support, and
override C<qorm_where_for_row> if your where format is not a plain hashref.

The skeleton below ignores SQL::Abstract entirely and emits SQL directly, to
show the bare contract. A where here is a C<< { column => value } >> hashref.

    package My::SQLBuilder;
    use strict;
    use warnings;

    use Carp qw/croak/;

    use Role::Tiny::With qw/with/;
    with 'DBIx::QuickORM::Role::SQLBuilder';

    # Build a "col = ? AND col = ?" fragment plus its field binds, starting
    # placeholders at $next. Column names are translated to database names.
    sub _where_sql {
        my ($self, $source, $where, $next) = @_;
        return ("", []) unless $where && keys %$where;

        my (@parts, @bind);
        for my $field (sort keys %$where) {
            my $db = $source->field_db_name($field);
            push @parts => "$db = ?";
            push @bind  => {
                param => $$next++,
                value => $where->{$field},
                type  => 'field',
                field => $db,
            };
        }

        return (" WHERE " . join(" AND " => @parts), \@bind);
    }

    sub qorm_select {
        my $self   = shift;
        my %params = @_;

        my $source = $params{source} or croak "No source provided";
        my $fields = $params{fields} or croak "'fields' is required";

        my $moniker = $source->source_db_moniker;
        my $cols    = join(", " => map { $source->field_db_name($_) } @$fields);

        my $param = 1;
        my ($where_sql, $bind) = $self->_where_sql($source, $params{where}, \$param);

        my $stmt = "SELECT $cols FROM $moniker$where_sql";

        if (my $limit = $params{limit}) {
            $stmt .= " LIMIT ?";
            push @$bind => {param => $param++, value => $limit, type => 'limit'};
        }

        return {statement => $stmt, bind => $bind, source => $source};
    }

    # qorm_insert / qorm_update / qorm_delete / qorm_where follow the same
    # shape: name the source via source_db_moniker, translate column names to
    # database names via $source->field_db_name, build the statement, emit one
    # bind spec per placeholder (type => 'field' for column values so the handle
    # deflates them), and return { statement, bind, source }.

    sub qorm_and {
        my ($self, $a, $b) = @_;
        return {%$a, %$b};   # naive: merge two hashref wheres
    }

    sub qorm_or { croak "OR not supported by this builder" }

    1;

Points the example makes concrete:

=over 4

=item *

Resolve the source through C<source_db_moniker> - never interpolate a source
object directly.

=item *

Translate column names through C<< $source->field_db_name >> so the SQL uses
database names; a non-aliased schema makes this a no-op. See
L</COLUMN NAME TRANSLATION>.

=item *

Number placeholders with C<param>, starting at 1, and keep the count in sync
between the statement and the bind list.

=item *

Tag column values C<< type => 'field' >> with their C<field>, so the handle
deflates and (if binary) quotes them. Use any other C<type> for values that
must bind raw.

=item *

Always return the C<source> in the result; the handle needs it at bind time.

=back

For a production-grade implementation that handles ordering, complex
where-clauses, and every dialect, model on
L<DBIx::QuickORM::SQLBuilder::SQLAbstract> rather than this skeleton.

=head1 SEE ALSO

=over 4

=item L<DBIx::QuickORM::Manual>

The documentation hub.

=item L<DBIx::QuickORM::Role::SQLBuilder>

The builder role and its required methods.

=item L<DBIx::QuickORM::SQLBuilder::SQLAbstract>

The shipped SQL::Abstract-backed builder.

=item L<DBIx::QuickORM::Role::Source>

The source interface a builder queries (C<source_db_moniker>, C<primary_key>,
C<field_db_name>, C<field_orm_name>).

=item L<DBIx::QuickORM::Handle>

Where builders are selected, called, and their binds executed.

=item L<DBIx::QuickORM::Dialect>

Supplies the upsert conflict clause via C<upsert_statement>.

=back

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
