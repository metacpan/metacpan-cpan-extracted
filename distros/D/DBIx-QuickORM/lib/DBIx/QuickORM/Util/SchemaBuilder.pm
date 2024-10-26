package DBIx::QuickORM::Util::SchemaBuilder;
use strict;
use warnings;

our $VERSION = '0.000001';

use List::Util qw/mesh/;

use DBIx::QuickORM::BuilderState qw/plugin_hook/;

use DBIx::QuickORM qw{
    column
    columns
    conflate
    default
    index
    omit
    primary_key
    relation
    relations
    table
    unique
    schema
    sql_spec
    is_temp
    is_view
    rogue_table
    plugin
};

my %AUTO_CONFLATE = (
    uuid => 'DBIx::QuickORM::Conflator::UUID',
    json => 'DBIx::QuickORM::Conflator::JSON',
    jsonb => 'DBIx::QuickORM::Conflator::JSON',

    map {$_ => 'DBIx::QuickORM::Conflator::DateTime'} qw/timestamp date time timestamptz datetime year/,
);

sub _conflate {
    my $class = shift;
    my ($type) = @_;

    $type = lc($type);
    $type =~ s/\(.*$//g;

    return $AUTO_CONFLATE{$type} if $AUTO_CONFLATE{$type};
    return 'DBIx::QuickORM::Conflator::DateTime' if $type =~ m/(time|date|stamp|year)/;
}

sub generate_schema {
    my $class = shift;
    my ($con) = @_;

    require DBIx::QuickORM::Table::Relation;

    my %tables;
    my @todo;
    my $schema = schema sub {
        for my $table ($con->tables(details => 1)) {
            my $name = $table->{name};

            $tables{$name} = table $name => sub {
                push @todo => $class->_build_table($con, $table);
            };
        }
    };

    for my $item (@todo) {
        my ($type, $tname, @params) = @$item;
        my $table = $tables{$tname} or die "Invalid table name '$tname'";

        if ($type eq 'relation') {
            my ($alias, $fk, %relation_args) = @params;
            $alias = plugin_hook('relation_name', default_name => $alias, table => $table, table_name => $tname, fk => $fk) // $alias;
            my $rel = DBIx::QuickORM::Table::Relation->new(%relation_args);
            $table->add_relation($alias => $rel);
        }
        else {
            die "Invalid followup type: $type"
        }
    }

    return $schema;
}

sub generate_table {
    my $class = shift;
    my ($con, $table) = @_;

    return rogue_table $table->{name} => sub {
        $class->_build_table($con, $table);
    };
}

sub _build_table {
    my $class = shift;
    my ($con, $table) = @_;

    my $name = $table->{name};

    is_view() if $table->{type} eq 'view';
    is_temp() if $table->{temp};

    for my $col ($con->columns($name)) {
        column $col->{name} => sub {
            my $dtype = lc($col->{data_type});
            my $stype = lc($col->{sql_type});

            my $conflate;
            $conflate //= plugin_hook auto_conflate => (data_type => $dtype, sql_type => $stype, column => $col, table => $table);
            $conflate //= $class->_conflate($dtype);
            $conflate //= $class->_conflate($stype);

            if ($conflate) {
                conflate($conflate);

                if ($conflate eq 'DBIx::QuickORM::Conflator::JSON') {
                    omit();
                }
            }
            elsif ($col->{is_datetime}) {
                conflate('DBIx::QuickORM::Conflator::DateTime');
            }
            elsif ($col->{name} =~ m/uuid$/ && ($stype eq 'binary(16)' || $stype eq 'char(32)')) {
                conflate('DBIx::QuickORM::Conflator::UUID');
            }

            primary_key() if $col->{is_pk};

            my $spec = sql_spec type => $col->{sql_type};
            plugin_hook sql_spec => (column => $col, table => $table, sql_spec => $spec);
        };
    }

    plugin_hook sql_spec => (table => $table, sql_spec => sql_spec());

    my $keys = $con->db_keys($name);

    if (my $pk = $keys->{pk}) {
        primary_key(@$pk);
    }

    for my $u (@{$keys->{unique} // []}) {
        unique(@$u);
    }

    my @out;
    for my $fk (@{$keys->{fk} // []}) {
        my $relname = plugin_hook('relation_name', table => $table, table_name => $name, default_name => $fk->{foreign_table}, fk => $fk) // $fk->{foreign_table};
        relation $relname => {mesh($fk->{columns}, $fk->{foreign_columns})};
        push @out => ['relation', $fk->{foreign_table}, $name, $fk, table => $name, method => 'select', on => {mesh($fk->{foreign_columns}, $fk->{columns})}];
    }

    for my $idx ($con->indexes($name)) {
        unique(@{$idx->{columns}}) if $idx->{unique};
        index $idx;
    }

    return @out;
}

1;
