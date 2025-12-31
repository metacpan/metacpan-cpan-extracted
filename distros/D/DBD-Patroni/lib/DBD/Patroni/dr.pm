#  -*-cperl-*-
#
#  DBD::Patroni::dr - Driver class for DBD::Patroni
#
#  Copyright (c) 2025 Xavier Guimard
#
#  You may distribute under the terms of either the GNU General Public
#  License or the Artistic License, as specified in the Perl README file.

package DBD::Patroni::dr;

use strict;
use warnings;

use DBI;
use DBD::Patroni;

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
    my $leader_dsn = DBD::Patroni::_build_dsn( $dsn, $leader->{host}, $leader->{port} );

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
            my $replica_dsn = DBD::Patroni::_build_dsn( $dsn, $replica->{host}, $replica->{port} );

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

sub DESTROY { }

1;
