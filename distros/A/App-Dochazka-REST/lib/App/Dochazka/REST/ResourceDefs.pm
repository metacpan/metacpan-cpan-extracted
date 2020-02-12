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

# ------------------------
# The purpose of this package is to hold all the resource definitions
# and provide a hook for loading them.
# ------------------------

package App::Dochazka::REST::ResourceDefs;

use strict;
use warnings;

use App::CELL qw( $log );
use Web::MREST::InitRouter;

my $defs;
my $tsrange_validation = qr/^[[(].*,.*[])]$/;
my $ts_validation = qr/^(\"|\')?\d+-\d+-\d+( +\d+:\d+(:\d+)?)?(\"|\')?$/;
my $term_validation = qr/^[[:alnum:]_][[:alnum:]_-]*$/;
my $date_validation = qr/^\d{2,4}-\d{1,2}-\d{1,2}$/;
my $priv_validation = qr/^(admin)|(active)|(inactive)|(passerby)$/i;
my $psqlint_validation = qr/^[[:alnum:] ]+$/;





=head1 NAME

App::Dochazka::REST::ResourceDefs - Resource definitions




=head1 DESCRIPTION

The purpose of this package is to hold all the resource definitions
and provide a hook for loading them.

=cut




=head1 RESOURCE DEFINITIONS

=head2 Top-level resources

=cut

$defs->{'top'} = {

    # root resource
    '/' => {
        handler => 'handler_noop',
        acl_profile => 'passerby',
        description => 'The root resource',
        documentation => <<'EOH',
=pod

This resource is the parent of all resources that do not specify
a parent in their resource definition.
EOH
    },

    # bugreport
    'bugreport' => 
    {
        parent => '/',
        handler => {
            GET => 'handler_bugreport',
        },
        acl_profile => 'passerby',
        cli => 'bugreport',
        description => 'Display instructions for reporting bugs in Web::MREST',
        documentation => <<'EOH',
=pod

Returns a JSON structure containing instructions for reporting bugs.
EOH
    },

    # configinfo
    'configinfo' =>
    {
        parent => '/',
        handler => {
            GET => 'handler_configinfo',
        },
        acl_profile => 'passerby',
        cli => 'configinfo',
        description => 'Display information about Web::MREST configuration',
        documentation => <<'EOH',
=pod

Returns a list of directories that were scanned for configuration files.
EOH
    },

    # dbstatus
    'dbstatus' => {
        parent => '/',
        handler => {
            GET => 'handler_dbstatus',
        },
        acl_profile => 'inactive',
        cli => 'dbstatus',
        description => 'Display status of database connection',
        documentation => <<'EOH',
=pod

This resource checks the employee's database connection and reports on its status.
The result - either "UP" or "DOWN" - will be encapsulated in a payload like this:

    { "dbstatus" : "UP" }

Each employee gets her own database connection when she logs in to Dochazka.
Calling this resource causes the server to execute a 'ping' on the connection.
If the ping test fails, the server will attempt to open a new connection. Only
if this, too, fails will "DOWN" be returned.
EOH
    },

    # docu
    'docu' => 
    { 
        parent => '/',
        handler => 'handler_noop',
        acl_profile => 'passerby',
        cli => 'docu',
        description => 'Access on-line documentation (via POST to an appropriate subresource)',
        documentation => <<'EOH',
=pod

This resource provides access to on-line documentation through its
subresources: 'docu/pod', 'docu/html', and 'docu/text'.

To get documentation on a resource, send a POST reqeuest for one of
these subresources, including the resource name in the request
entity as a bare JSON string (i.e. in double quotes).
EOH
    },

    # docu/pod
    'docu/pod' => 
    {
        parent => 'docu',
        handler => {
            POST => 'handler_docu', 
        },
        acl_profile => 'passerby',
        cli => 'docu pod $RESOURCE',
        description => 'Display POD documentation of a resource',
        documentation => <<'EOH',
=pod
        
This resource provides access to on-line help documentation in POD format. 
It expects to find a resource name (e.g. "employee/eid/:eid" including the
double-quotes, and without leading or trailing slash) in the request body. It
returns a string containing the POD source code of the resource documentation.
EOH
    },

    # docu/html
    'docu/html' => 
    { 
        parent => 'docu',
        handler => {
            POST => 'handler_docu', 
        },
        acl_profile => 'passerby',
        cli => 'docu html $RESOURCE',
        description => 'Display HTML documentation of a resource',
        documentation => <<'EOH',
=pod

This resource provides access to on-line help documentation. It expects to find
a resource name (e.g. "employee/eid/:eid" including the double-quotes, and without
leading or trailing slash) in the request body. It generates HTML from the 
resource documentation's POD source code.
EOH
    },

    # docu/text
    'docu/text' =>
    { 
        parent => 'docu',
        handler => {
            POST => 'handler_docu', 
        },
        acl_profile => 'passerby',
        cli => 'docu text $RESOURCE',
        description => 'Display resource documentation in plain text',
        documentation => <<'EOH',
=pod

This resource provides access to on-line help documentation. It expects to find
a resource name (e.g. "employee/eid/:eid" including the double-quotes, and without
leading or trailing slash) in the request body. It returns a plain text rendering
of the POD source of the resource documentation.
EOH
    },

    # echo
    'echo' => 
    {
        parent => '/',
        handler => {
            POST => 'handler_echo', 
        },
        acl_profile => 'admin',
        cli => 'echo [$JSON]',
        description => 'Echo the request body',
        documentation => <<'EOH',
=pod

This resource simply takes whatever content body was sent and echoes it
back in the response body.
EOH
    },

    # forbidden
    'forbidden' =>
    {
        parent => '/',
        handler => 'handler_forbidden',
        acl_profile => 'forbidden',
        cli => 'forbidden',
        description => 'A resource that is forbidden to all',
        documentation => <<'EOH',
=pod

This resource returns 403 Forbidden for all allowed methods, regardless of user.

Implementation note: this can be accomplished for any resource by including an 'acl_profile'
property with the value 'undef' or any unrecognized privilege level string (like "foobar").
EOH
    },

    # /holiday/:tsrange
    'holiday/:tsrange' =>
    {
        parent => '/',
        handler => {
            'GET' => 'handler_holiday_tsrange',
        },
        acl_profile => 'passerby',
        cli => 'handler $TSRANGE',
        validations => {
            'tsrange' => $tsrange_validation,
        },
        description => 'Determine holidays and weekends within a tsrange',
        documentation => <<'EOH',
=pod

Used with GET. For a given tsrange, return an object keyed on dates. The for
each date key is itself an object. If a date falls on a weekend, the value will
contain a subobject { "weekend": true }. If a date is a holiday, it will
contain a subobject { "holiday": true }. If a date is neither a weekend nor a
holiday, the value will be an empty object.
EOH
    },

    # noop
    'noop' =>
    { 
        parent => '/',
        handler => 'handler_noop', 
        acl_profile => 'passerby',
        cli => 'noop',
        description => 'A resource that does nothing',
        documentation => <<'EOH',
=pod

Regardless of anything, this resource does nothing at all.
EOH
    },

    # param/:type/:param
    'param/:type/:param' => 
    {
        parent => '/',
        handler => {
            'GET' => 'handler_param',
            'PUT' => 'handler_param',
            'DELETE' => 'handler_param',
        },
        acl_profile => 'admin',
        cli => {
            'GET' => 'param $TYPE $PARAM',
            'PUT' => 'param $TYPE $PARAM $VALUE',
            'DELETE' => 'param $TYPE $PARAM', 
        },
        description => {
            'GET' => 'Display value of a meta/core/site parameter',
            'PUT' => 'Set value of a parameter (meta only)',
            'DELETE' => 'Delete a parameter (meta only)',
        },
        documentation => <<'EOH',
=pod

This resource can be used to look up (GET) meta, core, and site parameters, 
as well as to set (PUT) and delete (DELETE) meta parameters.
EOH
        validations => {
            'type' => qr/^(meta)|(core)|(site)$/,
            'param' => qr/^[[:alnum:]_][[:alnum:]_-]+$/,
        },
    },

    # session
    'session' =>
    { 
        parent => '/',
        handler => {
            GET => 'handler_session', 
        },
        acl_profile => 'passerby',
        cli => 'session',
        description => 'Display the current session',
        documentation => <<'EOH',
=pod

Dumps the current session data (server-side).
EOH
    },

    # session/terminate
    'session/terminate' =>
    {
        parent => '/session',
        handler => {
            POST => 'handler_session_terminate',
        },
        acl_profile => 'passerby',
        cli => 'session terminate',
        description => 'Terminate the current session',
        documentation => <<'EOH',
=pod

Terminates the current session
EOH
    },

    # version
    'version' =>
    { 
        parent => '/',
        handler => {
            GET => 'handler_version', 
        },
        acl_profile => 'passerby',
        cli => 'version',
        description => 'Display application name and version',
        documentation => <<'EOH',
=pod

Shows the software version running on the present instance. The version displayed
is taken from the C<$VERSION> package variable of the package specified in the
C<MREST_APPLICATION_MODULE> site parameter.
EOH
    },

    # /whoami
    'whoami' => {
        parent => '/',
        handler => {
            GET => 'handler_whoami',
        },
        acl_profile => 'passerby',
        cli => 'whoami',
        description => 'Display the current employee (i.e. the one we authenticated with)',
        documentation => <<'EOH',
=pod

Displays the profile of the currently logged-in employee
EOH
    },

};

=head2 Activity resources

=cut

$defs->{'activity'} = {

    # /activity
    'activity' =>
    {
        parent => '/',
        handler => 'handler_noop',
        acl_profile => 'passerby',
        cli => 'activity',
        description => 'Parent for activity resources',
        documentation => <<'EOH',
=pod

Parent for activity resources
EOH
    },

    # /activity/aid
    'activity/aid' => 
    {
        parent => 'activity',
        handler => {
            POST => 'handler_post_activity_aid',
        },
        acl_profile => 'admin', 
        cli => 'activity aid',
        description => 'Update an existing activity object via POST request (AID must be included in request body)',
        documentation => <<'EOH',
=pod

Enables existing activity objects to be updated by sending a POST request to
the REST server. Along with the properties to be modified, the request body
must include an 'aid' property, the value of which specifies the AID to be
updated.
EOH
    },

    # /activity/aid/:aid
    'activity/aid/:aid' => 
    {
        parent => 'activity',
        handler => {
            GET => 'handler_activity_aid',
            PUT => 'handler_activity_aid',
            DELETE => 'handler_activity_aid',
        },
        acl_profile => {
            GET => 'active',
            PUT => 'admin',
            DELETE => 'admin',
        },
        cli => 'activity aid $AID',
        validations => {
            'aid' => 'Int',
        },
        description => 'GET, PUT, or DELETE an activity object by its AID',
        documentation => <<'EOH',
=pod

This resource allows the user to GET, PUT, or DELETE an activity object by its
AID.

=over

=item * GET

Retrieves an activity object by its AID.

=item * PUT

Updates the activity object whose AID is specified by the ':aid' URI parameter.
The fields to be updated and their new values should be sent in the request
body, e.g., like this:

    { "long_desc" : "new description", "disabled" : "f" }

=item * DELETE

Deletes the activity object whose AID is specified by the ':aid' URI parameter.
This will work only if nothing in the database refers to this activity.

=back
EOH
    },

    # /activity/all
    'activity/all' =>
    {
        parent => 'activity',
        handler => {
            GET => 'handler_get_activity_all',
        },
        acl_profile => 'passerby',
        cli => 'activity all',
        description => 'Retrieve all activity objects (excluding disabled ones)',
        documentation => <<'EOH',
=pod

Retrieves all activity objects in the database (excluding disabled activities).
EOH
    },

    # /activity/all/disabled
    'activity/all/disabled' =>
    {
        parent => 'activity/all',
        handler => {
            GET => 'handler_get_activity_all_disabled', 
        },
        acl_profile => 'admin', 
        cli => 'activity all disabled',
        description => 'Retrieve all activity objects, including disabled ones',
        documentation => <<'EOH',
=pod

Retrieves all activity objects in the database (including disabled activities).
EOH
    },

    # /activity/code
    'activity/code' => 
    {
        parent => 'activity',
        handler => {
            POST => 'handler_post_activity_code',
        },
        acl_profile => 'admin', 
        cli => 'activity aid',
        description => 'Update an existing activity object via POST request (activity code must be included in request body)',
        documentation => <<'EOH',
=pod

This resource enables existing activity objects to be updated, and new
activity objects to be inserted, by sending a POST request to the REST server.
Along with the properties to be modified/inserted, the request body must
include an 'code' property, the value of which specifies the activity to be
updated.  
EOH
    },

    # /activity/code/:code
    'activity/code/:code' => 
    {
        parent => 'activity',
        handler => {
            GET => 'handler_get_activity_code',
            PUT => 'handler_put_activity_code',
            DELETE => 'handler_delete_activity_code',
        },
        acl_profile => {
            GET => 'passerby',
            PUT => 'admin',
            DELETE => 'admin',
        },
        cli => 'activity code $CODE',
        validations => {
            'code' => qr/^[[:alnum:]_][[:alnum:]_-]+$/,
        },
        description => 'GET, PUT, or DELETE an activity object by its code',
        documentation => <<'EOH',
=pod

With this resource, a user can GET, PUT, or DELETE an activity object by its
code.

=over

=item * GET

Retrieves an activity object by its code.

=item * PUT

Inserts new or updates existing activity object whose code is specified by the
':code' URI parameter.  The fields to be updated and their new values should be
sent in the request body, e.g., like this:

    { "long_desc" : "new description", "disabled" : "f" }

=item * DELETE

Deletes an activity object by its code whose code is specified by the ':code'
URI parameter.  This will work only if nothing in the database refers to this
activity.

=back
EOH
    },

};


=head2 Component resources

=cut

$defs->{'component'} = {

    # /component
    'component' =>
    {
        parent => '/',
        handler => 'handler_noop',
        acl_profile => 'passerby',
        cli => 'component',
        description => 'Parent for component resources',
        documentation => <<'EOH',
=pod

Parent for component resources
EOH
    },

    # /component/all
    'component/all' =>
    {
        parent => 'component',
        handler => {
            GET => 'handler_get_component_all',
        },
        acl_profile => 'admin', 
        cli => 'component all',
        description => 'Retrieve all component objects',
        documentation => <<'EOH',
=pod

Retrieves all component objects in the database.
EOH
    },

    # /component/cid
    'component/cid' => 
    {
        parent => 'component',
        handler => {
            POST => 'handler_post_component_cid',
        },
        acl_profile => 'admin', 
        cli => 'component cid',
        description => 'Update an existing component object via POST request (cid must be included in request body)',
        documentation => <<'EOH',
=pod

Enables existing component objects to be updated by sending a POST request to
the REST server. Along with the properties to be modified, the request body
must include an 'cid' property, the value of which specifies the cid to be
updated.
EOH
    },

    # /component/cid/:cid
    'component/cid/:cid' => 
    {
        parent => 'component',
        handler => {
            GET => 'handler_component_cid',
            PUT => 'handler_component_cid',
            DELETE => 'handler_component_cid',
        },
        acl_profile => 'admin', 
        cli => 'component cid $cid',
        validations => {
            'cid' => 'Int',
        },
        description => 'GET, PUT, or DELETE an component object by its cid',
        documentation => <<'EOH',
=pod

This resource allows the user to GET, PUT, or DELETE an component object by its
cid.

=over

=item * GET

Retrieves an component object by its cid.

=item * PUT

Updates the component object whose cid is specified by the ':cid' URI parameter.
The fields to be updated and their new values should be sent in the request
body, e.g., like this:

    { "path" : "new/path", "source" : "new source", "acl" : "inactive" }

=item * DELETE

Deletes the component object whose cid is specified by the ':cid' URI parameter.
This will work only if nothing in the database refers to this component.

=back
EOH
    },

    # /component/path
    'component/path' => 
    {
        parent => 'component',
        handler => {
            POST => 'handler_post_component_path',
        },
        acl_profile => 'admin', 
        cli => 'component cid',
        description => 'Update an existing component object via POST request (component path must be included in request body)',
        documentation => <<'EOH',
=pod

This resource enables existing component objects to be updated, and new
component objects to be inserted, by sending a POST request to the REST server.
Along with the properties to be modified/inserted, the request body must
include an 'path' property, the value of which specifies the component to be
updated.  
EOH
    },

};


=head2 Employee resources

=cut

$defs->{'employee'} = {

    # /employee
    'employee' =>
    {
        parent => '/',
        handler => 'handler_noop',
        acl_profile => 'passerby',
        cli => 'employee',
        description => 'Parent for employee resources',
        documentation => <<'EOH',
=pod

Parent for employee resources
EOH
    },

    # /employee/count/?:priv
    'employee/count/?:priv' =>
    { 
        parent => 'employee',
        handler => {
            GET => 'handler_get_employee_count', 
        },
        acl_profile => 'admin', 
        cli => 'employee count',
        validations => {
            'priv' => $priv_validation,
        },
        description => 'Display total count of employees (optionally by privlevel)',
        documentation => <<'EOH',
=pod

If ':priv' is not specified, gets the total number of employees in the
database. This includes employees of all privilege levels, including not only
administrators and active employees, but inactives and passerbies as well.

If ':priv' is specified, gets the total number of employees with the
given privlevel. Valid privlevels are: 

=over

=item * passerby

=item * inactive

=item * active

=item * admin

=back
EOH
    },

    # /employee/eid
    'employee/eid' =>
    {
        parent => 'employee',
        handler => {
            POST => 'handler_post_employee_eid', 
        },
        acl_profile => 'inactive', 
        cli => 'employee eid $JSON',
        description => 'Update existing employee (JSON request body with EID required)',
        documentation => <<'EOH',
=pod

This resource provides a way to update employee objects using the
POST method, provided the employee's EID is provided in the content body.
The properties to be modified should also be included, e.g.:

    { "eid" : 43, "fullname" : "Foo Bariful" }

This would change the 'fullname' property of the employee with EID 43 to "Foo
Bariful" (provided such an employee exists).

ACL note: 'inactive' and 'active' employees can use this resource to modify
their own employee profile. Exactly which fields can be updated may differ from
site to site (see the DOCHAZKA_PROFILE_EDITABLE_FIELDS site parameter).
EOH
    },

    # /employee/eid/:eid
    'employee/eid/:eid' =>
    { 
        parent => 'employee',
        handler => {
            GET => 'handler_get_employee_eid', 
            PUT => 'handler_put_employee_eid', 
            DELETE => 'handler_delete_employee_eid',
        },
        acl_profile => {
            GET => 'passerby', 
            PUT => 'inactive',
            DELETE => 'admin',
        },
        cli => 'employee eid $EID [$JSON]',
        validations => {
            eid => 'Int',
        },
        description => 'GET: look up employee (exact match); PUT: update existing employee; DELETE: delete employee',
        documentation => <<'EOH',
=pod

With this resource, we can look up an employee by exact match (GET),
update an existing employee (PUT), or delete an employee (DELETE).

=over

=item * GET

Retrieves an employee object by its EID.  

=item * PUT

Updates the "employee profile" (employee object) of the employee with
the given EID. For example, if the request body was:

    { "fullname" : "Foo Bariful" }

the request would change the 'fullname' property of the employee with EID 43
(provided such an employee exists) to "Foo Bariful". Any 'eid' property
provided in the content body will be ignored.

ACL note: 'inactive' and 'active' employees can use this resource to modify
their own employee profile. Exactly which fields can be updated may differ from
site to site (see the DOCHAZKA_PROFILE_EDITABLE_FIELDS site parameter).

=item * DELETE

Deletes the employee with the given EID (will only work if the EID
exists and nothing in the database refers to it).

=back
EOH
    },

    # /employee/eid/:eid/full
    'employee/eid/:eid/full' =>
    {
        parent => 'employee/eid/:eid',
        handler => {
            GET => 'handler_get_employee_eid_full',
        },
        acl_profile => 'inactive',
        cli => 'employee eid $EID full',
        validations => {
            eid => 'Int',
        },
        description => 'Full employee profile',
        documentation => <<'EOH',
=pod

This resource enables any active employee to retrieve her own
full employee profile. Admins and supervisors can retrieve the
profiles of other employees.
EOH
    },

    # /employee/eid/:eid/minimal
    'employee/eid/:eid/minimal' =>
    {
        parent => 'employee/eid/:eid',
        handler => {
            GET => 'handler_get_employee_minimal', 
        },
        acl_profile => 'passerby',
        cli => 'employee eid $EID minimal',
        validations => {
            eid => 'Int',
        },
        description => 'List minimal info on an employee',
        documentation => <<'EOH',
=pod

This resource enables any employee to get minimal information
on any other employee. Useful for EID to nick conversion or to
look up another employee's email address or name.
EOH
    },

    # /employee/eid/:eid/team
    'employee/eid/:eid/team' =>
    { 
        parent => 'employee/eid/:eid',
        handler => {
            GET => 'handler_get_employee_eid_team', 
        },
        acl_profile => 'admin',
        cli => 'employee eid $EID team',
        validations => {
            eid => 'Int',
        },
        description => 'List the nicks of an employee\'s team members',
        documentation => <<'EOH',
=pod

This resource enables administrators to list the nicks of team members
of an arbitrary employee - i.e. that employee\'s direct reports.
EOH
    },

    # /employee/list/?:priv
    'employee/list/?:priv' =>
    {
        parent => 'employee',
        handler => {
            GET => 'handler_get_employee_list',
        },
        acl_profile => 'admin', 
        cli => 'employee list [$PRIV]',
        validations => {
            'priv' => $priv_validation,
        },
        description => 'List nicks of employees',
        documentation => <<'EOH',
=pod

This resource enables the administrator to easily list the nicks of
employees. If priv is not given, all employees are listed.
EOH
    },

    # /employee/nick
    'employee/nick' =>
    {
        parent => 'employee',
        handler => {
            POST => 'handler_post_employee_nick', 
        },
        acl_profile => 'inactive', 
        cli => 'employee nick $JSON',
        description => 'Insert new/update existing employee (JSON request body with nick required)',
        documentation => <<'EOH',
=pod

This resource provides a way to insert/update employee objects using the
POST method, provided the employee's nick is provided in the content body.

Consider, for example, the following request body:

    { "nick" : "foobar", "fullname" : "Foo Bariful" }

If an employee "foobar" exists, such a request would change the 'fullname'
property of that employee to "Foo Bariful". On the other hand, if the employee
doesn't exist this HTTP request would cause a new employee 'foobar' to be
created.

ACL note: 'inactive' and 'active' employees can use this resource to modify
their own employee profile. Exactly which fields can be updated may differ from
site to site (see the DOCHAZKA_PROFILE_EDITABLE_FIELDS site parameter).
EOH
    },

    # /employee/nick/:nick
    'employee/nick/:nick' =>
    { 
        parent => 'employee',
        handler => {
            GET => 'handler_get_employee_nick', 
            PUT => 'handler_put_employee_nick', 
            DELETE => 'handler_delete_employee_nick',
        },
        acl_profile => {
            GET => 'passerby',
            PUT => 'inactive',
            DELETE => 'admin', 
        },
        cli => 'employee nick $NICK [$JSON]',
        validations => {
            'nick' => $term_validation,
        },
        description => "Retrieves (GET), updates/inserts (PUT), and/or deletes (DELETE) the employee specified by the ':nick' parameter",
        documentation => <<'EOH',
=pod

Retrieves (GET), updates/inserts (PUT), and/or deletes (DELETE) the employee
specified by the ':nick' parameter.

=over

=item * GET

Retrieves employee object(s) by exact match. For example:

    GET employee/nick/foobar

would look for an employee whose nick is 'foobar'. 

=item * PUT

Inserts a new employee or updates an existing one (exact match only).
If a 'nick' property is provided in the content body and its value is
different from the nick provided in the URI, the employee's nick will be
changed to the value provided in the content body.

ACL note: 'inactive' and 'active' employees can use this resource to modify
their own employee profile. Exactly which fields can be updated may differ from
site to site (see the DOCHAZKA_PROFILE_EDITABLE_FIELDS site parameter).

=item * DELETE

Deletes an employee (exact match only). This will work only if the
exact nick exists and nothing else in the database refers to the employee
in question.

=back
EOH
    },

    # /employee/nick/:nick/ldap
    'employee/nick/:nick/ldap' =>
    {
        parent => 'employee/nick/:nick',
        handler => {
            GET => 'handler_get_employee_ldap', 
            PUT => 'handler_put_employee_ldap',
        },
        acl_profile => {
            GET => 'passerby',
            PUT => 'active',
        },
        cli => 'employee nick $nick ldap',
        validations => {
            nick => $term_validation,
        },
        description => 'List LDAP info on an employee',
        documentation => <<'EOH',
=pod

LDAP search and sync resource

=over

=item * GET

Enables any employee to perform an LDAP lookup on any other employee.

=item * PUT

Enables active employees to sync their own employee profile fields[1] from the
site's LDAP database.

Enables admin employees to sync/create[1] any existing employee from the LDAP
database. If the employee does not exist, it will be created (just the employee
object itself, without any privhistory records).

=back

[1] Which fields get synced depends on DOCHAZKA_LDAP_MAPPING site config
parameter.

EOH
    },

    # /employee/nick/:nick/full
    'employee/nick/:nick/full' =>
    {
        parent => 'employee/nick/:nick',
        handler => {
            GET => 'handler_get_employee_nick_full',
        },
        acl_profile => 'active',
        cli => 'employee nick $nick full',
        validations => {
            nick => $term_validation,
        },
        description => 'Full employee profile',
        documentation => <<'EOH',
=pod

This resource enables any active employee to retrieve her own
full employee profile. Admins and supervisors can retrieve the
profiles of other employees.
EOH
    },

    # /employee/nick/:nick/minimal
    'employee/nick/:nick/minimal' =>
    {
        parent => 'employee/nick/:nick',
        handler => {
            GET => 'handler_get_employee_minimal', 
        },
        acl_profile => 'passerby',
        cli => 'employee nick $nick minimal',
        validations => {
            nick => $term_validation,
        },
        description => 'List minimal info on an employee',
        documentation => <<'EOH',
=pod

This resource enables any employee to get minimal information
on any other employee. Useful for nick to EID conversion or to
look up another employee's email address or name.
EOH
    },

    # /employee/nick/:nick/team
    'employee/nick/:nick/team' =>
    { 
        parent => 'employee/nick/:nick',
        handler => {
            GET => 'handler_get_employee_nick_team', 
        },
        acl_profile => 'admin',
        cli => 'employee nick $nick team',
        validations => {
            nick => $term_validation,
        },
        description => 'List the nicks of an employee\'s team members',
        documentation => <<'EOH',
=pod

This resource enables administrators to list the nicks of team members
of an arbitrary employee - i.e. that employee\'s direct reports.
EOH
    },

    # /employee/search
    'employee/search' =>
    {
        parent => 'employee',
        handler => 'handler_noop',
        acl_profile => 'passerby',
        cli => 'employee search',
        description => 'Employee search resources',
        documentation => <<'EOH',
=pod

See child resources.
EOH
    },

    # /employee/search/nick/:key
    'employee/search/nick/:key' =>
    {
        parent => 'employee/search',
        handler => {
            'GET' => 'handler_get_employee_search_nick',
        },
        acl_profile => 'inactive',
        cli => 'employee search nick $KEY',
        description => 'Search employee profiles on nick (% is wild)',
        validations => {
            'key' => qr/^[%[:alnum:]_][%[:alnum:]_-]*$/,
        },
        documentation => <<'EOH',
=pod

Look up employee profiles using a search key, which can optionally contain
a wildcard ('%'). For example:

    GET employee/search/nick/foo%

would return a list of employees whose nick starts with 'foo', provided the '%'
character in the URI is properly encoded (as '%25') by the client.

Note that if the user provides no wildcard characters in the key, they will
implicitly be added. Example: a search for 'foo' would be converted to
'%foo%'. For a literal nick lookup, use the 'employee/nick/:nick' resource.
EOH
    },

    # /employee/sec_id/:sec_id
    'employee/sec_id/:sec_id' =>
    {
        parent => 'employee',
        handler => {
            GET => 'handler_get_employee_sec_id',
        },
        acl_profile => {
            GET => 'passerby'
        },
        cli => 'employee sec_id $SEC_ID',
        description => 'GET an employee profile by the employee\'s secondary ID',
        validations => {
            'sec_id' => $term_validation,
        },
        documentation => <<'EOH',
=pod

Retrieves an employee object by the secondary ID (must be an exact match)
EOH
    },

    # /employee/sec_id/:sec_id/minimal
    'employee/sec_id/:sec_id/minimal' =>
    {
        parent => 'employee/sec_id/:sec_id',
        handler => {
            GET => 'handler_get_employee_minimal', 
        },
        acl_profile => 'passerby',
        cli => 'employee sec_id $sec_id minimal',
        validations => {
            'sec_id' => $term_validation,
        },
        description => 'List minimal info on an employee',
        documentation => <<'EOH',
=pod

This resource enables any employee to get minimal information
on any other employee. Useful for sec_id to EID conversion or to
look up another employee's email address or name.
EOH
    },

    # /employee/self
    'employee/self' =>
    { 
        parent => 'employee',
        handler => {
            GET => 'handler_whoami',
            POST => 'handler_post_employee_self', 
        },
        acl_profile => {
            'GET' => 'passerby', 
            'POST' => 'inactive',
        },
        cli => 'employee current',
        description => 'Retrieve (GET) and edit (POST) our own employee profile',
        documentation => <<'EOH',
=pod

With this resource, we can retrieve (GET) and/or edit (POST) our own employee
profile.

=over

=item * GET

Displays the profile of the currently logged-in employee. The information
is limited to just the employee object itself.

=item * POST

Provides a way for an employee to update certain fields of her own employee
profile. Exactly which fields can be updated may differ from site to site
(see the DOCHAZKA_PROFILE_EDITABLE_FIELDS site parameter).

=back
EOH
    },

    # /employee/self/full
    'employee/self/full' =>
    { 
        parent => 'employee/self',
        handler => {
            GET => 'handler_get_employee_self_full',
        },
        acl_profile => 'passerby',
        cli => 'employee current priv',
        description => 'Retrieve our own employee profile, privlevel, and schedule', 
        documentation => <<'EOH',
=pod

Displays the "full profile" of the currently logged-in employee. The
information includes the full employee object (taken from the 'current_emp'
property) as well as the employee's current privlevel and schedule, which are
looked up from the database.

N.B. The value of the "schedule" property is just the SID, not the actual
schedule record.
EOH
    },

    # /employee/team
    'employee/team' =>
    {
        parent => 'employee',
        handler => {
            GET => 'handler_get_employee_team',
        },
        acl_profile => 'active', 
        cli => 'team',
        description => 'List nicks of the logged-in employee\'s team members',
        documentation => <<'EOH',
=pod

This resource enables supervisors to easily list the nicks of
employees in their team - i.e. their direct reports.
EOH
    },

};


=head2 Genreport resources

=cut

$defs->{'genreport'} = {

    # /genreport
    'genreport' => 
    {
        parent => '/',
        handler => {
            GET => 'handler_noop',
            POST => 'handler_genreport',
        },
        acl_profile => {
            GET => 'passerby',
            POST => 'admin',
        },
        cli => 'genreport',
        description => 'Generate reports',
        documentation => <<'EOH',
=pod

The "POST genreport" resource generates reports from Mason templates.
The resource takes a request body with one mandatory property, "path"
(corresponding to the path of a Mason component relative to the component
root), and one optional property, "parameters", which should be a hash
of parameter names and values.

The resource handler checks (1) if the component exists in the database,
(2) whether current employee has sufficient permissions to generate the
report (by comparing the employee's privlevel with the ACL profile of the
component), and (3) validates the parameters, if any, by applying the 
validation rules specified in the component object. Iff all of these
conditions are met, the component is called with the provided parameters.
EOH
    },

};


=head2 History resources

=cut

$defs->{'history'} = {

    'priv/history' => 
    {
        parent => 'priv',
        handler => 'handler_noop',
        cli => 'priv history',
        description => 'Privilege history resources',
        documentation => <<'EOH',
=pod

This resource presents a list of subresources, all related to privilege histories.
EOH
    },

    'schedule/history' => 
    {
        parent => 'schedule',
        handler => 'handler_noop',
        cli => 'schedule history',
        description => 'Schedule history resources',
        documentation => <<'EOH',
=pod

This resource presents a list of subresources, all related to schedule histories.
EOH
    },

    'priv/history/eid/:eid' =>
    { 
        parent => 'priv/history',
        handler => {
            GET => 'handler_history_get_multiple',
            POST => 'handler_history_post',
        },
        acl_profile => {
            GET => 'inactive',
            POST => 'admin',
        },
        cli => 'priv history eid $EID [$JSON]',
        validations => {
            'eid' => 'Int',
        },
        description => 'Retrieves entire history of privilege level changes for employee with the given EID (GET); or, with an appropriate content body, adds (POST) a record to employee\'s privhistory',
        documentation => <<'EOH',
=pod

Retrieves entire history of privilege level changes for employee with the given
EID (GET); or, with an appropriate content body, adds (POST) a record to
employee\'s privhistory.

=over

=item * GET

Retrieves the "privhistory", or history of changes in
privilege level, of the employee with the given EID.

=item * POST

Adds a record to the privhistory of the given employee. The content body should
contain two properties: "effective" (a timestamp) and "priv" (one of
"passerby", "inactive", "active", or "admin").

It is assumed that schedule histories will be built up record-by-record; 
insertion of multiple history records in a single request is not supported.

=back

Update note: histories can be updated by adding new records and deleting old
ones. Existing history records cannot be changed. Adds/deletes should be
performed with due care - especially with regard to existing employee
attendance data (if any).
EOH
    },

    'schedule/history/eid/:eid' =>
    { 
        parent => 'schedule/history',
        handler => {
            GET => 'handler_history_get_multiple',
            POST => 'handler_history_post',
        },
        acl_profile => {
            GET => 'inactive',
            POST => 'admin',
        },
        cli => 'schedule history eid $EID [$JSON]',
        validations => {
            'eid' => 'Int',
        },
        description => 'Retrieves entire history of schedule changes for employee with the given EID (GET); or, with an appropriate content body, adds (POST) a record to employee\'s schedule history',
        documentation => <<'EOH',
=pod

Retrieves entire history of schedule changes for employee with the given EID
(GET); or, with an appropriate content body, adds (POST) a record to
employee\'s schedule history.

=over

=item * GET

Retrieves the full history of schedule changes of the employee with the given EID.
For partial history, see 'schedule/history/eid/:eid/:tsrange'.

=item * POST

Adds a record to the schedule history of the given employee. The content body should
contain two properties: "effective" (a timestamp) and "sid" (the ID of the schedule).
Alternatively, an "scode" property (schedule code) can be sent instead of "sid".

It is assumed that schedule histories will be built up record-by-record; 
insertion of multiple history records in a single request is not supported.

=back

Update note: histories can be updated by adding new records and deleting old
ones. Existing history records cannot be changed. Adds/deletes should be
performed with due care - especially with regard to existing employee
attendance data (if any).
EOH
    },

    'priv/history/eid/:eid/:tsrange' =>
    {
        parent => 'priv/history',
        handler => {
            GET => 'handler_history_get_multiple',
        },
        acl_profile => 'inactive',
        cli => 'priv history eid $EID $TSRANGE',
        description => 'Get a slice of history of privilege level changes for employee with the given EID',
        validations => {
            'eid' => 'Int',
            'tsrange' => $tsrange_validation,
        },
        documentation => <<'EOH',
=pod

Retrieves a slice (given by the tsrange argument) of the employee's
"privhistory" (history of changes in privilege level).
EOH
    },

    'schedule/history/eid/:eid/:tsrange' =>
    {
        parent => 'schedule/history',
        handler => {
            GET => 'handler_history_get_multiple',
        },
        acl_profile => 'inactive',
        cli => 'schedule history eid $EID $TSRANGE',
        description => 'Get a slice of history of schedule changes for employee with the given EID',
        validations => {
            'eid' => 'Int',
            'tsrange' => $tsrange_validation,
        },
        documentation => <<'EOH',
=pod

Retrieves a slice (given by the tsrange argument) of the employee's
"schedule history" (history of changes in schedule).
EOH
    },

    'priv/history/eid/:eid/:ts' =>
    {
        parent => 'priv/history',
        handler => {
            GET => 'handler_history_get_single',
        },
        acl_profile => 'inactive',
        cli => 'priv history eid $EID $TS',
        description => 'Get the privhistory record effective at a given timestamp',
        validations => {
            'eid' => 'Int',
            'ts' => $ts_validation,
        },
        documentation => <<'EOH',
=pod

Retrieves an employee's effective privhistory record (status change) as of a
given timestamp.
EOH
    },

    'schedule/history/eid/:eid/:ts' =>
    {
        parent => 'schedule/history',
        handler => {
            GET => 'handler_history_get_single',
        },
        acl_profile => 'inactive',
        cli => 'schedule history eid $EID $TS',
        description => 'Get the privhistory record effective at a given timestamp',
        validations => {
            'eid' => 'Int',
            'ts' => $ts_validation,
        },
        documentation => <<'EOH',
=pod

Retrieves an employee's effective schedhistory record (status change) as of a
given timestamp.
EOH
    },

    'priv/history/eid/:eid/now' =>
    {
        parent => 'priv/history',
        handler => {
            GET => 'handler_history_get_single',
        },
        acl_profile => 'inactive',
        cli => 'priv history eid $EID now',
        description => 'Get the privhistory record effective as of "now" (the current timestamp)',
        validations => {
            'eid' => 'Int',
        },
        documentation => <<'EOH',
=pod

Retrieves an employee's effective privhistory record (status change) as of
"now" (the current timestamp).
EOH
    },

    'schedule/history/eid/:eid/now' =>
    {
        parent => 'schedule/history',
        handler => {
            GET => 'handler_history_get_single',
        },
        acl_profile => 'inactive',
        cli => 'schedule history eid $EID now',
        description => 'Get the privhistory record effective as of "now" (the current timestamp)',
        validations => {
            'eid' => 'Int',
        },
        documentation => <<'EOH',
=pod

Retrieves an employee's effective schedhistory record (status change) as of
"now" (the current timestamp).
EOH
    },

    'priv/history/nick/:nick' =>
    { 
        parent => 'priv/history',
        handler => {
            GET => 'handler_history_get_multiple',
            POST => 'handler_history_post', 
        },
        acl_profile => {
            GET => 'inactive',
            POST => 'admin',
        },
        cli => 'priv history nick $NICK [$JSON]',
        validations => {
            'nick' => $term_validation,
        },
        description => 'Retrieves entire history of privilege level changes for employee with the given nick (GET); or, with an appropriate content body, adds (PUT) a record to employee\'s privhistory',
        documentation => <<'EOH',
=pod

Retrieves entire history of privilege level changes for employee with the given
nick (GET); or, with an appropriate content body, adds (PUT) a record to
employee\'s privhistory.

=over

=item * GET

Retrieves the "privhistory", or history of changes in
privilege level, of the employee with the given nick.

=item * POST

Adds a record to the privhistory of the given employee. The content body should
contain two properties: "effective" (a timestamp) and "priv" (one of
"passerby", "inactive", "active", or "admin").

It is assumed that schedule histories will be built up record-by-record; 
insertion of multiple history records in a single request is not supported.

=back

Update note: histories can be updated by adding new records and deleting old
ones. Existing history records cannot be changed. Adds/deletes should be
performed with due care - especially with regard to existing employee
attendance data (if any).
EOH
    },

    'schedule/history/nick/:nick' =>
    { 
        parent => 'schedule/history',
        handler => {
            GET => 'handler_history_get_multiple',
            POST => 'handler_history_post', 
        },
        acl_profile => {
            GET => 'inactive',
            POST => 'admin',
        },
        cli => 'schedule history nick $NICK [$JSON]',
        validations => {
            'nick' => $term_validation,
        },
        description => 'Retrieves entire history of schedule changes for employee with the given nick (GET); or, with an appropriate content body, adds (PUT) a record to employee\'s schedule history',
        documentation => <<'EOH',
=pod

Retrieves entire history of schedule changes for employee with the given nick
(GET); or, with an appropriate content body, adds (PUT) a record to employee\'s
schedule history.
        
=over

=item * GET

Retrieves the full history of schedule changes of the employee with the given nick.
For partial histories, see 'schedule/history/nick/:nick/:tsrange'.

=item * POST

Adds a record to the schedule history of the given employee. The content body should
contain two properties: "effective" (a timestamp) and "sid" (the ID of the schedule).
Alternatively, an "scode" property (schedule code) can be sent instead of "sid".

It is assumed that schedule histories will be built up record-by-record; 
insertion of multiple history records in a single request is not supported.

=back

Update note: histories can be updated by adding new records and deleting old
ones. Existing history records cannot be changed. Adds/deletes should be
performed with due care - especially with regard to existing employee
attendance data (if any).
EOH
    },

    'priv/history/nick/:nick/:tsrange' =>
    { 
        parent => 'priv/history',
        handler => {
            GET => 'handler_history_get_multiple',
        },
        acl_profile => 'inactive',
        cli => 'priv history nick $NICK $TSRANGE',
        validations => {
            'nick' => $term_validation,
            'tsrange' => $tsrange_validation,
        },
        description => 'Get partial history of privilege level changes for employee with the given nick ' . 
                     '(i.e, limit to given tsrange)',
        documentation => <<'EOH',
=pod

Retrieves a slice (given by the tsrange argument) of the employee's
"privhistory" (history of changes in privilege level).
EOH
    },

    'schedule/history/nick/:nick/:tsrange' =>
    { 
        parent => 'schedule/history',
        handler => {
            GET => 'handler_history_get_multiple',
        },
        acl_profile => 'inactive',
        cli => 'schedule history nick $NICK $TSRANGE',
        validations => {
            'nick' => $term_validation,
            'tsrange' => $tsrange_validation,
        },
        description => 'Get partial history of schedule changes for employee with the given nick ' . 
                     '(i.e, limit to given tsrange)',
        documentation => <<'EOH',
=pod

Retrieves a slice (given by the tsrange argument) of the employee's
"schedule history" (history of changes in schedule). 
EOH
    },

    'priv/history/phid/:phid' => 
    {
        parent => 'priv/history',
        handler => {
            GET => 'handler_history_get_phid',
            POST => 'handler_history_post_phid',
            DELETE => 'handler_history_delete_phid',
        },
        acl_profile => 'admin',
        cli => 'priv history phid $PHID',
        validations => {
            'phid' => 'Int',
        },
        description => 'Retrieves (GET), updates (POST), or deletes (DELETE) a single privilege history record by its PHID',
        documentation => <<'EOH',
=pod

Retrieves (GET), updates (POST), or deletes (DELETE) a single privilege history record by its
PHID.

=over

=item * GET

Retrieves a privhistory record by its PHID.

=item * POST

Updates a privilege history record by its PHID. The 'phid' and 'eid'
properties cannot be changed in this way.

=item * DELETE

Deletes a privhistory record by its PHID.

=back

(N.B.: history records can be added using POST requests on "priv/history/eid/:eid" or
"priv/history/nick/:nick")
EOH
    },

    'schedule/history/shid/:shid' => 
    {
        parent => 'schedule/history',
        handler => {
            GET => 'handler_history_get_shid',
            POST => 'handler_history_post_shid',
            DELETE => 'handler_history_delete_shid',
        },
        acl_profile => 'admin',
        cli => 'schedule history phid $PHID',
        validations => {
            'shid' => 'Int',
        },
        description => 'Retrieves (GET), updates (POST), or deletes (DELETE) a single schedule history record by its SHID',
        documentation => <<'EOH',
=pod

Retrieves (GET), updates (POST), or deletes (DELETE) a single schedule
history record by its SHID.

=over

=item * GET

Retrieves a schedule history record by its SHID.

=item * POST

Updates a schedule history record by its SHID. The 'shid' and 'eid'
properties cannot be changed in this way.

=item * DELETE

Deletes a schedule history record by its SHID.

=back

(N.B.: history records can be added using POST requests on "schedule/history/eid/:eid" or
"schedule/history/nick/:nick")
EOH
    },

    'priv/history/self/?:tsrange' =>
    { 
        parent => 'priv/history',
        handler => {
            GET => 'handler_history_self', 
        },
        acl_profile => 'inactive',
        cli => 'priv history self [$TSRANGE]',
        validations => {
            'tsrange' => $tsrange_validation,
        },
        description => 'Retrieves privhistory of present employee, with option to limit to :tsrange',
        documentation => <<'EOH',
=pod

This resource retrieves the "privhistory", or history of changes in
privilege level, of the present employee. Optionally, the listing can be
limited to a specific tsrange such as 

    "[2014-01-01, 2014-12-31)"

EOH
    },

    'schedule/history/self/?:tsrange' =>
    { 
        parent => 'schedule/history',
        handler => {
            GET => 'handler_history_self', 
        },
        acl_profile => 'inactive',
        cli => 'schedule history self [$TSRANGE]',
        validations => {
            'tsrange' => $tsrange_validation,
        },
        description => 'Retrieves schedule history of present employee, with option to limit to :tsrange',
        documentation => <<'EOH',
=pod

This resource retrieves the "schedule history", or history of changes in
schedule, of the present employee. Optionally, the listing can be
limited to a specific tsrange such as 

    "[2014-01-01, 2014-12-31)"

EOH
    },

};


=head2 Interval resources

=cut

$defs->{'interval'} = {

    # /interval
    'interval' =>
    {
        parent => '/',
        handler => 'handler_noop',
        acl_profile => 'passerby',
        cli => 'interval',
        description => 'Parent for interval resources',
        documentation => <<'EOH',
=pod

Parent for interval resources
EOH
    },

    # /interval/eid/:eid/:tsrange
    'interval/eid/:eid/:tsrange' => 
    {
        parent => 'interval',
        handler => {
            GET => 'handler_interval_eid',
            DELETE => 'handler_interval_eid',
        },
        acl_profile => {
            GET => 'inactive', 
            DELETE => 'active',
        },
        cli => 'interval eid $EID $TSRANGE',
        validations => {
            'eid' => 'Int',
            'tsrange' => $tsrange_validation,
        },
        description => 'Retrieve an arbitrary employee\'s intervals over the given tsrange',
        documentation => <<'EOH',
=pod

With this resource, administrators can retrieve any employee's intervals 
over a given tsrange, and active employees can do the same with their own intervals. 

Before any records are returned, the tsrange is checked to see if it overlaps with
any privlevel or schedule changes - in which case an error is returned. This is so
interval report-generators do not have to handle changes in employee status.

By default, the number of intervals returned is limited to 500. This number
can be changed via the DOCHAZKA_INTERVAL_SELECT_LIMIT site configuration
parameter (set to 'undef' for no limit).
EOH
    },

    # /interval/eid/:eid/:ts/:psqlint'
    'interval/eid/:eid/:ts/:psqlint' => 
    {
        parent => 'interval',
        handler => {
            GET => 'handler_interval_eid',
            DELETE => 'handler_interval_eid',
        },
        acl_profile => 'active', 
        cli => 'interval eid $EID $TS DELTA $PSQLINT',
        validations => {
            'eid' => 'Int',
            'ts' => $ts_validation,
            'psqlint' => $psqlint_validation,
        },
        description => 'Retrieve an arbitrary employee\'s intervals falling within a time period',
        documentation => <<'EOH',
=pod

This is just like 'interval/eid/:eid/:tsrange' except that the time range is
specified by giving a timestamp and a PostgreSQL time interval, e.g "1 week 3 days".
EOH
    },

    # /interval/fillup
    'interval/fillup' =>
    {
        parent => 'interval',
        handler => {
            POST => 'handler_interval_fillup',
        },
        acl_profile => {
            POST => 'active',
        },
        cli => 'interval fillup',
        description => 'Generate intervals according to schedule',
        documentation => <<'EOH',
=pod

Used with POST to create multiple attendance intervals for an employee,
according to the prevailing schedule.

The request body is a JSON object with the following parameters:

=over

=item * C<eid> (the EID of the employee to create intervals for; alternatively, C<nick> or C<sec_id>)

=item * C<tsrange> (the time span over which to create intervals)

=item * C<datelist> (a list of dates to create intervals for)

=item * C<dry_run> (boolean value)

=item * C<aid> (the AID of the activity; alternatively, C<code>)

=item * C<desc> (optional interval description)

=item * C<remark> (optional remark)

=back

If C<tsrange> is provided, C<datelist> should be omitted - and vice versa.

If C<dry_run> is true, the resource does not change the database state.
EOH
    },

    # /interval/iid
    'interval/iid' => 
    {
        parent => 'interval',
        handler => {
            POST => 'handler_post_interval_iid',
        },
        acl_profile => 'active', 
        cli => 'interval iid $JSON',
        description => 'Update an existing interval object via POST request (iid must be included in request body)',
        documentation => <<'EOH',
=pod

Enables existing interval objects to be updated by sending a POST request to
the REST server. Along with the properties to be modified, the request body
must include an 'iid' property, the value of which specifies the iid to be
updated.
EOH
    },

    # /interval/iid/:iid
    'interval/iid/:iid' => 
    {
        parent => 'interval',
        handler => {
            GET => 'handler_get_interval_iid',
            PUT => 'handler_interval_iid',
            DELETE => 'handler_interval_iid',
        },
        acl_profile => {
            GET => 'inactive',
            PUT => 'active',
            DELETE => 'active',
        },
        cli => 'interval iid $iid [$JSON]',
        validations => {
            'iid' => 'Int',
        },
        description => 'GET, PUT, or DELETE an interval object by its iid',
        documentation => <<'EOH',
=pod

This resource makes it possible to GET, PUT, or DELETE an interval object by
its IID.

=over

=item * GET

Retrieves an interval object by its IID.

=item * PUT

Updates the interval object whose iid is specified by the ':iid' URI parameter.
The fields to be updated and their new values should be sent in the request
body, e.g., like this:

    { 
        "eid" : 34, 
        "aid" : 1, 
        "intvl" : '[ 2014-11-18 08:00, 2014-11-18 12:00 )' 
    }

=item * DELETE

Deletes the interval object whose iid is specified by the ':iid' URI parameter.
As long as the interval does not overlap with a lock interval, the delete operation
will probably work as expected.

=back

ACL note: 'active' employees can update/delete only their own unlocked intervals.
EOH
    },

    # /interval/new
    'interval/new' => 
    {
        parent => 'interval',
        handler => {
            POST => 'handler_interval_new',
        },
        acl_profile => 'active', 
        cli => 'interval new $JSON',
        description => 'Add a new attendance data interval',
        documentation => <<'EOH',
=pod

This is the resource by which employees add new attendance data to the
database. It takes a request body containing, at the very least, C<aid> and
C<intvl> properties. Additionally, it can contain C<long_desc>, while
administrators can also specify C<eid> and C<remark>.
EOH
    },

    # /interval/nick/:nick/:tsrange
    'interval/nick/:nick/:tsrange' => 
    {
        parent => 'interval',
        handler => {
            GET => 'handler_interval_nick',
            DELETE => 'handler_interval_nick',
        },
        acl_profile => {
            GET => 'inactive', 
            DELETE => 'active',
        },
        cli => 'interval nick $NICK $TSRANGE',
        validations => {
            'nick' => $term_validation,
            'tsrange' => $tsrange_validation,
        },
        description => 'Retrieve an arbitrary employee\'s intervals over the given tsrange',
        documentation => <<'EOH',
=pod

With this resource, administrators can retrieve any employee's intervals 
over a given tsrange, and active employees can do the same with their own intervals. 

Before any records are returned, the tsrange is checked to see if it overlaps with
any privlevel or schedule changes - in which case an error is returned. This is so
interval report-generators do not have to handle changes in employee status.

By default, the number of intervals returned is limited to 500. This number
can be changed via the DOCHAZKA_INTERVAL_SELECT_LIMIT site configuration
parameter (set to 'undef' for no limit).
EOH
    },

    # /interval/nick/:nick/:ts/:psqlint'
    'interval/nick/:nick/:ts/:psqlint' => 
    {
        parent => 'interval',
        handler => {
            GET => 'handler_interval_nick',
            DELETE => 'handler_interval_nick',
        },
        acl_profile => 'active', 
        cli => 'interval nick $NICK $TS DELTA $PSQLINT',
        validations => {
            'nick' => $term_validation,
            'ts' => $ts_validation,
            'psqlint' => $psqlint_validation,
        },
        description => 'Retrieve an arbitrary employee\'s intervals falling within a time period',
        documentation => <<'EOH',
=pod

This is just like 'interval/nick/:nick/:tsrange' except that the time range is
specified by giving a timestamp and a PostgreSQL time interval, e.g "1 week 3 days".
EOH
    },

    # /interval/scheduled
    'interval/scheduled' =>
    {
        parent => 'interval',
        handler => {
            POST => 'handler_interval_scheduled',
        },
        acl_profile => {
            POST => 'inactive',
        },
        cli => 'interval scheduled',
        description => 'Generate intervals according to schedule',
        documentation => <<'EOH',
=pod

Used with POST to generate intervals according to an employee's schedule,
without actually creating any intervals - for example, to find out what
intervals are scheduled for a given day.

(This resource is very similar to C<interval/fillup>. The key difference is it
does not check for existing attendance intervals that might conflict. As a
result, it can easily produce conflicts if used with C<<dry_run => 0>> (false).  
If you want a list of non-conflicting intervals, use C<interval/fillup> with
C<<dry_run => 1>> (true).)

The request body takes the following parameters:

=over

=item * C<eid> (the EID of the employee to create intervals for; alternatively, C<nick> or C<sec_id>)

=item * C<tsrange> (the time span over which to create intervals)

=item * C<datelist> (a list of dates to create intervals for)

=back

If C<tsrange> is provided, C<datelist> should be omitted - and vice versa.

EOH
    },

    # /interval/self/:tsrange
    'interval/self/:tsrange' => 
    {
        parent => 'interval',
        handler => {
            GET => 'handler_interval_self',
            DELETE => 'handler_interval_self',
        },
        acl_profile => 'inactive', 
        cli => 'interval self $TSRANGE',
        validations => {
            'tsrange' => $tsrange_validation,
        },
        description => 'Retrieve one\'s own intervals over the given tsrange',
        documentation => <<'EOH',
=pod

With this resource, employees can retrieve their own attendance intervals 
over a given tsrange. 

Before any records are returned, the tsrange is checked to see if it overlaps with
any privlevel or schedule changes - in which case an error is returned. This is so
interval report-generators do not have to handle changes in employee status.

By default, the number of intervals returned is limited to 500. This number
can be changed via the DOCHAZKA_INTERVAL_SELECT_LIMIT site configuration
parameter (set to 'undef' for no limit).
EOH
    },

    # /interval/self/:ts/:psqlint'
    'interval/:self/:ts/:psqlint' => 
    {
        parent => 'interval',
        handler => {
            GET => 'handler_interval_self',
            DELETE => 'handler_interval_self',
        },
        acl_profile => 'active', 
        cli => 'INTERVAL SELF $TS DELTA $PSQLINT',
        validations => {
            'ts' => $ts_validation,
            'psqlint' => $psqlint_validation,
        },
        description => 'Retrieve one\'s own intervals falling within a time period',
        documentation => <<'EOH',
=pod

This is just like 'interval/self/:tsrange' except that the time range is
specified by giving a timestamp and a PostgreSQL time interval, e.g "1 week 3 days".
EOH
    },

    # /interval/summary/eid/:eid/:tsrange
    'interval/summary/eid/:eid/:tsrange' => {
        parent => 'interval',
        handler => {
            GET => 'handler_get_interval_summary',
        },
        acl_profile => 'inactive', 
        cli => 'interval summary',
        description => 'Retrieve summary of an employee\'s intervals over a time period',
        documentation => <<'EOH',
=pod

With this resource, employees can generate summaries of their attendance intervals
over a given period. 

EOH
    },

};


=head2 Lock resources

=cut

$defs->{'lock'} = {

    # /lock
    'lock' =>
    {
        parent => '/',
        handler => 'handler_noop',
        acl_profile => 'passerby',
        cli => 'lock',
        description => 'Parent for lock resources',
        documentation => <<'EOH',
=pod

Parent for lock resources
EOH
    },

    # /lock/eid/:eid/:tsrange
    'lock/eid/:eid/:tsrange' => 
    {
        parent => 'lock',
        handler => {
            GET => 'handler_get_lock_eid',
        },
        acl_profile => 'active', 
        cli => 'lock eid $EID $TSRANGE',
        validations => {
            'eid' => 'Int',
            'tsrange' => $tsrange_validation,
        },
        description => 'Retrieve an arbitrary employee\'s locks over the given tsrange',
        documentation => <<'EOH',
=pod

With this resource, administrators can retrieve any employee's locks 
over a given tsrange. 

There are no syntactical limitations on the tsrange, but if too many records would
be fetched, the return status will be C<DISPATCH_TOO_MANY_RECORDS_FOUND>.
EOH
    },

    # /lock/lid
    'lock/lid' => 
    {
        parent => 'lock',
        handler => {
            POST => 'handler_post_lock_lid',
        },
        acl_profile => 'admin', 
        cli => 'lock lid $JSON',
        description => 'Update an existing lock object via POST request (lid must be included in request body)',
        documentation => <<'EOH',
=pod

Enables existing lock objects to be updated by sending a POST request to
the REST server. Along with the properties to be modified, the request body
must include an 'lid' property, the value of which specifies the lid to be
updated.
EOH
    },

    # /lock/lid/:lid
    'lock/lid/:lid' => 
    {
        parent => 'lock',
        handler => {
            GET => 'handler_get_lock_lid',
            PUT => 'handler_lock_lid',
            DELETE => 'handler_lock_lid',
        },
        acl_profile => {
            GET => 'active',
            PUT => 'admin',
            DELETE => 'admin',
        },
        cli => 'lock lid $lid [$JSON]',
        validations => {
            'lid' => 'Int',
        },
        description => 'GET, PUT, or DELETE an lock object by its LID',
        documentation => <<'EOH',
=pod

This resource makes it possible to GET, PUT, or DELETE an lock object by its
LID.

=over

=item * GET

Retrieves an lock object by its lid.

=item * PUT

Updates the lock object whose lid is specified by the ':lid' URI parameter.
The fields to be updated and their new values should be sent in the request
body, e.g., like this:

    { 
        "eid" : 34, 
        "intvl" : '[ 2014-11-18 00:00, 2014-11-18 24:00 )' 
    }

=item * DELETE

Deletes the lock object whose lid is specified by the ':lid' URI parameter.

=back

ACL note: 'active' employees can view only their own locks, and of course
admin privilege is required to modify or remove a lock.
EOH
    },
    # /lock/new
    'lock/new' => 
    {
        parent => 'lock',
        handler => {
            POST => 'handler_lock_new',
        },
        acl_profile => 'active', 
        cli => 'lock new $JSON',
        description => 'Add a new attendance data lock',
        documentation => <<'EOH',
=pod

This is the resource by which the attendance data entered by an employee 
for a given time period can be "locked" to prevent any subsequent
modifications.  It takes a request body containing, at the very least, an
C<intvl> property specifying the tsrange to lock. Additionally, administrators
can specify C<remark> and C<eid> properties.
EOH
    },

    # /lock/nick/:nick/:tsrange
    'lock/nick/:nick/:tsrange' => 
    {
        parent => 'lock',
        handler => {
            GET => 'handler_get_lock_nick',
        },
        acl_profile => 'active', 
        cli => 'lock nick $NICK $TSRANGE',
        validations => {
            'nick' => $term_validation,
            'tsrange' => $tsrange_validation,
        },
        description => 'Retrieve an arbitrary employee\'s locks over the given tsrange',
        documentation => <<'EOH',
=pod

With this resource, administrators can retrieve any employee's locks 
over a given tsrange. 

There are no syntactical limitations on the tsrange, but if too many records would
be fetched, the return status will be C<DISPATCH_TOO_MANY_RECORDS_FOUND>.
EOH
    },

    # /lock/self/:tsrange
    'lock/self/:tsrange' => 
    {
        parent => 'lock',
        handler => {
            GET => 'handler_get_lock_self',
        },
        acl_profile => 'inactive', 
        cli => 'lock self $TSRANGE',
        validations => {
            'tsrange' => $tsrange_validation,
        },
        description => 'Retrieve one\'s own locks over the given tsrange',
        documentation => <<'EOH',
=pod

With this resource, employees can retrieve their own attendance locks 
over a given tsrange. 

There are no syntactical limitations on the tsrange, but if too many records would
be fetched, the return status will be C<DISPATCH_TOO_MANY_RECORDS_FOUND>.
EOH
    },

};


=head2 Priv (non-history) resources

=cut

$defs->{'priv'} = {

    # /priv
    'priv' => 
    {
        parent => '/',
        handler => 'handler_noop',
        acl_profile => 'passerby',
        cli => 'priv',
        description => 'Privilege resources',
        documentation => <<'EOH',
=pod

This resource presents a list of subresources, all related to employee privileges.
EOH
    },

    # /priv/eid/:eid/?:ts
    'priv/eid/:eid/?:ts' => 
    { 
        parent => 'priv',
        handler => {
            GET => 'handler_priv_get_eid',
        },
        acl_profile => 'passerby', 
        cli => 'priv eid $EID [$TIMESTAMP]',
        validations => {
            'eid' => 'Int',
        },
        description => 'Get the present privlevel of arbitrary employee, or with optional timestamp, that employee\'s privlevel as of that timestamp',
        documentation => <<'EOH',
=pod

This resource retrieves the privlevel of an arbitrary employee specified by EID.

If no timestamp is given, the present privlevel is retrieved. If a timestamp
is present, the privlevel as of that timestamp is retrieved.
EOH
    },

    # /priv/nick/:nick/?:ts
    'priv/nick/:nick/?:ts' => 
    { 
        parent => 'priv',
        handler => {
            GET => 'handler_priv_get_nick',
        },
        acl_profile => 'passerby', 
        cli => 'priv nick $NICK [$TIMESTAMP]',
        validations => {
            'nick' => $term_validation,
        },
        description => 'Get the present privlevel of arbitrary employee, or with optional timestamp, that employee\'s privlevel as of that timestamp',
        documentation => <<'EOH',
=pod

This resource retrieves the privlevel of an arbitrary employee specified by nick.

If no timestamp is given, the present privlevel is retrieved. If a timestamp
is present, the privlevel as of that timestamp is retrieved.
EOH
    },

    # /priv/self/?:ts
    'priv/self/?:ts' => 
    { 
        parent => 'priv',
        handler => {
            GET => 'handler_priv_get_self',
        },
        acl_profile => 'passerby', 
        cli => 'priv self [$TIMESTAMP]',
        description => 'Get the present privlevel of the currently logged-in employee, or with optional timestamp, that employee\'s privlevel as of that timestamp',
        documentation => <<'EOH',
=pod

This resource retrieves the privlevel of the caller (currently logged-in employee).

If no timestamp is given, the present privlevel is retrieved. If a timestamp
is present, the privlevel as of that timestamp is retrieved.
EOH
    },

};


=head2 Schedule (non-history) resources

=cut

$defs->{'schedule'} = {

    # /schedule
    'schedule' => 
    {
        parent => '/',
        handler => 'handler_noop',
        acl_profile => 'passerby',
        cli => 'schedule',
        description => 'Schedule resources',
        documentation => <<'EOH',
=pod

This resource presents a list of "child" resources (subresources), all of which
are related to schedules.  
EOH
    },

    # /schedule/all
    'schedule/all' => 
    { 
        parent => 'schedule',
        handler => {
            GET => 'handler_schedule_all',
        },
        acl_profile => 'inactive', 
        cli => 'schedule all',
        description => 'Retrieves (GET) all non-disabled schedules',
        documentation => <<'EOH',
=pod

This resource returns a list (array) of all schedules for which the 'disabled' field has
either not been set or has been set to 'false'.
EOH
    },

    # /schedule/all/disabled
    'schedule/all/disabled' => 
    { 
        parent => 'schedule/all',
        handler => {
            GET => 'handler_schedule_all',
        },
        acl_profile => 'admin', 
        cli => 'schedule all disabled',
        description => 'Retrieves (GET) all schedules (disabled and non-disabled)',
        documentation => <<'EOH',
=pod

This resource returns a list (array) of all schedules, regardless of the contents
of the 'disabled' field.
EOH
    },

    # /schedule/eid/:eid/?:ts
    'schedule/eid/:eid/?:ts' => 
    { 
        parent => 'schedule',
        handler => {
            GET => 'handler_get_schedule_eid',
        },
        acl_profile => 'passerby',
        cli => 'schedule eid $EID [$TIMESTAMP]',
        validations => {
            'eid' => 'Int',
        },
        description => 'Get the current schedule of arbitrary employee, or with optional timestamp, that employee\'s schedule as of that timestamp',
        documentation => <<'EOH',
=pod

This resource retrieves the schedule of an arbitrary employee specified by EID.

If no timestamp is given, the current schedule is retrieved. If a timestamp
is present, the schedule as of that timestamp is retrieved.
EOH
    },

    # /schedule/new
    'schedule/new' => 
    { 
        parent => 'schedule',
        handler => {
            POST => 'handler_schedule_new',
        },
        acl_profile => 'admin', 
        cli => 'schedule new $JSON',
        description => 'Insert schedules',
        documentation => <<'EOH',
=pod

Given a set of intervals, all of which must fall within a single contiguous
168-hour (7-day) period, this resource performs all actions necessary to either
create a new schedule from those intervals or verify that an equivalent
schedule already exists.

Sample JSON:

    { "schedule" : [
        "[2014-09-22 08:00, 2014-09-22 12:00)",
        "[2014-09-22 12:30, 2014-09-22 16:30)",
        "[2014-09-23 08:00, 2014-09-23 12:00)",
        "[2014-09-23 12:30, 2014-09-23 16:30)",
        "[2014-09-24 08:00, 2014-09-24 12:00)",
        "[2014-09-24 12:30, 2014-09-24 16:30)",
        "[2014-09-25 08:00, 2014-09-25 12:00)",
        "[2014-09-25 12:30, 2014-09-25 16:30)"
    ] }

(Optionally, an scode can be assigned by including an "scode" property.)

Read on for details:

First, a set of scratch intervals is created in the 'schedintvls' table.
If this succeeds, an INSERT operation is used to create a new record in the
'schedule' table. This operation has two possible successful outcomes 
depending on whether such a schedule already existed in the database, or not.
The status codes for these outcomes are DISPATCH_SCHEDULE_OK and
DISPATCH_SCHEDULE_INSERT_OK, respectively.

In both cases, the underlying scratch intervals are deleted automatically.
(All operations on the 'schedintlvs' table are supposed to be hidden from 
Dochazka clients.) 

Note that many sets of intervals can map to a single schedule (the conversion
process is only interested in the day of the week), so this resource may return
DISPATCH_SCHEDULE_OK more often than you think.

Whether or not the exact schedule existed already, if the underlying database
operation is successful the payload will contain three properties: 'sid' (the
SID assigned to the schedule containing the intervals), 'intervals' (the
intervals themselves), and 'schedule' (the intervals as they appear after being
converted into the format suitable for insertion into the 'schedule' table).

N.B. At present there is no way to just check for the existence of a schedule
corresponding to a given set of intervals. 
EOH
    },

    # /schedule/nick/:nick/?:ts
    'schedule/nick/:nick/?:ts' => 
    { 
        parent => 'schedule',
        handler => {
            GET => 'handler_get_schedule_nick',
        },
        acl_profile => 'admin', 
        cli => 'schedule nick $NICK [$TIMESTAMP]',
        validations => {
            'nick' => $term_validation,
        },
        description => 'Get the current schedule of arbitrary employee, or with optional timestamp, that employee\'s schedule as of that timestamp',
        documentation => <<'EOH',
=pod

This resource retrieves the schedule of an arbitrary employee specified by nick.

If no timestamp is given, the current schedule is retrieved. If a timestamp
is present, the schedule as of that timestamp is retrieved.
EOH
    },

    # /schedule/scode/:scode
    'schedule/scode/:scode' => 
    { 
        parent => 'schedule',
        handler => {
            GET => 'handler_get_schedule_scode',
            PUT => 'handler_put_schedule_scode', 
            DELETE => 'handler_delete_schedule_scode',
        },
        acl_profile => {
            GET => 'inactive',
            PUT => 'admin', 
            DELETE => 'admin',
        },
        cli => 'schedule scode $scode',
        validations => {
            'scode' => qr/^[[:alnum:]_][[:alnum:]_-]*$/,
        },
        description => 'Retrieves, updates, or deletes a schedule by its scode',
        documentation => <<'EOH',
=pod

This resource makes it possible to GET, PUT, or DELETE a schedule by its scode.

=over

=item * GET

An scode (string) must be given as a URI parameter. If a schedule with this
scode is found (exact, case-sensitive match), it is returned in the payload.

=item * PUT

This resource/method provides a way to set (modify) the 'scode', 'remark'
and/or 'disabled' fields of a schedule record. Simply provide the property (or
properties) and the new value(s) in the request body, e.g.:

    { "scode" : "WIGWAM" }

or

    { "remark" : "foobar", "disabled" : "t" }

Properties other than these three cannot be modified using this resource.

=item * DELETE

The scode must be given as an URI parameter. If found, the schedule with that
scode will be deleted in an atomic operation. If the operation is successful the
return status will be "OK".

=back
EOH
    },

    # /schedule/self/?:ts
    'schedule/self/?:ts' => 
    { 
        parent => 'schedule',
        handler => {
            GET => 'handler_get_schedule_self',
        },
        acl_profile => 'passerby', 
        cli => 'schedule current [$TIMESTAMP]',
        description => 'Get the current schedule of the currently logged-in employee, or with optional timestamp, that employee\'s schedule as of that timestamp',
        documentation => <<'EOH',
=pod

This resource retrieves the schedule of the caller (currently logged-in employee).

If no timestamp is given, the current schedule is retrieved. If a timestamp
is present, the schedule as of that timestamp is retrieved.
EOH
    },

    # /schedule/sid/:sid
    'schedule/sid/:sid' => 
    { 
        parent => 'schedule',
        handler => {
            GET => 'handler_get_schedule_sid',
            PUT => 'handler_put_schedule_sid', 
            DELETE => 'handler_delete_schedule_sid',
        },
        acl_profile => {
            GET => 'passerby',
            PUT => 'admin',
            DELETE => 'admin',
        },
        cli => 'schedule sid $SID',
        validations => {
            'sid' => 'Int',
        },
        description => 'Retrieves, updates, or deletes a schedule by its SID',
        documentation => <<'EOH',
=pod

This resource makes it possible to GET, PUT, or DELETE a schedule by its SID.

=over

=item * GET

An integer SID must be given as an URI parameter. If a schedule
with this SID is found, it is returned in the payload.

=item * PUT

This resource/method provides a way to set (modify) the 'scode', 'remark'
and/or 'disabled' fields of a schedule record. Simply provide the property (or
properties) and the new value(s) in the request body, e.g.:

    { "scode" : "WIGWAM" }

or

    { "remark" : "foobar", "disabled" : "t" }

Properties other than these three cannot be modified using this resource.

=item * DELETE

An integer SID must be given as an URI parameter. If found, the schedule with
that SID will be deleted in an atomic operation. If the operation is successful
the return status will be "OK".

=back
EOH
    },

};



=head1 FUNCTIONS

=head2 load

Load all the resource definitions into the L<Path::Router> instance.

=cut

sub load {
    foreach my $prop ( qw( top activity component employee genreport
                           history interval lock priv schedule ) ) {
        Web::MREST::InitRouter::load_resource_defs( $defs->{$prop} ) if $defs->{$prop};
    }
}


1;
