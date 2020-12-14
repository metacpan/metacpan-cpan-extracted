package BenchmarkAnything::Storage::Backend::SQL::Query::SQLite;
our $AUTHORITY = 'cpan:TAPPER';
# ABSTRACT: BenchmarkAnything::Storage::Backend::SQL - querying - SQLite backend
$BenchmarkAnything::Storage::Backend::SQL::Query::SQLite::VERSION = '0.029';
use strict;
use warnings;
use base 'BenchmarkAnything::Storage::Backend::SQL::Query::common';

use List::MoreUtils qw( any );

my %h_used_selects;
my %h_default_columns = (
    'NAME'      => 'b.bench',
    'UNIT'      => 'bu.bench_unit',
    'VALUE'     => 'bv.bench_value',
    'VALUE_ID'  => 'bv.bench_value_id',
    'CREATED'   => 'bv.created_at',
);

sub _NOW { "CURRENT_TIMESTAMP" }

sub _FOR_UPDATE { "" }

sub select_benchmark_values {

    my ( $or_self, $hr_search ) = @_;

    # clear selected columns
    $h_used_selects{$or_self} = {};

    # deep copy hash
    require JSON::XS;
    $hr_search = JSON::XS::decode_json(
        JSON::XS::encode_json( $hr_search )
    );

    my (
        $s_limit,
        $s_offset,
        $s_order_by,
        @a_select,
        @a_from,
        @a_from_vals,
        @a_where,
        @a_where_vals,
    ) = (
        q##,
        q##,
        q##,
    );

    # limit clause
    if ( $hr_search->{limit} ) {
        if ( $hr_search->{limit} =~ /^\d+$/ ) {
            $s_limit = "LIMIT $hr_search->{limit}";
        }
        else {
            require Carp;
            Carp::confess("invalid limit value '$hr_search->{limit}'");
            return;
        }
    }

    # offset clause
    if ( $hr_search->{offset} ) {
        if ( $hr_search->{offset} =~ /^\d+$/ ) {
            $s_offset = "OFFSET $hr_search->{offset}";
        }
        else {
            require Carp;
            Carp::confess("invalid offset value '$hr_search->{offset}'");
            return;
        }
    }

    # where clause
    my $i_counter = 0;
    if ( $hr_search->{where} ) {

        for my $ar_where ( @{$hr_search->{where}} ) {
            if ( any { $ar_where->[1] eq $_  } keys %h_default_columns ) {
                my $s_column = splice( @{$ar_where}, 1, 1 );
                push @a_where, $or_self->create_where_clause( $h_default_columns{$s_column}, $ar_where );
                push @a_where_vals , @{$ar_where}[1..$#{$ar_where}] unless $ar_where->[0] eq 'is_empty';
            }
            else {
                my $s_additional_type = splice( @{$ar_where}, 1, 1 );
                my $hr_additional_type = $or_self
                    ->select_addtype_by_name( $s_additional_type )
                    ->fetchrow_hashref()
                ;
                if ( !$hr_additional_type || !$hr_additional_type->{bench_additional_type_id} ) {
                    require Carp;
                    Carp::confess("benchmark additional value '$s_additional_type' not exists");
                    return;
                }
                push @a_from, "
                    JOIN (
                        $or_self->{config}{tables}{additional_relation_table} bar$i_counter
                        JOIN $or_self->{config}{tables}{additional_value_table} bav$i_counter
                            ON ( bav$i_counter.bench_additional_value_id = bar$i_counter.bench_additional_value_id )
                    )
                        ON (
                            bar$i_counter.bench_value_id = bv.bench_value_id
                            AND bav$i_counter.bench_additional_type_id = ?
                        )
                ";
                push @a_from_vals, $hr_additional_type->{bench_additional_type_id};
                push @a_where, $or_self->create_where_clause( "bav$i_counter.bench_additional_value", $ar_where );
                push @a_where_vals , @{$ar_where}[1..$#{$ar_where}] unless $ar_where->[0] eq 'is_empty';
                $i_counter++;
            }
        }
    }

    # select clause
    my $b_aggregate_all = 0;
    if ( $hr_search->{select} ) {
        for my $i_counter ( 0..$#{$hr_search->{select}} ) {
            if ( ref $hr_search->{select}[$i_counter] ne 'ARRAY' ) {
                $hr_search->{select}[$i_counter] = ['',$hr_search->{select}[$i_counter]];
            }
            elsif ( !$b_aggregate_all && $hr_search->{select}[$i_counter][0] ne q## ) {
                $b_aggregate_all = 1;
                for my $s_clause (qw/ order_by limit offset /) {
                    if ( $hr_search->{$s_clause} ) {
                        require Carp;
                        Carp::confess("cannot use '$s_clause' with aggregation");
                    }
                }
            }
        }
    }
    push @{$hr_search->{select} ||= []}, map {['',$_]} keys %h_default_columns;

    for my $ar_select ( @{$hr_search->{select}} ) {

        my ( $s_column, $s_select ) = $or_self->create_select_column(
            $ar_select, $i_counter, $b_aggregate_all,
        );

        if ( $s_select ) {

            push @a_select, $s_select;

            if ( $s_column ) {

                my $hr_additional_type = $or_self
                    ->select_addtype_by_name( $s_column )
                    ->fetchrow_hashref()
                ;
                if ( !$hr_additional_type || !$hr_additional_type->{bench_additional_type_id} ) {
                    require Carp;
                    Carp::confess("benchmark additional value '$s_column' not exists");
                    return;
                }

                push @a_from_vals, $hr_additional_type->{bench_additional_type_id};
                push @a_from, "
                    LEFT JOIN (
                        $or_self->{config}{tables}{additional_relation_table} bar$i_counter
                        JOIN $or_self->{config}{tables}{additional_value_table} bav$i_counter
                            ON ( bav$i_counter.bench_additional_value_id = bar$i_counter.bench_additional_value_id )
                    )
                        ON (
                            bar$i_counter.bench_value_id = bv.bench_value_id
                            AND bav$i_counter.bench_additional_type_id = ?
                        )
                ";
                $i_counter++;
            }
        }

    }

    # order_by clause
    if ( $hr_search->{order_by} ) {
        my @a_order_by_possible  = keys %h_default_columns;
        my @a_order_by_direction = qw/ ASC DESC /;
        if ( $hr_search->{select} ) {
            push @a_order_by_possible, map { $_->[1] } @{$hr_search->{select}};
        }
        my @a_order_by;
        for my $order_column ( @{$hr_search->{order_by}} ) {
            if ( ref $order_column ) {
                if ( any { $order_column->[0] eq $_  } @a_order_by_possible ) {
                    if ( any { $order_column->[1] eq $_ } @a_order_by_direction ) {
                        my $s_numeric_cast = q##;
                        if ( $order_column->[2] && $order_column->[2]{numeric} ) {
                            $s_numeric_cast = '0 + ';
                        }
                        if ( any { $order_column->[0] eq $_ } keys %h_default_columns ) {
                            push @a_order_by, "$s_numeric_cast$h_default_columns{$order_column->[0]} $order_column->[1]";
                        }
                        else {
                            push @a_order_by, "$s_numeric_cast$order_column->[0] $order_column->[1]";
                        }
                    }
                    else {
                        require Carp;
                        Carp::confess("unknown order by direction '$order_column->[1]'");
                        return;
                    }
                }
                else {
                    require Carp;
                    Carp::confess("unknown order by column '$order_column->[0]'");
                    return;
                }
            }
            else {
                if ( any { $order_column eq $_ } @a_order_by_possible ) {
                    if ( any { $order_column eq $_ } keys %h_default_columns ) {
                        push @a_order_by, "$h_default_columns{$order_column} ASC";
                    }
                    else {
                        push @a_order_by, "$order_column ASC";
                    }
                }
                else {
                    require Carp;
                    Carp::confess("unknown order by column '$order_column'");
                    return;
                }
            }
        }
        $s_order_by = 'ORDER BY ' . (join ', ', @a_order_by)
    }

    # replace placeholders inside of raw sql where clause
    my $s_raw_where = $hr_search->{where_sql};
    if ( $s_raw_where ) {
        $s_raw_where =~ s/
            \$\{(.+?)\}
        /
            $h_used_selects{$or_self}{$1}
                ? $h_used_selects{$or_self}{$1}
                : die "column '$1' not exists in SELECT clause"
        /gex;
    }

    return $or_self->execute_query(
        "
            SELECT
                " . ( join ",\n", map {"$_"} @a_select ) . "
            FROM
                $or_self->{config}{tables}{benchmark_table} b
                JOIN $or_self->{config}{tables}{benchmark_value_table} bv
                    ON ( bv.bench_id = b.bench_id )
                LEFT JOIN $or_self->{config}{tables}{unit_table} bu
                    ON ( bu.bench_unit_id = b.bench_unit_id )
                " . ( join "\n", @a_from ) . "
            WHERE
                b.active = 1
                AND bv.active = 1
                " .
                ( @a_where      ? join "\n", map { "AND $_" } @a_where  : q## ) .
                ( $s_raw_where  ? " $s_raw_where"                       : q## ) .
            "
            $s_order_by
            $s_limit
            $s_offset
        ",
        @a_from_vals,
        @a_where_vals,
    );

}

sub create_select_column {

    my ( $or_self, $ar_select, $i_counter, $b_aggregate_all ) = @_;

    my $s_aggr_func           = q##;
    my ( $s_aggr, $s_column ) = @{$ar_select};
    my $s_return_select       = q##;

    AGGR: {
            if ( $s_aggr eq q##   ) {
                # aggregate all columns if a single column is aggregated
                if ( $b_aggregate_all ) {
                    $s_aggr = $or_self->{config}{default_aggregation};
                    redo AGGR;
                }
                $s_return_select = '${COLUMN}';
            }
            elsif ( $s_aggr eq 'min' ) {
                $s_return_select = 'MIN( ${COLUMN} )';
            }
            elsif ( $s_aggr eq 'max' ) {
                $s_return_select = 'MAX( ${COLUMN} )';
            }
            elsif ( $s_aggr eq 'avg' ) {
                $s_return_select = 'AVG( ${COLUMN} )';
            }
            # Geometric Mean, unsupported in SQLite due to lack of EXP(),
            # see http://stackoverflow.com/questions/13190064/how-to-find-power-of-a-number-in-sqlite
            #
            # elsif ( $s_aggr eq 'gem' ) {
            #     $s_return_select = 'EXP( SUM( LOG( ${COLUMN} ) ) / COUNT( ${COLUMN} ) )';
            # }
            elsif ( $s_aggr eq 'sum' ) {
                $s_return_select = 'SUM( ${COLUMN} )';
            }
            elsif ( $s_aggr eq 'cnt' ) {
                $s_return_select = 'COUNT( ${COLUMN} )';
            }
            elsif ( $s_aggr eq 'cnd' ) {
                $s_return_select = 'COUNT( DISTINCT ${COLUMN} )';
            }
            else {
                require Carp;
                Carp::confess("unknown aggregate function '$s_aggr'");
                return;
            }
    } # AGGR

    my ( $s_return_column );
    my $s_replace_as = $s_aggr ? $s_aggr . "_$s_column" : $s_column;

    if ( $h_used_selects{$or_self}{$s_replace_as} ) {
        return;
    }
    if ( any { $s_column eq $_  } keys %h_default_columns ) {
        $h_used_selects{$or_self}{$s_replace_as} = $h_default_columns{$s_column};
    }
    else {
        $s_return_column                         = $s_column;
        $h_used_selects{$or_self}{$s_replace_as} = "bav$i_counter.bench_additional_value";
    }

    $s_return_select =~ s/\$\{COLUMN\}/$h_used_selects{$or_self}{$s_replace_as}/g;

    return ( $s_return_column, "$s_return_select AS '$s_replace_as'", );

}

sub insert_addtyperelation {

    my ( $or_self, @a_vals ) = @_;

    return $or_self->execute_query( "
        INSERT OR IGNORE INTO $or_self->{config}{tables}{additional_type_relation_table}
            ( bench_id, bench_additional_type_id, created_at )
        VALUES
            ( ?, ?, @{[$or_self->_NOW]} )
    ", @a_vals );

}

sub insert_unit {

    my ( $or_self, @a_vals ) = @_;

    return $or_self->execute_query( "
        INSERT INTO $or_self->{config}{tables}{unit_table}
            ( bench_unit, created_at )
        VALUES
            ( ?, @{[$or_self->_NOW]} )
    ", @a_vals );

}

sub insert_benchmark {

    my ( $or_self, @a_vals ) = @_;

    return $or_self->execute_query( "
        INSERT INTO $or_self->{config}{tables}{benchmark_table}
            ( bench, bench_unit_id, active, created_at )
        VALUES
            ( ?, ?, 1, @{[$or_self->_NOW]} )
    ", @a_vals );

}

sub insert_benchmark_value {

    my ( $or_self, @a_vals ) = @_;

    return $or_self->execute_query( "
        INSERT OR IGNORE INTO $or_self->{config}{tables}{benchmark_value_table}
            ( bench_id, bench_subsume_type_id, bench_value, active, created_at )
        VALUES
            ( ?, ?, ?, 1, @{[$or_self->_NOW]} )
    ", @a_vals );

}

sub insert_addtype {

    my ( $or_self, @a_vals ) = @_;

    return $or_self->execute_query( "
        INSERT INTO $or_self->{config}{tables}{additional_type_table}
            ( bench_additional_type, created_at )
        VALUES
            ( ?, @{[$or_self->_NOW]} )
    ", @a_vals );

}

sub insert_addvalue {

    my ( $or_self, @a_vals ) = @_;

    return $or_self->execute_query( "
        INSERT INTO $or_self->{config}{tables}{additional_value_table}
            ( bench_additional_type_id, bench_additional_value, created_at )
        VALUES
            ( ?, ?, @{[$or_self->_NOW]} )
    ", @a_vals );

}

sub insert_addvaluerelation {

    my ( $or_self, @a_vals ) = @_;

    return $or_self->execute_query( "
        INSERT OR IGNORE INTO $or_self->{config}{tables}{additional_relation_table}
            ( bench_value_id, bench_additional_value_id, active, created_at )
        VALUES
            ( ?, ?, 1, @{[$or_self->_NOW]} )
    ", @a_vals );

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BenchmarkAnything::Storage::Backend::SQL::Query::SQLite - BenchmarkAnything::Storage::Backend::SQL - querying - SQLite backend

=head1 AUTHOR

Roberto Schaefer <schaefr@amazon.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Amazon.com, Inc. or its affiliates.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
