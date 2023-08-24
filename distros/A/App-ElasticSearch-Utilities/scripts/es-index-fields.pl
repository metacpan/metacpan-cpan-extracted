#!perl
# PODNAME: es-index-fields.pl
# ABSTRACT: Show information on the fields storage usage
use strict;
use warnings;

use App::ElasticSearch::Utilities qw(:all);
use CLI::Helpers qw(:all);
use Const::Fast;
use JSON::MaybeXS;
use Getopt::Long::Descriptive;
use Pod::Usage;

#------------------------------------------------------------------------#
# Argument Collection
const my %DEFAULT => (
    duration => 'transient',
    top      => 10,
);
my ($opt,$usage) = describe_options('%c %o',
    ['top|limit|size|n=i', "Show the top N fields, defaults to $DEFAULT{top}",
        { default => $DEFAULT{top} },
    ],
    ['no-meta-fields|N', "Disable showing meta fields starting with an underscore"],
    []     ,
    ['help', 'Display this message', { shortcircuit => 1 }],
    ['manual', 'Display full manual', { shortcircuit => 1 }],
);

#------------------------------------------------------------------------#
# Documentations!
if( $opt->help ) {
    print $usage->text;
    exit 0;
}
pod2usage(-exitstatus => 0, -verbose => 2) if $opt->manual;

#------------------------------------------------------------------------#
my $json = JSON->new->pretty->utf8->canonical;

my %indices = map { $_ => (es_index_days_old($_) || 0) } es_indices();

const my @FieldStores => qw(
    doc_values
    norms
    stored_fields
    term_vectors
    points
);

my %Fields = ();

foreach my $idx ( sort keys %indices ) {
    output({clear=>1, color=>"cyan"}, "Getting field data for $idx");

    # Get Field Data
    my $result;
    eval {
        $result = es_request('_disk_usage', {
            method => 'POST',
            index  => $idx,
            uri_param => {
                run_expensive_tasks => 'true'
            },
        });
        1;
    } or do {
        my $err = $@;
        output({indent=>1, color=>'red'}, "Request Failed: $err");
    };
    $result //= {};

    if( my $fields = $result->{$idx}{fields} ) {
        my $by_size = sub {
            $fields->{$b}{total_in_bytes} <=> $fields->{$a}{total_in_bytes}
        };
        my $n = 0;
        foreach my $field ( sort $by_size keys %{ $fields } ) {
            # Skip meta fields
            next if $opt->no_meta_fields && $field =~ /^_/;

            # Collect field totals
            my $data = $fields->{$field};
            $Fields{$field} += $data->{total_in_bytes};

            # Skip the output, but collect all the datas
            $n++;
            next if $n > $opt->top;

            output({indent=>1,kv=>1,color=>color_pick($data->{total_in_bytes})}, $field => $data->{total});
            foreach my $k ( @FieldStores ) {
                if( $data->{"${k}_in_bytes"} > 0 ) {
                    output({indent=>2,kv=>1,color=>color_pick($data->{"${k}_in_bytes"})}, $k => $data->{$k} );
                }
            }
        }
    }
    else {
        output({indent=>1, color=>'red'}, "Failed retrieving field storage information");
    }

    if ( my $totals = $result->{$idx}{all_fields} ) {
            output({clear=>1,indent=>1,color=>'cyan'}, "All Fields ($idx):");
            output({indent=>2,kv=>1,color=>color_pick($totals->{total_in_bytes})}, total => $totals->{total});

            foreach my $k ( @FieldStores ) {
                if( $totals->{"${k}_in_bytes"} > 0 ) {
                    output({indent=>3,kv=>1,color=>color_pick($totals->{"${k}_in_bytes"})}, $k => $totals->{$k} );
                }
            }
    }
}

output({clear=>1,color=>'yellow'}, "Totals for fields in all indexes");
my $n = 0;
foreach my $k ( sort { $Fields{$b} <=> $Fields{$a} } keys %Fields ) {
    output({indent=>1,kv=>1,color=>color_pick($Fields{$k})}, $k, es_human_size($Fields{$k}));
    $n++;
    last if $n >= $opt->top;
}

sub color_pick {
    my ($v) = @_;
    return
        $v > 1024 * 1024 * 1024 * 10  ? 'red'
            : $v > 1024 * 1024 * 1024 ? 'yellow'
            : 'green';
}

__END__

=pod

=head1 NAME

es-index-fields.pl - Show information on the fields storage usage

=head1 VERSION

version 8.7

=head1 SYNOPSIS

es-index-fields.pl --index my-index-001

Options:

    --help              print help
    --manual            print full manual

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

=head1 DESCRIPTION

This script allows you to see the storage usage by field

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
