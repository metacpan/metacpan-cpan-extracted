#!perl
# PODNAME: es-open.pl
# ABSTRACT: Open any closed indices matching your paramters.
use strict;
use warnings;

use App::ElasticSearch::Utilities qw(es_indices es_request);
use CLI::Helpers qw(:output);
use Getopt::Long qw(:config no_ignore_case no_ignore_case_always);
use Pod::Usage;

#------------------------------------------------------------------------#
# Argument Parsing
my %OPT;
GetOptions(\%OPT,
    'help|h',
    'manual|m',
);

#------------------------------------------------------------------------#
# Documentation
pod2usage(1) if $OPT{help};
pod2usage(-exitval => 0, -verbose => 2) if $OPT{manual};

# Return all closed indexes within our constraints.
my @indices = es_indices(state => 'closed');

foreach my $idx (reverse sort @indices) {
    verbose("Opening index: $idx");
    my $result = es_request('_open', { index=>$idx, method => 'POST'});
    debug_var($result);
    my $color = 'green';
    output({color=>$color}, "+ Opened '$idx'");
}

__END__

=pod

=head1 NAME

es-open.pl - Open any closed indices matching your paramters.

=head1 VERSION

version 6.9

=head1 SYNOPSIS

es-open.pl [options]

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

This tool provides access to open any closed indices in the cluster
matching the parameters.

Open the last 45 days of logstash indices:

    es-open.pl --base logstash --days 45

=head1 NAME

es-open.pl - Utility for opening indices that are closed mathcing the constraints.

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

This software is Copyright (c) 2019 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
