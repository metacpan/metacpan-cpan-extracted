#!perl
# PODNAME: es-nodes.pl
# ABSTRACT: Listing the nodes in a cluster with some details
use strict;
use warnings;

use App::ElasticSearch::Utilities qw(es_request);
use CLI::Helpers qw(:output);
use Getopt::Long qw(:config no_ignore_case no_ignore_case_always);
use Pod::Usage;

#------------------------------------------------------------------------#
# Argument Parsing
my %OPT;
GetOptions(\%OPT,
    'attributes|attr=s',
    'help|h',
    'manual|m',
);


#------------------------------------------------------------------------#
# Documentation
pod2usage(1) if $OPT{help};
pod2usage(-exitval => 0, -verbose => 2) if $OPT{manual};

my $cres = es_request('_cluster/health');
my $CLUSTER = defined $cres ? $cres->{cluster_name} : 'UNKNOWN';

output({clear=>1,color=>'magenta'}, "Cluster [$CLUSTER] contains $cres->{number_of_nodes} nodes.", '-='x20);
# Get a list of nodes
my $nres = es_request('_cluster/state/master_node,nodes', {});
if(!defined $nres) {
    output({stderr=>1,color=>'red'}, 'Fetching node status failed.');
    exit 1;
}
debug_var($nres);
foreach my $uuid (sort { $nres->{nodes}{$a}->{name} cmp $nres->{nodes}{$b}->{name} } keys %{ $nres->{nodes} }) {
    my $node = $nres->{nodes}{$uuid};
    my $color = defined $nres->{master_node} && $uuid eq $nres->{master_node} ? 'green' : 'cyan';

    output({color=>$color}, $node->{name});
    output({indent=>1,kv=>1,color=>$color}, address => $node->{transport_address});
    verbose({indent=>1,kv=>1,color=>$color}, uuid => $uuid);
    if( exists $OPT{attributes} ) {
        output({indent=>1}, "attributes:");
        foreach my $attr ( split /,/, $OPT{attributes} ) {
            next unless exists $node->{attributes}{$attr};
            output({indent=>2,kv=>1}, $attr => $node->{attributes}{$attr});
        }
    }
}

__END__

=pod

=head1 NAME

es-nodes.pl - Listing the nodes in a cluster with some details

=head1 VERSION

version 7.0

=head1 SYNOPSIS

es-nodes.pl [options]

Options:

    --help              print help
    --manual            print full manual
    --attibutes         Comma separated list of attributes to display, default is NONE

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

This tool provides access to information on nodes in the the cluster.

=head1 NAME

es-nodes.pl - Utility for investigating the nodes in a cluster

=head1 OPTIONS

=over 8

=item B<help>

Print this message and exit

=item B<manual>

Print detailed help with examples

=item B<attributes>

Comma separated list of node attributes to display, aliased as --attr

    --attributes dc,id

=back

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
