package Daje::Workflow::GenerateSchema::Create::Schema;
use Mojo::Base  -base, -signatures;

# NAME
#
# Daje::Workflow::GenerateSchema::Create::Schema
#
#
# DESCRIPTION
# ===========
# Daje::Workflow::GenerateSchema::Create::Schema creates a json representation of a postgres database
#
#
#
#
#  REQUIRES
#
# Syntax::Operator::Matches
#
# Scalar::Util
#
# Mojo::Base
#
#
# METHODS
#
#    build_view_methods($self,)
#
#    get_db_schema($self)
#
#

#
# LICENSE
# =======
#
# Copyright (C) janeskil1525.
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# AUTHOR
# ======
# janeskil1525 E<lt>janeskil1525@gmail.comE<gt>



use Scalar::Util qw {reftype};
use Syntax::Operator::Matches qw( matches mismatches );

has 'db';
has 'excludes';

sub get_db_schema($self, $schema) {
    $schema = 'public' unless $schema;
    my @tab;
    my @vie;
    my @tables = ();
    @tables = $self->_get_tables($schema);
    my $length = scalar @tables;
    for (my $i = 0; $i < $length; $i++) {
        my $table->{table}->{table_name} = $tables[$i]->{table_name};
        my $column_names = $self->_get_table_column_names($tables[$i]->{table_name}, $schema);
        $table->{table}->{column_names} = $column_names;
        my $indexes = $self->_get_table_indexes($tables[$i]->{table_name}, $schema);
        if (defined $indexes) {
            $table->{table}->{indexes} = $indexes;
        }
        push (@tab, $table);
        my $temp = 1;
    }
    my $result->{tables} = \@tab;
    my @views = $self->_get_views($schema);
    $length = scalar @views;
    for (my $i = 0; $i < $length; $i++ ) {
        my $view->{view} = $views[$i];
        my $column_names = $self->get_table_column_names($view->{view}->{table_name}, $schema);
        $view->{view}->{column_names} = $column_names;
        $view->{view}->{keys} = $self->_get_keys($column_names);
        push (@vie, $view);
    }

    $result->{views} = \@vie;
    return $result;
}

sub build_view_methods($self, $view, $column_names) {

    my $methods->{table_name} = $view->{table_name};
    $methods->{keys} = $self->_get_keys($column_names);
    $methods->{create_endpoint} = 1;
    my $method = $self->get_view_list($view->{table_name},$column_names);
    push @{$methods->{methods}}, $method ;

    return $methods;
}

sub _get_keys($self, $column_names) {

    my $keys->{has_companies} = 0;
    $keys->{has_users} = 0;
    $keys->{fk} = ();
    my $length = scalar @{$column_names};
    for (my $i = 0; $i < $length; $i++ ) {
        if (length(@{$column_names}[$i]->{column_name}) > 0) {
            if (index(@{$column_names}[$i]->{column_name},'_pkey') > -1){
                $keys->{pk} = @{$column_names}[$i]->{column_name};
            } elsif (@{$column_names}[$i]->{column_name} eq 'companies_fkey') {
                $keys->{has_companies} = 1;
            } elsif (@{$column_names}[$i]->{column_name} eq 'users_fkey') {
                $keys->{has_users} = 1;
            } elsif (index(@{$column_names}[$i]->{column_name},'_fkey') > -1) {
                push @{$keys->{fk}}, @{$column_names}[$i]->{column_name};
            }
        }
    }
    return $keys;
}

sub _get_tables($self, $schema) {

    my $excludes = $self->excludes();
    my @tables = $self->db->query(qq {
        SELECT table_name
          FROM information_schema.tables
         WHERE table_schema = ? AND table_name NOT IN(?)
           AND table_type='BASE TABLE';
    },($schema, $excludes))->hashes;
    @tables = @{ $tables[0] };

    return @tables;
}


sub _get_views($self, $schema) {

    my @views = $self->db->query(qq {
        SELECT table_name
            FROM
              information_schema.views
            WHERE
              table_schema NOT IN (
                'information_schema', 'pg_catalog'
              ) AND table_schema = ?
            ORDER BY table_name;
    },($schema))->hashes;
    @views =  @{$views[0]};

    return @views;
}

sub _get_table_column_names($self, $table, $schema) {

    $schema = 'public' unless $schema;
    my @column_names = $self->db->query(
        qq{
            SELECT column_name
                FROM information_schema.columns
            WHERE table_schema = ?
                AND table_name = ?
        }, ($schema, $table)
    )->hashes;

    @column_names = @{ $column_names[0] } if @{ $column_names[0] };
    return \@column_names;
}

sub _get_table_indexes($self, $table, $schema) {
    $schema = 'public' unless $schema;
        my @column_names = $self->db->query(
            qq{
                select
                    t.relname as table_name,
                    i.relname as index_name,
                    a.attname as column_name,
                    insp.nspname as index_schema
                from
                    pg_class t,
                    pg_class i,
                    pg_index ix,
                    pg_attribute a,
                    pg_namespace insp
                where
                    t.oid = ix.indrelid
                    and i.oid = ix.indexrelid
                    and a.attrelid = t.oid
                    and a.attnum = ANY(ix.indkey)
                    and t.relkind = 'r'
                    and ix.indisunique
                    and ix.indisprimary = false
                    and t.relname not like 'pg_%'
                    and insp.oid = i.relnamespace
                    and insp.nspname = ?
                    AND t.relname  = ?
                order by
                    t.relname,
                    i.relname;
            }, ($schema, $table)
        )->hashes;

    @column_names = @{ $column_names[0] } if @{ $column_names[0] };
    return \@column_names;
}

1;



#################### pod generated by Pod::Autopod - keep this line to make pod updates possible ####################

=head1 NAME

Daje::Workflow::GenerateSchema::Create::Schema


=head1 DESCRIPTION

NAME

Daje::Workflow::GenerateSchema::Create::Schema


Daje::Workflow::GenerateSchema::Create::Schema creates a json representation of a postgres database




 REQUIRES

Syntax::Operator::Matches

Scalar::Util

Mojo::Base


METHODS

   build_view_methods($self,)

   get_db_schema($self)




=head1 REQUIRES

L<Syntax::Operator::Matches> 

L<Scalar::Util> 

L<Mojo::Base> 


=head1 METHODS

=head2 build_view_methods($self,

 build_view_methods($self,();

=head2 get_db_schema($self,

 get_db_schema($self,();


=cut

