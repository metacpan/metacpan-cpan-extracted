package BenchmarkAnything::Storage::Backend::SQL;
# git description: v0.023-12-g9b05097

our $AUTHORITY = 'cpan:TAPPER';
# ABSTRACT: Autonomous SQL backend to store benchmarks
$BenchmarkAnything::Storage::Backend::SQL::VERSION = '0.024';
use 5.008;
use utf8;
use strict;
use warnings;
use Try::Tiny;

my $hr_default_config = {
    select_cache        => 0,
    default_aggregation => 'min',
    tables              => {
        unit_table                       => 'bench_units',
        benchmark_table                  => 'benchs',
        benchmark_value_table            => 'bench_values',
        subsume_type_table               => 'bench_subsume_types',
        benchmark_backup_value_table     => 'bench_backup_values',
        additional_type_table            => 'bench_additional_types',
        additional_value_table           => 'bench_additional_values',
        additional_relation_table        => 'bench_additional_relations',
        additional_type_relation_table   => 'bench_additional_type_relations',
        backup_additional_relation_table => 'bench_backup_additional_relations',
    },
};

my $hr_column_ba_mapping = {
    bench_value_id => 'VALUE_ID',
    bench          => 'NAME',
    bench_value    => 'VALUE',
    bench_unit     => 'UNIT',
    created_at     => 'CREATED',
};

my $fn_add_subsumed_point = sub {

    my ( $or_self, $hr_atts ) = @_;

    $or_self->{query}->start_transaction();

    eval {

        # insert subsumed benchmark value
        $or_self->{query}->insert_benchmark_value(
            $hr_atts->{rows}[0]{bench_id},
            $hr_atts->{type_id},
            $hr_atts->{VALUE},
        );
        my $i_bench_value_id = $or_self->{query}->last_insert_id(
            $or_self->{config}{tables}{benchmark_value_table},
            'bench_value_id',
        );

        # insert subsumed benchmark additional values
        $or_self->{query}->copy_additional_values({
            new_bench_value_id => $i_bench_value_id,
            old_bench_value_id => $hr_atts->{rows}[0]{bench_value_id},
        });

        for my $hr_backup_row ( @{$hr_atts->{rows}} ) {

            if ( $hr_backup_row->{bench_subsume_type_rank} == 1 ) {
                if ( $hr_atts->{backup} ) {
                    # copy data rows to backup table
                    $or_self->{query}->copy_benchmark_backup_value({
                        new_bench_value_id => $i_bench_value_id,
                        old_bench_value_id => $hr_backup_row->{bench_value_id},
                    });
                    my $i_bench_backup_value_id = $or_self->{query}->last_insert_id(
                        $or_self->{config}{tables}{benchmark_backup_value_table},
                        'bench_backup_value_id',
                    );
                    $or_self->{query}->copy_benchmark_backup_additional_relations({
                        new_bench_value_id => $i_bench_backup_value_id,
                        old_bench_value_id => $hr_backup_row->{bench_value_id},
                    });
                }
            }
            else {
                # update bench_value_id in backup table
                $or_self->{query}->update_benchmark_backup_value({
                    new_bench_value_id => $i_bench_value_id,
                    old_bench_value_id => $hr_backup_row->{bench_value_id},
                });
            }

            # now lets remove the old rows
            $or_self->{query}->delete_benchmark_additional_relations(
                $hr_backup_row->{bench_value_id},
            );
            $or_self->{query}->delete_benchmark_value(
                $hr_backup_row->{bench_value_id},
            );

        }

    };

    $or_self->{query}->finish_transaction( $@ );

    return 1;

};

sub new {

    my ( $s_self, $hr_atts ) = @_;

    my $or_self = bless {}, $s_self;

    for my $s_key (qw/ dbh /) {
        if (! $hr_atts->{$s_key} ) {
            require Carp;
            Carp::confess("missing '$s_key' parameter");
            return;
        }
    }

    # get tapper benchmark configuration
    $or_self->{config} = { %{$hr_default_config} };

    if ( $hr_atts->{config} ) {
        require Hash::Merge;
        $or_self->{config} = {
            Hash::Merge
                ->new('LEFT_PRECEDENT')
                ->merge(
                    %{$hr_atts->{config}},
                    %{$or_self->{config}},
                )
        };
    }

    require CHI;
    if ( $or_self->{config}{select_cache} ) {
        $or_self->{cache} = CHI->new( driver => 'RawMemory', global => 1 );
    }

    my $s_module = "BenchmarkAnything::Storage::Backend::SQL::Query::$hr_atts->{dbh}{Driver}{Name}";

    my $fn_new_sub;
    eval {
        require Module::Load;
        Module::Load::load( $s_module );
        $fn_new_sub = $s_module->can('new');
    };

    if ( $@ || !$fn_new_sub ) {
        require Carp;
        Carp::confess("database engine '$hr_atts->{dbh}{Driver}{Name}' not supported");
        return;
    }
    else {
        $or_self->{query} = $s_module->new({
            dbh    => $hr_atts->{dbh},
            driver => $hr_atts->{dbh}{Driver}{Name},
            debug  => $hr_atts->{debug} || 0,
            verbose=> $hr_atts->{verbose} || 0,
            config => $or_self->{config},
        });
    }

    $or_self->{searchengine} = $hr_atts->{searchengine} if $hr_atts->{searchengine};
    $or_self->{debug}        = $hr_atts->{debug} || 0;
    $or_self->{verbose}      = $hr_atts->{verbose} || 0;
    $or_self->{dbh_config}   = $hr_atts->{dbh_config};

    return $or_self;

}


sub add_single_benchmark {

    my ( $or_self, $hr_benchmark, $hr_options ) = @_;

    my $hr_config = $or_self->{config};

    my $VALUE_ID; # same spelling as reserved key in BenchmarkAnything schema

    # benchmark
    my $i_benchmark_id;
    if ( $hr_benchmark->{NAME} ) {
        if (
            my $hr_bench_select = $or_self->{query}
                ->select_benchmark( $hr_benchmark->{NAME} )
                ->fetchrow_hashref()
        ) {
            $i_benchmark_id = $hr_bench_select->{bench_id};
        }
        else {
            my $i_unit_id;
            if ( $hr_benchmark->{UNIT} ) {
                if (
                    my $hr_unit_select = $or_self->{query}
                        ->select_unit( $hr_benchmark->{UNIT} )
                        ->fetchrow_hashref()
                ) {
                    $i_unit_id = $hr_unit_select->{bench_unit_id};
                }
                else {
                    $or_self->{query}->insert_unit(
                        $hr_benchmark->{UNIT},
                    );
                    $i_unit_id = $or_self->{query}->last_insert_id(
                        $hr_config->{tables}{unit_table},
                        'bench_unit_id',
                    );
                }
            }
            $or_self->{query}->insert_benchmark(
                $hr_benchmark->{NAME}, $i_unit_id,
            );
            $i_benchmark_id = $or_self->{query}->last_insert_id(
                $hr_config->{tables}{benchmark_table},
                'bench_id',
            );
        }
    }
    else {
        require Carp;
        Carp::confess('missing element "NAME"');
        return 0;
    }

    if (
        $hr_benchmark->{data}
        && ref( $hr_benchmark->{data} ) eq 'ARRAY'
        && @{$hr_benchmark->{data}}
    ) {

        my $i_benchmark_subsume_type_id = $or_self->{query}
            ->select_min_subsume_type()
            ->fetchrow_hashref()
            ->{bench_subsume_type_id}
        ;

        my $i_counter = 1;
        for my $hr_point ( @{$hr_benchmark->{data}} ) {

            if ( not exists $hr_point->{VALUE} ) {
                require Carp;
                if ( $hr_options->{force} ) {
                    Carp::cluck("missing parameter 'VALUE' in element $i_counter");
                }
                else {
                    Carp::confess("missing parameter 'VALUE' in element $i_counter");
                }
            }

            # benchmark value
            $or_self->{query}->insert_benchmark_value(
                $i_benchmark_id, $i_benchmark_subsume_type_id, $hr_point->{VALUE},
            );
            my $i_benchmark_value_id = $or_self->{query}->last_insert_id(
                $hr_config->{tables}{benchmark_value_table},
                'bench_value_id',
            );
            $VALUE_ID = $i_benchmark_value_id;

            ADDITIONAL: for my $s_key ( keys %{$hr_point} ) {

                next ADDITIONAL if $s_key eq 'VALUE';
                next ADDITIONAL if not defined $hr_point->{$s_key};

                # additional type
                my $i_addtype_id;
                if ( $or_self->{cache} ) {
                    $i_addtype_id = $or_self->{cache}->get("addtype||$s_key");
                }
                if ( !$i_addtype_id ) {
                    if (
                        my $hr_addtype_select = $or_self->{query}
                            ->select_addtype( $s_key )
                            ->fetchrow_hashref()
                    ) {
                        $i_addtype_id = $hr_addtype_select->{bench_additional_type_id};
                    }
                    else {
                        $or_self->{query}->insert_addtype(
                            $s_key,
                        );
                        $i_addtype_id = $or_self->{query}->last_insert_id(
                            $hr_config->{tables}{addition_type_table},
                            'bench_additional_type_id',
                        );
                    }
                    if ( $or_self->{cache} ) {
                        $or_self->{cache}->set( "addtype||$s_key" => $i_addtype_id );
                    }
                }

                # benchmark - additional type - relation
                my $b_inserted   = 0;
                my $s_addtyperel = "$i_benchmark_id|$i_addtype_id";
                if ( $or_self->{cache} ) {
                    if ( $or_self->{cache}->get("addtyperel||$s_addtyperel") ) {
                        $b_inserted = 1;
                    }
                }
                if (! $b_inserted ) {
                    if(!
                        $or_self->{query}
                            ->select_addtyperelation( $i_benchmark_id, $i_addtype_id )
                            ->fetchrow_hashref()
                    ) {
                        $or_self->{query}
                            ->insert_addtyperelation( $i_benchmark_id, $i_addtype_id )
                        ;
                    }
                    if ( $or_self->{cache} ) {
                        $or_self->{cache}->set("addtyperel||$s_addtyperel" => 1 );
                    }
                }

                # additional value
                my $i_addvalue_id;
                my $s_addvalue_key = "$i_addtype_id|$hr_point->{$s_key}";
                if ( $or_self->{cache} ) {
                    $i_addvalue_id = $or_self->{cache}->get("addvalue||$s_addvalue_key");
                }
                if (! $i_addvalue_id ) {
                    if (
                        my $hr_addvalue_select = $or_self->{query}
                            ->select_addvalue( $i_addtype_id, $hr_point->{$s_key} )
                            ->fetchrow_hashref()
                    ) {
                        $i_addvalue_id = $hr_addvalue_select->{bench_additional_value_id};
                    }
                    else {
                        $or_self->{query}->insert_addvalue(
                            $i_addtype_id, $hr_point->{$s_key},
                        );
                        $i_addvalue_id = $or_self->{query}->last_insert_id(
                            $hr_config->{tables}{addition_type_table},
                            'bench_additional_value_id',
                        );
                    }
                    if ( $or_self->{cache} ) {
                        $or_self->{cache}->set( "addvalue||$s_addvalue_key" => $i_addvalue_id );
                    }
                }

                # additional value relation
                $or_self->{query}->insert_addvaluerelation(
                    $i_benchmark_value_id, $i_addvalue_id,
                );

            } # ADDITIONAL

            $i_counter++;

        }
    }
    else {
        require Carp;
        Carp::cluck('no benchmark data found');
        return 0;
    }

    if ( $or_self->{searchengine}{elasticsearch}{index_single_added_values_immediately} )
    {
        require BenchmarkAnything::Storage::Search::Elasticsearch;
        my ($or_es, $s_index, $s_type) = BenchmarkAnything::Storage::Search::Elasticsearch::get_elasticsearch_client
         (
          {searchengine => $or_self->{searchengine}, ownjson => 1}
         );

        # Sic, we re-read from DB to get the very same data we
        # *really got* stored, not just what we wish it should
        # have stored. That gives us translations like
        # num->string, CREATED date, etc., etc.

        my $hr_bmk = $or_self->get_single_benchmark_point($VALUE_ID);
        my $ret = $or_es->index(index => $s_index,
                                type  => $s_type,
                                id    => $VALUE_ID,
                                body  => $hr_bmk);
    }

    return 1;

}

sub enqueue_multi_benchmark {

    my ( $or_self, $ar_data_points, $hr_options ) = @_;

    require Sereal::Encoder;

    my $s_serialized = Sereal::Encoder->new->encode($ar_data_points);
    $or_self->{query}->insert_raw_bench_bundle($s_serialized);

    return 1;

}

# dequeues a single bundle (can contain multiple data points)
sub process_queued_multi_benchmark {

    my ( $or_self, $hr_options ) = @_;

    my $i_id;
    my $s_serialized;
    my $ar_data_points;
    my $ar_results_lock;
    my $or_result_lock;
    my $ar_results_process;

    my $driver = $or_self->{query}{dbh}{Driver}{Name};

    $or_self->{query}{dbh}->do("set transaction isolation level read committed") if $driver eq "mysql"; # avoid deadlocks due to gap locking
    $or_self->{query}->start_transaction;

    # ===== exclusively pick single raw entry =====
    # Lock single row via processing=1 so that only one worker handles it!
    eval {
        try {
            $ar_results_lock = $or_self->{query}->select_raw_bench_bundle_for_lock;
            $or_result_lock  = $ar_results_lock->fetchrow_hashref;
        }
        catch {
            if (/Deadlock found when trying to get lock/) {
                # very normal, handled by eval{} and finish_transaction() in this sub.
                # warn("IGNORED - DEADLOCK\n");
                die $_;
            } elsif (/DBD::mysql::st fetchrow_hashref failed: fetch.. without execute/) {
                # very normal with multiple workers, usually related
                # to above deadlock. It is handled by eval{} and
                # finish_transaction() in this sub.
                warn("IGNORED - FETCH-WITHOUT-EXECUTE\n");
                die $_;
            } else {
                # An unexpected exception can happen anytime. It is
                # handled by eval{} and finish_transaction() in this
                # sub. Still, we print it to know what's happening.
                require Carp;
                Carp::cluck("SQL DATABASE EXCEPTION: {{{\n$_\n}}}\n");
                die $_;
            }
        };
        $i_id       = $or_result_lock->{raw_bench_bundle_id};
        if ($i_id) {
            $or_self->{query}->start_processing_raw_bench_bundle($i_id);

            # ===== process that single raw entry =====
            require Sereal::Decoder;

            $ar_results_process = $or_self->{query}->select_raw_bench_bundle_for_processing($i_id);
            $s_serialized       = $ar_results_process->fetchrow_hashref->{raw_bench_bundle_serialized};
            $ar_data_points     = Sereal::Decoder::decode_sereal($s_serialized);

            # preserve order, otherwise add_multi_benchmark() would reorder to optimize insert
            $or_self->add_multi_benchmark([$_], $hr_options) foreach @$ar_data_points;
            $or_self->{query}->update_raw_bench_bundle_set_processed($i_id);
        }
    };
    $or_self->{query}->finish_transaction($@, { silent => 1 });

    # $or_self->{query}->start_transaction;
    # eval { $or_self->{query}->unlock_raw_bench_bundle($i_id) };
    # $or_self->{query}->finish_transaction($@, { silent => 1 });

    $or_self->{query}{dbh}->do("set transaction isolation level repeatable read") if $driver eq "mysql"; # reset to normal gap locking
    return $@ ? undef : $i_id;

}

# garbage collect - initially raw_bench_bundles, but also other stuff.
sub gc {

    my ( $or_self, $hr_options ) = @_;

    $or_self->{query}->delete_processed_raw_bench_bundles;
    if ($or_self->{searchengine}{elasticsearch}{enable_query}) {
        require BenchmarkAnything::Storage::Search::Elasticsearch;
        my ($or_es, $s_index, $s_type) = BenchmarkAnything::Storage::Search::Elasticsearch::get_elasticsearch_client
         (
          {searchengine => $or_self->{searchengine}}
         );
        $or_es->indices->clear_cache(index => $s_index);
    }
}

sub add_multi_benchmark {

    my ( $or_self, $ar_data_points, $hr_options ) = @_;

    my $i_counter    = 1;
    my %h_benchmarks = ();
    for my $hr_data_point ( @{$ar_data_points} ) {

        for my $s_param (qw/ NAME VALUE /) {
            if ( not exists $hr_data_point->{$s_param} ) {
                require Carp;
                if ( $hr_options->{force} ) {
                    Carp::cluck("missing parameter '$s_param' in element $i_counter");
                }
                else {
                    Carp::confess("missing parameter '$s_param' in element $i_counter");
                }
            }
        }

        my ( $s_name, $s_unit ) = delete @{$hr_data_point}{qw/ NAME UNIT /};

        if (! $h_benchmarks{$s_name} ) {
            $h_benchmarks{$s_name} = {
                NAME    => $s_name,
                UNIT    => $s_unit,
                data    => [],
            };
        }
        else {
            $h_benchmarks{$s_name}{UNIT} ||= $s_unit;
        }

        push @{$h_benchmarks{$s_name}{data}}, $hr_data_point;

        $i_counter++;

    }
    for my $hr_benchmark ( values %h_benchmarks ) {
        $or_self->add_single_benchmark( $hr_benchmark, $hr_options );
    }

    return 1;

}

sub search {

    my ( $or_self, $hr_search ) = @_;

    return $or_self->{query}->select_benchmark_values(
        $hr_search
    );

}

sub list_benchmark_names {

    my ( $or_self, $s_pattern ) = @_;

    my $ar_pattern = defined($s_pattern) ? [$s_pattern] : [];

    my $s_key;
    if ( $or_self->{cache} ) {
        require JSON::XS;
        $s_key = JSON::XS::encode_json($ar_pattern);
        if ( my $ar_search_data = $or_self->{cache}->get("list_benchmark_names||$s_key") ) {
            return $ar_search_data;
        }
    }

    my $ar_result = $or_self->{query}
        ->select_benchmark_names( @$ar_pattern )
        ->fetchall_arrayref([0]);
    my $ar_benchmark_names = [ map { $_->[0] } @$ar_result ];

    if ( $or_self->{cache} ) {
        $or_self->{cache}->set( "list_benchmark_names||$s_key" => $ar_benchmark_names );
    }

    return $ar_benchmark_names;

}

sub list_additional_keys {

    my ( $or_self, $s_pattern ) = @_;

    my $ar_pattern = defined($s_pattern) ? [$s_pattern] : [];

    my $s_key;
    if ( $or_self->{cache} ) {
        require JSON::XS;
        $s_key = JSON::XS::encode_json($ar_pattern);
        if ( my $ar_search_data = $or_self->{cache}->get("list_additional_keys||$s_key") ) {
            return $ar_search_data;
        }
    }

    my $ar_result = $or_self->{query}
        ->select_additional_keys( @$ar_pattern )
        ->fetchall_arrayref([0]);
    my $ar_key_names = [ map { $_->[0] } @$ar_result ];

    if ( $or_self->{cache} ) {
        $or_self->{cache}->set( "list_additional_keys||$s_key" => $ar_key_names );
    }

    return $ar_key_names;

}

sub get_stats {

    my ( $or_self ) = @_;

    my %h_searchengine_stats  = ();
    my %h_flat_searchengine_stats = ();
    my %stats = ();

    # Not strictly *stats* but useful information.
    if ( $or_self->{searchengine}{elasticsearch}{index} )
    {
        require BenchmarkAnything::Storage::Search::Elasticsearch;
        my ($or_es, $s_index, $s_type) = BenchmarkAnything::Storage::Search::Elasticsearch::get_elasticsearch_client
         (
          {searchengine => $or_self->{searchengine}}
         );

        $stats{count_datapoints} = (map {chomp; $_} split(qr/ +/, $or_es->cat->count))[2];
        %h_searchengine_stats =
            (
             index          => $or_self->{searchengine}{elasticsearch}{index} || 'UNKNOWN',
             type           => $or_self->{searchengine}{elasticsearch}{type}  || 'UNKNOWN',
             enable_query   => $or_self->{searchengine}{elasticsearch}{enable_query} || 0,
             cluster_health => $or_es->cluster->health,
             index_single_added_values_immediately => $or_self->{searchengine}{elasticsearch}{index_single_added_values_immediately} || 0,
            );
        # boolean -> 0/1
        for (values %{$h_searchengine_stats{elasticsearch}{cluster_health}}) {
            $_ = $_ ? 1 : 0 if ref eq 'JSON::XS::Boolean';
        }
        $h_flat_searchengine_stats{"elasticsearch_$_"} = $h_searchengine_stats{$_}
          for qw(index type enable_query index_single_added_values_immediately);
        $h_flat_searchengine_stats{"elasticsearch_cluster_health_$_"} = $h_searchengine_stats{cluster_health}{$_}
          for qw(cluster_name active_shards_percent_as_number active_primary_shards number_of_nodes status);
    }

    $stats{count_datapoints}    ||= 0+$or_self->{query}->select_count_datapoints->fetch->[0];
    $stats{count_datapointkeys}   = 0+$or_self->{query}->select_count_datapointkeys->fetch->[0] if $or_self->{verbose};
    $stats{count_metrics}         = 0+$or_self->{query}->select_count_metrics->fetch->[0]       if $or_self->{verbose};
    $stats{count_keys}            = 0+$or_self->{query}->select_count_keys->fetch->[0]          if $or_self->{verbose};

    %stats = (%stats, %h_flat_searchengine_stats);

    return \%stats;
}

sub get_single_benchmark_point {

    my ( $or_self, $i_bench_value_id ) = @_;

    return {} unless $i_bench_value_id;

    # cache?
    my $s_key;
    if ( $or_self->{cache} ) {
        require JSON::XS;
        $s_key = JSON::XS::encode_json({bench_value_id => $i_bench_value_id});
        if ( my $hr_search_data = $or_self->{cache}->get("get_single_benchmark_point||$s_key") ) {
            return $hr_search_data;
        }
    }

    # fetch all additional key/value fields
    my $ar_query_result = $or_self->{query}
        ->select_complete_benchmark_point( $i_bench_value_id )
        ->fetchall_arrayref({});

    # fetch essentials, like NAME, VALUE, UNIT
    my $hr_essentials = $or_self->{query}
        ->select_benchmark_point_essentials( $i_bench_value_id )
        ->fetchrow_hashref();

    # create complete BenchmarkAnything-like key/value entry
    my $hr_result;
    $hr_result          = { map { ($_->{bench_additional_type} => $_->{bench_additional_value} ) } @$ar_query_result };
    $hr_result->{NAME}  = $hr_essentials->{bench};
    $hr_result->{VALUE} = $hr_essentials->{bench_value};
    $hr_result->{VALUE_ID} = $hr_essentials->{bench_value_id};
    $hr_result->{CREATED} = $hr_essentials->{created_at};
    $hr_result->{UNIT}  = $hr_essentials->{bench_unit} if $hr_essentials->{bench_unit};

    # cache!
    if ( $or_self->{cache} ) {
        $or_self->{cache}->set( "get_single_benchmark_point||$s_key" => $hr_result );
    }

    return $hr_result;
}

sub get_full_benchmark_points {

    my ( $or_self, $i_bench_value_id, $i_count ) = @_;

    return [] unless $i_bench_value_id;

    $i_count ||= 1;

    # cache?
    my $s_key;
    if ( $or_self->{cache} ) {
        require JSON::XS;
        $s_key = JSON::XS::encode_json({bench_value_id => $i_bench_value_id});
        if ( my $hr_search_data = $or_self->{cache}->get("get_full_benchmark_points||$s_key") ) {
            return $hr_search_data;
        }
    }

    # fetch essentials, like NAME, VALUE, UNIT
    my $ar_essentials = $or_self->{query}
        ->select_multiple_benchmark_points_essentials($i_bench_value_id, $i_count)
        ->fetchall_arrayref({});
    # additional key/value pairs
    my $ar_additional_values = $or_self->{query}
        ->select_multiple_benchmark_points_additionals($i_bench_value_id, $i_count)
        ->fetchall_arrayref({});

    # map columns into BenchmarkAnything schema
    my $hr_bmk;
    foreach my $k (keys %$hr_column_ba_mapping)
    {
        my $K = $hr_column_ba_mapping->{$k};
        foreach my $e (@$ar_essentials) {
            $hr_bmk->{$e->{bench_value_id}}{$K} = $e->{$k} if $k ne 'bench_unit' or defined $e->{$k};
        }
    }
    foreach (@$ar_additional_values) {
        $hr_bmk->{$_->{bench_value_id}}{$_->{bench_additional_type}} = $_->{bench_additional_value};
    }
    # sorted (by VALUE_ID) array of BenchmarkAnything entries
    my @a_bmk = map { $hr_bmk->{$_} } sort keys %$hr_bmk;

    # cache!
    if ( $or_self->{cache} ) {
        $or_self->{cache}->set( "get_full_benchmark_points||$s_key" => \@a_bmk );
    }

    return \@a_bmk;
}

sub search_array {

    my ( $or_self, $hr_search ) = @_;

    my $debug = $or_self->{debug} || $or_self->{searchengine}{elasticsearch}{debug};

    my $s_key;
    if ( $or_self->{cache} ) {
        require JSON::XS;
        $s_key = JSON::XS::encode_json($hr_search);
        if ( my $ar_search_data = $or_self->{cache}->get("search_array||$s_key") ) {
            return $ar_search_data;
        }
    }

    if ( $debug )
    {
        require JSON::XS;
        require Data::Dumper;
        print STDERR ',-------------------'."\n";
        print STDERR "benchmarkanything query:\n";
        print STDERR "benchmarkanything-storage search -d '\n";
        print STDERR JSON::XS->new->pretty->encode($hr_search);
        print STDERR "'\n";
        print STDERR '`-------------------'."\n";
    }

    if ( $or_self->{searchengine}{elasticsearch}{enable_query} )
    {
        # If anything goes wrong with Elasticsearch we just continue
        # below with relational backend query.

        require BenchmarkAnything::Storage::Search::Elasticsearch;
        my $hr_es_query = BenchmarkAnything::Storage::Search::Elasticsearch::get_elasticsearch_query($hr_search);

        if ($debug)
        {
            require JSON::XS;
            require Data::Dumper;
            print STDERR ',-------------------'."\n";
            print STDERR "elasticsearch query:\n";
            print STDERR "curl -s -XGET 'http://localhost:9200/tapper/benchmarkanything/_search?pretty' -d '\n";
            print STDERR JSON::XS->new->pretty->encode($hr_es_query);
            print STDERR "'\n";
            print STDERR '`-------------------'."\n";
        }

        # If we could transform the query then we run it against Elasticsearch and return its result.
        if (defined $hr_es_query)
        {
            # ===== client =====

            require BenchmarkAnything::Storage::Search::Elasticsearch;
            my ($or_es, $s_index, $s_type) = BenchmarkAnything::Storage::Search::Elasticsearch::get_elasticsearch_client
             (
              {searchengine => $or_self->{searchengine}, ownjson => 1}
             );

            # ===== prepare =====

            # If sort fields are of type 'text' then those fields needs to
            # get their properties being declared as "fielddata":true.
            my $field_mapping = {};
            my @sort_fields = map {keys %$_} @{$hr_es_query->{sort}||[]};
            if (@sort_fields) {
                $field_mapping = $or_es->indices->get_mapping->{$s_index}{mappings}{$s_type}{properties};
            }
            foreach my $sort_field (@sort_fields)
            {
                if ($field_mapping->{$sort_field}{type} and $field_mapping->{$sort_field}{type} eq 'text')
                {
                    require BenchmarkAnything::Storage::Backend::SQL::Search;
                    $or_es->indices->put_mapping
                     (
                      index => $s_index,
                      type => $s_type,
                      body => { $s_type => { properties => { $sort_field => { type => 'text',
                                                                              fielddata => BenchmarkAnything::Storage::Backend::SQL::Search::json_true(),
                                                                            }}}}
                     );
                }
            }

            # ===== search =====
            my $hr_es_answer = $or_es->search(index => $s_index, type => $s_type, body => $hr_es_query);

            if (
                !$hr_es_answer->{timed_out} and
                !$hr_es_answer->{_shards}{failed}
               )
            {
                my @ar_es_result = map { $_->{_source} } @{$hr_es_answer->{hits}{hits} || []};
                return \@ar_es_result;
            }
        } else {
            print STDERR "Did not get Elasticsearch query, fall back to SQL.\n" if $debug;
        }

        # Else no-op, continue with relational backend query.
    }

    my $ar_result = $or_self
        ->search( $hr_search )
        ->fetchall_arrayref({})
    ;

    if ( $or_self->{cache} ) {
        $or_self->{cache}->set( "search_array||$s_key" => $ar_result );
    }

    return $ar_result;

}

sub search_hash {

    my ( $or_self, $hr_search ) = @_;

    my $s_key;
    if ( $or_self->{cache} ) {
        require JSON::XS;
        $s_key = JSON::XS::encode_json($hr_search);
        if ( my $hr_search_data = $or_self->{cache}->get( "search_hash||$s_key" ) ) {
            return $hr_search_data;
        }
    }

    if (! $hr_search->{keys} ) {
        require Carp;
        Carp::confess(q#cannot get hash search result without 'keys'#);
        return;
    }

    my $hr_result = $or_self
        ->search( $hr_search )
        ->fetchall_hashref($hr_search->{keys})
    ;

    if ( $or_self->{cache} ) {
        $or_self->{cache}->set( "search_hash||$s_key" => $hr_result )
    }

    return $hr_result;

}

sub subsume {

    my ( $or_self, $hr_options ) = @_;

    for my $s_parameter (qw/ subsume_type /) {
        if (! $hr_options->{$s_parameter}) {
            require Carp;
            Carp::confess("missing parameter '$s_parameter'");
            return;
        }
    }

    # check if subsume type exists
    my $hr_subsume_type = $or_self->{query}
        ->select_subsume_type( $hr_options->{subsume_type} )
        ->fetchrow_hashref()
    ;
    if (! $hr_subsume_type ) {
        require Carp;
        Carp::confess("subsume type '$hr_options->{subsume_type}' not exists");
        return;
    }
    if ( $hr_subsume_type->{bench_subsume_type_rank} == 1 ) {
        require Carp;
        Carp::confess("cannot subsume with type '$hr_options->{subsume_type}'");
        return;
    }

    # looking for values with with a higher rank subsume type
    if (
        $or_self->{query}
            ->select_check_subsumed_values({
                date_to           => $hr_options->{date_to},
                date_from         => $hr_options->{date_from},
                subsume_type_id   => $hr_subsume_type->{bench_subsume_type_id},
            })
            ->rows()
    ) {
        require Carp;
        Carp::confess(
            "cannot use subsume type '$hr_options->{subsume_type}' " .
            'because a higher rank subsume type is already used for this date period'
        );
        return;
    }

    # look if excluded additional types really exists
    my @a_excluded_adds;
    if ( $hr_options->{exclude_additionals} ) {
        for my $s_additional_type ( @{$hr_options->{exclude_additionals}} ) {
            if (
                my $hr_addtype = $or_self->{query}
                    ->select_addtype( $s_additional_type )
                    ->fetchrow_hashref()
            ) {
                push @a_excluded_adds, $hr_addtype->{bench_additional_type_id}
            }
            else {
                require Carp;
                Carp::confess( "additional type '$s_additional_type' not exists" );
                return;
            }
        }
    }

    # get all data points for subsume
    my $or_data_values = $or_self->{query}->select_data_values_for_subsume({
        date_to             => $hr_options->{date_to},
        date_from           => $hr_options->{date_from},
        exclude_additionals => \@a_excluded_adds,
        subsume_type_id     => $hr_subsume_type->{bench_subsume_type_id},
    });

    require DateTime::Format::Strptime;
    my $or_strp = DateTime::Format::Strptime->new( pattern => '%F %T', );

    my @a_rows;
    my $i_counter   = 0;
    my $i_sum_value = 0;
    my $b_backup    = ((not exists $hr_options->{backup}) || $hr_options->{backup}) ? 1 : 0;
    my $s_last_key  = q##;

    while ( my $hr_values = $or_data_values->fetchrow_hashref() ) {

        my $s_act_key = join '__',
            $hr_values->{bench_id},
            $or_strp->parse_datetime( $hr_values->{created_at} )->strftime( $hr_subsume_type->{datetime_strftime_pattern} ),
            $hr_values->{additionals} || q##,
        ;

        if ( $s_last_key ne $s_act_key ) {

            if ( $i_counter ) {
                $or_self->$fn_add_subsumed_point({
                    rows    => \@a_rows,
                    VALUE   => $i_sum_value / $i_counter,
                    backup  => $b_backup,
                    type_id => $hr_subsume_type->{bench_subsume_type_id}
                });
            }

            @a_rows         = ();
            $i_counter      = 0;
            $i_sum_value    = 0;
            $s_last_key     = $s_act_key;

        }

        $i_counter   += 1;
        $i_sum_value += $hr_values->{bench_value};

        push @a_rows, $hr_values;

    }

    if ( $i_counter ) {
        $or_self->$fn_add_subsumed_point({
            rows    => \@a_rows,
            VALUE   => $i_sum_value / $i_counter,
            backup  => $b_backup,
            type_id => $hr_subsume_type->{bench_subsume_type_id}
        });
    }

    return 1;

}

sub _get_additional_key_id {

    my ( $or_self, $s_key ) = @_;

    return $or_self->{query}->select_additional_key_id($s_key)->fetch->[0];

}

sub default_columns {

    my ( $or_self ) = @_;

    return $or_self->{query}->default_columns;

}

sub benchmark_operators {

    my ( $or_self ) = @_;

    return $or_self->{query}->benchmark_operators;

}

sub init_search_engine
{
    my ( $or_self, $b_force) = @_;

    require BenchmarkAnything::Storage::Backend::SQL::Search;
    BenchmarkAnything::Storage::Backend::SQL::Search::init_search_engine (@_);
}

sub sync_search_engine
{
    require BenchmarkAnything::Storage::Backend::SQL::Search;
    BenchmarkAnything::Storage::Backend::SQL::Search::sync_search_engine (@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BenchmarkAnything::Storage::Backend::SQL - Autonomous SQL backend to store benchmarks

=head1 SYNOPSIS

    require YAML::Syck;
    require BenchmarkAnything::Storage::Backend::SQL;
    my $or_bench = BenchmarkAnything::Storage::Backend::SQL->new({
        dbh    => $or_dbh,
        debug  => 0,
        config => YAML::Syck::LoadFile('~/conf/tapper_benchmark.conf'),
    });

    my $b_success = $or_bench->add_single_benchmark({
        NAME => 'testbenchmark',
        UNIT => 'example unit',
        testplanid => 813,
        DATA => [
            {
                VALUE          => 123.45,
                testrun_id     => 123,
                machine        => 'mx1.small',
                benchmark_date => '2013-09-25 12:12:00',
            },{
                VALUE          => 122.88,
                testrun_id     => 123,
                machine        => 'mx1.large',
                benchmark_date => '2013-09-23 13:02:14',
            },
            ...
        ],
    },{
        force => 1,
    });

    my $b_success = $or_bench->add_multi_benchmark([
        {
            NAME           => 'testbenchmark',
            UNIT           => 'example unit',
            VALUE          => 123.45,
            testrun_id     => 123,
            machine        => 'mx1.small',
            benchmark_date => '2013-09-25 12:12:00',
        },{
            NAME           => 'testbenchmark',
            UNIT           => 'example unit',
            VALUE          => 122.88,
            testrun_id     => 123,
            machine        => 'mx1.large',
            benchmark_date => '2013-09-23 13:02:14',
        },
        ...
    ],{
        force => 1,
    });

    my $or_benchmark_points = $or_bench->search({
        select      => [
            'testrun_id',
            'machine',
        ],
        where       => [
            ['!=', 'machine', 'mx1.small'     ],
            ['=' , 'bench'  , 'testbenchmark' ],
        ],
        order_by    => [
            'machine',
            ['testrun_id','ASC',{ numeric => 1 }]
        ],
        limit       => 2,
        offset      => 1,
    });

    while my $hr_data_point ( $or_benchmark_points->fetchrow_hashref() ) {
        ...
    }

    my $b_success = $or_bench->subsume({
        subsume_type        => 'month',
        exclude_additionals => [qw/ benchmark_date /],
        date_from           => '2013-01-01 00:00:00',
        date_to             => '2014-01-01 00:00:00',
    });

=head1 DESCRIPTION

B<BenchmarkAnything::Storage::Backend::SQL> is a module for adding benchmark points in a standardised
way to the the database. A search function with complexe filters already exists.

=head2 Class Methods

=head3 new

Create a new B<BenchmarkAnything::Storage::Backend::SQL> object.

    my $or_bench = BenchmarkAnything::Storage::Backend::SQL->new({
        dbh    => $or_dbh,
        debug  => 0,
        verbose=> 0,
        config => YAML::Syck::LoadFile('~/conf/tapper_benchmark.conf'),
        searchengine => ... # optional, see below at "Elasticsearch support"
    });

=over 4

=item dbh

A B<DBI> database handle.

=item config [optional]

Containing the path to the BenchmarkAnything::Storage::Backend::SQL-Configuration-File. See
B<Configuration> for details.

=item debug [optional]

Setting C<debug> to a true value results in multiple debugging informations
written to STDOUT. The default is 0.

=item verbose [optional]

Setting C<verbose> to a true value provides more logs or status
information. The default is 0.

=back

=head3 add_single_benchmark

Add one or more data points to a single benchmark to the database.

    my $b_success = $or_bench->add_single_benchmark({
        NAME => 'testbenchmark',
        UNIT => 'example unit',
        data => [
            {
                VALUE          => 123.45,
            },{
                VALUE          => 122.88,
                testrun_id     => 123,
                machine        => 'mx1.large',
                benchmark_date => '2013-09-23 13:02:14',
            },{
                VALUE          => 122.88,
                testrun_id     => 123,
            },
            ...
        ],
    },{
        force => 1
    });

=over 4

=item 1st Parameter Hash => NAME

The name of the benchmark for grouping benchmark data points.

=item 1st Parameter Hash => data

This parameter contains the benchmark data points. It's an array of hashes. The
element C<VALUE> is the only required element in this hashes. The C<VALUE> is
the benchmark data point value.

=item 1st Parameter Hash => UNIT [optional]

Containing a unit for benchmark data point values.

=item 2nd Parameter Hash => force [optional]

Ignore forgivable errors while writing.

=back

=head3 add_multi_benchmark

Add one or more data points for multiple benchmarks to the database.

    my $b_success = $or_bench->add_multi_benchmark([
        {
            NAME           => 'testbenchmark 1',
            UNIT           => undef,
            VALUE          => 123.45,
        },{
            NAME           => 'testbenchmark 2',
            VALUE          => 122.88,
            testrun_id     => 123,
            machine        => 'mx1.large',
            benchmark_date => '2013-09-23 13:02:14',
        },{
            NAME           => 'testbenchmark 1',
            UNIT           => 'example unit',
            VALUE          => 122.88,
            testrun_id     => 123,
        },
        ...
    ],{
        force => 1
    });

=over 4

=item 1st Parameter Array of Hashes => NAME

The name of the benchmark for grouping benchmark data points.

=item 1st Parameter Hash => VALUE

The value is the benchmark data point value.

=item 1st Parameter Hash => UNIT [optional]

Containing a unit for benchmark data point values.

=item 1st Parameter Hash => all others

All other elements in the hashes are additional values added to this data point.

=item 2nd Parameter Hash => force [optional]

Ignore forgivable errors while writing.

=back

=head3 search

Search for benchmark data points in the database. Function returns a DBI
Statement Handle.

    my $or_benchmark_points = $or_bench->search({
        select      => [
            'testrun_id',
            'machine',
        ],
        where       => [
            ['!=', 'machine', 'mx1.small'     ],
            ['=' , 'NAME'   , 'testbenchmark' ],
        ],
        where_sql   => q#,
            AND NOT(
                   ${testrun_id} = 123
                OR ${VALUE}      = '144'
            )
        #,
        limit       => 2,
        offset      => 1,
        order_by    => [
            'machine',
            ['testrun_id','ASC']
        ],
    });

=over 4

=item select [optional]

An Array of Strings or Array References containing additional selected columns.
The default selected columns are:
    NAME      - name of benchmark
    UNIT      - benchmark unit [optional]
    VALUE     - value of benchmark data point
    VALUE_ID  - unique benchmark data point identifier
    CREATED   - benchmark data point created date in format YYYY-MM-DD HH:II:SS

Add additional data "testrun_id" and "machine" as columns to selection.

    ...
        select      => [
            'testrun_id',
            'machine',
        ],
    ...

Do the same as above.

    ...
        select      => [
            ['','testrun_id'],
            ['','machine'],
        ],
    ...

Get the maximum "testrun_id" of all selected data points. All other columns
without an aggregation become the C<default_aggregation> from
BenchmarkAnything::Storage::Backend::SQL-Configuration. Possible aggregation types are:

    - min = minimum
    - max = maximum
    - avg = average
    - gem = geometric mean
    - sum = summary
    - cnt = count
    - cnd = distinct value count

    ...
        select      => [
            ['max','testrun_id'],
            'machine',
        ],
    ...

A aggregation is also possible for the default columns.

    ...
        select      => [
            ['max','testrun_id'],
            ['avg','VALUE'],
        ],
    ...

=item where [optional]

An Array of Array References containing restrictions for benchmark data points.

    ...
        where       => [
            ['!=', 'machine', 'mx1.small'     ],
            ['=' , 'NAME'   , 'testbenchmark' ],
        ],
    ...

1. Parameter in Sub-Array = restriction operator

    =           - equal
    !=          - not equal
    <           - lower
    >           - greater
    <=          - lower equal
    >=          - greater equal
    like        - SQL LIKE
    not_like    - SQL NOT LIKE
    is_empty    - empty string or undef or null

2. Parameter in Sub-Array = restricted column

A restriction is possible for additional values and the default columns.

3 - n. Parameters in Sub-Array = value for restriction

In general there is just a single value. For '=' and '!=' a check for multiple
values is possible. In SQL it is implemented with IN and NOT IN.

=item where_sql [optional]

A String containing an additional where clause. Please use this feature just if
the "where" parameter is not sufficient to restrict.

=item order_by [optional]

An Array of Strings or an Array of Array References determining the order of
returned benchmark data points.

Array of Strings:
    column to sort with default order direction "ASC" (ascending)

Array of Array References
    1. Element: column to sort
    2. Element: order direction with possible values "ASC" (ascending) and "DESC" (descending)
    3. Element: hash of additional options. Possible values:
        numeric: Set a true value for a numeric sort

    ...
        order_by    => [
            'machine',
            ['benchmark_date','DESC']
            ['testrun_id','ASC',{numeric => 1}]
        ],
    ...

=item limit [optional]

An integer value which determine the number of returned benchmark data points.

=item offset [optional]

An integer value which determine the number of omitted benchmark data points.

=back

=head3 search_array

Returning all benchmark data points as Array of Hashes.

    my $or_benchmark_points = $or_bench->search_array({
        select      => [
            'testrun_id',
            'machine',
        ],
        where       => [
            ['!=', 'machine', 'mx1.small'     ],
            ['=' , 'NAME'   , 'testbenchmark' ],
        ],
        limit       => 2,
        offset      => 1,
        order_by    => [
            'machine',
            ['testrun_id','ASC']
        ],
    });

=head3 search_hash

Returning all benchmark data points as Hash of Hashes. As compared to search
C<search_array> this function needs the parameter C<keys>. C<keys> is an Array
of Strings which determine the columns used as the keys for the nested hashes.
Every "key" create a new nested hash.

    my $or_benchmark_points = $or_bench->search_array({
        keys        => [
            'testrun_id',
            'machine',
            'VALUE_ID',
        ],
        select      => [
            'testrun_id',
            'machine',
        ],
        where       => [
            ['!=',       'machine',      'mx1.small'     ],
            ['=',        'NAME'   ,      'testbenchmark' ],
            ['like',     'some_key',     'some%value'    ],
            ['not_like', 'another_key',  'another%value' ],
            ['is_empty', 'parameter1',   1 ], # check parameter1 is empty     - Elasticsearch backend only
            ['is_empty', 'parameter2',   0 ], # check parameter2 is not empty - Elasticsearch backend only
        ],
        limit       => 2,
        offset      => 1,
        order_by    => [
            'machine',
            ['testrun_id','ASC']
        ],
    });

=head3 get_stats

Returns a hash with info about the storage, like how many data points,
how many metrics, how many additional keys, are stored.

 my $stats = $or_bench->get_stats();

=head3 get_single_benchmark_point

Get a single data point from the database including all essential
fields (NAME, VALUE, UNIT, VALUE_ID, CREATED) and all additional
fields.

 my $point = $or_bench->get_single_benchmark_point($value_id);

=head3 get_full_benchmark_points

Get C<$count> data points from the database including all essential
fields (NAME, VALUE, UNIT, VALUE_ID, CREATED) and all additional
fields, beginning with C<$value_id>.

 my $point = $or_bench->get_full_benchmark_points($value_id, $count);

=head3 list_benchmark_names

Get a list of all benchmark NAMEs, optionally matching a given pattern
(SQL LIKE syntax, i.e., using C<%> as placeholder.

 $benchmarkanythingdata = $or_bench->list_benchmark_names($pattern);

=head3 list_additional_keys

Get a list of all additional key names, optionally matching a given
pattern (SQL LIKE syntax, i.e., using C<%> as placeholder.

 $benchmarkanythingdata = $or_bench->list_additional_keys($pattern);

=head3 enqueue_multi_benchmark

As a low-latency alternative to directly calling
L</add_multi_benchmark> there is a queuing functionality.

The C<enqueue_multi_benchmark> function simply writes the raw incoming
data structure serialized (and compressed) into a single row and
returns. The complementary function to this is
C<process_queued_multi_benchmark> which takes these values over using
the real C<add_multi_benchmark> internally.

=head3 process_queued_multi_benchmark

This is part 2 of the low-latency queuing alternative to directly
calling L</add_multi_benchmark>.

It transactionally marks a single raw entry as being processed and
then takes over its values by calling C<add_multi_benchmark>. It
preserves the order of entries by inserting each chunk sequentially,
to not confuse the IDs to the careful reader. After the bundle is
taken over it is marked as processed.

This function only handles one single raw entry. It is expected to
called from co-operating multiple worker tasks or multiple times from
a wrapper.

Currently the original raw values are B<not> deleted immediately, just
for safety reasons, until the transactional code is death-proof (and
certified by Stuntman Mike). There is a dedicated funtion L/gc> for
that cleanup.

The function returns the ID of the processed raw entry.

=head3 gc

This calls garbage collection, in particular deletes raw entries
created by C<process_queued_multi_benchmark> and already processed by
C<process_queued_multi_benchmark>.

It is separated from those processing just for safety reasons until
the transactional code in there is waterproof.

The gc function can cleanup more stuff in the future.

=head3 subsume

This is a maintenance function for reducing the number of data points in the
database. Calling this function reduces the rows in the benchmark values table
by building an average value for all benchmark data points grouped by specfic
columns. By default all old grouped columns will be added to backup tables for
rebuilding the original state.
It is highly recommended to do this periodically for better search performance.

    my $b_success = $or_bench->subsume({
        subsume_type        => 'month',
        exclude_additionals => [qw/ benchmark_date /],
        date_from           => '2013-01-01 00:00:00',
        date_to             => '2014-01-01 00:00:00',
        backup              => 0,
    });

=over 4

=item subsume_type

The subsume of benchmark data points is made by group with the following
elements:

 - bench_id
 - additional data values ( Example: testrun_id, machine )
 - specific data range ( subsume_type ).
   The possible subsume types are stored in the
   extrapolation_type_table ( BenchmarkAnything::Storage::Backend::SQL-Configuration ). By default there
   are the following types: "second", "minute", "hour", "day", "week", "month",
   "year".

=item date_from

Begin of subsume period.

=item date_to

End of subsume period.

=item exclude_additionals

Array Reference of additional values that should be excluded from grouping.

=item backup

By default all subsumed rows will be inserted to backup tables. If this
isn't desired a false value must be passed.

=back

=head3 init_search_engine( $force )

Initializes the configured search engine (Elasticsearch). If the index
already exists it does nothing, except when you set C<$force> to a
true value which deletes and re-creates the index. This is necessary
for example to apply new type mappings.

After a successful (re-)init you need to run C<sync_search_engine>.

During (re-init) and sync you should disable querying by setting

  searchengine.elasticsearch.enable_query: 0

=head3 sync_search_engine( $force, $start, $count)

Sync C<$count> (default 10000) entries from the relational backend
into the search engine (Elasticsearch) for indexing, beginning at
C<$start> (default 1). Already existing entries in Elasticsearch are
skipped unless C<$force> is set to a true value.

=head1 NAME

BenchmarkAnything::Storage::Backend::SQL - Save and search benchmark points by database

=head1 Configuration

The following elements are required in configuration:

=over 4

=item default_aggregation

Default aggregation used for non aggregated columns if an aggregation on any
other column is found.

=item tables

Containing the names of the tables used bei B<BenchmarkAnything::Storage::Backend::SQL>

    tables => {
        unit_table                       => 'bench_units',
        benchmark_table                  => 'benchs',
        benchmark_value_table            => 'bench_values',
        subsume_type_table               => 'bench_subsume_types',
        benchmark_backup_value_table     => 'bench_backup_values',
        additional_type_table            => 'bench_additional_types',
        additional_value_table           => 'bench_additional_values',
        additional_relation_table        => 'bench_additional_relations',
        additional_type_relation_table   => 'bench_additional_type_relations',
        backup_additional_relation_table => 'bench_backup_additional_relations',
    }

=item select_cache [optional]

In case of a true value the module cache some select results

=back

=head3 default_columns

Returns the hash about those columns that are by default part of each
single data point (NAME, UNIT, VALU, VALUE_ID, CREATED, each with its
internal column name). These default columns might go away in the
future, but for now some systems need this internal information.

=head3 benchmark_operators

Returns the list of operators supported by the query language. This is
provided for frontend systems that support creating queries
automatically.

=head3 json_true

Auxiliary function for Elasticsearch JSON data.

=head3 json_false

Auxiliary function for Elasticsearch JSON data.

=head2 Elasticsearch support

=head3 Config

You can pass through a config entry for an external search engine
(currently only Elasticsearch) to the constructor:

    my $or_bench = BenchmarkAnything::Storage::Backend::SQL->new({
        dbh    => $or_dbh,
        searchengine => {
          elasticsearch =>
            #
            # which index/type to use
            index => "myapp",
            type  => "benchmarkanything",
            #
            # queries use the searchengine
            enable_query => 1,
            #
            # should each single added value be stored immediately
            # (maybe there is another bulk sync mechanism)
            index_single_added_values_immediately => 1,
            #
            # which nodes to use
            nodes => [ 'localhost:9200' ],
            #
            # (OPTIONAL)
            # Your additional application specific mappings, used when
            # index is created.
            #
            # WARNING: You are allowed to overwrite the pre-defined
            # defaults for the built-in fields (NAME, VALUE, VALUE_ID,
            # UNIT, CREATED) as it is a RIGHT_PRECEDENT hash merge with
            # your additional_mappings on the right side. So if you
            # touch the internal fields you better know what you are
            # doing.
            additional_mappings => {
                # type as defined above in elasticsearch.type
                benchmarkanything => {
                    # static key <properties>
                    properties => {
                        # field
                        tapper_report => {
                            type => long,
                        },
                        tapper_testrun => {
                            type => long,
                        },
                        tapper_testplan => {
                            type => long,
                        },
                    },
                },
            },
        },
    });

With such a config and an already set up Elasticsearch you can use the
lib as usual but it is handling all things transparently behind the
scenes to index and query the data with Elasticsearch. The relational
SQL storage is still used as the primary storage.

=head3 Index

When C<index_single_added_values_immediately> is set, every single
added entry is fetched right after insert (to get all transformations
and added metadata) and sent to elasticsearch for index.

Please note, this immediate indexing adds an overhead to insert
time. You could as well switch-off this setting and take care of
indexing the data at another time. Then again, for instance the
C<::Frontend::HTTP> already takes care of bulk-adding new data
asynchronously, so the overhead should be hidden in there, so just
switch-on the feature and don't worry too much.

=head3 Search

When C<enable_query> is set, the BenchmarkAnything queries are
transformed into corresponding Elasticsearch queries, sent to
Elastisearch, and the result is taken directly from its answers.

=head1 AUTHOR

Roberto Schaefer <schaefr@amazon.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Amazon.com, Inc. or its affiliates.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
