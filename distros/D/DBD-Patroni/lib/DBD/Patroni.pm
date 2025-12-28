#  -*-cperl-*-
#
#  DBD::Patroni - DBI driver for PostgreSQL with Patroni cluster support
#
#  Copyright (c) 2024 Xavier Guimard
#
#  You may distribute under the terms of either the GNU General Public
#  License or the Artistic License, as specified in the Perl README file.

use strict;
use warnings;

package DBD::Patroni;

use DBI;
require DBD::Pg;

our $VERSION = '0.02';
our $drh     = undef;    # Driver handle
our $err     = 0;        # DBI error code
our $errstr  = '';       # DBI error string
our $state   = '';       # DBI state
our $rr_idx  = 0;        # Round-robin index for replica selection

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

# ====== DRIVER ======
package DBD::Patroni::dr;

our $imp_data_size = 0;

sub connect {
    my ( $drh, $dsn, $user, $pass, $attr ) = @_;

    $attr //= {};

    # Parse DSN for Patroni parameters
    my ( $clean_dsn, $dsn_params ) = DBD::Patroni::_parse_dsn($dsn);
    $dsn = $clean_dsn;

    # Extract Patroni-specific attributes (attr takes precedence over DSN)
    my $patroni_url = delete $attr->{patroni_url} // $dsn_params->{patroni_url};
    my $patroni_lb  = delete $attr->{patroni_lb}  // $dsn_params->{patroni_lb}
      // 'round_robin';
    my $patroni_timeout = delete $attr->{patroni_timeout}
      // $dsn_params->{patroni_timeout} // 3;

    unless ($patroni_url) {
        $DBD::Patroni::errstr = 'patroni_url is required';
        return;
    }

    # Discover cluster
    my ( $leader, @replicas ) =
      DBD::Patroni::_discover_cluster( $patroni_url, $patroni_timeout );

    unless ($leader) {
        $DBD::Patroni::errstr = "Cannot discover cluster from: $patroni_url";
        return;
    }

    # Build leader DSN
    my $leader_dsn = $dsn;
    $leader_dsn =~ s/(?:host|port)=[^;]*;?//gi;
    $leader_dsn .= ";host=$leader->{host};port=$leader->{port}";

    # Connect to leader via DBD::Pg
    my $leader_dbh =
      DBI->connect( "dbi:Pg:$leader_dsn", $user, $pass,
        { %$attr, RaiseError => 0, PrintError => 0 } );

    unless ($leader_dbh) {
        $DBD::Patroni::errstr = "Cannot connect to leader: $DBI::errstr";
        return;
    }

    # Connect to replica (if available and not leader_only mode)
    my $replica_dbh;
    if ( @replicas && $patroni_lb ne 'leader_only' ) {
        my $replica = DBD::Patroni::_select_replica( \@replicas, $patroni_lb );
        if ($replica) {
            my $replica_dsn = $dsn;
            $replica_dsn =~ s/(?:host|port)=[^;]*;?//gi;
            $replica_dsn .= ";host=$replica->{host};port=$replica->{port}";

            $replica_dbh =
              DBI->connect( "dbi:Pg:$replica_dsn", $user, $pass,
                { %$attr, RaiseError => 0, PrintError => 0 } );
        }
    }
    $replica_dbh //= $leader_dbh;

    # Create the DBI database handle
    my ( $outer, $dbh ) = DBI::_new_dbh(
        $drh,
        {
            Name => $dsn,
        }
    );

    # Store our private data
    $dbh->{patroni_leader_dbh}  = $leader_dbh;
    $dbh->{patroni_replica_dbh} = $replica_dbh;
    $dbh->{patroni_config}      = {
        dsn             => $dsn,
        user            => $user,
        pass            => $pass,
        attr            => $attr,
        patroni_url     => $patroni_url,
        patroni_lb      => $patroni_lb,
        patroni_timeout => $patroni_timeout,
    };

    # Copy attributes from leader handle
    $dbh->STORE( Active     => 1 );
    $dbh->STORE( AutoCommit => $leader_dbh->{AutoCommit} );

    return $outer;
}

sub data_sources {
    return ("dbi:Patroni:");
}

sub disconnect_all { }

sub DESTROY { undef }

1;

# ====== DATABASE ======
package DBD::Patroni::db;

our $imp_data_size = 0;

# Rediscover cluster and reconnect
sub _rediscover_cluster {
    my $dbh    = shift;
    my $config = $dbh->{patroni_config};

    # Close old connections
    eval { $dbh->{patroni_leader_dbh}->disconnect }
      if $dbh->{patroni_leader_dbh};
    if (   $dbh->{patroni_replica_dbh}
        && $dbh->{patroni_replica_dbh} ne $dbh->{patroni_leader_dbh} )
    {
        eval { $dbh->{patroni_replica_dbh}->disconnect };
    }

    # Rediscover cluster
    my ( $leader, @replicas ) =
      DBD::Patroni::_discover_cluster( $config->{patroni_url},
        $config->{patroni_timeout} );

    return 0 unless $leader;

    # Rebuild leader DSN
    my $leader_dsn = $config->{dsn};
    $leader_dsn =~ s/(?:host|port)=[^;]*;?//gi;
    $leader_dsn .= ";host=$leader->{host};port=$leader->{port}";

    # Reconnect to leader
    $dbh->{patroni_leader_dbh} =
      DBI->connect( "dbi:Pg:$leader_dsn", $config->{user}, $config->{pass},
        { %{ $config->{attr} }, RaiseError => 0, PrintError => 0 } );

    return 0 unless $dbh->{patroni_leader_dbh};

    # Reconnect to replica
    if ( @replicas && $config->{patroni_lb} ne 'leader_only' ) {
        my $replica =
          DBD::Patroni::_select_replica( \@replicas, $config->{patroni_lb} );
        if ($replica) {
            my $replica_dsn = $config->{dsn};
            $replica_dsn =~ s/(?:host|port)=[^;]*;?//gi;
            $replica_dsn .= ";host=$replica->{host};port=$replica->{port}";

            $dbh->{patroni_replica_dbh} =
              DBI->connect( "dbi:Pg:$replica_dsn", $config->{user},
                $config->{pass},
                { %{ $config->{attr} }, RaiseError => 0, PrintError => 0 } );
        }
    }
    $dbh->{patroni_replica_dbh} //= $dbh->{patroni_leader_dbh};

    return 1;
}

# Execute with automatic retry on failure
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
            if ( DBD::Patroni::_is_connection_error($error) && $attempt == 0 ) {
                warn
"DBD::Patroni: Connection error on $target, rediscovering cluster...\n";
                if ( $dbh->_rediscover_cluster() ) {
                    next;
                }
            }
            die $error;
        }
        return $wantarray ? @results : $result;
    }
}

sub prepare {
    my ( $dbh, $statement, @attribs ) = @_;

    return unless defined $statement;

    my $is_readonly = DBD::Patroni::_is_readonly($statement);
    my $target      = $is_readonly ? 'replica' : 'leader';
    my $target_dbh =
      $is_readonly
      ? $dbh->{patroni_replica_dbh}
      : $dbh->{patroni_leader_dbh};

    my $real_sth = $target_dbh->prepare( $statement, @attribs );
    return unless $real_sth;

    # Create DBI statement handle
    my ( $outer, $sth ) = DBI::_new_sth(
        $dbh,
        {
            Statement => $statement,
        }
    );

    $sth->{patroni_real_sth}  = $real_sth;
    $sth->{patroni_target}    = $target;
    $sth->{patroni_statement} = $statement;

    return $outer;
}

sub do {
    my ( $dbh, $statement, $attr, @bind ) = @_;
    my $is_readonly = DBD::Patroni::_is_readonly($statement);
    my $target      = $is_readonly ? 'replica' : 'leader';

    my $result = DBD::Patroni::_with_retry(
        $dbh,
        $target,
        sub {
            my $handle =
                $is_readonly
              ? $dbh->{patroni_replica_dbh}
              : $dbh->{patroni_leader_dbh};
            my $rv = $handle->do( $statement, $attr, @bind );

            # Propagate error state from underlying handle
            unless ( defined $rv ) {
                my $err = $handle->errstr;
                if ( $err && DBD::Patroni::_is_connection_error($err) ) {
                    die $err;    # Will trigger retry
                }

                # Propagate error to our dbh
                $dbh->set_err( $handle->err, $err, $handle->state );
            }
            return $rv;
        }
    );

    return $result;
}

sub ping {
    my $dbh = shift;
    return $dbh->{patroni_leader_dbh}->ping if $dbh->{patroni_leader_dbh};
    return 0;
}

sub disconnect {
    my $dbh = shift;
    if ( $dbh->{patroni_leader_dbh} ) {
        $dbh->{patroni_leader_dbh}->disconnect;
    }
    if (   $dbh->{patroni_replica_dbh}
        && $dbh->{patroni_replica_dbh} ne $dbh->{patroni_leader_dbh} )
    {
        $dbh->{patroni_replica_dbh}->disconnect;
    }
    $dbh->STORE( Active => 0 );
    return 1;
}

# Transactions: always on leader
sub begin_work {
    my $dbh = shift;
    return $dbh->{patroni_leader_dbh}->begin_work;
}

sub commit {
    my $dbh = shift;
    return $dbh->{patroni_leader_dbh}->commit;
}

sub rollback {
    my $dbh = shift;
    return $dbh->{patroni_leader_dbh}->rollback;
}

# Delegate to leader
sub quote {
    my $dbh = shift;
    return $dbh->{patroni_leader_dbh}->quote(@_);
}

sub quote_identifier {
    my $dbh = shift;
    return $dbh->{patroni_leader_dbh}->quote_identifier(@_);
}

sub last_insert_id {
    my $dbh = shift;
    return $dbh->{patroni_leader_dbh}->last_insert_id(@_);
}

sub table_info {
    my $dbh = shift;
    return $dbh->{patroni_leader_dbh}->table_info(@_);
}

sub column_info {
    my $dbh = shift;
    return $dbh->{patroni_leader_dbh}->column_info(@_);
}

sub primary_key_info {
    my $dbh = shift;
    return $dbh->{patroni_leader_dbh}->primary_key_info(@_);
}

sub foreign_key_info {
    my $dbh = shift;
    return $dbh->{patroni_leader_dbh}->foreign_key_info(@_);
}

sub tables {
    my $dbh = shift;
    return $dbh->{patroni_leader_dbh}->tables(@_);
}

sub get_info {
    my $dbh = shift;
    return $dbh->{patroni_leader_dbh}->get_info(@_);
}

sub STORE {
    my ( $dbh, $attr, $val ) = @_;

    # Handle DBI standard attributes
    if ( $attr eq 'AutoCommit' ) {
        $dbh->{patroni_leader_dbh}->{AutoCommit} = $val
          if $dbh->{patroni_leader_dbh};
        $dbh->{patroni_replica_dbh}->{AutoCommit} = $val
          if $dbh->{patroni_replica_dbh}
          && $dbh->{patroni_replica_dbh} ne $dbh->{patroni_leader_dbh};
        $dbh->{AutoCommit} = $val;
        return 1;
    }

    if ( $attr eq 'Active' ) {
        $dbh->{Active} = $val;
        return 1;
    }

    if ( $attr =~ /^patroni_/ ) {
        $dbh->{$attr} = $val;
        return 1;
    }

    # Forward to leader dbh for other attributes
    if ( $dbh->{patroni_leader_dbh} ) {
        $dbh->{patroni_leader_dbh}->{$attr} = $val;
    }

    # Store in our hash for DBI attributes
    $dbh->{$attr} = $val;
    return 1;
}

sub FETCH {
    my ( $dbh, $attr ) = @_;

    if ( $attr =~ /^patroni_/ ) {
        return $dbh->{$attr};
    }

    # Handle DBI standard attributes
    if ( $attr eq 'AutoCommit' ) {
        return $dbh->{AutoCommit};
    }

    if ( $attr eq 'Active' ) {
        return $dbh->{Active};
    }

    # Forward to leader for other common attributes
    if ( $dbh->{patroni_leader_dbh} ) {
        return $dbh->{patroni_leader_dbh}->{$attr}
          if exists $dbh->{patroni_leader_dbh}->{$attr};
    }

    return $dbh->{$attr};
}

sub DESTROY {
    my $dbh = shift;
    $dbh->disconnect if $dbh->FETCH('Active');
}

1;

# ====== STATEMENT ======
package DBD::Patroni::st;

our $imp_data_size = 0;

sub execute {
    my ( $sth, @bind ) = @_;
    my $dbh    = $sth->{Database};
    my $target = $sth->{patroni_target};

    return DBD::Patroni::_with_retry(
        $dbh,
        $target,
        sub {
            my $real_sth = $sth->{patroni_real_sth};

            # Check if statement handle is still valid
            unless ( $real_sth
                && $real_sth->{Database}
                && $real_sth->{Database}{Active} )
            {
                # Re-prepare statement after reconnection
                my $handle =
                    $target eq 'replica'
                  ? $dbh->{patroni_replica_dbh}
                  : $dbh->{patroni_leader_dbh};
                $sth->{patroni_real_sth} =
                  $handle->prepare( $sth->{patroni_statement} );
                $real_sth = $sth->{patroni_real_sth};
            }
            my $rv = $real_sth->execute(@bind);

            # Check for connection errors that need retry
            unless ( defined $rv ) {
                my $err = $real_sth->errstr;
                if ( $err && DBD::Patroni::_is_connection_error($err) ) {
                    die $err;    # Will trigger retry
                }

                # Propagate error to our dbh
                $dbh->set_err( $real_sth->err, $err, $real_sth->state );
            }

            # Copy NUM_OF_FIELDS to our sth for DBI
            if ( $real_sth->{NUM_OF_FIELDS} ) {
                $sth->STORE( 'NUM_OF_FIELDS', $real_sth->{NUM_OF_FIELDS} );
            }
            return $rv;
        }
    );
}

sub fetch {
    my $sth = shift;
    return $sth->{patroni_real_sth}->fetch;
}

sub fetchrow_array {
    my $sth = shift;
    return $sth->{patroni_real_sth}->fetchrow_array;
}

sub fetchrow_arrayref {
    my $sth = shift;
    return $sth->{patroni_real_sth}->fetchrow_arrayref;
}

sub fetchrow_hashref {
    my $sth = shift;
    return $sth->{patroni_real_sth}->fetchrow_hashref(@_);
}

sub fetchall_arrayref {
    my $sth = shift;
    return $sth->{patroni_real_sth}->fetchall_arrayref(@_);
}

sub fetchall_hashref {
    my $sth = shift;
    return $sth->{patroni_real_sth}->fetchall_hashref(@_);
}

sub finish {
    my $sth = shift;
    return $sth->{patroni_real_sth}->finish if $sth->{patroni_real_sth};
    return 1;
}

sub rows {
    my $sth = shift;
    return $sth->{patroni_real_sth}->rows if $sth->{patroni_real_sth};
    return -1;
}

sub bind_param {
    my $sth = shift;
    return $sth->{patroni_real_sth}->bind_param(@_);
}

sub bind_param_inout {
    my $sth = shift;
    return $sth->{patroni_real_sth}->bind_param_inout(@_);
}

sub bind_col {
    my $sth = shift;
    return $sth->{patroni_real_sth}->bind_col(@_);
}

sub bind_columns {
    my $sth = shift;
    return $sth->{patroni_real_sth}->bind_columns(@_);
}

sub STORE {
    my ( $sth, $attr, $val ) = @_;

    if ( $attr =~ /^patroni_/ ) {
        $sth->{$attr} = $val;
        return 1;
    }

    return $sth->SUPER::STORE( $attr, $val );
}

sub FETCH {
    my ( $sth, $attr ) = @_;

    if ( $attr =~ /^patroni_/ ) {
        return $sth->{$attr};
    }

    # Delegate to real sth for common attributes
    if ( $sth->{patroni_real_sth} ) {
        my $real_sth = $sth->{patroni_real_sth};
        if ( $attr eq 'NAME' || $attr eq 'NAME_lc' || $attr eq 'NAME_uc' ) {
            return $real_sth->{$attr};
        }
        if ( $attr eq 'TYPE' || $attr eq 'PRECISION' || $attr eq 'SCALE' ) {
            return $real_sth->{$attr};
        }
        if ( $attr eq 'NULLABLE' || $attr eq 'NUM_OF_FIELDS' ) {
            return $real_sth->{$attr};
        }
        if ( $attr eq 'NUM_OF_PARAMS' ) {
            return $real_sth->{$attr};
        }
    }

    return $sth->SUPER::FETCH($attr);
}

sub DESTROY {
    my $sth = shift;
    $sth->{patroni_real_sth}->finish if $sth->{patroni_real_sth};
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
