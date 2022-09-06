#!perl
#
# PODNAME: es-aggregate.pl
# ABSTRACT: Multi-level aggregations in Elasticsearch
#
use v5.10;
use strict;
use warnings;

use App::ElasticSearch::Utilities qw(es_request);
use App::ElasticSearch::Utilities::QueryString;
use App::ElasticSearch::Utilities::Aggregations;
use CLI::Helpers qw(:output);
use Getopt::Long::Descriptive;
use JSON::MaybeXS;
use Pod::Usage;
use Storable qw(dclone);
use YAML::XS ();

# Grab a copy of the args
my @args = @ARGV;
# Process args
my ($opt,$usage) = describe_options("%c %o",
    ['aggregate|agg=s@', "Aggregate these fields, specified more than once to sub aggregate", { required => 1 }],
    ['by=s@',            "Sort by this aggregation" ],
    ['asc',              "Sort ascending, default is descnding" ],
    [],
    ["Display"],
    ['json',      "Results as JSON"],
    ['show-aggs', "Show computed aggregation block"],
    ['show-raw',  "Show raw results from Elasticsearch"],
    [],
    ['help', "Display this help", { shortcircuit => 1 } ],
    ['manual', "Display complete options and documentation.", { shortcircuit => 1 }],
);
if( $opt->help ) {
    print $usage->text;
    exit 0;
}
pod2usage(-exitval => 0, -verbose => 2) if $opt->manual;

my $json = JSON->new->utf8->canonical;
my $qs = App::ElasticSearch::Utilities::QueryString->new();
my $q  = $qs->expand_query_string( @ARGV );
$q->set_size(0);

# Figure out where the --by's are spatially
my $ORDER     = $opt->asc ? 'asc' : 'desc';
my @agg_param = @{ $opt->aggregate };
my @by_param  = $opt->by ? @{ $opt->by } : ();
my @by        = ();

foreach my $token ( reverse @args ) {
    if( $token =~ /^--agg/ ) {
        $q->wrap_aggs( %{ expand_aggregate_string( pop @agg_param ) } );
        $q->aggs_by( $ORDER => [@by] ) if @by;
        @by=();
    }
    elsif( $token eq '--by' ) {
        push @by, pop @by_param;
    }
}

output({color=>'yellow'}, YAML::XS::Dump($q->aggregations)) if $opt->show_aggs;

my $result = $q->execute();
my $aggs   = $result->{aggregations};

output({color=>'cyan'}, YAML::XS::Dump($aggs)) if $opt->show_raw;

my $flat = es_flatten_aggs($aggs);
foreach my $row ( @{ $flat } ) {
    if ( $opt->json ) {
        output({data=>1}, $json->encode({ @{ $row } }));
    }
    else {
        output({data=>1}, join("\t", grep { !/\.hits$/  } @{ $row }));
    }
}

__END__

=pod

=head1 NAME

es-aggregate.pl - Multi-level aggregations in Elasticsearch

=head1 VERSION

version 8.4

=head1 SYNOPSIS

es-aggregate.pl [search string] --agg <aggregate>

Options:

    --agg               Aggregation string, can be specified multiple times
    --by                Perform an aggregation using the result of this, example: --by cardinality:src_ip
    --asc               Change default sort order to ascending
    --show-agg          Show the aggregate clause being sent to the backend
    --show-raw          Show the raw results from the backend
    --json              Output as newline delimited JSON

From App::ElasticSearch::Utilities:

    --local         Use localhost as the elasticsearch host
    --host          ElasticSearch host to connect to
    --port          HTTP port for your cluster
    --proto         Defaults to 'http', can also be 'https'
    --http-username HTTP Basic Auth username
    --password-exec Script to run to get the users password
    --insecure      Don't verify TLS certificates
    --cacert        Specify the TLS CA file
    --capath        Specify the directory with TLS CAs
    --cert          Specify the path to the client certificate
    --key           Specify the path to the client private key file
    --noop          Any operations other than GET are disabled, can be negated with --no-noop
    --timeout       Timeout to ElasticSearch, default 10
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
    --tags              A comma separated list of tags to display
    --color             Boolean, enable/disable color, default use git settings
    --verbose           Incremental, increase verbosity (Alias is -v)
    --debug             Show developer output
    --debug-class       Show debug messages originating from a specific package, default: main
    --quiet             Show no output (for cron)
    --syslog            Generate messages to syslog as well
    --syslog-facility   Default "local0"
    --syslog-tag        The program name, default is the script name
    --syslog-debug      Enable debug messages to syslog if in use, default false
    --nopaste           Use App::Nopaste to paste output to configured paste service
    --nopaste-public    Defaults to false, specify to use public paste services
    --nopaste-service   Comma-separated App::Nopaste service, defaults to Shadowcat

=head1 OPTIONS

=over 8

=item B<help>

Print this message and exit

=item B<manual>

Print detailed help with examples

=back

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
