package Database::Async::Engine::PostgreSQL::DDL;

use strict;
use warnings;

our $VERSION = '0.011'; # VERSION

=head1 NAME

Database::Async::Engine::PostgreSQL::DDL - support for DDL required for
L<Database::Async::ORM>

=head1 DESCRIPTION

This class is not intended to be used directly. L<Database::Async> will
locate it based on the provided engine.

This class deals with the mechanics of applying schemata to a database,
or reading data back from an existing database.

=cut

use Template;

use Log::Any qw($log);

sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

=head1 METHODS

=cut

sub table_info {
    my ($self, $tbl) = @_;
    return (<<'EOS', 'schema', 'table');
select  a.attname as "name",
        t.typname as "type",
        not(a.attnotnull) as "nullable",
        (
            select substring(
                pg_catalog.pg_get_expr(d.adbin, d.adrelid),
                E'\'(.*)\''
            )
            from pg_catalog.pg_attrdef d
            where d.adrelid = a.attrelid
            and d.adnum = a.attnum
            and a.atthasdef
        ) as "default"
from pg_class c
inner join pg_namespace n on n.oid = c.relnamespace
inner join pg_attribute a on a.attrelid = c.oid
inner join pg_type t on a.atttypid = t.oid
where n.nspname = $1
and c.relname = $2
and a.attnum > 0
order by a.attnum
EOS
}

sub schema_info {
    my ($self, $tbl) = @_;
    return (<<'EOS', 'schema');
select  n.nspname as "name"
from pg_namespace n
where n.nspname = $1
EOS
}

sub type_info {
    my ($self, $tbl) = @_;
    return (<<'EOS', 'schema', 'type');
select *
from pg_catalog.pg_type t
inner join pg_namespace n on n.oid = t.typnamespace
where n.nspname = $1
and t.typname = $2
EOS
}

=head2 create_type

Creates a type, assuming that it does not currently exist.

Returns a list of SQL commands to run.

=cut

sub create_type {
    my ($self, $type) = @_;
    my $tt = $self->tt;
    my $data = {
        type => {
            defined_in  => $type->defined_in,
            name        => $type->name,
            schema      => $type->schema->name,
            type        => $type->type,
            basis       => $type->basis,
            description => $type->description,
            ($type->type eq 'enum' ? (data => [ $type->values ]) : ()),
            ($type->type eq 'composite'
                ? (
            fields => [
                (map {;
                        +{
                            name => $_->name,
                            type => {
                                schema => $_->type->schema,
                                name => $_->type->name,
                                is_builtin => $_->type->is_builtin,
                            },
                            nullable => $_->nullable,
                        }
                    } $type->fields)
            ]) : ())
        }
    };

    my @pending = do {
        $tt->process(
            \<<'TEMPLATE',
[% IF type.defined_in -%]
-- Defined in [% type.defined_in %]
[% END -%]
[% SWITCH type.type -%]
[%  CASE 'enum' -%]
create type "[% type.schema %]"."[% type.name %]" as enum (
[% FOREACH item IN type.data -%]
  '[% item %]'[% UNLESS loop.last %],[% END %]
[% END -%]
)
[%  CASE 'domain' -%]
create domain "[% type.schema %]"."[% type.name %]" as [% type.basis %]
[%  CASE 'composite' -%]
create type "[% type.schema %]"."[% type.name %]" as (
[% FOREACH field IN type.fields -%]
    "[% field.name %]" [% IF field.type.schema %]"[% field.type.schema.name %]".[% END %][% IF field.type.is_builtin; field.type.name; ELSE %]"[% field.type.name %]"[% END %][% IF !field.nullable %] not null[% END %][% UNLESS loop.last %],[% END %]
[% END -%]
)
[% END -%]
TEMPLATE
            $data,
            \my $out
        ) or die $tt->error;
        $log->tracef('Type %s definition would be: %s', $type->name, $out);
        $out
    };
    push @pending, do {
        $tt->process(
            \<<'TEMPLATE',
[% SWITCH type.type -%]
[%  CASE 'enum' -%]
comment on type "[% type.schema %]"."[% type.name %]" is '[% type.description | pg_text %]'
[%  CASE 'domain' -%]
comment on domain "[% type.schema %]"."[% type.name %]" is '[% type.description | pg_text %]'
[% END -%]
TEMPLATE
            $data,
            \my $out
        ) or die $tt->error;
        $log->tracef('Type %s description would be: %s', $type->name, $out);
        $out
    } if defined $type->description;
    @pending
}

=head2 create_table

Creates a table, assuming that it does not already exist.

Returns a list of SQL commands to run.

=cut

sub create_table {
    my ($self, $tbl) = @_;
    my $tt = $self->tt;
    $log->tracef('Creating table %s', $tbl->name);
    my $data = {
        table => {
            defined_in => $tbl->defined_in,
            schema => $tbl->schema->name,
            (map {; $_ => $tbl->$_ } grep { defined $tbl->$_ } qw(name tablespace)),
            primary_keys => [ map { $_->name } $tbl->primary_keys ],
            constraints => [
                map +{
                    type       => $_->type,
                    references => {
                        name   => $_->references->name,
                        schema => $_->references->schema->name,
                    },
                    fields     => [ map { $_->name } $_->fields ],
                }, $tbl->foreign_keys
            ],
            parents => [
                map {;
                    +{
                        name => $_->name,
                        schema => $_->schema->name
                    }
                } $tbl->parents
            ],
            fields => [
                (map {;
                    +{
                        name => $_->name,
                        type => {
                            schema => ($_->type->is_builtin
                                ? undef
                                : $_->type->schema
                                ? $_->type->schema->name
                                : $tbl->schema->name
                            ),
                            name => $_->type->name,
                            is_builtin => $_->type->is_builtin,
                        },
                        nullable => $_->nullable,
                    }
                } $tbl->fields)
            ]
        }
    };
    my @pending = do {
        $tt->process(
            \<<'TEMPLATE',
[% IF table.defined_in -%]
-- Defined in [% table.defined_in %]
[% END -%]
create [% IF table.temporary %]temporary [% END %][% IF table.unlogged %]unlogged [% END %]table if not exists "[% table.schema %]"."[% table.name %]" (
[% FOREACH field IN table.fields -%]
    "[% field.name %]" [% IF field.type.schema.defined %]"[% field.type.schema %]".[% END %][% IF field.type.is_builtin; field.type.name; ELSE %]"[% field.type.name %]"[% END %][% IF !field.nullable %] not null[% END %][% IF table.primary_keys.size > 0 || !loop.last %],[% END %]
[% END -%]
[% IF table.primary_keys.size -%]
    primary key ([% FOR pk IN table.primary_keys %]"[% pk %]"[% UNLESS loop.last %], [% END %][% END %])
[% END -%]
)[% IF table.parents.size %] inherits (
[% FOREACH parent IN table.parents -%]
    "[% parent.schema %]"."[% parent.name %]"[% UNLESS loop.last %],[% END %]
[% END -%]
)[% END %][% IF table.tablespace %] tablespace "[% table.tablespace %]"[% END %]
TEMPLATE
            $data,
            \my $out
        ) or die $tt->error;
        $log->tracef('Table %s definition would be: %s', $tbl->name, $out);
        $out
    };
    push @pending, do {
        $tt->process(
            \<<'TEMPLATE',
comment on table "[% table.schema %]"."[% table.name %]" is '[% table.description | pg_text %]'
TEMPLATE
            $data,
            \my $out
        ) or die $tt->error;
        $log->tracef('Table %s description would be: %s', $tbl->name, $out);
        $out
    } if defined $tbl->description;

    for my $constraint ($data->{table}{constraints}->@*) {
        unless($constraint->{type} eq 'foreign_key') {
            $log->warnf('unsupported constraint %s on table %s', $constraint->{type}, $data->{table}{name});
            next;
        }
        push @pending, do {
            $tt->process(
                \<<'TEMPLATE',
alter table "[% table.schema %]"."[% table.name %]" add foreign key ([% constraint.fields.join(',') %]) references "[% constraint.references.schema %]"."[% constraint.references.name %]"
TEMPLATE
                { %$data, constraint => $constraint },
                \my $out
            ) or die $tt->error;
            $log->tracef('Table %s FK on (%s) to %s', $tbl->name, join(',', $constraint->{fields}->@*), $constraint->{references});
            $out
        };
    }
    @pending;
}

=head2 create_schema

Creates a schema, assuming that it does not currently exist.

Returns a list of SQL commands to run.

=cut

sub create_schema {
    my ($self, $schema) = @_;
    my $tt = $self->tt;
    my $data = {
        schema => {
            name => $schema->name,
            defined_in => $schema->defined_in,
        }
    };
    my @pending = do {
        $tt->process(
            \<<'TEMPLATE',
[% IF schema.defined_in -%]
-- Defined in [% schema.defined_in %]
[% END -%]
create schema if not exists "[% schema.name %]"
TEMPLATE
            $data,
            \my $out
        ) or die $tt->error;
        $log->tracef('Schema %s definition would be: %s', $schema->name, $out);
        $out
    };
    push @pending, do {
        $tt->process(
            \<<'TEMPLATE',
comment on schema "[% schema.name %]" is '[% schema.description | pg_text %]'
TEMPLATE
            $data,
            \my $out
        ) or die $tt->error;
        $log->tracef('Schema %s description would be: %s', $schema->name, $out);
        $out
    } if defined $schema->description;
    @pending;
}

=head1 METHODS - Internal

=cut

=head2 tt

Returns a L<Template> instance.

=cut

sub tt {
    shift->{tt} //= Template->new(
        UNICODE => 1,
        FILTERS => {
            pg_text => sub {
                my ($txt) = @_;
                for($txt) {
                    s{^\s+}{};
                    s{\s+$}{};
                    s{'}{''}g;
                }
                return $txt
            }
        }
    );
}

1;

__END__

=head1 AUTHOR

Tom Molesworth C<< <TEAM@cpan.org> >>

=head1 LICENSE

Copyright Tom Molesworth 2019-2021. Licensed under the same terms as Perl itself.

