#!perl
# PODNAME: es-copy-index.pl
# ABSTRACT: Copy an index from one cluster to another

use strict;
use warnings;

use App::ElasticSearch::Utilities qw(:default :index);
use App::ElasticSearch::Utilities::Query;
use App::ElasticSearch::Utilities::QueryString;
use CLI::Helpers qw(:all);
use File::Basename;
use File::Slurp::Tiny qw(read_lines);
use Getopt::Long qw(:config posix_default no_ignore_case no_ignore_case_always);
use Hash::Merge::Simple qw(clone_merge);
use JSON::MaybeXS;
use Pod::Usage;
use Ref::Util qw(is_hashref);
use Time::HiRes qw(time);

#------------------------------------------------------------------------#
# Argument Parsing
my %OPT;
GetOptions(\%OPT, qw(
    from=s
    to=s
    source=s
    destination=s
    append|A
    block=i
    mapping=s
    settings=s
    help|h
    manual|m
));

#------------------------------------------------------------------------#
# Documentation
pod2usage(1) if $OPT{help};
pod2usage(-exitstatus => 0, -verbose => 2) if $OPT{manual};
debug_var(\%OPT);

#------------------------------------------------------------------------#
# Copy To/From
my %INDEX = (
    from  => $OPT{source},
    to    => exists $OPT{destination} ? $OPT{destination} : $OPT{source},
    block => exists $OPT{block} ? $OPT{block} : 1000,
);
my %HOST = (
    from => $OPT{from},
    to   => exists $OPT{to} ? $OPT{to} : $OPT{from},
);
if( $HOST{to} eq $HOST{from} && $INDEX{to} eq $INDEX{from} ) {
    output({color=>'red',IMPORTANT=>1},
        "FATAL: Cannot copy from the same host to the same index name!"
    );
    exit 1;
}

#------------------------------------------------------------------------#
# Build the Query
my $JSON = JSON->new->pretty->canonical;
my $qs = App::ElasticSearch::Utilities::QueryString->new();
my $q  = @ARGV ? $qs->expand_query_string(@ARGV)
               : App::ElasticSearch::Utilities::Query->new(must => {match_all=>{}});

$q->set_scan_scroll('1m');
$q->set_size( $INDEX{block} );

# Connect to ElasticSearch
my %ES = ();
foreach my $dir (qw(from to)) {
    $ES{$dir} = es_connect( $HOST{$dir} );
}

die "Invalid index: $INDEX{from}" unless $ES{from}->exists( index => $INDEX{from} );
my $TO_EXISTS = $ES{to}->exists( index => $INDEX{to}  );

my $RECORDS = 0;
my $TOTAL=0;
my $LAST = time;
my ($status, $res);

# Mappings/Settings for Non-existant index.
unless( exists $OPT{append} ) {
    die "Index $INDEX{to} already exists in $HOST{to}" if $TO_EXISTS;
    $res = es_request($ES{from}, '_settings', {index => $INDEX{from}} );
    debug_var($res);
    my $from_settings = $res->{$INDEX{from}}{settings};
    my @settings = ({
        index => {
            number_of_shards   => $from_settings->{index}{number_of_shards},
            number_of_replicas => $from_settings->{index}{number_of_replicas},
        }
    });
    if( exists $OPT{settings} && -f $OPT{settings} ) {
        my $content = join '', read_lines($OPT{settings});
        eval {
            push @settings, $JSON->decode($content);
            1;
        } or do {
            debug($content);
            die "Parsing JSON from $OPT{settings} failed: $@";
        };
    }
    my $to_settings = clone_merge(@settings);

    # Determine if we get mappings from a file or from the index.
    my $mappings;
    if( exists $OPT{mapping} && -f $OPT{mapping} ) {
        my $content = join '', read_lines($OPT{mapping});
        eval {
            $mappings = $JSON->decode($content);
            1;
        } or do {
            debug($content);
            die "Parsing JSON from $OPT{mapping} failed: $@";
        };
    }
    else {
        $mappings = $res->{$INDEX{from}}{mappings};
    }

    $res = es_request($ES{to}, '/',
        {
            method => 'PUT',
            index => $INDEX{to},
        },
        {
            settings => $to_settings,
            $mappings ? ( mappings => $mappings ) : (),
        }
    );

    if (!defined $res || !is_hashref($res) || !$res->{ok}) {
        die "Failed to create index in $HOST{to} : " . $JSON->encode($res);
    }
}
else {
    my @ignored=();
    foreach my $k (qw(settings mapping)) {
        push @ignored, $k if exists $OPT{$k} && -f $OPT{$k};
    }
    output({color=>'yellow',sticky=>1},
        sprintf "%s - warning ignoring %s as they are invalid in this context.", basename($0), join(', ', map { "--$_" } @ignored)
    ) if @ignored;
} # End Mappings/Settings for Non-existant index.

debug_var($q->request_body);
$res = es_request($ES{from}, '_search',
    # Search Parameters
    {
        index     => $INDEX{from},
        uri_param => $q->uri_params,
        method => 'GET',
    },
    # Search Body
    $q->request_body,
);
debug_var($res);

while( $res && @{ $res->{hits}{hits} }) {
    $TOTAL ||= $res->{hits}{total};
    my $start=time;
    my $batch=0;
    my $body = [
        map {
            $batch++;
            (
                { create => { _type => $_->{_type},  _id => $_->{_id}, } },
                $_->{_source}
            )
        } @{ $res->{hits}{hits} }
    ];
    my $max_retries = 3;
    my $success = 0;
    while ($max_retries--) {
        debug("Attempting bulk load of $batch documents");
        my ($s2, $r2) = $ES{to}->bulk(
            index => $INDEX{to},
            body => $body
        );
        if ($s2 ne "200") {
            output({stderr=>1,color=>'red'},"Failed to put documents to $HOST{to} (http status = $status): " . $JSON->encode([ $s2, $r2 ]));
            next;
        }
        $success=1;
        last;
    }
    die "Failed to write data to $HOST{to}:9200/$INDEX{to} after $RECORDS docs indexed."
        unless $success;
    my $took = time - $start;
    show_counts( scalar @{$res->{hits}{hits}} );
    $res = es_request($ES{from}, '_search/scroll', {
        uri_param => {
            scroll_id => $res->{_scroll_id},
            scroll    => '1m',
        }
    });

    verbose(sprintf "Batch of %d done in %00.2fs.", $batch, $took);
}

sub show_counts {
    my $inc_records = shift;

    output({color=>'green'}, "Starting copy of $INDEX{from} to $HOST{to}:$INDEX{to}.") if $RECORDS == 0;

    $RECORDS += $inc_records;
    if( $RECORDS % ($INDEX{block} * 10) == 0 ) {
        my $now = time;
        my $diff = $now - $LAST;
        my @time=localtime;
        my $msg = sprintf "%00.2f%% %02d:%02d:%02d Records: %d of %d in %0.2fs", ($RECORDS/$TOTAL)*100, @time[2,1,0], $RECORDS, $TOTAL, $diff;
        output({color=>'yellow'}, $msg);
        $LAST=$now;
    }
}

__END__

=pod

=head1 NAME

es-copy-index.pl - Copy an index from one cluster to another

=head1 VERSION

version 6.9

=head1 SYNOPSIS

es-copy-access.pl [options] [query to select documents]

Options:

    --source            (Required) The source index name for the copy
    --destination       Destination index name, assumes source
    --from              (Required) A server in the cluster where the index lives
    --to                A server in the cluster where the index will be copied to
    --block             How many docs to process in one batch, default: 1,000
    --mapping           JSON mapping to use instead of the source mapping
    --settings          JSON index settings to use instead of those from the source
    --append            Instead of creating the index, add the documents to the destination
    --help              print help
    --manual            print full manual

From App::ElasticSearch::Utilities:

    --local         Use localhost as the elasticsearch host
    --host          ElasticSearch host to connect to
    --port          HTTP port for your cluster
    --proto         Defaults to 'http', can also be 'https'
    --http-username HTTP Basic Auth username
    --http-password HTTP Basic Auth password (if not specified, and --http-user is, you will be prompted)
    --password-exec Script to run to get the users password
    --noop          Any operations other than GET are disabled, can be negated with --no-noop
    --timeout       Timeout to ElasticSearch, default 30
    --keep-proxy    Do not remove any proxy settings from %ENV
    --index         Index to run commands against
    --base          For daily indexes, reference only those starting with "logstash"
                     (same as --pattern logstash-* or logstash-DATE)
    --datesep       Date separator, default '.' also (--date-separator)
    --pattern       Use a pattern to operate on the indexes
    --days          If using a pattern or base, how many days back to go, default: 1

See also the "CONNECTION ARGUMENTS" and "INDEX SELECTION ARGUMENTS" sections from App::ElasticSearch::Utilities.

From CLI::Helpers:

    --data-file         Path to a file to write lines tagged with 'data => 1'
    --color             Boolean, enable/disable color, default use git settings
    --verbose           Incremental, increase verbosity (Alias is -v)
    --debug             Show developer output
    --debug-class       Show debug messages originating from a specific package, default: main
    --quiet             Show no output (for cron)
    --syslog            Generate messages to syslog as well
    --syslog-facility   Default "local0"
    --syslog-tag        The program name, default is the script name
    --syslog-debug      Enable debug messages to syslog if in use, default false

=head1 DESCRIPTION

This script allows you to copy data from one index to another on the same cluster or
on a separate cluster.  It handles index creation, either directly copying the mapping
and settings from the source index or from mapping/settings JSON files.

This script could also be used to split up an index into smaller indexes for any number of reasons.

This uses the reindex API to copy data from one cluster to another

=head1 NAME

es-copy-index.pl - Copy an index from one cluster to another

=head1 OPTIONS

=over 8

=item B<from>

B<REQUIRED>: hostname or IP of the source cluster

=item B<to>

Hostname or IP of the destination cluster, defaults to the same host unless otherwise specified.

=item B<source>

B<REQUIRED>: name of the source index for the copy

=item B<destination>

Optional: change the name of the index on the destination cluster

=item B<block>

Batch size of docs to process in one retrieval, default is 1,000

=item B<mapping>

Path to a file containing JSON mapping to use on the destination index
instead of the mapping directly from the source index.

=item B<settings>

Path to a file containing JSON settings to use on the destination index
instead of the settings directly from the source index.

=item B<append>

This mode skips the index mapping and settings configuration and just being indexing
documents from the source into the destination.

=item B<help>

Print this message and exit

=item B<manual>

Print detailed help with examples

=back

=head1 EXAMPLES

=head2 Copy to different cluster

   es-copy-index.pl --from localhost --to remote.cluster.com --source logstash-2013.01.11

=head2 Rename an existing index

   es-copy-index.pl --from localhost --source logstash-2013.01.11 --destination logs-2013.01.11

=head2 Subset an existing index

   es-copy-index.pl --from localhost \
        --source logstash-2013.01.11 \
        --destination secure-2013.01.11 \
        category:'(authentication authorization)'

=head2 Changing settings and mappings

   es-copy-index.pl --from localhost \
        --source logstash-2013.01.11 \
        --destination testing-new-settings-old-data-2013.01.11 \
        --settings new_settings.json \
        --mappings new_mappings.json

=head2 Building an Incident Index using append

Let's say we were investigating an incident and wanted to have
an index that contained the data we were interested in.  We could use different
retention rules for incident indexes and we could arbitrarily add data to them based
on searches being performed on the source index.

Here's our initial query, a bad actor on our admin login page.

   es-copy-index.pl --from localhost \
        --source logstash-2013.01.11 \
        --destination incident-rt1234-2013.01.11 \
        src_ip:1.2.3.4 dst:admin.exmaple.com and file:'\/login.php'

Later on, we discover there was another actor:

   es-copy-index.pl --from localhost \
        --source logstash-2013.01.11 \
        --destination incident-rt1234-2013.01.11 \
        --append \
        src_ip:4.3.2.1 dst:admin.exmaple.com and file:'\/login.php'

The B<incident-rt1234-2013.01.11> index will now hold all the data from both of those queries.

=head1 Query Syntax Extensions

The search string is pre-analyzed before being sent to ElasticSearch.  The following plugins
work to manipulate the query string and provide richer, more complete syntax for CLI applications.

=head2 App::ElasticSearch::Utilities::QueryString::AutoEscape

Provide an '=' prefix to a query string parameter to promote that parameter to a C<term> filter.

This allows for exact matches of a field without worrying about escaping Lucene special character filters.

E.g.:

    user_agent:"Mozilla/5.0 (iPhone; CPU iPhone OS 12_1_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Mobile/15E148 Safari/604.1"

Is evaluated into a weird query that doesn't do what you want.   However:

    =user_agent:"Mozilla/5.0 (iPhone; CPU iPhone OS 12_1_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Mobile/15E148 Safari/604.1"

Is translated into:

    { term => { user_agent => "Mozilla/5.0 (iPhone; CPU iPhone OS 12_1_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Mobile/15E148 Safari/604.1" } }

Which provides an exact match to the term in the query.

=head2 App::ElasticSearch::Utilities::QueryString::Barewords

The following barewords are transformed:

    or => OR
    and => AND
    not => NOT

=head2 App::ElasticSearch::Utilities::QueryString::IP

If a field is an IP address uses CIDR Notation, it's expanded to a range query.

    src_ip:10.0/8 => src_ip:[10.0.0.0 TO 10.255.255.255]

=head2 App::ElasticSearch::Utilities::QueryString::Ranges

This plugin translates some special comparison operators so you don't need to
remember them anymore.

Example:

    price:<100

Will translate into a:

    { range: { price: { lt: 100 } } }

And:

    price:>50,<100

Will translate to:

    { range: { price: { gt: 50, lt: 100 } } }

=head3 Supported Operators

B<gt> via E<gt>, B<gte> via E<gt>=, B<lt> via E<lt>, B<lte> via E<lt>=

=head2 App::ElasticSearch::Utilities::QueryString::Underscored

This plugin translates some special underscore surrounded tokens into
the Elasticsearch Query DSL.

Implemented:

=head3 _prefix_

Example query string:

    _prefix_:useragent:'Go '

Translates into:

    { prefix => { useragent => 'Go ' } }

=head2 App::ElasticSearch::Utilities::QueryString::FileExpansion

If the match ends in .dat, .txt, .csv, or .json then we attempt to read a file with that name and OR the condition:

    $ cat test.dat
    50  1.2.3.4
    40  1.2.3.5
    30  1.2.3.6
    20  1.2.3.7

Or

    $ cat test.csv
    50,1.2.3.4
    40,1.2.3.5
    30,1.2.3.6
    20,1.2.3.7

Or

    $ cat test.txt
    1.2.3.4
    1.2.3.5
    1.2.3.6
    1.2.3.7

Or

    $ cat test.json
    { "ip": "1.2.3.4" }
    { "ip": "1.2.3.5" }
    { "ip": "1.2.3.6" }
    { "ip": "1.2.3.7" }

We can source that file:

    src_ip:test.dat      => src_ip:(1.2.3.4 1.2.3.5 1.2.3.6 1.2.3.7)
    src_ip:test.json[ip] => src_ip:(1.2.3.4 1.2.3.5 1.2.3.6 1.2.3.7)

This make it simple to use the --data-file output options and build queries
based off previous queries. For .txt and .dat file, the delimiter for columns
in the file must be either a tab or a null.  For files ending in
.csv, Text::CSV_XS is used to accurate parsing of the file format.  Files
ending in .json are considered to be newline-delimited JSON.

You can also specify the column of the data file to use, the default being the last column or (-1).  Columns are
B<zero-based> indexing. This means the first column is index 0, second is 1, ..  The previous example can be rewritten
as:

    src_ip:test.dat[1]

or:
    src_ip:test.dat[-1]

For newline delimited JSON files, you need to specify the key path you want to extract from the file.  If we have a
JSON source file with:

    { "first": { "second": { "third": [ "bob", "alice" ] } } }
    { "first": { "second": { "third": "ginger" } } }
    { "first": { "second": { "nope":  "fred" } } }

We could search using:

    actor:test.json[first.second.third]

Which would expand to:

    { "terms": { "actor": [ "alice", "bob", "ginger" ] } }

This option will iterate through the whole file and unique the elements of the list.  They will then be transformed into
an appropriate L<terms query|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-terms-query.html>.

=head2 App::ElasticSearch::Utilities::QueryString::Nested

Implement the proposed nested query syntax early.  Example:

    nested_path:"field:match AND string"

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
