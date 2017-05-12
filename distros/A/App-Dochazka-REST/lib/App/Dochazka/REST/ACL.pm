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
#
# ACL routines

package App::Dochazka::REST::ACL;

use strict;
use warnings;

use App::CELL qw( $CELL $log );
use App::Dochazka::REST::Model::Employee;
use Data::Dumper;
use Params::Validate qw( :all );



=head1 NAME

App::Dochazka::REST::ACL - ACL module





=head1 DESCRIPTION

This module provides helper code for ACL checks.

=cut




=head1 EXPORTS

=cut

use Exporter qw( import );
our @EXPORT_OK = qw( 
    check_acl 
    check_acl_context 
    acl_check_is_me 
    acl_check_is_my_report
    acl_check_iid_lid
);



=head1 PACKAGE VARIABLES

The 'check_acl' routine uses a hash to look up which privlevels 
satisfy a given ACL profile.

=cut

my %acl_lookup = (
    'admin' => { 'passerby' => '', 'inactive' => '', 'active' => '', 'admin' => '' },
    'active' => { 'passerby' => '', 'inactive' => '', 'active' => '' },
    'inactive' => { 'passerby' => '', 'inactive' => '' },
    'passerby' => { 'passerby' => '', },
);




=head1 FUNCTIONS

=head2 check_acl

Takes a PARAMHASH with two properties: C<profile> and C<privlevel>. Their
values are assumed to be the ACL profile of a resource and the privlevel of an
employee, respectively. The function returns a true or false value indicating
whether that employee satisfies the given ACL profile.

In addition to the usual privlevels, the C<profile> property can be
'forbidden', in which case the function returns false for all possible values
of C<privlevel>.

=cut

sub check_acl {
    my ( %ARGS ) = validate( @_, {
        profile => { type => SCALAR, regex => qr/^(passerby)|(inactive)|(active)|(admin)|(forbidden)$/ }, 
        privlevel => { type => SCALAR, regex => qr/^(passerby)|(inactive)|(active)|(admin)$/ }, 
    } );
    return exists( $acl_lookup{$ARGS{privlevel}}->{$ARGS{profile}} )
        ? 1
        : 0;
}


=head2 check_acl_context

Check ACL and compare with eid in request body. This routine is designed
for resources that have an ACL profile of 'active'. If the request body
contains an 'eid' property, it is checked against the current user's EID.  If
they are different and the current user's priv is 'active',
DOCHAZKA_FORBIDDEN_403 is returned; otherwise, an OK status is returned to
signify that the check passed.

If the request body does not contain an 'eid' property, it is added.

=cut

sub check_acl_context {
    my $context = shift;
    my $current_eid = $context->{'current'}->{'eid'};
    my $current_priv = $context->{'current_priv'};
    if ( $current_priv eq 'passerby' or $current_priv eq 'inactive' ) {
        return $CELL->status_err( 'DOCHAZKA_FORBIDDEN_403' );
    }
    if ( $context->{'request_entity'}->{'eid'} ) {
        my $desired_eid = $context->{'request_entity'}->{'eid'};
        if ( $desired_eid != $current_eid ) {
            return $CELL->status_err( 'DOCHAZKA_FORBIDDEN_403' ) if $current_priv eq 'active';
        }
    } else {
        $context->{'request_entity'}->{'eid'} = $current_eid;
    }
    return $CELL->status_ok('DOCHAZKA_ACL_CHECK');
}


=head2 acl_check_is_me

Takes a property and a value. The property can be 'eid', 'nick', or 'sec_id'.
This routine checks the eid/nick/sec_id against C<< $self->context->{'current_obj'} >>
(the current employee object) and returns a boolean value answering the
question "is this me?"

=cut

sub acl_check_is_me {
    my $self = shift;
    my %pl = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::acl_check_is_me with " . Dumper( \%pl ) );

    my $ce = $self->context->{'current_obj'};
    my $priv = $self->context->{'current_priv'};

    return 1 if $priv eq 'admin';

    if ( my $eid = $pl{'eid'} ) {
        $log->debug( "acl_check_is_me: I am EID " . $ce->eid . " - checking against $eid" );
        return ( defined($eid) and defined($ce->eid) and $eid == $ce->eid );
    } elsif ( my $nick = $pl{'nick'} ) {
        return ( defined($nick) and defined($ce->nick) and $nick eq $ce->nick );
    } elsif ( my $sec_id = $pl{'sec_id'} ) {
        return ( defined($sec_id) and defined($ce->sec_id) and $sec_id eq $ce->sec_id );
    }

    die "AAAAGAGAGAHHHHAHAHAAJJAJAJAJAAHAHAHA! " . Dumper( \%pl );
}


=head2 acl_check_is_my_report

Takes a property and a value. The property can be 'eid', 'nick', or 'sec_id'.
This routine first gets the employee object corresponding to the
eid/nick/sec_id and then checks if the current employee is that
employee's supervisor.

=cut

sub acl_check_is_my_report {
    my $self = shift;
    my %pl = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::acl_check_is_my_report with " . Dumper( \%pl ) );

    my $ce = $self->context->{'current_obj'};
    my $priv = $self->context->{'current_priv'};
    my $emp = App::Dochazka::REST::Model::Employee->spawn;
    my $conn = $self->context->{'dbix_conn'};
    my $status;

    return 1 if $priv eq 'admin';

    if ( my $eid = $pl{'eid'} ) {
        $log->debug( "acl_check_is_my_report: given EID $eid" );
        $status = $emp->load_by_eid( $conn, $eid );
    } elsif ( my $nick = $pl{'nick'} ) {
        $log->debug( "acl_check_is_my_report: given nick $nick" );
        $status = $emp->load_by_nick( $conn, $nick );
    } elsif ( my $sec_id = $pl{'sec_id'} ) {
        $log->debug( "acl_check_is_my_report: given sec_id $sec_id" );
        $status = $emp->load_by_sec_id( $conn, $sec_id );
    } else {
        die "AAAGAAHHAHAHAAJJAJAJAHAHA! " . Dumper( \%pl );
    }

    if ( $status->not_ok ) {
        $log->error( "acl_check_is_my_report: employee lookup failed (" . $status->text . ")" );
        return 0;
    }

    $emp = $status->payload;
    
    if ( defined($emp->supervisor) and defined($ce->eid) and $emp->supervisor eq $ce->eid ) {
        $log->debug( "acl_check_is_my_report: I am the supervisor of ->" . $emp->nick . "<-" );
        return 1;
    }

    return 0;
}


1;
