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

package App::Dochazka::REST::Auth;

use strict;
use warnings;

use App::CELL qw( $CELL $log $meta $site );
use App::Dochazka::REST;
use App::Dochazka::REST::ConnBank qw( $dbix_conn conn_status );
use App::Dochazka::REST::ACL qw( check_acl );
use App::Dochazka::REST::LDAP qw( ldap_exists ldap_search ldap_auth );
use App::Dochazka::REST::Model::Employee qw( autocreate_employee nick_exists );
use Authen::Passphrase::SaltedDigest;
use Data::Dumper;
use Params::Validate qw(:all);
use Try::Tiny;
use Web::Machine::Util qw( create_header );
use Web::MREST::InitRouter qw( $resources );

# methods/attributes not defined in this module will be inherited from:
use parent 'Web::MREST::Entity';




=head1 NAME

App::Dochazka::REST::Auth - HTTP request authentication and authorization




=head1 DESCRIPTION

This package, which is between L<Web::MREST::Entity> and
L<Web::Dochazka::REST::Dispatch> in the chain of inheritance, provides the
'is_authorized' and 'forbidden' methods called by L<Web::Machine> on each
incoming HTTP request.




=head1 METHODS


=head2 is_authorized

This overrides the L<Web::Machine> method of the same name.

Authenticate the originator of the request, using HTTP Basic Authentication.
Upon successful authentication, check that the user (employee) exists in 
the database (create if necessary) and retrieve her EID. Push the EID and
current privilege level onto the context. Get the user's L<DBIx::Connector>
object and push that onto the context, too.

=cut

sub is_authorized {
    my ( $self, $auth_header ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::is_authorized" );
    
    # get database connection for this HTTP request
    App::Dochazka::REST::ConnBank::init_singleton();

    if ( ! $meta->META_DOCHAZKA_UNIT_TESTING ) {
        return 1 if $self->_validate_session;
    }
    if ( $auth_header ) {
        $log->debug("is_authorized: auth header is $auth_header" );
        my $username = $auth_header->username;
        my $password = $auth_header->password;
        my $auth_status = $self->_authenticate( $username, $password );
        if ( $auth_status->ok ) {
            my $emp = $auth_status->payload;
            $self->push_onto_context( { 
                current => $emp->TO_JSON,
                current_obj => $emp,
                current_priv => $emp->priv( $dbix_conn ),
                dbix_conn => $dbix_conn,
            } );
            $self->_init_session( $emp ) unless $meta->META_DOCHAZKA_UNIT_TESTING;
            return 1;
        } else {
            $log->error(
                "_authenticate returned non-OK status. The entire status object is " . 
                Dumper( $auth_status )
            );
        }
    }
    return create_header(
        'WWWAuthenticate' => [ 
            'Basic' => ( 
                realm => $site->DOCHAZKA_BASIC_AUTH_REALM 
            ) 
        ]
    ); 
}


=head3 _init_session

Initialize the session. Takes an employee object.

=cut

sub _init_session {
    my $self = shift;
    $log->debug( "Entering " . __PACKAGE__ . "::_init_session" );

    my ( $emp ) = validate_pos( @_, { type => HASHREF, can => 'eid' } );

    my $r = $self->request;
    my $ip_addr = $r->{'env'}->{'REMOTE_ADDR'};
    my $session = $r->{'env'}->{'psgix.session'};
    my $eid = $emp->eid;

    $session->{'eid'} = $eid;
    $session->{'ip_addr'} = $ip_addr;
    $session->{'last_seen'} = time;

    $log->info( "Initialized new session, EID $eid" );

    return;
}


=head3 _validate_session

Validate the session

=cut

sub _validate_session {
    my ( $self ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::_validate_session" );

    my $r = $self->request;

    my $remote_addr = $r->{'env'}->{'REMOTE_ADDR'};

    my $session = $r->{'env'}->{'psgix.session'};
    $log->debug( "Session is " . Dumper( $session ) );

    return 0 unless %$session;
    return 0 unless _is_fresh( $session->{'last_seen'} );
    return 0 unless $session->{'ip_addr'} eq $remote_addr;
    return 0 unless exists( $session->{'eid'} ) and $session->{'eid'};

    $log->info( "Detected valid existing session" .
        ", EID " . $session->{'eid'} .
        ", last seen " .  $session->{'last_seen'}
    );

    $session->{'last_seen'} = time;

    my $emp = App::Dochazka::REST::Model::Employee->load_by_eid( $dbix_conn, $session->{'eid'} )->payload;
    die "missing employee object in session management"
        unless $emp->isa( "App::Dochazka::REST::Model::Employee" );
    $self->push_onto_context( {
        current => $emp->TO_JSON,
        current_obj => $emp,
        current_priv => $emp->priv( $dbix_conn ),
        dbix_conn => $dbix_conn,
    } );

    return 1;
}


=head3 _is_fresh

Takes a single argument, which is assumed to be number of seconds since
epoch when the session was last seen. This is compared to "now" and if the
difference is greater than the DOCHAZKA_REST_SESSION_EXPIRATION_TIME site
parameter, the return value is false, otherwise true.

=cut

sub _is_fresh {
    $log->debug( "Entering " . __PACKAGE__ . "::_is_fresh" );
    my ( $last_seen ) = validate_pos( @_, { type => SCALAR } );
    if ( time - $last_seen > $site->DOCHAZKA_REST_SESSION_EXPIRATION_TIME ) {
        $log->error( "Session expired!" );
        return 0;
    }
    return 1;
}


=head3 _authenticate

Authenticate the nick associated with an incoming REST request.  Takes a nick
and a password (i.e., a set of credentials). Returns a status object, which
will have level 'OK' on success (with employee object in the payload), 'NOT_OK'
on failure. In the latter case, there will be a declared status.

=cut

sub _authenticate {
    my ( $self, $nick, $password ) = @_;
    my ( $status, $emp );
    $log->debug( "Entering " . __PACKAGE__ . "::_authenticate" );

    # empty credentials: fall back to demo/demo
    if ( $nick ) {
        $log->notice( "Login attempt from $nick" );
    } else {
        $log->notice( "Login attempt from (anonymous) -- defaulting to demo/demo" );
        $nick = 'demo'; 
        $password = 'demo'; 
    }

    $log->debug( "\$site->DOCHAZKA_LDAP is " . $site->DOCHAZKA_LDAP );

    # check if LDAP is enabled and if the employee exists in LDAP
    if ( ! $meta->META_DOCHAZKA_UNIT_TESTING and 
         $site->DOCHAZKA_LDAP and
         ldap_exists( $nick ) 
    ) {

        $log->info( "Detected authentication attempt from $nick, a known LDAP user" );
        #$log->debug( "Password provided: $password" );

        # - authenticate by LDAP bind
        if ( ldap_auth( $nick, $password ) ) {
            # successful LDAP auth: if the employee doesn't already exist in
            # the database, possibly autocreate
            $status = autocreate_employee( $dbix_conn, $nick );
            return $status unless $status->ok;
        } else {
            return $CELL->status_not_ok( 'DOCHAZKA_EMPLOYEE_AUTH' );
        }

        # load the employee object
        my $emp = App::Dochazka::REST::Model::Employee->load_by_nick( $dbix_conn, $nick )->payload;
        die "missing employee object in _authenticate" unless ref($emp) eq "App::Dochazka::REST::Model::Employee";
        return $CELL->status_ok( 'DOCHAZKA_EMPLOYEE_AUTH', payload => $emp );
    }

    # if not, authenticate against the password stored in the employee object.
    else {

        $log->notice( "Employee $nick not found in LDAP; reverting to internal auth" );

        # - check if this employee exists in database
        my $emp = nick_exists( $dbix_conn, $nick );

        if ( ! defined( $emp ) or ! $emp->isa( 'App::Dochazka::REST::Model::Employee' ) ) {
            $log->notice( "Rejecting login attempt from unknown user $nick" );
            $self->mrest_declare_status( explanation => "Authentication failed for user $nick", permanent => 1 );
            return $CELL->status_not_ok;
        }

        # - the password might be empty
        $password = '' unless defined( $password );
        my $passhash = $emp->passhash;
        $passhash = '' unless defined( $passhash );

        # - check password against passhash 
        my ( $ppr, $status );
        try {
            $ppr = Authen::Passphrase::SaltedDigest->new(
                algorithm => "SHA-512",
                salt_hex => $emp->salt,
                hash_hex => $emp->passhash,
            );
        } catch {
            $status = $CELL->status_err( 'DOCHAZKA_PASSPHRASE_EXCEPTION', args => [ $_ ] );
        };

        if ( ref( $ppr ) ne 'Authen::Passphrase::SaltedDigest' ) {
            $log->crit( "employee $nick has invalid passhash and/or salt" );
            return $CELL->status_not_ok( 'DOCHAZKA_EMPLOYEE_AUTH' );
        }
        if ( $ppr->match( $password ) ) {
            $log->notice( "Internal auth successful for employee $nick" );
            return $CELL->status_ok( 'DOCHAZKA_EMPLOYEE_AUTH', payload => $emp );
        } else {
            $self->mrest_declare_status( explanation => 
                "Internal auth failed for known employee $nick (mistyped password?)" 
            );
            return $CELL->status_not_ok;
        }
    }
}            


=head2 forbidden

This overrides the L<Web::Machine> method of the same name.

Authorization (ACL check) method.

First, parse the path and look at the method to determine which controller
action the user is asking us to perform. Each controller action has an ACL
associated with it, from which we can determine whether employees of each of
the four different privilege levels are authorized to perform that action.  

Requests for non-existent resources will always pass the ACL check.

=cut

sub forbidden {
    my ( $self ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::forbidden" );

    my $method = $self->context->{'method'};
    my $resource_name = $self->context->{'resource_name'};

    # if there is no handler on the context, the URL is invalid so we
    # just pass on the request 
    if ( not exists $self->context->{'handler'} ) {
        $log->debug("forbidden: no handler on context, passing on this request");
        return 0;
    }

    my $resource_def = $resources->{$resource_name}->{$method};

    # now we get the ACL profile.  There are three possibilities: 
    # 1. acl_profile property does not exist => fail
    # 2. single ACL profile for the entire resource
    # 3. separate ACL profiles for each HTTP method
    my ( $acl_profile_prop, $acl_profile );
    SKIP: { 

        # check acl_profile property 
        if ( exists( $resource_def->{'acl_profile'} ) ) {
            $acl_profile_prop = $resource_def->{'acl_profile'};
        } else {
            $log->notice( "Resource $resource_name has no acl_profile property; ACL check will fail" );
            last SKIP;
        } 

        # got the property, process it
        if ( ! ref( $acl_profile_prop ) ) {
            $acl_profile = $acl_profile_prop;
            $log->debug( "ACL profile for all methods is " . ( $acl_profile || "undefined" ) );
        } elsif ( ref( $acl_profile_prop ) eq 'HASH' ) {
            $acl_profile = $acl_profile_prop->{$method};
            $log->debug( "ACL profile for $method requests is " . ( $acl_profile || "undefined" ) );
        } else {
            $self->mrest_declare_status( code => 500, explanation => 
                "Cannot determine ACL profile of resource!!! Path is " . $self->context->{'path'},
                permanent => 1 );
            return 1;
        }
    }
    # push ACL profile onto context
    $self->push_onto_context( { 'acl_profile' => $acl_profile } );

    # determine privlevel of our user
    my $acl_priv = $self->context->{'current_priv'};
    $log->debug( "My ACL level is $acl_priv and the ACL profile of this resource is "
        . ( $acl_profile || "undefined" ) );

    # compare the two
    my $acl_check_passed = check_acl( profile => $acl_profile, privlevel => $acl_priv );
    if ( $acl_check_passed ) {
        $log->debug( "ACL check passed" );
        $self->push_onto_context( { 'acl_priv' => $acl_priv } );
        return 0;
    }
    $self->mrest_declare_status( explanation => 'DISPATCH_ACL_CHECK_FAILED', 
        args => [ $resource_name ] );
    return 1;
}

1;
