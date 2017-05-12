# ************************************************************************* 
# Copyright (c) 2014-2015, SUSE LLC
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 
# 3. Neither the name of SUSE LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# ************************************************************************* 

package App::Dochazka::REST::Model::Schedintvls;

use 5.012;
use strict;
use warnings;
use App::CELL qw( $CELL $log $meta $site );
use App::Dochazka::REST::ConnBank qw( $dbix_conn );
use App::Dochazka::REST::Model::Shared;
use Data::Dumper;
use JSON;
use Params::Validate qw( :all );
use Try::Tiny;

# we get 'spawn', 'reset', and accessors from parent
use parent 'App::Dochazka::Common::Model::Schedintvls';




=head1 NAME

App::Dochazka::REST::Model::Schedintvls - object class for "scratch schedules"




=head1 SYNOPSIS

    use App::Dochazka::REST::Model::Schedintvls;

    ...




=head1 METHODS


=head2 populate

Populate the schedintvls object (called automatically by 'reset' method
which is, in turn, called automatically by 'spawn')

=cut

sub populate {
    my $self = shift;

    my $ss = _next_scratch_sid();
    $log->debug( "Got next scratch SID: $ss" );
    $self->{'ssid'} = $ss;
    return;
}


=head2 load

Instance method. Once the scratch intervals are inserted, we have a fully
populated object. This method runs each scratch interval through the stored
procedure 'translate_schedintvl' -- upon success, it creates a new attribute,
C<< $self->{schedule} >>, containing the translated intervals.

=cut

sub load {
    my $self = shift;
    my ( $conn ) = validate_pos( @_,
        { isa => 'DBIx::Connector' }
    );

    my $status;
    my @results;
    try {
        $conn->run( fixup => sub {
            # prepare and execute statement
            my $sth = $_->prepare( $site->SQL_SCHEDINTVLS_SELECT );
            $sth->execute( $self->{'ssid'} );

            # since the statement returns n rows, we use a loop to fetch them
            while( defined( my $tmpres = $sth->fetchrow_hashref() ) ) {
                push( @results, $tmpres );
            }
        } );
    } catch {
        $status = $CELL->status_err( 'DOCHAZKA_DBI_ERR', args => [ $_ ] );
    };
    return $status if $status;

    # success: add a new attribute with the translated intervals
    $self->{schedule} = \@results;

    return $CELL->status_ok( "Schedule has " . scalar( @results ) . " rows" );
}
    


=head2 insert

Instance method. Attempts to INSERT one or more records (one for each
interval in the 'intvls' attribute) into the 'schedintvls' table.
Field values are taken from the object. Returns a status object.

=cut

sub insert {
    my $self = shift;
    my ( $conn ) = validate_pos( @_,
        { isa => 'DBIx::Connector' }
    );

    # the insert operation needs to take place within a transaction,
    # because all the intervals are inserted in one go
    my $status;
    try {
        $conn->txn( fixup => sub {
            my $sth = $_->prepare( $site->SQL_SCHEDINTVLS_INSERT );
            my $intvls;

            # the next sequence value is already in $self->{ssid}
            $sth->bind_param( 1, $self->{ssid} );

            # execute SQL_SCHEDINTVLS_INSERT for each element of $self->{intvls}
            map {
                $sth->bind_param( 2, $_ );
                $sth->execute;
                push @$intvls, $_;
            } @{ $self->{intvls} };
            $status = $CELL->status_ok( 
                'DOCHAZKA_SCHEDINTVLS_INSERT_OK', 
                payload => {
                    intervals => $intvls,
                    ssid => $self->{ssid},
                }
            );
        } );
    } catch {
        $status = $CELL->status_err( 'DOCHAZKA_DBI_ERR', args => [ $_ ] );
    };
    return $status;
}


=head2 update

There is no update method for schedintvls. Instead, delete and re-create.


=head2 delete

Instance method. Once we are done with the scratch intervals, they can be deleted.
Returns a status object.

=cut

sub delete {
    my $self = shift;
    my ( $conn ) = validate_pos( @_,
        { isa => 'DBIx::Connector' }
    );

    my $status;
    try {
        $conn->run( fixup => sub {
            my $sth = $_->prepare( $site->SQL_SCHEDINTVLS_DELETE );
            $sth->bind_param( 1, $self->ssid );
            $sth->execute;
            my $rows = $sth->rows;
            if ( $rows > 0 ) {
                $status = $CELL->status_ok( 'DOCHAZKA_RECORDS_DELETED', args => [ $rows ] );
            } elsif ( $rows == 0 ) {
                $status = $CELL->status_warn( 'DOCHAZKA_RECORDS_DELETED', args => [ $rows ] );
            } else {
                die( "\$sth->rows returned a weird value $rows" );
            }
        } );
    } catch {
        $status = $CELL->status_err( 'DOCHAZKA_DBI_ERR', args => [ $_ ] );
    };
    return $status;
}


=head2 json

Instance method. Returns a JSON string representation of the schedule.

=cut

sub json {
    my ( $self ) = @_;

    return JSON->new->utf8->canonical(1)->encode( $self->{schedule} );
}




=head1 FUNCTIONS

=head2 Exported functions



=head2 Non-exported functions

=head3 _next_scratch_sid

Get next value from the scratch_sid_seq sequence

=cut

sub _next_scratch_sid {
    my $val;
    my $status;
    try {
        $dbix_conn->run( fixup => sub {
            ( $val ) = $_->selectrow_array( $site->SQL_SCRATCH_SID );
        } );    
    } catch {
        $status = $CELL->status_err( 'DOCHAZKA_DBI_ERR', args => [ $_ ] );
    };
    return if $status;
    return $val;
}



=head1 AUTHOR

Nathan Cutler, C<< <presnypreklad@gmail.com> >>

=cut 

1;

