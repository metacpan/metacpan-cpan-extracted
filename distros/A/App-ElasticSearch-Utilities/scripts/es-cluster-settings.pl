#!perl
# PODNAME: es-cluster-settings.pl
# ABSTRACT: Get or apply settings to the cluster
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
);
my ($opt,$usage) = describe_options('%c %o',
    ['duration=s', hidden =>
        {
            default => $DEFAULT{duration},
            one_of => [
                [ 'transient|t' => "Apply to the transient settings, the default", { implies => { duration => 'transient' } } ],
                [ 'persistent|p' => "Apply to the persistent settings", { implies => { duration => 'persistent' } } ],
            ],
        },
    ],
    ['update|u=s%', "Settings in flat form to set, can be specified more than once, ie: -s search.max_buckets=1000000"],
    ['delete=s@',   "Settings in flat form to delete, can be specified more than once"],
    [],
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

my $current = es_request('/_cluster/settings', { uri_param => { flat_settings => 'true' } });
output({color=>'cyan'}, "-- Current Settings --");
output($json->encode($current));

if( $opt->update || $opt->delete ) {
    output({color=>'magenta',clear =>1}, sprintf "-- Updating Settings [%s] --", $opt->duration);

    # Add updates
    my %settings = $opt->update ? %{ $opt->update } : ();

    # Add deletes
    if( my $deletes = $opt->delete ) {
        foreach my $setting ( @{ $deletes } ) {
            $settings{$setting} = undef;
        }
    }

    # Peform the operation
    my $data = es_request('/_cluster/settings',
        {
            method => 'PUT',
            uri_param => { flat_settings => 'true' },
        },
        {
            $opt->duration => \%settings,
        }
    );

    die "Failed updating settings" unless $data;

    # Report success/failure
    if( my $ack = delete $data->{acknowledged} ) {
            output({color=>'green'}, "Successfully applied settings!");
    }
    else {
        output({color=>'red'}, "FAILED applying settings:");
    }
    output($json->encode($data));

    # Show resulting settings
    my $now = es_request('/_cluster/settings', { uri_param => { flat_settings => 'true' } });
    output({color=>'cyan'}, "-- Final Settings --");
    output($json->encode($now));
}

__END__

=pod

=head1 NAME

es-cluster-settings.pl - Get or apply settings to the cluster

=head1 VERSION

version 8.5

=head1 SYNOPSIS

es-cluster-settings.pl --update cluster.routing.allocation.exclude._name=node101

Options:

    --transient         Update the transient cluster settings, the default
    --persistent        Update the persistent cluster settings

    --update            Expects K=V in the flat form to update the cluster settings,
                        can be specified more than once:
                            --update search.max_buckets=10000000 \
                            --update cluster.routing.allocation.awareness.attributes=rack

    --delete            Name of a setting in flat form to delete, can be specified
                        more than once

                            --delete search.max_buckets --delete cluster.routing.allocation.awareness.*

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

=head1 DESCRIPTION

This script allows you to change cluster settings easily.

Usage:

    # Show current settings
    $ es-cluster-settings.pl

    # Remove a node from shard allocation via the transient settings
    $ es-cluster-settings.pl --update cluster.routing.allocation.exclude._name=node-101

    # Update the search.max_buckets persistently
    $ es-cluster-settings.pl --persistent --update search.max_buckets=10000000

    # Delete the search.max_buckets from the transient settings
    $ es-cluster-settings.pl --delete search.max_buckets

    # Delete the cluster.routing.allocation.enabled in the persistent settings
    $ es-cluster-settings.pl --persistent --delete cluster.routing.allocation.enabled

    # Delete all the cluster.routing.allocation.* settings in the persistent section
    $ es-cluster-settings.pl --persistent --delete cluster.routing.allocation.*

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
