package Database::Async::Engine::PostgreSQL::DDL;

use strict;
use warnings;

our $VERSION = '0.003'; # VERSION

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

=head1 METHODS

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
        $log->infof('Type %s definition would be: %s', $type->name, $out);
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
        $log->infof('Type %s description would be: %s', $type->name, $out);
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
    my $data = {
        table => {
            defined_in => $tbl->defined_in,
            schema => $tbl->schema->name,
            (map {; $_ => $tbl->$_ } grep { defined $tbl->$_ } qw(name tablespace)),
            parents => [
                $tbl->parents
            ],
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
    "[% field.name %]" [% IF field.type.schema %]"[% field.type.schema.name %]".[% END %][% IF field.type.is_builtin; field.type.name; ELSE %]"[% field.type.name %]"[% END %][% IF !field.nullable %] not null[% END %][% UNLESS loop.last %],[% END %]
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
        $log->infof('Table %s definition would be: %s', $tbl->name, $out);
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
        $log->infof('Table %s description would be: %s', $tbl->name, $out);
        $out
    } if defined $tbl->description;
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
        $log->infof('Schema %s definition would be: %s', $schema->name, $out);
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
        $log->infof('Schema %s description would be: %s', $schema->name, $out);
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

Copyright Tom Molesworth 2019. Licensed under the same terms as Perl itself.

