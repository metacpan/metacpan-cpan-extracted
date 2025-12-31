#  -*-cperl-*-
#
#  DBD::Patroni - DBI driver for PostgreSQL with Patroni cluster support
#
#  Copyright (c) 2025 Xavier Guimard
#
#  You may distribute under the terms of either the GNU General Public
#  License or the Artistic License, as specified in the Perl README file.

use strict;
use warnings;

package DBD::Patroni;

use DBI;
require DBD::Pg;

our $VERSION = '0.03';
our $drh     = undef;    # Driver handle
our $err     = 0;        # DBI error code
our $errstr  = '';       # DBI error string
our $state   = '';       # DBI state
our $rr_idx  = 0;        # Round-robin index for replica selection

# Load submodules
require DBD::Patroni::dr;
require DBD::Patroni::db;
require DBD::Patroni::st;

# DBI driver method - required for DBI->connect("dbi:Patroni:...")
sub driver {
    return $drh if $drh;
    my ( $class, $attr ) = @_;

    $class .= "::dr";

    $drh = DBI::_new_drh(
        $class,
        {
            Name        => 'Patroni',
            Version     => $VERSION,
            Attribution => 'DBD::Patroni by Xavier Guimard',
        }
    );
    return $drh;
}

# Discover Patroni cluster via REST API
sub _discover_cluster {
    my ( $urls, $timeout ) = @_;
    $timeout //= 3;

    require LWP::UserAgent;
    require JSON;

    my $ua = LWP::UserAgent->new(
        timeout   => $timeout,
        env_proxy => 1,
    );

    for my $url ( split /[,\s]+/, $urls ) {
        next unless $url;
        my $resp = $ua->get($url);
        next unless $resp->is_success;

        my $data = eval { JSON::decode_json( $resp->decoded_content ) };
        next if $@ or !$data->{members} or ref( $data->{members} ) ne 'ARRAY';

        my ($leader) = grep { $_->{role} eq 'leader' } @{ $data->{members} };
        my @replicas = grep { $_->{role} ne 'leader' } @{ $data->{members} };

        return ( $leader, @replicas ) if $leader;
    }
    return;
}

# Select a replica based on load balancing mode
sub _select_replica {
    my ( $replicas, $mode ) = @_;
    return undef unless $replicas && @$replicas;

    $mode //= 'round_robin';

    if ( $mode eq 'random' ) {
        return $replicas->[ int( rand(@$replicas) ) ];
    }
    elsif ( $mode eq 'leader_only' ) {
        return undef;
    }
    else {    # round_robin
        return $replicas->[ $rr_idx++ % @$replicas ];
    }
}

# Parse and extract Patroni parameters from DSN
sub _parse_dsn {
    my ($dsn) = @_;
    my %params;
    my @remaining;

    for my $part ( split /;/, $dsn ) {
        if ( $part =~ /^(patroni_url|patroni_lb|patroni_timeout)=(.*)$/i ) {
            $params{ lc($1) } = $2;
        }
        else {
            push @remaining, $part;
        }
    }

    return ( join( ';', @remaining ), \%params );
}

# Build DSN with host/port, cleaning up any existing host/port params
sub _build_dsn {
    my ( $dsn, $host, $port ) = @_;

    # Remove existing host/port parameters
    $dsn =~ s/(?:host|port)=[^;]*;?//gi;

    # Clean up multiple semicolons and leading/trailing semicolons
    $dsn =~ s/;+/;/g;
    $dsn =~ s/^;|;$//g;

    # Append new host/port
    return "$dsn;host=$host;port=$port";
}

# Detect read-only queries
sub _is_readonly {
    my $sql = shift;
    return 0 unless defined $sql;

    # SELECT or WITH ... SELECT (CTE)
    return $sql =~ /^\s*(SELECT|WITH\s+\w+.*?\bSELECT)\b/si ? 1 : 0;
}

# Detect connection errors
sub _is_connection_error {
    my $error = shift;
    return 0 unless $error;

    return 1
      if $error =~
/(?:c(?:o(?:nnection (?:re(?:fused|set)|timed out)|uld not connect)|annot execute .* in a read-only transaction)|t(?:he database system is (?:s(?:hutting down|tarting up)|in recovery mode)|erminating connection)|no(?: connection to the server|t accepting connections)|re(?:covery is in progress|ad-only transaction)|(?:server closed the|lost) connection|hot standby mode is disabled)/i;

    return 0;
}

# Execute with automatic retry on failure (shared helper)
sub _with_retry {
    my ( $dbh, $target, $code ) = @_;
    my $result;
    my $wantarray = wantarray;

    foreach my $attempt ( 0 .. 1 ) {
        my @results;
        eval {
            if ($wantarray) {
                @results = $code->();
            }
            else {
                $result = $code->();
            }
        };

        if ($@) {
            my $error = $@;

            # Only retry on connection errors, not SQL errors
            if ( _is_connection_error($error) && $attempt == 0 ) {
                warn
"DBD::Patroni: Connection error on $target, rediscovering cluster...\n";
                if ( DBD::Patroni::db::_rediscover_cluster($dbh) ) {
                    next;
                }
            }
            die $error;
        }
        return $wantarray ? @results : $result;
    }
}

1;

__END__

=head1 NAME

DBD::Patroni - DBI driver for PostgreSQL with Patroni cluster support

=head1 SYNOPSIS

    use DBI;

    # Standard DBI connection with patroni_url in DSN
    my $dbh = DBI->connect(
        "dbi:Patroni:dbname=mydb;patroni_url=http://patroni1:8008/cluster,http://patroni2:8008/cluster",
        $user, $password
    );

    # Or with attributes
    my $dbh = DBI->connect(
        "dbi:Patroni:dbname=mydb",
        $user, $password,
        {
            patroni_url => "http://patroni1:8008/cluster",
            patroni_lb  => "round_robin",
        }
    );

    # SELECT queries go to replica
    my $sth = $dbh->prepare("SELECT * FROM users WHERE id = ?");
    $sth->execute(1);

    # INSERT/UPDATE/DELETE queries go to leader
    $dbh->do("INSERT INTO users (name) VALUES (?)", undef, "John");

    $dbh->disconnect;

=head1 DESCRIPTION

DBD::Patroni is a DBI driver that wraps DBD::Pg and provides automatic
routing of queries to the appropriate node in a Patroni-managed PostgreSQL
cluster.

=head2 Features

=over 4

=item * Standard DBI interface - use DBI->connect("dbi:Patroni:...")

=item * Automatic leader discovery via Patroni REST API

=item * Read queries (SELECT) routed to replicas

=item * Write queries (INSERT, UPDATE, DELETE) routed to leader

=item * Configurable load balancing for replicas

=item * Automatic failover with retry on connection errors

=back

=head1 CONNECTION

    my $dbh = DBI->connect($dsn, $user, $pass, \%attr);

The DSN format is:

    dbi:Patroni:dbname=...;patroni_url=...;[other_pg_options]

All standard L<DBD::Pg> connection parameters are supported.

Patroni-specific parameters can be in the DSN or attributes hash.
Attributes hash takes precedence.

=head1 CONNECTION ATTRIBUTES

=over 4

=item patroni_url (required)

Comma-separated list of Patroni REST API endpoints.

=item patroni_lb

Load balancing mode: C<round_robin> (default), C<random>, or C<leader_only>.

=item patroni_timeout

HTTP timeout in seconds for Patroni API calls. Default: 3

=back

=head1 QUERY ROUTING

=over 4

=item * B<SELECT> and B<WITH...SELECT> go to replica

=item * All other queries go to leader

=back

=head1 FAILOVER

On connection failure, DBD::Patroni will:

=over 4

=item 1. Query Patroni API to discover current leader

=item 2. Reconnect to new leader/replica

=item 3. Retry the failed operation

=back

=head1 SEE ALSO

L<DBD::Pg>, L<DBI>

=head1 AUTHOR

Xavier Guimard

=head1 LICENSE

Same as Perl itself.

=cut
