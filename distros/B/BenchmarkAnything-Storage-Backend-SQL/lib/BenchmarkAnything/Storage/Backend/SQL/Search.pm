package BenchmarkAnything::Storage::Backend::SQL::Search;
our $AUTHORITY = 'cpan:TAPPER';
# ABSTRACT: searchengine support functions
$BenchmarkAnything::Storage::Backend::SQL::Search::VERSION = '0.024';
use strict;
use warnings;
use Data::Dumper;


sub json_true  { bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ) }
sub json_false { bless( do{\(my $o = 0)}, 'JSON::PP::Boolean' ) }

sub _sync_search_engine_process_chunk
{
    my ( $orig_sql, $b_force, $i_start, $i_end) = @_;

    # === use own connection so we can run this function in parallel ===

    my $dbh = DBI->connect($orig_sql->{dbh_config}{dsn},
                           $orig_sql->{dbh_config}{user},
                           $orig_sql->{dbh_config}{password}, {'RaiseError' => 1})
        or die "benchmarkanything: can not connect: ".$DBI::errstr;
    my $or_sql = BenchmarkAnything::Storage::Backend::SQL->new({dbh          => $dbh,
                                                                dbh_config   => $orig_sql->{dbh_config},
                                                                debug        => $orig_sql->{debug},
                                                                force        => $orig_sql->{force},
                                                                verbose      => $orig_sql->{verbose},
                                                                searchengine => $orig_sql->{searchengine},
                                                               });

    # === elasticsearch client ===

    require BenchmarkAnything::Storage::Search::Elasticsearch;
    my ($or_es, $s_index, $s_type) = BenchmarkAnything::Storage::Search::Elasticsearch::get_elasticsearch_client
     (
      {searchengine => $or_sql->{searchengine}, ownjson => 1}
     );
    my $bulk = $or_es->bulk_helper(index => $s_index, type => $s_type);

    # === bulk index ===

    my $i_count = $i_end - $i_start + 1;
    print STDERR "search-sync - process chunk: $i_start..$i_end ($i_count elements, force=$b_force)\n" if $or_sql->{verbose} || $or_sql->{debug};

    if ($b_force
        # If the beginning or the end of a range do not exist we sync that window.
        # Careful! This will not sync that window if there is a hole in-between! So
        # if in doubt you better force a full sync.
        or not $or_es->exists(index => $s_index, type => $s_type, id => $i_start)
        or not $or_es->exists(index => $s_index, type => $s_type, id => $i_end)
       )
    {
        # Make sure to query the ::Backend::SQL store!
        my $bmks = $or_sql->get_full_benchmark_points($i_start, $i_count);
        $bulk->index({ id => $_->{VALUE_ID}, source => $_}) foreach @$bmks;
        $bulk->flush;
    }
}


sub sync_search_engine_classic
{
    my ( $or_self, $b_force, $i_start, $i_count) = @_;

    my $i_count_datapoints = $or_self->{query}->select_count_datapoints->fetch->[0];

    for (my $i = $i_start; $i <= $i_count_datapoints; $i += $i_count)
    {
        my $i_end = $i + $i_count-1;
        _sync_search_engine_process_chunk ($or_self, $b_force, $i, $i_end);
    }
}


sub init_search_engine
{
    my ( $or_sql, $b_force) = @_;

    my $debug = $or_sql->{debug} || $or_sql->{searchengine}{elasticsearch}{debug};

    if ( $or_sql->{searchengine}{elasticsearch}{index} )
    {
        require BenchmarkAnything::Storage::Search::Elasticsearch;
        my ($or_es, $s_index, $s_type) = BenchmarkAnything::Storage::Search::Elasticsearch::get_elasticsearch_client
         (
          {searchengine => $or_sql->{searchengine}}
         );

        # exists?
        if ($or_es->indices->exists(index => $s_index) and not $b_force)
        {
            print STDERR "init_search_engine: index '$s_index' already exists, use force to delete and recreate.\n";
            return;
        }

        # delete
        if ($or_es->indices->exists(index => $s_index))
        {
            my $response = $or_es->indices->delete(index => $s_index);
        }

        # mappings
        my $mappings =
        {
         $s_type => {
          dynamic_templates =>
          [
           { "core_field_NAME"     => { "match" => "NAME",     "mapping" => { "type" => "keyword", "store" => json_true } } },
           { "core_field_VALUE"    => { "match" => "VALUE",    "mapping" => { "type" => "text", } } },
           { "core_field_UNIT"     => { "match" => "UNIT",     "mapping" => { "type" => "text", } } },
           { "core_field_VALUE_ID" => { "match" => "VALUE_ID", "mapping" => { "type" => "long", } } },
           { "core_field_CREATED"  => { "match" => "CREATED",  "mapping" => { "type" => "date", format => 'yyyy-MM-dd||yyyy-MM-dd HH:mm:ss', } } },
           { "non_core_fields"     => { "match" => "*",        "mapping" => { "type" => "keyword", } } },
          ]
         }
        };
        require JSON::XS;
        require Hash::Merge;
        require Data::Dumper;
        local $Types::Serialiser::true;
        my $merge = Hash::Merge->new( 'RIGHT_PRECEDENT' );
        my $additional_mappings = $or_sql->{searchengine}{elasticsearch}{additional_mappings} || {};
        $mappings = $merge->merge($mappings, $additional_mappings);
        print STDERR "create.mappings:\n".JSON::XS->new->convert_blessed->pretty->encode($mappings) if $debug;

        # create
        my $answer = $or_es->indices->create
         (
          index => $s_index,
          body  => { mappings => $mappings },
         );
        print STDERR "create.answer:\n".Data::Dumper::Dumper($answer) if $debug;
    }
}


sub sync_search_engine
{
    my ( $or_sql, $b_force, $i_start, $i_bulkcount) = @_;

    $i_start     ||= 1;
    $i_bulkcount ||= 10_000;

    if ($or_sql->{searchengine}{elasticsearch})
    {
        eval { require BenchmarkAnything::Storage::Backend::SQL::Search::MCE };

        if (!$@) {
            # parallel with MCE
            print STDERR "search-sync - parallel processing (using MCE)\n" if $or_sql->{verbose} || $or_sql->{debug};
            BenchmarkAnything::Storage::Backend::SQL::Search::MCE::sync_search_engine_mce( $or_sql, $b_force, $i_start, $i_bulkcount);
        } else {
            # non-parallel fallback
            print STDERR "search-sync - serial processing\n" if $or_sql->{verbose} || $or_sql->{debug};
            sync_search_engine_classic($or_sql, $b_force, $i_start, $i_bulkcount);
        }
    } else {
            # Unsupported search engine
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BenchmarkAnything::Storage::Backend::SQL::Search - searchengine support functions

=head2 json_true

Boolean true in JSON documents.

=head2 json_false

Boolean false in JSON documents.

=head2 sync_search_engine_classic ($or_sql, $b_force, $i_start, $i_bulkcount)

Sync in linear way.

=over 4

=item $or_sql

The L<BenchmarkAnything::Storage::Backend::SQL|BenchmarkAnything::Storage::Backend::SQL> instance.

=item $b_force

Boolean. Re-sync without check if data already exist in index. Default C<false>.

=item $i_start

First element ID where to start. Default C<1>.

=item $i_bulkcount

How many elements to read and index per bunch. Default C<10000>.

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

=head1 AUTHOR

Roberto Schaefer <schaefr@amazon.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Amazon.com, Inc. or its affiliates.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
