#!perl
# PODNAME: es-index-blocks.pl
# ABSTRACT: Report and manage index blocks
use strict;
use warnings;

use App::ElasticSearch::Utilities qw(es_request es_node_stats es_index_stats es_index_strip_date es_flatten_hash);
use CLI::Helpers qw(:all);
use Getopt::Long::Descriptive;
use IO::Socket::INET;
use Pod::Usage;
use Ref::Util qw(is_hashref is_arrayref);

#------------------------------------------------------------------------#
# Argument Collection
my ($opt,$usage) = describe_options('%c %o',
    ['remove-blocks|remove',  "Remove discovered blocks, default is to just report."],
    [],
    ['For complete options, see the manual.'],
    [],
    ['help',   "Display this message and exit.", { shortcircuit => 1 }],
    ['manual', "Display complete man page.", { shortcircuit => 1 }],
);
#------------------------------------------------------------------------#
# Documentations!
if( $opt->help ) {
    print $usage->text;
    exit;
}
if( $opt->manual ) {
    pod2usage(-exitstatus => 0, -verbose => 2);
}

#------------------------------------------------------------------------#
# Get Index Blocks
my $result = es_request('_settings/index.blocks.*', { index => '_all' });
my %blocks=();
my @all_indices=();
foreach my $idx ( keys %{ $result } ) {
    push @all_indices, $idx;
    if( $result->{$idx}{settings} ) {
        my $settings = es_flatten_hash( $result->{$idx}{settings} );
        foreach my $block ( keys %{ $settings } ) {
            my $value = $settings->{$block};
            if( lc $value eq 'true') {
                push @{ $blocks{$block} }, $idx;
            }
        }
    }
}

#------------------------------------------------------------------------#
# Report Blocks
if( my @blocks = keys %blocks ) {
    foreach my $block ( sort @blocks ) {
        output({color=>'cyan',clear=>1}, "Index block: $block");
        foreach my $index (sort @{ $blocks{$block} }) {
            output({data=>1}, "$index is $block");
            if( $opt->remove_blocks ) {
                eval {
                    my $result = es_request('_settings',
                        { index  => $index, method => 'PUT' },
                        { $block => 'false' },
                    );
                    die "not acknowledged" unless $result->{acknowledged};
                    output({color=>'green',indent=>1}, "$block removed.");
                    1;
                } or do {
                    my $err = $@;
                    output({color=>'red',indent=>1}, "ERROR removing $block from $index: $err");
                };
            }
        }
    }
}
else {
    output({color=>'green'}, "No blocks discovered on any indices.");
    exit 0;
}

__END__

=pod

=head1 NAME

es-index-blocks.pl - Report and manage index blocks

=head1 VERSION

version 8.3

=head1 SYNOPSIS

es-index-blocks.pl --host [host] [options]

Options:

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

This script reports and optionally clears indexes with read_only_allow_delete set.

=head1 OPTIONS

=over 8

=item B<help>

Print this message and exit

=item B<manual>

Print this message and exit

=back

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
