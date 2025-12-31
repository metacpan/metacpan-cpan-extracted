#  -*-cperl-*-
#
#  DBD::Patroni::db - Database class for DBD::Patroni
#
#  Copyright (c) 2025 Xavier Guimard
#
#  You may distribute under the terms of either the GNU General Public
#  License or the Artistic License, as specified in the Perl README file.

package DBD::Patroni::db;

use strict;
use warnings;

use DBI;
use DBD::Patroni;
use Scalar::Util qw(refaddr);

our $imp_data_size = 0;

# Rediscover cluster and reconnect
sub _rediscover_cluster {
    my $dbh    = shift;
    my $config = $dbh->{patroni_config};

    # Close old connections
    eval { $dbh->{patroni_leader_dbh}->disconnect }
      if $dbh->{patroni_leader_dbh};
    if (   $dbh->{patroni_replica_dbh}
        && refaddr( $dbh->{patroni_replica_dbh} ) != refaddr( $dbh->{patroni_leader_dbh} ) )
    {
        eval { $dbh->{patroni_replica_dbh}->disconnect };
    }

    # Rediscover cluster
    my ( $leader, @replicas ) =
      DBD::Patroni::_discover_cluster( $config->{patroni_url},
        $config->{patroni_timeout} );

    return 0 unless $leader;

    # Rebuild leader DSN
    my $leader_dsn = DBD::Patroni::_build_dsn( $config->{dsn}, $leader->{host}, $leader->{port} );

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
            my $replica_dsn = DBD::Patroni::_build_dsn( $config->{dsn}, $replica->{host}, $replica->{port} );

            $dbh->{patroni_replica_dbh} =
              DBI->connect( "dbi:Pg:$replica_dsn", $config->{user},
                $config->{pass},
                { %{ $config->{attr} }, RaiseError => 0, PrintError => 0 } );
        }
    }
    $dbh->{patroni_replica_dbh} //= $dbh->{patroni_leader_dbh};

    return 1;
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
        && refaddr( $dbh->{patroni_replica_dbh} ) != refaddr( $dbh->{patroni_leader_dbh} ) )
    {
        $dbh->{patroni_replica_dbh}->disconnect;
    }
    $dbh->STORE( Active => 0 );
    return 1;
}

# Transactions: always on leader
sub begin_work {
    my $dbh = shift;
    return unless $dbh->{patroni_leader_dbh};
    return $dbh->{patroni_leader_dbh}->begin_work;
}

sub commit {
    my $dbh = shift;
    return unless $dbh->{patroni_leader_dbh};
    return $dbh->{patroni_leader_dbh}->commit;
}

sub rollback {
    my $dbh = shift;
    return unless $dbh->{patroni_leader_dbh};
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
          && refaddr( $dbh->{patroni_replica_dbh} ) != refaddr( $dbh->{patroni_leader_dbh} );
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
