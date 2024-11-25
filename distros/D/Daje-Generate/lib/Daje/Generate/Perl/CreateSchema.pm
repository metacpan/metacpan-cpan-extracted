use v5.40;
use feature 'class';
no warnings 'experimental::class';

class Daje::Generate::Perl::CreateSchema {
use Scalar::Util qw {reftype};
use Syntax::Operator::Matches qw( matches mismatches );

    field $db :param;

    method get_db_schema( $schema) {
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

    method build_view_methods($view, $column_names) {

        my $methods->{table_name} = $view->{table_name};
        $methods->{keys} = $self->_get_keys($column_names);
        $methods->{create_endpoint} = 1;
        my $method = $self->get_view_list($view->{table_name},$column_names);
        push @{$methods->{methods}}, $method ;

        return $methods;
    }

    method _get_keys($column_names) {

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

    method _get_tables($schema) {

        my @tables = $db->query(qq {
            SELECT table_name
              FROM information_schema.tables
             WHERE table_schema = ?
               AND table_type='BASE TABLE';
        },($schema))->hashes;
        @tables = @{ $tables[0] };

        return @tables;
    }


    method _get_views($schema) {

        my @views = $db->query(qq {
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

    method _get_table_column_names($table, $schema) {

        $schema = 'public' unless $schema;
        my @column_names = $db->query(
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

method _get_table_indexes($table, $schema) {

    $schema = 'public' unless $schema;
        my @column_names = $db->query(
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
}
1;

#################### pod generated by Pod::Autopod - keep this line to make pod updates possible ####################

=head1 NAME

lib::Daje::Generate::Perl::CreateSchema - lib::Daje::Generate::Perl::CreateSchema


=head1 DESCRIPTION

pod generated by Pod::Autopod - keep this line to make pod updates possible ####################


=head1 REQUIRES

L<Syntax::Operator::Matches> 

L<Scalar::Util> 

L<feature> 

L<v5.40> 


=head1 METHODS


=cut

