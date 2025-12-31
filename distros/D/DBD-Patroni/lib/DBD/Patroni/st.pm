#  -*-cperl-*-
#
#  DBD::Patroni::st - Statement class for DBD::Patroni
#
#  Copyright (c) 2025 Xavier Guimard
#
#  You may distribute under the terms of either the GNU General Public
#  License or the Artistic License, as specified in the Perl README file.

package DBD::Patroni::st;

use strict;
use warnings;

use DBD::Patroni;

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
    return unless $sth->{patroni_real_sth};
    return $sth->{patroni_real_sth}->fetch;
}

sub fetchrow_array {
    my $sth = shift;
    return unless $sth->{patroni_real_sth};
    return $sth->{patroni_real_sth}->fetchrow_array;
}

sub fetchrow_arrayref {
    my $sth = shift;
    return unless $sth->{patroni_real_sth};
    return $sth->{patroni_real_sth}->fetchrow_arrayref;
}

sub fetchrow_hashref {
    my $sth = shift;
    return unless $sth->{patroni_real_sth};
    return $sth->{patroni_real_sth}->fetchrow_hashref(@_);
}

sub fetchall_arrayref {
    my $sth = shift;
    return unless $sth->{patroni_real_sth};
    return $sth->{patroni_real_sth}->fetchall_arrayref(@_);
}

sub fetchall_hashref {
    my $sth = shift;
    return unless $sth->{patroni_real_sth};
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
    return unless $sth->{patroni_real_sth};
    return $sth->{patroni_real_sth}->bind_param(@_);
}

sub bind_param_inout {
    my $sth = shift;
    return unless $sth->{patroni_real_sth};
    return $sth->{patroni_real_sth}->bind_param_inout(@_);
}

sub bind_col {
    my $sth = shift;
    return unless $sth->{patroni_real_sth};
    return $sth->{patroni_real_sth}->bind_col(@_);
}

sub bind_columns {
    my $sth = shift;
    return unless $sth->{patroni_real_sth};
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
