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

package App::Dochazka::REST::Model::Lock;

use 5.012;
use strict;
use warnings;
use App::CELL qw( $CELL $log $meta $site );
use App::Dochazka::REST::Model::Shared qw( cud load load_multiple );
use Data::Dumper;
use Params::Validate qw( :all );

# we get 'spawn', 'reset', and accessors from parent
use parent 'App::Dochazka::Common::Model::Lock';




=head1 NAME

App::Dochazka::REST::Model::Lock - lock data model




=head1 SYNOPSIS

    use App::Dochazka::REST::Model::Lock;

    ...


=head1 DESCRIPTION

A description of the lock data model follows.


=head2 Locks in the database

    CREATE TABLE locks (
        lid     serial PRIMARY KEY,
        eid     integer REFERENCES Employees (EID),
        intvl   tsrange NOT NULL,
        remark  text
    )

There is also a stored procedure, C<fully_locked>, that takes an EID
and a tsrange, and returns a boolean value indicating whether or not
that period is fully locked for the given employee.


=head3 Locks in the Perl API

# FIXME: MISSING VERBIAGE




=head1 EXPORTS

This module provides the following exports:

=cut

use Exporter qw( import );
our @EXPORT_OK = qw( 
    count_locks_in_tsrange
    fetch_locks_by_eid_and_tsrange
    lid_exists 
);



=head1 METHODS


=head2 load_by_lid

Instance method. Given an LID, loads a single lock into the object, rewriting
whatever was there before.  Returns a status object.

=cut

sub load_by_lid {
    my $self = shift;
    my ( $conn, $lid ) = validate_pos( @_, 
        { isa => 'DBIx::Connector' },
        { type => SCALAR },
    );

    return load(
        conn => $conn,
        class => __PACKAGE__,
        sql => $site->SQL_LOCK_SELECT_BY_LID,
        keys => [ $lid ],
    );
}
    


=head2 insert

Instance method. Attempts to INSERT a record. Field values are taken from the
object. Returns a status object.

=cut

sub insert { 
    my $self = shift;
    my ( $context ) = validate_pos( @_, { type => HASHREF } );

    my $status = cud( 
        conn => $context->{'dbix_conn'},
        eid => $context->{'current'}->{'eid'},
        object => $self, 
        sql => $site->SQL_LOCK_INSERT, 
        attrs => [ 'eid', 'intvl', 'remark' ],
    );

    return $status; 
}


=head2 update

Instance method. Attempts to UPDATE a record. Field values are taken from the
object. Returns a status object.

=cut

sub update { 
    my $self = shift;
    my ( $context ) = validate_pos( @_, { type => HASHREF } );

    return $CELL->status_err( 'DOCHAZKA_MALFORMED_400' ) unless $self->{'lid'};

    my $status = cud( 
        conn => $context->{'dbix_conn'},
        eid => $context->{'current'}->{'eid'},
        object => $self, 
        sql => $site->SQL_LOCK_UPDATE, 
        attrs => [ 'eid', 'intvl', 'remark', 'lid' ],
    );

    return $status; 
}


=head2 delete

Instance method. Attempts to DELETE a record. Field values are taken from the
object. Returns a status object.

=cut

sub delete { 
    my $self = shift;
    my ( $context ) = validate_pos( @_, { type => HASHREF } );

    my $status = cud( 
        conn => $context->{'dbix_conn'},
        eid => $context->{'current'}->{'eid'},
        object => $self, 
        sql => $site->SQL_LOCK_DELETE, 
        attrs => [ 'lid' ],
    );
    $self->reset( lid => $self->{lid} ) if $status->ok;

    #$log->debug( "Returning from " . __PACKAGE__ . "::delete with status code " . $status->code ); 
    return $status; 
}



=head1 FUNCTIONS


=head2 lid_exists

Boolean

=cut

BEGIN {
    no strict 'refs';
    *{'lid_exists'} = App::Dochazka::REST::Model::Shared::make_test_exists( 'lid' );
}


=head2 fetch_locks_by_eid_and_tsrange

Given a L<DBIx::Connector> object, an EID, and a tsrange, returns a status
object. Upon successfully finding one or more locks, the payload will 
be an ARRAYREF of lock records.

=cut

sub fetch_locks_by_eid_and_tsrange {
    my ( $conn, $eid, $tsrange ) = validate_pos( @_,
        { isa => 'DBIx::Connector' },
        { type => SCALAR },
        { type => SCALAR, optional => 1 },
    );

    return load_multiple(
        conn => $conn,
        class => __PACKAGE__,
        sql => $site->SQL_LOCK_SELECT_BY_EID_AND_TSRANGE,
        keys => [ $eid, $tsrange ],
    );
}


=head2 count_locks_in_tsrange

Given a L<DBIx::Connector> object, an EID, and a tsrange, returns a status 
object. If the level is OK, the payload can be expected to contain an integer
representing the number of locks that overlap (contain points in common) with
this tsrange.

=cut

sub count_locks_in_tsrange {
    my ( $conn, $eid, $tsrange ) = validate_pos( @_,
        { isa => 'DBIx::Connector' },
        { type => SCALAR },
        { type => SCALAR, optional => 1 },
    );

    my $status = fetch_locks_by_eid_and_tsrange( $conn, $eid, $tsrange );
    if ( $status->ok ) {
        my $count = @{ $status->payload };
        return $CELL->status_ok( "DOCHAZKA_NUMBER_OF_LOCKS", payload => $count );
    }
    if ( $status->level eq 'NOTICE' and $status->code eq 'DISPATCH_NO_RECORDS_FOUND' ) {
        return $CELL->status_ok( "DOCHAZKA_NUMBER_OF_LOCKS", payload => 0 );
    }
    return $status;
}


=head1 AUTHOR

Nathan Cutler, C<< <presnypreklad@gmail.com> >>

=cut 

1;


