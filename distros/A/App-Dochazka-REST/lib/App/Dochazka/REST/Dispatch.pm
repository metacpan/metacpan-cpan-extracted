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

# ------------------------
# Top-level resources
# ------------------------

package App::Dochazka::REST::Dispatch;

use strict;
use warnings;

use App::CELL qw( $CELL $log $core $meta $site );
use App::Dochazka::Common qw( $today init_timepiece );
use App::Dochazka::REST;
use App::Dochazka::REST::ACL qw( 
    check_acl_context 
    acl_check_is_me 
    acl_check_is_my_report 
);
use App::Dochazka::REST::ConnBank qw( $dbix_conn conn_status );
use App::Dochazka::REST::Fillup;
use App::Dochazka::REST::LDAP qw( ldap_exists );
use App::Dochazka::REST::Model::Activity;
use App::Dochazka::REST::Model::Component qw( get_all_components );
use App::Dochazka::REST::Model::Employee qw( 
    list_employees_by_priv 
    noof_employees_by_priv 
);
use App::Dochazka::REST::Model::Interval qw(
    delete_intervals_by_eid_and_tsrange
    fetch_intervals_by_eid_and_tsrange
    generate_interval_summary
);
use App::Dochazka::REST::Model::Lock qw(
    fetch_locks_by_eid_and_tsrange
);
use App::Dochazka::REST::Model::Privhistory qw( get_privhistory );
use App::Dochazka::REST::Model::Schedhistory qw( get_schedhistory );
use App::Dochazka::REST::Model::Schedintvls;
use App::Dochazka::REST::Model::Schedule qw( get_all_schedules );
use App::Dochazka::REST::Model::Shared qw( 
    canonicalize_date
    canonicalize_tsrange
    load_multiple
    priv_by_eid
    schedule_by_eid
    select_set_of_single_scalar_rows
    split_tsrange
    timestamp_delta_plus
);
use App::Dochazka::REST::ResourceDefs;
use App::Dochazka::REST::Shared qw( :ALL );  # all the shared_* functions
use App::Dochazka::REST::Holiday qw( holidays_in_daterange );
use Data::Dumper;
use File::Path qw( mkpath rmtree );
use Module::Runtime qw( use_module );
use Params::Validate qw( :all );
use Try::Tiny;
use Web::MREST::InitRouter qw( $router $resources );
use Web::MREST::Util qw( pod_to_html pod_to_text );

use parent 'App::Dochazka::REST::Auth';




=head1 NAME

App::Dochazka::REST::Dispatch - Implementation of top-level resources




=head1 DESCRIPTION

This module contains the C<init_router> method as well as all the resource
handlers referred to in the resource definitions.



=head1 PACKAGE VARIABLES

This module uses some package variables, which are essentially constants, to do
its work.

=cut

my $fail = $CELL->status_not_ok;
my %iue_dispatch = (
    'insert_employee' => \&shared_insert_employee,
    'update_employee' => \&shared_update_employee,
);



=head1 FUNCTIONS

=cut

=head2 init

This function is called by C<bin/mrest>.

=cut

sub init {
    $log->debug("Entering " . __PACKAGE__. "::init");
    App::Dochazka::REST::ConnBank::init_singleton();

    my $status = App::Dochazka::REST::reset_mason_dir();
    return $status unless $status->ok;
    my $comp_root = $status->payload;

    # get Mason components from database and write them to filesystem
    $status = get_all_components( $dbix_conn );
    if ( $status->ok and $status->code eq 'DISPATCH_RECORDS_FOUND' ) {
        foreach my $comp ( @{ $status->payload } ) {
            $comp->create_file;
        }
    }
}


=head2 init_router

The "router" (i.e., L<Path::Router> instance) is initialized when the first
request comes in, as a first step before any processing of the request takes
place.

This happens when L<Web::MREST::Resource> calls the C<init_router> method.

L<App::Dochazka::REST> implements its own C<init_router> method, overriding the
default one in L<Web::MREST::InitRouter>.

=cut

sub init_router {
    $log->debug("Entering " . __PACKAGE__. "::init_router");
    return if ref( $router ) and $router->can( 'match' );
    $router = Path::Router->new;
    App::Dochazka::REST::ResourceDefs::load();
}


=head2 Top-level handlers

These are largely (but not entirely) copy-pasted from L<Web::MREST::Dispatch>.


=head3 handler_bugreport

Handler for the C<bugreport> resource.

=cut

sub handler_bugreport {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_bugreport, pass number $pass" );

    # first pass
    return 1 if $pass == 1;

    # second pass
    return $CELL->status_ok( 'DISPATCH_BUGREPORT', 
        payload => { report_bugs_to => $site->DOCHAZKA_REPORT_BUGS_TO },
    );
}


=head3 handler_configinfo

Handler for the C<configinfo> resource.

=cut

sub handler_configinfo {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_configinfo, pass number $pass" );

    # first pass
    return 1 if $pass == 1;

    # second pass
    return $CELL->status_ok( 'DISPATCH_CONFIGINFO', 
        payload => $meta->CELL_META_SITEDIR_LIST,
    );
}


=head3 handler_dbstatus

Handler for the C<dbstatus> resource.

=cut

sub handler_dbstatus {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::_get_dbstatus" );
    $log->debug( "DBIx::Connector object: " . ref( $self->context->{'dbix_conn'} ) );

    # first pass
    return 1 if $pass == 1;

    # second pass
    my $conn = $self->context->{'dbix_conn'};
    return $CELL->status_crit( "DOCHAZKA_NO_DBIX_CONNECTOR" ) unless ref( $conn ) and $conn->can( 'dbh' );
    my $dbh = $conn->dbh;
    my $noof_connections;
    my $status;
    try {
        $conn->run( fixup => sub { 
            ( $noof_connections ) = $_->selectrow_array( 
                $site->SQL_NOOF_CONNECTIONS,
                undef,
            );
        } );
        $log->notice( "Current number of DBI connections is $noof_connections" ); 
        my $dbstatus = conn_status( $conn );
        $status = $CELL->status_ok( 
            'DOCHAZKA_DBSTATUS', 
            args => [ $dbstatus ],
            payload => { 
                'conn_status' => $dbstatus,
                'dbmsname' => $dbh->get_info(17),
                'dbmsver' => $dbh->get_info(18),
                'username' => $dbh->{Username},
                'noof_connections' => ( $noof_connections += 0 ),
            } 
        );
    } catch {
        $status = $CELL->status_err( 'DOCHAZKA_DBI_ERR', args => [ $_ ] );
    };

    return $status;
}


=head3 handler_docu

=cut

sub handler_docu {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_docu, pass number $pass" );

    # first pass
    return 1 if $pass == 1;

    # '/docu/...' resources only

    # the resource to be documented should be in the request body - if not, return 400
    my $docu_resource = $self->context->{'request_entity'};
    if ( $docu_resource ) {
        $log->debug( "handler_docu: request body is ->$docu_resource<-" );
    } else {
        $self->mrest_declare_status( 'code' => 400, 'explanation' => 'Missing request entity' );
        return $fail;
    }

    # the resource should be defined - if not, return 404
    my $def = $resources->{$docu_resource};
    $log->debug( "handler_docu: resource definition is " . Dumper( $def ) );
    if ( ref( $def ) ne 'HASH' ) {
        $self->mrest_declare_status( 'code' => 404, 
            'explanation' => "Could not find resource definition for $docu_resource" 
        );
        return $fail;
    }

    # all green - assemble the requested documentation
    my $method = $self->context->{'method'};
    my $resource_name = $self->context->{'resource_name'};
    my $pl = {
        'resource' => $docu_resource,
    };
    my $docs = $def->{'documentation'} || <<"EOH";
=pod

The definition of resource $docu_resource lacks a 'documentation' property 
EOH
    # if they want POD, give them POD; if they want HTML, give them HTML, etc.
    if ( $resource_name eq 'docu/pod' ) {
        $pl->{'format'} = 'POD';
        $pl->{'documentation'} = $docs;
    } elsif ( $resource_name eq 'docu/html' ) {
        $pl->{'format'} = 'HTML';
        $pl->{'documentation'} = pod_to_html( $docs );
    } else {
        # fall back to plain text
        $pl->{'format'} = 'text';
        $pl->{'documentation'} = pod_to_text( $docs );
    }
    return $CELL->status_ok( 'DISPATCH_ONLINE_DOCUMENTATION', payload => $pl );
}


=head3 handler_echo

Echo request body back in the response

=cut

sub handler_echo {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_echo, pass number $pass" );
    
    # first pass
    return 1 if $pass == 1;

    # second pass
    return $CELL->status_ok( "ECHO_REQUEST_ENTITY", payload =>
       $self->context->{'request_entity'} );
}


=head3 handler_forbidden

Handler for 'forbidden' resource.

=cut

sub handler_forbidden {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_forbidden, pass number $pass" );
    
    # first pass
    return 1 if $pass == 1;

    # second pass
    $self->mrest_declare_status( explanation => 'Resource forbidden by definition', permanent => 1 );
    return $fail;
}


=head3 handler_holiday_tsrange

Handler for 'holiday/:tsrange' resource.

=cut

sub handler_holiday_tsrange {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_holiday_tsrange, pass number $pass" );
    
    # first pass
    if ( $pass == 1 ) {
        my $status = split_tsrange( 
            $self->context->{'dbix_conn'},
            $self->context->{'mapping'}->{'tsrange'},
        );
        if ( $status->not_ok ) {
            $status->{'http_code'} = ( $status->code eq 'DOCHAZKA_DBI_ERR' )
                ? 500 
                : 400;
            $self->mrest_declare_status( $status );
            return 0;
        }
        my $datereg = qr/(\d+-\d+-\d+)/;
        my ( $begin ) = $status->payload->[0] =~ $datereg;
        my ( $end ) = $status->payload->[1] =~ $datereg;
        if ( ! defined( $begin ) or ! defined( $end ) ) {
            $self->mrest_declare_status( 
                level => 'ERR', 
                code => 400,
                explanation => 'DISPATCH_UNBOUNDED_TSRANGE',
            );
            return 0;
        }
        $self->context->{'stashed_daterange'} = { 
                "begin" => $begin, 
                "end" => $end,
        };
    }

    # second pass
    return $CELL->status_ok( 'DOCHAZKA_HOLIDAYS_IN_TSRANGE', payload =>
        holidays_in_daterange( %{ $self->context->{'stashed_daterange'} } )
    );
}


=head3 handler_param

Handler for 'param/:type/:param' resource.

=cut

sub handler_param {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_param, pass number $pass" );

    # get parameters
    my $method = $self->context->{'method'};
    my $mapping = $self->context->{'mapping'};
    my ( $type, $param );
    if ( $mapping ) {
        $type = $self->context->{'mapping'}->{'type'};
        $param = $self->context->{'mapping'}->{'param'};
    } else {
        die "AAAHAHAHAAHAAHAAAAAAAA! no mapping?? in handler_param_get";
    }
    my $resource_name = $self->context->{'resource_name'};

    my ( $bool, $param_obj );
    if ( $type eq 'meta' ) {
        $param_obj = $meta;
    } elsif ( $type eq 'core' ) {
        $param_obj = $core;
    } elsif ( $type eq 'site' ) {
        $param_obj = $site;
    }
    if ( ! $param_obj) {
        $self->mrest_declare_status( code => '500', explanation => 'IMPROPER TYPE' );
        return 0;
    }

    # first pass
    if ( $pass == 1 ) {
        $bool = $param_obj->exists( $param );
        $bool = $bool ? 1 : 0;
        $self->context->{'stash'}->{'param_value'} = $param_obj->get( $param ) if $bool;
        return $bool;
    }

    # second pass
    if ( $type ne 'meta' and $method =~ m/^(PUT)|(DELETE)$/ ) {
        $self->mrest_declare_status( code => 400, explanation => 
            'PUT and DELETE can be used with meta parameters only' );
        return $fail;
    }
    if ( $method eq 'GET' ) {
        return $CELL->status_ok( 'MREST_PARAMETER_VALUE', payload => {
            $param => $self->context->{'stash'}->{'param_value'},
        } );
    } elsif ( $method eq 'PUT' ) {
        $log->debug( "Request entity: " . Dumper( $self->context->{'request_entity'} ) );
        return $param_obj->set( $param, $self->context->{'request_entity'} );
    } elsif ( $method eq 'DELETE' ) {
        delete $param_obj->{$param};
        return $CELL->status_ok( 'MREST_PARAMETER_DELETED', payload => {
            'type' => $type,
            'param' => $param,
        } );
    }
}


=head3 handler_noop

Generalized handler for resources that don't do anything.

=cut

sub handler_noop {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_noop" );

    # first pass
    return 1 if $pass == 1;

    # second pass
    my $method = $self->context->{'method'};
    my $resource_name = $self->context->{'resource_name'};
    my $def = $resources->{$resource_name};
    my $pl = {
        'resource_name' => $resource_name,
        'description' => $def->{$method}->{'description'},
        'parent' => $def->{'parent'},
        'children' => $def->{'children'},
    };
    return $CELL->status_ok( 'DISPATCH_NOOP',
        payload => $pl
    );
}


=head3

Handler for the C<session> resource.

=cut

sub handler_session {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_session" );

    # first pass
    return 1 if $pass == 1;

    # second pass
    my $session = $self->request->{'env'}->{'psgix.session'};
    return $CELL->status_ok( 'DISPATCH_SESSION_DATA', payload => {
        session => $session,
    } );
}


=head3

Handler for the C<session/terminate> resource.

=cut

sub handler_session_terminate {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_session_terminate" );

    # first pass
    return 1 if $pass == 1;

    # second pass
    $self->request->{'env'}->{'psgix.session'} = {};
    return $CELL->status_ok;
}


=head3 handler_version

Handler for the C<version> resource.

=cut

sub handler_version {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_version, pass number $pass" );

    # first pass
    return 1 if $pass == 1;

    # second pass
    my $param = $site->MREST_APPLICATION_MODULE;
    my $version = use_module( $param )->version;
    my $payload = ( $version )
        ? {
            'application' => $param,
            'version' => $version,
        }
        : "BUBBA did not find nothin";

    return $CELL->status_ok( 'DISPATCH_VERSION', payload => $payload );
}


=head2 Activity handlers


=head3 handler_get_activity_all

Handler for 'GET activity/all'

=cut

sub handler_get_activity_all {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_get_activity_all" );

    # first pass
    return 1 if $pass == 1 ;

    # second pass
    return App::Dochazka::REST::Model::Activity::get_all_activities( 
        $self->context->{'dbix_conn'}, 
        disabled => 0 
    );
}


=head3 handler_get_activity_all_disabled

Handler for 'GET activity/all/disabled'

=cut

sub handler_get_activity_all_disabled {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_get_activity_all_disabled" );

    # first pass
    return 1 if $pass == 1 ;

    # second pass
    return App::Dochazka::REST::Model::Activity::get_all_activities( 
        $self->context->{'dbix_conn'}, 
        disabled => 1 
    );
}


=head3 handler_post_activity_aid

Handler for 'POST activity/aid' resource.

=cut

sub handler_post_activity_aid {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_post_activity_aid" );

    # first pass
    return 1 if $pass == 1;

    # second pass
    # - check that entity is kosher
    my $status = shared_entity_check( $self, 'aid' );
    return $status unless $status->ok;
    my $context = $self->context;
    my $entity = $context->{'request_entity'};

    # - get aid and look it up
    my $aid = $entity->{'aid'};
    my $act = shared_first_pass_lookup( $self, 'AID', $aid );
    return $fail unless $act;

    # - perform the update
    return shared_update_activity( $self, $act, $entity );
}


=head3 handler_post_activity_code

Handler for 'POST activity/code' resource. This is a little more complicated
because it can be either create or modify.

=cut

sub handler_post_activity_code {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_post_activity_code" );

    # first pass
    return 1 if $pass == 1;

    # second pass
    # - check that entity is kosher
    my $status = shared_entity_check( $self, 'code' );
    return $status unless $status->ok;
    my $context = $self->context;
    my $entity = $context->{'request_entity'};

    # - create or modify?
    my $code = $entity->{'code'};
    my $act = shared_first_pass_lookup( $self, 'code', $code );
    $self->nullify_declared_status;

    # - perform the insert/update
    if ( $act ) {
        return shared_update_activity( $self, $act, $entity );
    } else {
        return shared_insert_activity( $self, $code, $entity );
    }
}


=head3 handler_activity_aid

Handler for the 'activity/aid/:aid' resource.

=cut

sub handler_activity_aid {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_activity_aid" ); 

    my $context = $self->context;
    
    # first pass
    if ( $pass == 1 ) {
        my $act = shared_first_pass_lookup( $self, 'AID', $context->{'mapping'}->{'aid'} );
        return 0 unless $act;
        $context->{'stashed_activity_object'} = $act;
        return 1;
    }

    # second pass
    if ( $context->{'method'} eq 'GET' ) {
        return $CELL->status_ok( 'DISPATCH_ACTIVITY_FOUND', 
            payload => $context->{'stashed_activity_object'}
        );
    } elsif ( $context->{'method'} eq 'PUT' ) {
        return shared_update_activity( 
            $self, 
            $context->{'stashed_activity_object'}, 
            $context->{'request_entity'} 
        );
    } elsif ( $context->{'method'} eq 'DELETE' ) {
        return $context->{'stashed_activity_object'}->delete( $context );
    }
    return $CELL->status_crit("Aaaaaaaaaaahhh! Swallowed by the abyss" );
}


=head3 handler_get_activity_code

Handler for the 'GET activity/code/:code' resource.

=cut

sub handler_get_activity_code {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_get_activity_code" ); 

    my $context = $self->context;
    
    # first pass
    if ( $pass == 1 ) {
        my $act = shared_first_pass_lookup( $self, 'code', $context->{'mapping'}->{'code'} );
        return 0 unless $act;
        $context->{'stashed_activity_object'} = $act;
        return 1;
    }

    # second pass
    return $CELL->status_ok( 'DISPATCH_ACTIVITY_FOUND', 
        payload => $context->{'stashed_activity_object'}
    );
}


=head3 handler_delete_activity_code

Handler for the 'DELETE activity/code/:code' resource.

=cut

sub handler_delete_activity_code {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_delete_activity_code" ); 

    my $context = $self->context;
    
    # first pass
    if ( $pass == 1 ) {
        my $act = shared_first_pass_lookup( $self, 'code', $context->{'mapping'}->{'code'} );
        return 0 unless $act;
        $context->{'stashed_activity_object'} = $act;
        return 1;
    }

    # second pass
    return $context->{'stashed_activity_object'}->delete( $context );
}


=head3 handler_put_activity_code

Handler for the 'PUT activity/code/:code' resource.

=cut

sub handler_put_activity_code {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_put_activity_code" ); 

    my $context = $self->context;
    
    # first pass
    return 1 if ( $pass == 1 );

    # second pass

    # - create or modify?
    my $code = $context->{'mapping'}->{'code'};
    my $entity = $context->{'request_entity'};
    if ( ! defined($entity) ) {
        $self->mrest_declare_status( 'code' => 400, 'explanation' => 'Missing request entity' );
        return $fail;
    }
    my $act = shared_first_pass_lookup( $self, 'code', $code );
    $self->nullify_declared_status;

    # - perform insert/update operation
    if ( $act ) {
        return shared_update_activity( $self, $act, $entity );
    } else {
        return shared_insert_activity( $self, $code, $entity );
    }
}



=head2 Component handlers


=head3 handler_get_component_all

Handler for 'GET component/all'

=cut

sub handler_get_component_all {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_get_component_all" );

    # first pass
    return 1 if $pass == 1 ;

    # second pass
    return App::Dochazka::REST::Model::Component::get_all_components( 
        $self->context->{'dbix_conn'}, 
    );
}


=head3 handler_post_component_cid

Handler for 'POST component/cid' resource.

=cut

sub handler_post_component_cid {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_post_component_cid" );

    # first pass
    return 1 if $pass == 1;

    # second pass
    # - check that entity is kosher
    my $status = shared_entity_check( $self, 'cid' );
    return $status unless $status->ok;
    my $context = $self->context;
    my $entity = $context->{'request_entity'};

    # - get cid and look it up
    my $cid = $entity->{'cid'};
    my $comp = shared_first_pass_lookup( $self, 'CID', $cid );
    return $fail unless $cid;

    # - perform the update
    return shared_update_component( $self, $comp, $entity );
}


=head3 handler_post_component_path

Handler for 'POST component/path' resource. This is a little more complicated
because it can be either create or modify.

=cut

sub handler_post_component_path {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_post_component_path" );

    # first pass
    return 1 if $pass == 1;

    # second pass
    # - check that entity is kosher
    my $status = shared_entity_check( $self, 'path' );
    return $status unless $status->ok;
    my $context = $self->context;
    my $entity = $context->{'request_entity'};

    # - create or modify?
    my $path = $entity->{'path'};
    my $comp = shared_first_pass_lookup( $self, 'path', $path );
    $self->nullify_declared_status;

    # - perform the insert/update
    if ( $comp ) {
        return shared_update_component( $self, $comp, $entity );
    } else {
        my $status = shared_entity_check( $self, 'path', 'source', 'acl' );
        return $status unless $status->ok;
        return shared_insert_component( $self, $path, $entity );
    }
}


=head3 handler_component_cid

Handler for the 'component/cid/:cid' resource.

=cut

sub handler_component_cid {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_component_cid" ); 

    my $context = $self->context;

    # first pass
    if ( $pass == 1 ) {
        my $comp = shared_first_pass_lookup( $self, 'cid', $context->{'mapping'}->{'cid'} );
        return 0 unless $comp;
        $context->{'stashed_component_object'} = $comp;
        return 1;
    }

    # second pass
    if ( $context->{'method'} eq 'GET' ) {
        return $CELL->status_ok( 'DISPATCH_COMPONENT_FOUND', 
            payload => $context->{'stashed_component_object'}
        );
    } elsif ( $context->{'method'} eq 'PUT' ) {
        return shared_update_component( 
            $self, 
            $context->{'stashed_component_object'}, 
            $context->{'request_entity'} 
        );
    } elsif ( $context->{'method'} eq 'DELETE' ) {
        return $context->{'stashed_component_object'}->delete( $context );
    }
    return $CELL->status_crit("Aaaabllaaaaaaahhh Component! Swallowed by the abyss" );
}



=head2 Employee handlers


=head3 handler_get_employee_count

Handler for 'GET employee/count/?:priv' resource.

=cut

sub handler_get_employee_count {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_get_employee_count" ); 

    # first pass
    return 1 if $pass == 1;

    # second pass
    my $result;
    if ( my $priv = $self->context->{'mapping'}->{'priv'} ) {
        $result = noof_employees_by_priv( $self->context->{'dbix_conn'}, lc $priv );
    } else {
        $result = noof_employees_by_priv( $self->context->{'dbix_conn'}, 'total' );
    }
    return $result;
}


=head3 handler_get_employee_list

Handler for 'GET employee/list/?:priv' resource.

=cut

sub handler_get_employee_list {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_get_employee_list" ); 

    # first pass
    return 1 if $pass == 1;

    # second pass
    my $result;
    if ( my $priv = $self->context->{'mapping'}->{'priv'} ) {
        $result = list_employees_by_priv( $self->context->{'dbix_conn'}, lc $priv );
    } else {
        $result = list_employees_by_priv( $self->context->{'dbix_conn'}, 'all' );
    }
    return $result;
}


=head3 handler_get_employee_team

Handler for 'GET employee/team' resource.

=cut

sub handler_get_employee_team {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_get_employee_team" ); 

    # first pass
    return 1 if $pass == 1;

    # second pass
    my $employee_obj = $self->context->{'current_obj'};
    my $dbix_conn = $self->context->{'dbix_conn'};
    my $status = $employee_obj->team_nicks( $dbix_conn );

    return $status;
}


=head3 handler_whoami

Handler for GET requests on the 'whoami', 'employee/current', and
'employee/self' resources (which are all synonyms).

=cut

sub handler_whoami {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_whoami" ); 

    # first pass
    return 1 if $pass == 1;

    # second pass
    my $context = $self->context;
    my $current_emp = $context->{'current'};
    delete $current_emp->{'passhash'};
    delete $current_emp->{'salt'};
    delete $current_emp->{'remark'} unless $context->{'current_priv'} eq 'admin';
    $CELL->status_ok( 'DISPATCH_EMPLOYEE_SELF', args => 
        [ $current_emp->{'nick'} ], payload => $current_emp );
}


=head3 _handler_get_employee_full_pass2

=cut

sub _handler_get_employee_full_pass2 {
    my ( $self ) = @_;
    my $context = $self->context;
    my $emp = $context->{'stashed_employee_object'};
    my $conn = $context->{'dbix_conn'};
    my $current_priv = priv_by_eid( $conn, $emp->{'eid'} );
    my $current_sched = schedule_by_eid( $conn, $emp->{'eid'} );
    my %history;
    foreach my $prop ( 'priv', 'schedule' ) {
        my $status;
        my @ARGS = ( $conn, $emp->{'eid'} );
        if ( $prop eq 'priv' ) {
            $status = App::Dochazka::REST::Model::Privhistory->load_by_eid( @ARGS );
        } elsif ( $prop eq 'schedule' ) {
            $status = App::Dochazka::REST::Model::Schedhistory->load_by_eid( @ARGS );
        } else {
            die "DEFDXXEGUG!";
        }
        $history{$prop} = $status->payload;
    }
    $CELL->status_ok( 
        'DISPATCH_EMPLOYEE_PROFILE_FULL',
        args => [ $emp->{'nick'}, $current_priv ],
        payload => { 
            'emp' => $emp,
            'priv' => $current_priv,
            'privhistory' => $history{'priv'},
            'schedule' => $current_sched,
            'schedhistory' => $history{'schedule'},
        } 
    );
}

=head3 handler_get_employee_self_full

Handler for GET requests on 'employee/self/full'

=cut

sub handler_get_employee_self_full {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_get_employee_self_full" );

    my $context = $self->context;

    # first pass
    if ( $pass == 1 ) {
        $context->{'stashed_employee_object'} = $context->{'current'};
        return 1;
    }

    # second pass
    return $self->_handler_get_employee_full_pass2();
}


=head3 handler_get_employee_eid_full

Handler for GET requests on 'employee/eid/:eid/full'

=cut

sub handler_get_employee_eid_full {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_get_employee_eid_full" );

    my $context = $self->context;

    # first pass
    if ( $pass == 1 ) {
        return shared_get_employee_pass1( $self, $pass, 'EID', $self->context->{'mapping'}->{'eid'} );
    }

    # second pass
    return $self->_handler_get_employee_full_pass2();
}


=head3 handler_get_employee_nick_full

Handler for GET requests on 'employee/nick/:nick/full'

=cut

sub handler_get_employee_nick_full {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_get_employee_nick_full" );

    my $context = $self->context;

    # first pass
    if ( $pass == 1 ) {
        return shared_get_employee_pass1( $self, $pass, 'nick', $self->context->{'mapping'}->{'nick'} );
    }

    # second pass
    return $self->_handler_get_employee_full_pass2();
}


=head3 handler_put_employee_eid

Handler for 'PUT employee/eid/:eid' - can only be update.

=cut

sub handler_put_employee_eid {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_put_employee_eid" ); 

    my $context = $self->context;

    # first pass
    if ( $pass == 1 ) {
        # determine if this is an insert or an update
        my $emp = shared_first_pass_lookup( $self, 'EID', $self->context->{'mapping'}->{'eid'} );
        return 0 unless $emp;
        return 0 unless shared_employee_acl_part1( $self, $emp );  # additional ACL checks
        $context->{'stashed_employee_object'} = $emp;
        return 1;
    }

    # second pass
    return $fail unless shared_employee_acl_part2( $self );
    return shared_update_employee( 
        $self,
        $context->{'stashed_employee_object'}, 
        $context->{'request_entity'} 
    );
}


=head3 handler_post_employee_eid

Handler for 'POST employee/eid' - can only be update.

=cut

sub handler_post_employee_eid {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_post_employee_eid" ); 

    my $context = $self->context;

    # first pass
    return 1 if $pass == 1;

    # second pass
    my ( $eid, $emp );
    if ( $eid = $context->{'request_entity'}->{'eid'} ) {
        $emp = shared_first_pass_lookup( $self, 'EID', $eid );
        return $fail unless $emp;
        return $fail unless shared_employee_acl_part1( $self, $emp );  # additional ACL checks
        return $fail unless shared_employee_acl_part2( $self );
    } else {
        $self->mrest_declare_status( code => 400, 
            explanation => 'DISPATCH_PROP_MISSING_IN_ENTITY', args => [ 'eid' ],
        );
        return $fail;
    }
    return shared_update_employee( 
        $self, 
        $emp, 
        $context->{'request_entity'} 
    );
}


=head3 handler_put_employee_nick

Handler for 'PUT employee/nick/:nick' - a little complicated because it can
be insert or update, depending on whether or not the employee exists.

=cut

sub handler_put_employee_nick {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_put_employee_nick" ); 

    my $context = $self->context;

    # first pass
    if ( $pass == 1 ) {
        # determine if this is an insert or an update
        my $emp = shared_first_pass_lookup( $self, 'nick', $self->context->{'mapping'}->{'nick'} );
        if ( $emp ) {
            $context->{'put_employee_func'} = 'update_employee';
        } else {
            $context->{'put_employee_func'} = 'insert_employee';
        }
        return 0 unless shared_employee_acl_part1( $self, $emp );  # additional ACL checks
        $context->{'stashed_employee_object'} = $emp;
        $self->nullify_declared_status;
        return 1;
    }

    # second pass
    my $func = $context->{'put_employee_func'};
    $log->debug( "PUT employee function is $func - " );
    if ( $func eq 'update_employee' ) {
        return $fail unless shared_employee_acl_part2( $self );
    } elsif ( $func eq 'insert_employee' ) {
        $context->{'request_entity'}->{'nick'} = $context->{'mapping'}->{'nick'};
    } else {
        die "AAAAAAAAAAAAGAGGGGGGGGAAAHAHAAHHHH!";
    }
    return $iue_dispatch{$func}->( 
        $self,
        $context->{'stashed_employee_object'}, 
        $context->{'request_entity'} 
    );
}


=head3 handler_post_employee_nick

Handler for 'POST employee/nick' - a little complicated because it can
be insert or update, depending on whether or not the employee exists.

=cut

sub handler_post_employee_nick {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_post_employee_nick" ); 

    my $context = $self->context;

    # first pass
    return 1 if $pass == 1;

    # second pass
    my ( $nick, $emp, $func );
    if ( $nick = $context->{'request_entity'}->{'nick'} ) {
        $emp = shared_first_pass_lookup( $self, 'nick', $nick );
        $func = $emp ? 'update_employee' : 'insert_employee';
        return $fail unless shared_employee_acl_part1( $self, $emp );  # additional ACL checks
        $self->nullify_declared_status;
    } else {
        $self->mrest_declare_status( code => 400, 
            explanation => 'DISPATCH_PROP_MISSING_IN_ENTITY', args => [ 'nick' ],
        );
        return $fail;
    }
    if ( $func eq 'update_employee' ) {
        delete $context->{'request_entity'}->{'nick'};
        return $fail unless shared_employee_acl_part2( $self );
    } elsif ( $func eq 'insert_employee' ) {
        $log->info( "Ready to insert new employee $nick" );
    } else {
        die "AAAAAAAAAAAAGAGGGGGGGGAAAHAHAAHHHH!";
    }
    die "AAGAGAGAGGGGGGGGG self is undef" unless defined $self;

    return $iue_dispatch{$func}->(
        $self,
        $emp,
        $context->{'request_entity'} 
    );

}


=head3 handler_post_employee_self

Handler for 'POST employee/{current,self}' resources. The request entity 
is supposed to contain a list of key:value pairs where the keys are properties
of the employee object and the values are new values for those properties, e.g.:

    { 
        "fullname" : "Bubba Jones",
        "nick" : "bubba"
    }

Note that it should be possible to set a property to null:

    { "fullname" : null }

The JSON will be converted into a Perl hashref, of course, and that will
be handed off to the DBI for insertion into placeholders in an UPDATE statement.

=cut

sub handler_post_employee_self {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_post_employee_self (pass $pass)" ); 

    # first pass
    return 1 if $pass == 1;
    
    # second pass
    my $context = $self->context;
    return $fail unless shared_employee_acl_part2( $self );
    return shared_update_employee( 
        $self,
        $context->{'current_obj'}, 
        $context->{'request_entity'} 
    );
}


=head3 handler_delete_employee_eid

Handler for 'DELETE employee/eid/:eid' resource.

=cut

sub handler_delete_employee_eid {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_delete_employee_eid" ); 

    # first pass
    if ( $pass == 1 ) {
        return $self->handler_get_employee_eid( $pass );
    }

    # second pass
    my $context = $self->context;
    return $context->{'stashed_employee_object'}->delete( $context );
}


=head3 handler_get_employee_eid

Handler for 'GET employee/eid/:eid'

=cut

sub handler_get_employee_eid {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_get_employee_eid" ); 
    return shared_get_employee( $self, $pass, 'EID', $self->context->{'mapping'}->{'eid'} );
}


=head3 _ldap_sync_pass1

=cut

sub _ldap_sync_pass1 {
    my ( $self, $emp ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::_ldap_sync_pass1" ); 

    my $status = $emp->ldap_sync();
    $log->debug( "ldap_sync status: " . Dumper( $status ) );
    if ( $status->not_ok ) {
        if ( $status->code eq 'DOCHAZKA_LDAP_SYSTEM_USER_NOSYNC' ) {
            # system user - 403
            $status->{'http_code'} = 403;
        } else {
            $status->{'http_code'} = 404;
        }
        $self->mrest_declare_status( $status );
        return 0;
    }
    $self->context->{'stashed_employee_object'} = $emp;
    return 1;
}


=head3 handler_get_employee_ldap

Handler for 'GET employee/nick/:nick/ldap' resource.

=cut

sub handler_get_employee_ldap {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_get_employee_ldap" ); 

    my $context = $self->context;
    my $nick = $context->{'mapping'}->{'nick'};

    if ( $pass == 1 ) {
        my $emp = App::Dochazka::REST::Model::Employee->spawn(
            'nick' => $nick,
            'sync' => 1,
        );
        return $self->_ldap_sync_pass1( $emp );
    }

    return $CELL->status_ok( 'DOCHAZKA_LDAP_LOOKUP', payload => $context->{'stashed_employee_object'} );
}


=head3 handler_put_employee_ldap

Handler for 'PUT employee/nick/:nick/ldap' resource.

=cut

sub handler_put_employee_ldap {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_put_employee_ldap" ); 

    my $context = $self->context;
    $log->debug( "mapping " . Dumper( $context->{'mapping'} ) );
    my $nick = $context->{'mapping'}->{'nick'};
    my $status;

    # first pass
    if ( $pass == 1 ) {
        # determine if this is an insert or an update
        my $emp = shared_first_pass_lookup( $self, 'nick', $nick );
        $self->nullify_declared_status;
        return 0 unless shared_employee_acl_part1( $self, $emp );  # additional ACL checks
        if ( $emp ) {
            $context->{'put_employee_func'} = 'update_employee';
        } else {
            $context->{'put_employee_func'} = 'insert_employee';
            $emp = App::Dochazka::REST::Model::Employee->spawn( 'nick' => $nick );
        }
        $emp->sync( 1 );
        return $self->_ldap_sync_pass1( $emp );
    }

    # second pass

    my $emp = $context->{'stashed_employee_object'};
    my $func = $context->{'put_employee_func'};
    if ( $func eq 'update_employee' ) {
        $log->debug( "Updating employee from LDAP" );
        $status = $emp->update( $context );
    } elsif ( $func eq 'insert_employee' ) {
        $log->debug( "Inserting new employee from LDAP" );
        $status = $emp->insert( $context );
    } else {
        die "AAAAAAAAAAAAGAGGGGGGGGAAAHAHAAHHHH!";
    }

    return $status;
}


=head3 handler_get_employee_minimal

Handler for 'GET employee/eid/:eid/minimal' resource.
Handler for 'GET employee/nick/:nick/minimal' resource.
Handler for 'GET employee/sec_id/:sec_id/minimal' resource.

=cut

sub handler_get_employee_minimal {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_get_employee_minimal" ); 

    if ( $pass == 1 ) {

        # determine key and value
        my $resource_name = $self->context->{'resource_name'};
        my ( $key, $value );
        if ( $resource_name eq 'employee/eid/:eid/minimal' ) {
            $key = 'EID';
            $value = $self->context->{'mapping'}->{'eid'};
        } elsif ( $resource_name eq 'employee/nick/:nick/minimal' ) { 
            $key = 'nick';
            $value = $self->context->{'mapping'}->{'nick'};
        } elsif ( $resource_name eq 'employee/sec_id/:sec_id/minimal' ) {
            $key = 'sec_id';
            $value = $self->context->{'mapping'}->{'sec_id'};
        }

        # ACL check
        my $priv = $self->context->{'current_priv'};
        if ( $priv eq 'passerby' ) {
            if ( ! acl_check_is_me( $self, ( lc $key ) => $value ) ) { 
                $self->mrest_declare_status( code => 403, explanation => "DISPATCH_KEEP_TO_YOURSELF" );
                return 0;
            }
        }

        # populate $emp
        my $emp = shared_first_pass_lookup( $self, $key, $value );
        return 0 unless $emp;

        # populate stashed value
        my $min_fields = $site->DOCHAZKA_EMPLOYEE_MINIMAL_FIELDS;
        die "AGACHCH! Problem with DOCHAZKA_EMPLOYEE_MINIMAL_FIELDS site param, which is set to " .
            Dumper( $min_fields ) . " with the following sitedirs loaded: " .
            Dumper( $meta->CELL_META_SITEDIR_LIST ) unless ref( $min_fields) eq 'ARRAY';
        foreach my $prop ( @{ $site->DOCHAZKA_EMPLOYEE_MINIMAL_FIELDS } ) {
            $self->context->{'stashed_value'}->{ $prop } = $emp->get( $prop );
        }

        return 1;
    }

    return $CELL->status_ok( 'DOCHAZKA_EMPLOYEE_MINIMAL', payload => $self->context->{'stashed_value'} );
}


=head3 handler_get_employee_eid_team

Handler for 'GET employee/eid/:eid/team'

=cut

sub handler_get_employee_eid_team {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_get_employee_eid_team" ); 

    if ( $pass == 1 ) {
        return $self->handler_get_employee_eid( $pass );
    }

    my $context = $self->context;
    my $dbix_conn = $context->{'dbix_conn'};
    return $context->{'stashed_employee_object'}->team_nicks( $dbix_conn );
}


=head3 handler_get_employee_nick_team

Handler for 'GET employee/nick/:nick/team'

=cut

sub handler_get_employee_nick_team {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_get_employee_nick_team" ); 

    if ( $pass == 1 ) {
        return $self->handler_get_employee_nick( $pass );
    }

    my $context = $self->context;
    my $dbix_conn = $context->{'dbix_conn'};
    return $context->{'stashed_employee_object'}->team_nicks( $dbix_conn );
}


=head3 handler_delete_employee_nick

Handler for 'DELETE employee/nick/:nick'

=cut

sub handler_delete_employee_nick {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_delete_employee_nick" ); 

    # first pass
    if ( $pass == 1 ) {
        return $self->handler_get_employee_nick( $pass );
    }

    # second pass
    my $context = $self->context;
    return $context->{'stashed_employee_object'}->delete( $context );
}


=head3 handler_get_employee_nick

Handler for 'GET employee/nick/:nick'

=cut

sub handler_get_employee_nick {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_get_employee_nick" ); 
    return shared_get_employee( $self, $pass, 'nick', $self->context->{'mapping'}->{'nick'} );
}


=head3 handler_get_employee_sec_id

Handler for 'GET employee/sec_id/:sec_id'

=cut

sub handler_get_employee_sec_id {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_get_employee_sec_id" ); 
    return shared_get_employee( $self, $pass, 'sec_id', $self->context->{'mapping'}->{'sec_id'} );
}


=head3 handler_get_employee_search_nick

Handler for 'GET employee/search/nick/:key'

=cut

sub handler_get_employee_search_nick {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_get_employee_search_nick" ); 

    # first pass
    return 1 if $pass == 1;

    # second pass
    my $key = $self->context->{'mapping'}->{'key'};
    $key = "%$key%" unless $key =~ m/%/;
    my $status = $CELL->status_ok;
    $status = load_multiple(
        conn => $self->context->{'dbix_conn'},
        class => 'App::Dochazka::REST::Model::Employee',
        sql => $site->SQL_EMPLOYEE_SELECT_MULTIPLE_BY_NICK,
        keys => [ $key ],
    );
    # check for 404
    if ( $status->level eq 'NOTICE' and $status->code eq 'DISPATCH_NO_RECORDS_FOUND' ) {
        $self->mrest_declare_status( code => 404,
            explanation => "DISPATCH_SEARCH_EMPTY",
            args => [ 'employee', "nick LIKE $key" ],
        );
        return $fail;
    }
    return $status if $status->not_ok;

    # found some employee objects
    foreach my $emp ( @{ $status->payload } ) {
        $emp = $emp->TO_JSON;
    }
    return $status;
}


=head2 Genreport handlers

=head3 handler_genreport

Handler for the 'POST genreport' resource.

=cut

sub handler_genreport {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_genreport" ); 

    # first pass
    return 1 if $pass == 1;

    # second pass
    # - check that entity is kosher
    my $status = shared_entity_check( $self, 'path' );
    return $status unless $status->ok;
    my $context = $self->context;
    my $entity = $context->{'request_entity'};

    # - get path and look it up
    my $path = $entity->{'path'};
    my $comp = shared_first_pass_lookup( $self, 'path', $path );
    return $fail unless $path;
    delete $entity->{'path'};

    # - if there is a 'parameters' property, check that it is a hashref
    my $parameters;
    if ( $entity->{'parameters'} ) {
        $log->debug( "Vetting parameters: " . Dumper $entity->{'parameters'} ) ;
        if ( ref( $entity->{'parameters'} ) ne 'HASH' ) {
            $self->mrest_declare_status( 
                code => 400, 
                explanation => 'parameters must be given as key:value pairs'
            );
            return $fail;
        }
        # - convert $parameters hashref into $parameters arrayref for validation
        my $count = 0;
        foreach my $key ( keys %{ $entity->{'parameters'} } ) {
            $parameters->[$count] = $key;
            $count += 1;
            $parameters->[$count] = $entity->{'parameters'}->{$key};
            $count += 1;
        }
    }

    # - if there is a validations property, convert it into a hashref
    #   and check the parameters against it
    if ( $comp->{validations} ) { 
        my $validations = eval $comp->{validations};
        $log->debug( "Validations before eval: " . Dumper $comp->{validations} );
        $log->debug( "Validations after eval: " . Dumper $validations );
        die "AGAAKH! validations is not a HASHREF: $validations" unless
             ref( $validations ) eq 'HASH';
        $parameters = {} if not defined $parameters;
        $log->debug( "About to validate parameters: " . Dumper $parameters );
        my $success = 1;
        validate_with( 
            params => $parameters,
            spec => $validations,
            on_fail => sub {
                my $errmsg = shift;
                $self->mrest_declare_status( code => 400, explanation => $errmsg );
                $success = 0;
            },
        );
        return $fail unless $success;
    } elsif ( $parameters ) {
        $log->WARN( "Parameters were given to component, but component has no validations!" );
    }

    # - generate report
    $parameters = [] if not defined $parameters;
    return $CELL->status_ok( 
        'DISPATCH_GENERATED_REPORT', 
        payload => $comp->generate( my %paramhash = @$parameters )
    );
}


=head2 History handlers


=head3 handler_history_self

Handler method for the '{priv,schedule}/history/self/?:tsrange' resource.

=cut

sub handler_history_self {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_history_self" ); 

    # first pass
    return 1 if $pass == 1;

    # second pass
    my $context = $self->context;
    my %ARGS = (
        'eid' => $context->{'current'}->{'eid'},
        'nick' => $context->{'current'}->{'nick'},
    );

    if ( defined $context->{'mapping'}->{'tsrange'} ) {
        $ARGS{'tsrange'} = $context->{'mapping'}->{'tsrange'};
    }
    
    if ( $context->{'components'}->[0] eq 'priv' ) {
        return get_privhistory( $context, %ARGS );
    } elsif ( $context->{'components'}->[0] eq 'schedule' ) {
        return get_schedhistory( $context, %ARGS );
    }
}


=head3 handler_history_get_single

Handler method for GET requests on the '/{priv,schedule}/history/eid/..' and
'/{priv,schedule}/history/nick/..' resources (potentially returning
a single record).

=cut

sub handler_history_get_single {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_history_get_single" ); 

    my ( $context, $method, $mapping, undef, $ts, $key, $value ) = shared_history_init( $self->context );

    # first pass
    if ( $pass == 1 ) {
        my $emp = shared_first_pass_lookup( $self, $key, $value );
        return 0 unless $emp;
        $self->context->{'stashed_employee_obj'} = $emp;
        return 1;
    }

    # second pass
    my $prop = $context->{'components'}->[0];
    my $emp = $self->context->{'stashed_employee_obj'};
    my $status;
    if ( $prop eq 'priv' ) {
        $status = App::Dochazka::REST::Model::Privhistory->load_by_eid(
            $context->{'dbix_conn'},
            $emp->eid,
            $ts
        );
    } elsif ( $prop eq 'schedule' ) {
        $status = App::Dochazka::REST::Model::Schedhistory->load_by_eid(
            $context->{'dbix_conn'},
            $emp->eid,
            $ts
        );
    } else {
        die "BGUDFUUFF! Improper prop ->$prop<- seen!";
    }
    # - process return value
    if ( $status->level eq 'NOTICE' and $status->code eq 'DISPATCH_NO_RECORDS_FOUND' ) {
        my $tsmsg = ( $ts ) ? $ts : 'now';
        $self->mrest_declare_status(
            code => 404,
            explanation => "No $prop history for $key $value as of $tsmsg",
        );
        return $fail;
    } elsif ( $status->not_ok ) {
        $self->mrest_declare_status(
            code => 500,
            explanation => $status->text,
        );
        return $fail;
    }
    return $status;
}


=head3 handler_history_get_multiple

Handler method for GET requests on the '/{priv,schedule}/history/eid/..' and
'/{priv,schedule}/history/nick/..' resources (all potentially returning
multiple records).

=cut

sub handler_history_get_multiple {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_history_get_multiple" ); 

    my ( $context, $method, $mapping, $tsrange, undef, $key, $value ) = shared_history_init( $self->context );

    # first pass
    if ( $pass == 1 ) {
        my $emp = shared_first_pass_lookup( $self, $key, $value );
        return 0 unless $emp;
        $self->context->{'stashed_employee_obj'} = $emp;
        return 1;
    }

    # second pass
    my ( $class, $prop, undef ) = shared_get_class_prop_id( $context );
    my $emp = $self->context->{'stashed_employee_obj'};
    my $status = App::Dochazka::REST::Model::Shared::get_history( 
        $prop,
        $context->{'dbix_conn'},
        eid => $emp->eid,
        nick => $emp->nick, 
        tsrange => $tsrange, 
    );
    # - process return value
    if ( $status->level eq 'NOTICE' and $status->code eq 'DISPATCH_NO_RECORDS_FOUND' ) {
        $self->mrest_declare_status( code => 404, explanation => "No history for $key $value $tsrange" );
        return $fail;
    } elsif ( $status->not_ok ) {
        $self->mrest_declare_status( code => 500, explanation => $status->text );
        return $fail;
    }
    return $status;
}


=head3 handler_history_post

Handler method for POST requests on the '/{priv,schedule}/history/eid/..' and
'/{priv,schedule}/history/nick/..' resources.

=cut

sub handler_history_post {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_history_post" ); 

    my ( $context, undef, undef, undef, undef, $key, $value ) = shared_history_init( $self->context );

    # first pass
    if ( $pass == 1 ) {
        # get employee object from key+value
        my $emp = shared_first_pass_lookup( $self, $key, $value );
        return 0 unless $emp;
        $self->context->{'stashed_employee_obj'} = $emp;
        $self->context->{'post_is_create'} = 1;
        return 1;
    }

    # second pass
    my ( $class, $prop, $id ) = shared_get_class_prop_id( $context );
    my $emp = $context->{'stashed_employee_obj'};

    # - check entity for presence of certain properties
    my $status = shared_entity_check( $self, $prop, 'effective' );
    return $status unless $status->ok;
    my $entity = $context->{'request_entity'};

    # - run the insert operation
    my $ho;
    try {
        $ho = $class->spawn( 
            eid => $emp->eid, 
            effective => $entity->{'effective'},
            $prop => $entity->{$prop},
            remark => $entity->{'remark'},
        );
    } catch {
        $log->crit($_);
        return $CELL->status_crit("DISPATCH_HISTORY_COULD_NOT_SPAWN", args => [ $_ ] );
    };
    $status = $ho->insert( $context );
    if ( $status->not_ok ) {
        $self->context->{'create_path'} = $status->level;
        if ( $status->code eq 'DOCHAZKA_MALFORMED_400' ) {
            return $self->mrest_declare_status(
                code => 400,
                explanation => "Check syntax of your request entity"
            );
        }
        return $self->mrest_declare_status(
            code => 500,
            explanation => $status->code,
            args => $status->args
        );
    }
    $self->context->{'create_path'} = '.../history/phid/' . ( $status->payload->{$id} || 'UNDEF' );
    return $status;
}


=head3 handler_history_get_phid

Handler for 'GET priv/history/phid/:phid'

=cut

sub handler_history_get_phid {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_history_get_phid" ); 

    # first pass
    if ( $pass == 1 ) {
        my $p_obj = shared_first_pass_lookup( $self, 'PHID', $self->context->{'mapping'}->{'phid'} );
        return 0 unless $p_obj;
        $self->context->{'stashed_history_object'} = $p_obj;
        return 1;
    }

    # second pass
    return $CELL->status_ok( 
        'DISPATCH_HISTORY_RECORD_FOUND', 
        payload => $self->context->{'stashed_history_object'},
    );
}


=head3 handler_history_post_phid

Handler for 'POST priv/history/phid/:phid'

=cut

sub handler_history_post_phid {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_history_post_phid" ); 

    # first pass
    if ( $pass == 1 ) {
        my $p_obj = shared_first_pass_lookup( $self, 'PHID', $self->context->{'mapping'}->{'phid'} );
        return 0 unless $p_obj;
        $self->context->{'stashed_history_object'} = $p_obj;
        return 1;
    }

    # second pass
    return shared_update_history( 
        $self,
        $self->context->{'stashed_history_object'}, 
        $self->context->{'request_entity'} 
    );
}


=head3 handler_history_delete_phid

=cut

sub handler_history_delete_phid {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_history_delete_phid" ); 
    return $self->handler_history_get_phid(1) if $pass == 1;
    return $self->context->{'stashed_history_object'}->delete( $self->context );
}


=head3 handler_history_get_shid

Handler for 'GET schedule/history/shid/:shid'

=cut

sub handler_history_get_shid {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_history_get_shid" ); 

    # first pass
    if ( $pass == 1 ) {
        my $s_obj = shared_first_pass_lookup( $self, 'SHID', $self->context->{'mapping'}->{'shid'} );
        return 0 unless $s_obj;
        $self->context->{'stashed_history_object'} = $s_obj;
        return 1;
    }

    # second pass
    return $CELL->status_ok( 
        'DISPATCH_HISTORY_RECORD_FOUND', 
        payload => $self->context->{'stashed_history_object'},
    );
}


=head3 handler_history_post_shid

Handler for 'POST priv/history/shid/:shid'

=cut

sub handler_history_post_shid {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_history_post_shid" ); 

    # first pass
    if ( $pass == 1 ) {
        my $p_obj = shared_first_pass_lookup( $self, 'SHID', $self->context->{'mapping'}->{'shid'} );
        return 0 unless $p_obj;
        $self->context->{'stashed_history_object'} = $p_obj;
        return 1;
    }

    # second pass
    return shared_update_history( 
        $self,
        $self->context->{'stashed_history_object'}, 
        $self->context->{'request_entity'} 
    );
}


=head3 handler_history_delete_shid

=cut

sub handler_history_delete_shid {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_history_delete_shid" ); 
    return $self->handler_history_get_shid(1) if $pass == 1;
    return $self->context->{'stashed_history_object'}->delete( $self->context );
}


=head2 Interval handlers


=head3 handler_interval_eid

Handler for 

    GET interval/eid/:eid/:tsrange
    DELETE interval/eid/:eid/:tsrange

#FIXME: implement a configurable limit on the tsrange

=cut

sub handler_interval_eid {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_interval_eid " ); 

    return $self->_handler_intlock( 'Interval', 'eid', $pass );
}


=head3 handler_get_lock_eid

Handler for 'GET lock/eid/:eid/:tsrange'

#FIXME: implement a configurable limit on the tsrange

=cut

sub handler_get_lock_eid {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_get_lock_eid " ); 

    return $self->_handler_intlock( 'Lock', 'eid', $pass );
}


=head3 handler_interval_nick

Handler for 

    GET interval/nick/:nick/:tsrange
    DELETE interval/nick/:nick/:tsrange

#FIXME: implement a configurable limit on the tsrange

=cut

sub handler_interval_nick {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_interval_nick " ); 

    return $self->_handler_intlock( 'Interval', 'nick', $pass );
}


=head3 handler_get_lock_nick

Handler for 'GET lock/nick/:nick/:tsrange'

#FIXME: implement a configurable limit on the tsrange

=cut

sub handler_get_lock_nick {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_get_lock_nick " ); 

    return $self->_handler_intlock( 'Lock', 'nick', $pass );
}


=head3 handler_interval_self

Handler for 

    GET interval/self/:tsrange
    DELETE interval/self/:tsrange

#FIXME: implement a configurable limit on the tsrange

=cut

sub handler_interval_self {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_interval_self " ); 

    return $self->_handler_intlock( 'Interval', 'self', $pass );
}


=head3 handler_get_lock_self

Handler for 'GET lock/self/:tsrange'

#FIXME: implement a configurable limit on the tsrange

=cut

sub handler_get_lock_self {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_get_lock_self " ); 

    return $self->_handler_intlock( 'Lock', 'self', $pass );
}


sub _handler_intlock {
    my ( $self, $intlock, $key, $pass ) = @_;

    my $context = $self->context;

    # first pass
    if ( $pass == 1 ) {

        # determine the employee
        my $value;
        if ( $key eq 'self' ) {
            $key = 'eid';
            $value = $context->{'current'}->{'eid'};
        } else {
            $value = $context->{'mapping'}->{ $key };
        }
        if ( 
                ! acl_check_is_me( $self, $key => $value ) and
                ! acl_check_is_my_report( $self, $key => $value ) 
           ) 
        {
            $self->mrest_declare_status( code => 403, explanation => "DISPATCH_KEEP_TO_YOURSELF" );
            return 0;
        }
        my $emp = shared_first_pass_lookup( $self, $key, $value );
        return 0 unless $emp;

        # determine the tsrange
        my $status = _tsrange_from_context( $context );
        return $status unless $status->ok;
        my $tsr = $status->payload;

        my @ARGS = (
            $context->{'dbix_conn'},
            $emp->eid,
            $tsr,
        );
        my $method = $self->context->{'method'};
        my $resource = $self->context->{'resource_name'};
        $log->debug( "_handler_intlock: resource is $resource" );
        if ( $method eq 'GET' and $intlock eq 'Interval' ) {
            $status = fetch_intervals_by_eid_and_tsrange( @ARGS );
        } elsif ( $method eq 'GET' and $intlock eq 'Lock' ) {
            $status = fetch_locks_by_eid_and_tsrange( @ARGS );
        } elsif ( $method eq 'GET' and $intlock eq 'Summary' ) {
            $status = generate_interval_summary( @ARGS );
            if ( $status->level eq 'ERR' and 
                 $status->code eq 'DISPATCH_SUMMARY_ILLEGAL_TSRANGE' ) {
                $self->mrest_declare_status( 'code' => 400, 
                    'explanation' => $status->text );
                return 0;
            }
        } elsif ( $method eq 'DELETE' and $intlock eq 'Interval' ) {
            $status = delete_intervals_by_eid_and_tsrange( @ARGS );
        } else {
            die "AGACHCH!! Horrible, horrible: " . ( $intlock || "undef" );
        }
        if ( $status->level eq 'NOTICE' and $status->code eq 'DISPATCH_NO_RECORDS_FOUND' ) {
            $self->mrest_declare_status( explanation => 'DISPATCH_NOTHING_IN_TSRANGE',
                args => [ 'attendance intervals', $tsr ] 
            );
            return 0;
        }
        $context->{'stashed_attendance_status'} = $status;
        return 1;
    }

    # second pass
    return $context->{'stashed_attendance_status'};
}


=head3 handler_interval_new

Handler for 'POST interval/new'

=cut

sub handler_interval_new {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__. "::handler_interval_new" ); 

    my $context = $self->context;

    # first pass
    if ( $pass == 1 ) {
        $context->{'post_is_create'} = 1;
        return 1;
    }
        
    # second pass
    my $status = shared_entity_check( $self, 'aid', 'intvl' );
    return $fail if $status->not_ok;

    if ( check_acl_context( $context )->not_ok ) {
        $self->mrest_declare_status( code => 403, explanation => 'DISPATCH_KEEP_TO_YOURSELF' );
        return $fail;
    }

    return shared_insert_interval( $self );
}


=head3 handler_post_interval_iid

Handler for 'POST interval/iid'.

=cut

sub handler_post_interval_iid {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__. "::handler_post_interval_iid" ); 

    my $context = $self->context;

    # first pass
    return 1 if $pass == 1;

    # second pass
    # - get IID
    my $status = shared_entity_check( $self, 'iid' );
    return $fail unless $status->ok;
    my $iid = $context->{'request_entity'}->{'iid'};

    # - is there an interval with this IID?
    my $int = shared_first_pass_lookup( $self, 'IID', $iid );
    return $fail unless $int;

    # - additional ACL check
    if ( ! acl_check_is_me( $self, 'eid' => $int->eid ) ) {
        $self->mrest_declare_status( code => 403, explanation => "DISPATCH_KEEP_TO_YOURSELF" );
        return $fail;
    }

    # - perform the operation
    return shared_update_intlock( $self, $int, $context->{'request_entity'} );
}


=head3 handler_get_interval_iid

Handler for 'GET interval/iid/:iid' resource.

=cut

sub handler_get_interval_iid {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__. "::handler_get_interval_iid" ); 

    my $context = $self->context;

    # first pass
    if ( $pass == 1 ) {

        # - get IID
        my $iid = $self->context->{'mapping'}->{'iid'};
        return 0 unless $iid;

        # - is there an interval with this IID?
        my $int = shared_first_pass_lookup( $self, 'IID', $iid );
        return 0 unless $int;

        # - additional ACL check
        if ( 
                ! acl_check_is_me( $self, 'eid' => $int->eid ) and
                ! acl_check_is_my_report( $self, 'eid' => $int->eid ) 
           ) 
        {
            $self->mrest_declare_status( code => 403, explanation => "DISPATCH_KEEP_TO_YOURSELF" );
            return 0;
        }

        $context->{'stashed_interval_object'} = $int;
        return 1;
    }

    # second pass
    my $int = $context->{'stashed_interval_object'};
    my $method = $context->{'method'};
    if ( $method eq 'GET' ) {
        return $CELL->status_ok( 'DISPATCH_INTERVAL_FOUND', payload => $int );
    }
    die "AAGAGAGGGGGGGGGGHHGHGHKD! method is " . ( $method || "undef" );
}


=head3 handler_interval_iid

Handler for 'interval/iid/:iid' resource.

=cut

sub handler_interval_iid {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__. "::handler_interval_iid" ); 

    my $context = $self->context;

    # first pass
    if ( $pass == 1 ) {

        # - get IID
        my $iid = $self->context->{'mapping'}->{'iid'};
        return 0 unless $iid;

        # - is there an interval with this IID?
        my $int = shared_first_pass_lookup( $self, 'IID', $iid );
        return 0 unless $int;

        # - additional ACL check
        if ( ! acl_check_is_me( $self, 'eid' => $int->eid ) ) {
            $self->mrest_declare_status( code => 403, explanation => "DISPATCH_KEEP_TO_YOURSELF" );
            return 0;
        }

        $context->{'stashed_interval_object'} = $int;
        return 1;
    }

    # second pass
    my $int = $context->{'stashed_interval_object'};
    my $method = $context->{'method'};
    if ( $method =~ m/^(PUT)|(POST)$/ ) {
        return shared_update_intlock( $self, $int, $context->{'request_entity'} );
    } elsif ( $method eq 'DELETE' ) {
        return $int->delete( $context );
    }
    die "AAGAGAGGGGGGGGGGHHGHGHKD! method is " . ( $method || "undef" );
}


=head3 handler_get_interval_summary

Handler for  "GET interval/summary/eid/:eid/:tsrange"

=cut

sub handler_get_interval_summary {
    my ( $self, $pass ) = @_;
    $log->debug("Reached " . __PACKAGE__ . "::handler_get_interval_summary" );

    my $context = $self->context;

    # first pass
    if ( $pass == 1 ) {
        my $rv = $self->_handler_intlock( 'Summary', 'eid', $pass );
        return 0 unless $rv;
    }

    return $context->{'stashed_attendance_status'};
}



=head2 Lock handlers


=head3 handler_lock_new

Handler for 'POST lock/new'

=cut

sub handler_lock_new {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__. "::handler_lock_new" ); 

    my $context = $self->context;

    # first pass
    if ( $pass == 1 ) {
        $context->{'post_is_create'} = 1;
        return 1;
    }
        
    # second pass
    my $status = shared_entity_check( $self, 'intvl' );
    return $fail if $status->not_ok;

    if ( check_acl_context( $context )->not_ok ) {
        $self->mrest_declare_status( code => 403, explanation => 'DISPATCH_KEEP_TO_YOURSELF' );
        return $fail;
    }

    return shared_insert_lock( $self );
}


=head3 handler_post_lock_lid

Handler for 'POST lock/lid'.

=cut

sub handler_post_lock_lid {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__. "::handler_post_lock_lid" ); 

    my $context = $self->context;

    # first pass
    return 1 if $pass == 1;

    # second pass
    # - get LID
    my $status = shared_entity_check( $self, 'lid' );
    return $fail unless $status->ok;
    my $lid = $context->{'request_entity'}->{'lid'};

    # - is there a lock with this LID?
    my $lock = shared_first_pass_lookup( $self, 'LID', $lid );
    return $fail unless $lock;

    # - additional ACL check
    if ( ! acl_check_is_me( $self, 'eid' => $lock->eid ) ) {
        $self->mrest_declare_status( code => 403, explanation => "DISPATCH_KEEP_TO_YOURSELF" );
        return $fail;
    }

    # - perform the operation
    return shared_update_intlock( $self, $lock, $context->{'request_entity'} );
}


=head3 handler_get_lock_lid

Handler for 'GET lock/lid/:lid' resource.

=cut

sub handler_get_lock_lid {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__. "::handler_get_lock_lid" ); 

    my $context = $self->context;

    # first pass
    if ( $pass == 1 ) {

        # - get LID
        my $lid = $self->context->{'mapping'}->{'lid'};
        return 0 unless $lid;

        # - is there a lock with this LID?
        my $lock = shared_first_pass_lookup( $self, 'LID', $lid );
        return 0 unless $lock;

        # - additional ACL check
        if ( 
                ! acl_check_is_me( $self, 'eid' => $lock->eid ) and
                ! acl_check_is_my_report( $self, 'eid' => $lock->eid ) 
           ) 
        {
            $self->mrest_declare_status( code => 403, explanation => "DISPATCH_KEEP_TO_YOURSELF" );
            return 0;
        }

        $context->{'stashed_lock_object'} = $lock;
        return 1;
    }

    # second pass
    my $lock = $context->{'stashed_lock_object'};
    my $method = $context->{'method'};
    if ( $method eq 'GET' ) {
        return $CELL->status_ok( 'DISPATCH_LOCK_FOUND', payload => $lock );
    }
    die "AAGAGAGGGGGGGGGGHHGHGHKD! method is " . ( $method || "undef" );
}


=head3 handler_lock_lid

Handler for 'lock/lid/:lid' resource.

=cut

sub handler_lock_lid {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__. "::handler_lock_lid" ); 

    my $context = $self->context;

    # first pass
    if ( $pass == 1 ) {

        # - get LID
        my $lid = $self->context->{'mapping'}->{'lid'};
        return 0 unless $lid;

        # - is there a lock with this LID?
        my $lock = shared_first_pass_lookup( $self, 'LID', $lid );
        return 0 unless $lock;

        # - additional ACL check
        if ( 
                ! acl_check_is_me( $self, 'eid' => $lock->eid )
           ) 
        {
            $self->mrest_declare_status( code => 403, explanation => "DISPATCH_KEEP_TO_YOURSELF" );
            return 0;
        }

        $context->{'stashed_lock_object'} = $lock;
        return 1;
    }

    # second pass
    my $lock = $context->{'stashed_lock_object'};
    my $method = $context->{'method'};
    if ( $method =~ m/^(PUT)|(POST)$/ ) {
        return shared_update_intlock( $self, $lock, $context->{'request_entity'} );
    } elsif ( $method eq 'DELETE' ) {
        return $lock->delete( $context );
    }
    die "AAGAGAGGGGGGGGGGHHGHGHKD! method is " . ( $method || "undef" );
}


=head2 Priv handlers

=head3 handler_priv_get_eid

=cut

sub handler_priv_get_eid {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . ":handler_priv_get_eid" ); 
    my $eid = $self->context->{'mapping'}->{'eid'};
    return shared_get_privsched( $self, 'priv', $pass, 'EID', $eid );
}


=head3 handler_priv_get_nick

=cut

sub handler_priv_get_nick {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . ":handler_priv_get_nick" ); 
    my $nick = $self->context->{'mapping'}->{'nick'};
    return shared_get_privsched( $self, 'priv', $pass, 'nick', $nick );
}


=head3 handler_priv_get_self

=cut

sub handler_priv_get_self {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . ":handler_priv_get_self" ); 
    return shared_get_privsched( $self, 'priv', $pass, 'EID', $self->context->{'current'}->{'eid'} );
}



=head2 Schedule handlers

=head3 schedule_all

Works for both 'GET schedule/all' and 'GET schedule/all/disabled'

=cut

sub handler_schedule_all {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_schedule_all" );

    # first pass
    if ( $pass == 1 ) {
        my $disabled = grep( /disabled/, @{ $self->context->{'components'} } );
        my $status = get_all_schedules( conn => $self->context->{'dbix_conn'}, disabled => $disabled );
        if ( $status->level eq 'NOTICE' and $status->code eq 'DISPATCH_NO_RECORDS_FOUND' ) {
            my $explanation = ( $disabled )
                ? 'DISPATCH_NO_SCHEDULES'
                : 'DISPATCH_NO_ACTIVE_SCHEDULES';
            $self->mrest_declare_status( explanation => $explanation );
            return 0;
        }
        $self->context->{'stashed_all_schedules_status'} = $status;
    }

    # second pass
    return $self->context->{'stashed_all_schedules_status'};
}


=head3 handler_get_schedule_eid

=cut

sub handler_get_schedule_eid {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . ":handler_get_schedule_eid" ); 
    return shared_get_privsched( $self, 'schedule', $pass, 'EID', $self->context->{'mapping'}->{'eid'} );
}


=head3 handler_fillup

Handler for POST interval/fillup. For a description of what we're trying to
do, see https://github.com/smithfarm/dochazka-rest/issues/60

=cut

sub handler_fillup {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_fillup" );

    my $context = $self->context;
    my $method = $context->{'method'};
    my $entity = $context->{'request_entity'};

    # first pass
    return 1 if $self->_first_pass_always_exists( $pass ); 

    # second pass
    $log->debug( "handler_fillup(): Commencing pass #2, entity is " .  Dumper( $entity ) );

    # extract employee from request entity
    my $emp = $self->_extract_employee_spec( $entity );
    return $fail unless ref( $emp ) eq 'App::Dochazka::REST::Model::Employee';

    # extract activity from request entity
    my $act = $self->_extract_activity_spec( $entity );
    return $fail unless ref( $act ) eq 'App::Dochazka::REST::Model::Activity';

    # either tsrange or date_list, but not both
    my $tsdl = $self->_extract_date_list_or_tsrange( $entity );
    return $fail unless ref( $tsdl ) eq 'HASH';

    # create Fillup object
    my $fillup = App::Dochazka::REST::Fillup->new( 
        context => $context,
        emp_obj => $emp,
        aid => $act->aid,
        %$tsdl,
        %$entity,
    );
    if ( ! defined( $fillup ) or ref( $fillup ) ne 'App::Dochazka::REST::Fillup' ) {
        $self->mrest_declare_status( 
            code => 500, 
            explanation => "No Fillup object" 
        );
        return $fail;
    }
    if ( ! $fillup->constructor_status or
         ! $fillup->constructor_status->isa( 'App::CELL::Status' ) )
    {
        $self->mrest_declare_status( 
            code => 500, 
            explanation => "No constructor_status in Fillup object" 
        );
        return $fail;
    }
    $log->debug( "Fillup object created; constructor status is " . Dumper( $fillup->constructor_status ) );
    if ( $fillup->constructor_status->not_ok ) {
        my $status = $fillup->constructor_status;
        $status->{'http_code'} = ( $status->code eq 'DOCHAZKA_DBI_ERR' )
            ? 500 
            : 400;
        $self->mrest_declare_status( $status );
        return $fail;
    }
    
    my $status = $fillup->commit;
    if ( $status->not_ok ) {
        $self->mrest_declare_status( code => 500, explanation => $status->text );
        return $fail;
    }
    return $status;
}

# helper function to extract employee spec from request entity
# takes request entity hash and returns either undef on failure
# or Employee object on success
sub _extract_employee_spec {
    my ( $self, $entity ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::_extract_employee_spec " .
                 "with entity " . Dumper( $entity ) );
    my ( $key, $value );
    # the key can be one and only one of the following: 
    # eid, nick, sec_id (in that order; additional keys are ignored)
    if ( $entity->{eid} ) {
        $key = 'eid';
        $value = $entity->{eid};
    } elsif ( $entity->{nick} ) {
        $key = 'nick';
        $value = $entity->{nick};
    } elsif ( $entity->{sec_id} ) {
        $key = 'sec_id';
        $value = $entity->{sec_id};
    } else {
        $self->mrest_declare_status(
            code => 404,
            explanation => "DISPATCH_EMPLOYEE_CANNOT_BE_DETERMINED"
        );
        return;
    }
    map { delete $entity->{$_} } ( 'eid', 'nick', 'sec_id' );
    if ( ! acl_check_is_me( $self, $key => $value ) ) {
        $self->mrest_declare_status( code => 403, explanation => "DISPATCH_KEEP_TO_YOURSELF" );
        return;
    }
    my $emp = shared_first_pass_lookup( $self, $key, $value );
    return unless $emp->isa( 'App::Dochazka::REST::Model::Employee' );
    return $emp;
}

# helper function to extract activity spec from request entity
# takes request entity hash and returns either undef on failure
# or Activity object on success
sub _extract_activity_spec {
    my ( $self, $entity ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::_extract_activity_spec " .
                 "with entity " . Dumper( $entity ) );
    my ( $key, $value );
    # the key can be one and only one of the following: 
    # aid, code, or nothing (in which case code defaults to "WORK")
    if ( $entity->{aid} ) {
        $key = 'aid';
        $value = $entity->{aid};
    } elsif ( $entity->{code} ) {
        $key = 'code';
        $value = $entity->{code};
    } else {
        $key = 'code';
        $value = 'WORK';
    }
    map { delete $entity->{$_} } ( 'aid', 'code' );
    my $act = shared_first_pass_lookup( $self, $key, $value );
    return unless $act->isa( 'App::Dochazka::REST::Model::Activity' );
    return $act;
}

# helper function to extract date_list or tsrange from request entity
sub _extract_date_list_or_tsrange {
    my ( $self, $entity ) = @_;
    $log->debug( "Entering " . __PACKAGE__ .  "::_extract_date_list_or_tsrange " .
                 "with entity " . Dumper( $entity ) );

    my $date_list = $entity->{date_list};
    my $tsrange = $entity->{tsrange};
    my $dlts;
    
    if ( ( $date_list and $tsrange ) or
         ( ! $date_list and ! $tsrange ) ) {
        $self->mrest_declare_status( code => 400, explanation => "DISPATCH_DATE_LIST_OR_TSRANGE" );
        return;
    }

    if ( $entity->{date_list} ) {
        $dlts = { 'date_list' => $entity->{date_list} };
    } elsif ( $entity->{tsrange} ) {
        $dlts = { 'tsrange' => $entity->{tsrange} };
    } else {
        die "ASSERT AGCJDK!!!!!!DEE";
    }

    $log->debug( "_extract_date_list_or_tsrange returning " . Dumper $dlts );
    return $dlts;
}


=head3 handler_get_schedule_nick

=cut

sub handler_get_schedule_nick {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . ":handler_get_schedule_nick" ); 
    return shared_get_privsched( $self, 'schedule', $pass, 'nick', $self->context->{'mapping'}->{'nick'} );
}


=head3 handler_get_schedule_self

=cut

sub handler_get_schedule_self {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . ":handler_get_schedule_self" ); 
    return shared_get_privsched( $self, 'schedule', $pass, 'EID', $self->context->{'current'}->{'eid'} );
}


=head3 handler_schedule_new

Handler for the 'schedule/new' resource.

=cut

sub handler_schedule_new {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_schedule_new" ); 

    my $context = $self->context;

    # first pass
    if ( $pass == 1 ) {
        $context->{'post_is_create'} = 1;
        return 1;
    }

    # second pass
    my ( $status, $code );

    $status = shared_entity_check( $self, 'schedule' );
    return $fail if $status->not_ok;
    if ( ref( $context->{'request_entity'}->{'schedule'} ) ne "ARRAY" ) {
        $self->mrest_declare_status( code => 400, explanation => 'Check schedule syntax' );
        return $fail;
    }

    # first, spawn a Schedintvls object
    my $intvls = App::Dochazka::REST::Model::Schedintvls->spawn;
    $log->debug( "Spawned Schedintvls object " . Dumper( $intvls ) );

    # note that a SSID has been assigned
    my $ssid = $intvls->ssid;
    $log->debug("Spawned Schedintvls object with SSID $ssid");

    # assume that these are the intervals
    $intvls->{'intvls'} = $context->{'request_entity'}->{'schedule'};
    #
    # insert the intervals
    $status = $intvls->insert( $context->{'dbix_conn'} ); # schedintvls is not audited
    if ( $status->not_ok ) {
        $self->mrest_declare_status( code => 500, explanation => $status->text );
        return $fail;
    }
    $log->info( "schedule/new: Scratch intervals inserted" );

    #
    # convert the intervals to get the 'schedule' property
    $status = $intvls->load( $context->{'dbix_conn'} );
    if ( $status->not_ok ) {
        $intvls->delete( $context->{'dbix_conn'} );
        $self->mrest_declare_status( code => 400, explanation => $status->text );
        return $fail;
    }
    $log->info( "schedule/new: Scratch intervals converted" );

    #
    # spawn Schedule object
    my @ARGS = ( 'schedule' => $intvls->json );
    if ( my $scode = $context->{'request_entity'}->{'scode'} ) {
        push @ARGS, ( 'scode' => $scode );
    }
    my $sched = App::Dochazka::REST::Model::Schedule->spawn( @ARGS );
    #
    # insert schedule object to get SID
    $status = $sched->insert( $context );
    if ( $status->ok ) {
        if ( $status->code eq 'DOCHAZKA_SCHEDULE_EXISTS' ) {
            $self->context->{'create_path'} = '.../schedule/shid/' . $sched->sid;
            $code = 'DISPATCH_SCHEDULE_EXISTS';
            $log->info( "POST schedule/new: Returning existing schedule, unchanged" );
            $sched = $status->payload;
        } elsif ( $status->code eq 'DOCHAZKA_SCHEDULE_UPDATE_OK' ) {
            $self->context->{'create_path'} = '.../schedule/shid/' . $sched->sid;
            $code = 'DISPATCH_SCHEDULE_UPDATE_OK';
            $log->info( "POST schedule/new: Existing schedule updated" );
        } elsif ( $status->code eq 'DOCHAZKA_SCHEDULE_INSERT_OK' ) {
            $self->context->{'create_path'} = '.../schedule/shid/' . $sched->sid;
            $code = 'DISPATCH_SCHEDULE_INSERT_OK';
            $log->info( "POST schedule/new: New schedule inserted" );
        } else {
            die "AGGHGHG! could not handle App::Dochazka::REST::Model::Schedule->insert status: " 
                . Dumper( $status );
        }
    } else {
        $self->mrest_declare_status( code => 500, explanation => 
            "schedule/new: Model/Schedule.pm->insert failed: " . $status->text );
        $intvls->delete( $context->{'dbix_conn'} );
        return $fail;
    }
    #
    # delete the schedintvls object
    $status = $intvls->delete( $context->{'dbix_conn'} ); # schedintvls is not audited
    if ( $status->not_ok ) {
        $self->mrest_declare_status( code => 500, explanation => "Could not delete schedintvls: " . $status->text );
        return $fail;
    }
    $log->info( "schedule/new: scratch intervals deleted" );
    #
    # success
    return $CELL->status_ok( $code, payload => $sched->TO_JSON );
}


=head3 handler_get_schedule_sid

Handler for '/schedule/sid/:sid'

=cut

sub handler_get_schedule_sid {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . ":handler_get_schedule_sid" ); 

    # first pass
    if ( $pass == 1 ) {
        my $sched = shared_first_pass_lookup( $self, 'SID', $self->context->{'mapping'}->{'sid'} );
        return 0 unless $sched;
        $self->context->{'stashed_schedule_object'} = $sched;
        return 1;
    }
    
    # second pass
    return $CELL->status_ok( 
        'DISPATCH_SCHEDULE_FOUND',
        payload => $self->context->{'stashed_schedule_object'},
    );
}


=head3 handler_put_schedule_sid

Handler for 'PUT schedule/sid/:sid'

=cut

sub handler_put_schedule_sid {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . ":handler_put_schedule_sid" ); 

    my $context = $self->context;
    my $sid = $context->{'mapping'}->{'sid'};

    # first pass
    if ( $pass == 1 ) {
         my $sched = shared_first_pass_lookup( $self, 'SID', $sid );
         return 0 unless $sched;
         $context->{'stashed_schedule_object'} = $sched;
         return 1;
    }

    # run the update operation
    return shared_update_schedule( 
        $self,
        $context->{'stashed_schedule_object'}, 
        $context->{'request_entity'} 
    );
}


=head3 handler_delete_schedule_sid

Handler for '/schedule/sid/:sid'

=cut

sub handler_delete_schedule_sid {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . ":handler_delete_schedule_sid" ); 

    my $context = $self->context;

    # first pass
    if ( $pass == 1 ) {
        return $self->handler_get_schedule_sid( $pass );
    }

    # second pass
    return $context->{'stashed_schedule_object'}->delete( $context );
}


=head3 handler_get_schedule_scode

Handler for '/schedule/scode/:scode'

=cut

sub handler_get_schedule_scode {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . ":handler_get_schedule_scode" ); 

    # first pass
    if ( $pass == 1 ) {
        my $sched = shared_first_pass_lookup( $self, 'scode', $self->context->{'mapping'}->{'scode'} );
        return 0 unless $sched;
        $self->context->{'stashed_schedule_object'} = $sched;
        return 1;
    }
    
    # second pass
    return $CELL->status_ok( 
        'DISPATCH_SCHEDULE_FOUND',
        payload => $self->context->{'stashed_schedule_object'},
    );
}


=head3 handler_put_schedule_scode

Handler for 'PUT schedule/scode/:scode'

=cut

sub handler_put_schedule_scode {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . ":handler_put_schedule_scode" ); 

    my $context = $self->context;
    my $scode = $context->{'mapping'}->{'scode'};

    # first pass
    if ( $pass == 1 ) {
         my $sched = shared_first_pass_lookup( $self, 'scode', $scode );
         return 0 unless $sched;
         $context->{'stashed_schedule_object'} = $sched;
         return 1;
    }

    # run the update operation
    return shared_update_schedule( 
        $self,
        $context->{'stashed_schedule_object'}, 
        $context->{'request_entity'} 
    );
}


=head3 handler_delete_schedule_scode

Handler for '/schedule/scode/:scode'

=cut

sub handler_delete_schedule_scode {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . ":handler_delete_schedule_scode" ); 

    my $context = $self->context;

    # first pass
    if ( $pass == 1 ) {
        return $self->handler_get_schedule_scode( $pass );
    }

    # second pass
    return $context->{'stashed_schedule_object'}->delete( $context );
}


=head2 Helper functions

=head3 _first_pass_always_exists

Boilerplate code for use in handlers of resources that always exist

=cut

sub _first_pass_always_exists {
    my ( $self, $pass ) = @_;

    if ( $pass == 1 ) {
        $log->debug( "Resource handler first pass, resource always exists" );
        return 1;
    }
    return 0;
}

=head3 _tsrange_from_context

Given a mapping containing either a C<tsrange> property or, alternatively, 
a pair of properties C<ts> and C<psqlint> (i.e.  a timestamp and a PostgreSQL
interval), return a status object that, if the delta add operation is
successful, will contain a proper timestamp.

=cut

sub _tsrange_from_context { 
    my $context = shift;
    my $mapping = $context->{'mapping'};
    my ( $status, $tsr );
    $tsr = $mapping->{'tsrange'} if $mapping->{'tsrange'};
    if ( $mapping->{'ts'} and $mapping->{'psqlint'} ) {
        $status = timestamp_delta_plus( 
            $context->{'dbix_conn'}, 
            $mapping->{'ts'}, 
            $mapping->{'psqlint'} 
        ); 
        return $status unless $status->ok;
        $tsr = "[ " . $mapping->{ts} . ", " . $status->payload . " )";
    }
    return $CELL->status_ok( 'SUCCESS', payload => $tsr );
}

1;
