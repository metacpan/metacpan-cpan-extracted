# ************************************************************************* 
# Copyright (c) 2014-2017, SUSE LLC
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

package App::Dochazka::REST::Model::Tempintvl;

use 5.012;
use strict;
use warnings;

use App::CELL qw( $CELL $log $site );
use App::Dochazka::REST::Model::Shared qw(
    canonicalize_tsrange
    cud
    load_multiple
    tsrange_intersection
);
use Data::Dumper;
use Params::Validate qw( :all );

# we get 'spawn', 'reset', and accessors from parent
use parent 'App::Dochazka::Common::Model::Tempintvl';




=head1 NAME

App::Dochazka::REST::Model::Tempintvl - tempintvl data model




=head1 SYNOPSIS

    use App::Dochazka::REST::Model::Tempintvl;

    ...


=head1 DESCRIPTION

A description of the tempinvl data model follows.


=head2 Tempintvls in the database

    CREATE TABLE tempintvls (
        int_id  serial PRIMARY KEY,
        tiid    integer NOT NULL,
        intvl   tstzrange NOT NULL
    )



=head1 EXPORTS

This module provides the following exports:

=cut

use Exporter qw( import );
our @EXPORT_OK = qw( 
    fetch_tempintvls_by_tiid_and_tsrange
);



=head1 METHODS


=head2 delete

Attempts to the delete the record (in the tempintvls table) corresponding
to the object. Returns a status object.

=cut

sub delete {
    my $self = shift;
    my ( $context ) = validate_pos( @_, { type => HASHREF } );

    my $status = cud(
        conn => $context->{'dbix_conn'},
        eid => $context->{'current'}->{'eid'},
        object => $self,
        sql => $site->SQL_TEMPINTVL_DELETE_SINGLE,
        attrs => [ 'int_id' ],
    );
    $self->reset( int_id => $self->{int_id} ) if $status->ok;

    return $status;
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
        sql => $site->SQL_TEMPINTVL_INSERT,
        attrs => [ 'tiid', 'intvl' ],
    );

    return $status; 
}



=head1 FUNCTIONS


=head2 fetch_tempintvls_by_tiid_and_tsrange

Given a L<DBIx::Connector> object, a tiid and a tsrange, return the set
(array) of C<tempintvl> objects that match the tiid and tsrange.

=cut

sub fetch_tempintvls_by_tiid_and_tsrange {
    my ( $conn, $tiid, $tsrange ) = validate_pos( @_,
        { isa => 'DBIx::Connector' },
        { type => SCALAR },
        { type => SCALAR },
    );

    my $status = canonicalize_tsrange( $conn, $tsrange );
    return $status unless $status->ok;
    $tsrange = $status->payload;

    $status = load_multiple(
        conn => $conn,
        class => __PACKAGE__,
        sql => $site->SQL_TEMPINTVLS_SELECT_BY_TIID_AND_TSRANGE,
        keys => [ $tiid, $tsrange, $site->DOCHAZKA_INTERVAL_SELECT_LIMIT ],
    );
    return $status unless 
        ( $status->ok and $status->code eq 'DISPATCH_RECORDS_FOUND' ) or
        ( $status->level eq 'NOTICE' and $status->code eq 'DISPATCH_NO_RECORDS_FOUND' );
    my $whole_intervals = $status->payload;

    $status = load_multiple(
        conn => $conn,
        class => __PACKAGE__,
        sql => $site->SQL_TEMPINTVLS_SELECT_BY_TIID_AND_TSRANGE_PARTIAL_INTERVALS,
        keys => [ $tiid, $tsrange, $tiid, $tsrange ],
    );
    return $status unless 
        ( $status->ok and $status->code eq 'DISPATCH_RECORDS_FOUND' ) or
        ( $status->level eq 'NOTICE' and $status->code eq 'DISPATCH_NO_RECORDS_FOUND' );
    my $partial_intervals = $status->payload;

    map 
    { 
        $_->intvl( 
            tsrange_intersection( $conn, $tsrange, $_->intvl )
        );
    } ( @$partial_intervals );
    
    my @result_set = ();
    push @result_set, @$whole_intervals, @$partial_intervals;

    # But now the intervals are out of order
    my @sorted_tmpintvls = sort { $a->intvl cmp $b->intvl } @result_set;
    return \@sorted_tmpintvls;

    return \sort { $a->intvl cmp $b->intvl } @result_set;

}



=head1 AUTHOR

Nathan Cutler, C<< <presnypreklad@gmail.com> >>

=cut 

1;


