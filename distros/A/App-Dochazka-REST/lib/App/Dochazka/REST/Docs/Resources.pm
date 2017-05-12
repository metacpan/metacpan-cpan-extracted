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

package App::Dochazka::REST::Docs::Resources;

use 5.012;
use strict;
use warnings;

1;
__END__


=head1 NAME

App::Dochazka::REST::Docs::Resources - Documentation of REST resources


=head1 DESCRIPTION

This is a POD-only module containing documentation on all the REST resources 
defined in C<ResourceDefs.pm>. This module is auto-generated.


=head1 RESOURCES



=head2 C<< / >>


=over

Allowed methods: CONNECT, DELETE, GET, OPTIONS, POST, PUT, TRACE

This resource is the parent of all resources that do not specify
a parent in their resource definition.


=back

=head2 C<< activity >>


=over

Allowed methods: CONNECT, DELETE, GET, OPTIONS, POST, PUT, TRACE

Parent for activity resources


=back

=head2 C<< activity/aid >>


=over

Allowed methods: POST

Enables existing activity objects to be updated by sending a POST request to
the REST server. Along with the properties to be modified, the request body
must include an 'aid' property, the value of which specifies the AID to be
updated.


=back

=head2 C<< activity/aid/:aid >>


=over

Allowed methods: DELETE, GET, PUT

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


=back

=head2 C<< activity/all >>


=over

Allowed methods: GET

Retrieves all activity objects in the database (excluding disabled activities).


=back

=head2 C<< activity/all/disabled >>


=over

Allowed methods: GET

Retrieves all activity objects in the database (including disabled activities).


=back

=head2 C<< activity/code >>


=over

Allowed methods: POST

This resource enables existing activity objects to be updated, and new
activity objects to be inserted, by sending a POST request to the REST server.
Along with the properties to be modified/inserted, the request body must
include an 'code' property, the value of which specifies the activity to be
updated.  


=back

=head2 C<< activity/code/:code >>


=over

Allowed methods: DELETE, GET, PUT

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


=back

=head2 C<< bugreport >>


=over

Allowed methods: GET

Returns a JSON structure containing instructions for reporting bugs.


=back

=head2 C<< component >>


=over

Allowed methods: CONNECT, DELETE, GET, OPTIONS, POST, PUT, TRACE

Parent for component resources


=back

=head2 C<< component/all >>


=over

Allowed methods: GET

Retrieves all component objects in the database.


=back

=head2 C<< component/cid >>


=over

Allowed methods: POST

Enables existing component objects to be updated by sending a POST request to
the REST server. Along with the properties to be modified, the request body
must include an 'cid' property, the value of which specifies the cid to be
updated.


=back

=head2 C<< component/cid/:cid >>


=over

Allowed methods: DELETE, GET, PUT

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


=back

=head2 C<< component/path >>


=over

Allowed methods: POST

This resource enables existing component objects to be updated, and new
component objects to be inserted, by sending a POST request to the REST server.
Along with the properties to be modified/inserted, the request body must
include an 'path' property, the value of which specifies the component to be
updated.  


=back

=head2 C<< configinfo >>


=over

Allowed methods: GET

Returns a list of directories that were scanned for configuration files.


=back

=head2 C<< dbstatus >>


=over

Allowed methods: GET

This resource checks the employee's database connection and reports on its status.
The result - either "UP" or "DOWN" - will be encapsulated in a payload like this:

    { "dbstatus" : "UP" }

Each employee gets her own database connection when she logs in to Dochazka.
Calling this resource causes the server to execute a 'ping' on the connection.
If the ping test fails, the server will attempt to open a new connection. Only
if this, too, fails will "DOWN" be returned.


=back

=head2 C<< docu >>


=over

Allowed methods: CONNECT, DELETE, GET, OPTIONS, POST, PUT, TRACE

This resource provides access to on-line documentation through its
subresources: 'docu/pod', 'docu/html', and 'docu/text'.

To get documentation on a resource, send a POST reqeuest for one of
these subresources, including the resource name in the request
entity as a bare JSON string (i.e. in double quotes).


=back

=head2 C<< docu/html >>


=over

Allowed methods: POST

This resource provides access to on-line help documentation. It expects to find
a resource name (e.g. "employee/eid/:eid" including the double-quotes, and without
leading or trailing slash) in the request body. It generates HTML from the 
resource documentation's POD source code.


=back

=head2 C<< docu/pod >>


=over

Allowed methods: POST

=pod
        
This resource provides access to on-line help documentation in POD format. 
It expects to find a resource name (e.g. "employee/eid/:eid" including the
double-quotes, and without leading or trailing slash) in the request body. It
returns a string containing the POD source code of the resource documentation.


=back

=head2 C<< docu/text >>


=over

Allowed methods: POST

This resource provides access to on-line help documentation. It expects to find
a resource name (e.g. "employee/eid/:eid" including the double-quotes, and without
leading or trailing slash) in the request body. It returns a plain text rendering
of the POD source of the resource documentation.


=back

=head2 C<< echo >>


=over

Allowed methods: POST

This resource simply takes whatever content body was sent and echoes it
back in the response body.


=back

=head2 C<< employee >>


=over

Allowed methods: CONNECT, DELETE, GET, OPTIONS, POST, PUT, TRACE

Parent for employee resources


=back

=head2 C<< employee/count/?:priv >>


=over

Allowed methods: GET

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


=back

=head2 C<< employee/current >>


=over

Allowed methods: GET, POST

With this resource, we can retrieve (GET) and edit (POST) our own employee
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


=back

=head2 C<< employee/current/priv >>


=over

Allowed methods: GET

Displays the "full profile" of the currently logged-in employee. The
information includes the full employee object (taken from the 'current_emp'
property) as well as the employee's current privlevel and schedule, which are
looked up from the database.


=back

=head2 C<< employee/eid >>


=over

Allowed methods: POST

This resource provides a way to update employee objects using the
POST method, provided the employee's EID is provided in the content body.
The properties to be modified should also be included, e.g.:

    { "eid" : 43, "fullname" : "Foo Bariful" }

This would change the 'fullname' property of the employee with EID 43 to "Foo
Bariful" (provided such an employee exists).

ACL note: 'inactive' and 'active' employees can use this resource to modify
their own employee profile. Exactly which fields can be updated may differ from
site to site (see the DOCHAZKA_PROFILE_EDITABLE_FIELDS site parameter).


=back

=head2 C<< employee/eid/:eid >>


=over

Allowed methods: DELETE, GET, PUT

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


=back

=head2 C<< employee/eid/:eid/minimal >>


=over

Allowed methods: GET

This resource enables any employee to get minimal information
on any other employee. Useful for EID to nick conversion or to
look up another employee's email address or name.


=back

=head2 C<< employee/eid/:eid/team >>


=over

Allowed methods: GET

This resource enables administrators to list the nicks of team members
of an arbitrary employee - i.e. that employee\'s direct reports.


=back

=head2 C<< employee/list/?:priv >>


=over

Allowed methods: GET

This resource enables the administrator to easily list the nicks of
employees. If priv is not given, all employees are listed.


=back

=head2 C<< employee/nick >>


=over

Allowed methods: POST

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


=back

=head2 C<< employee/nick/:nick >>


=over

Allowed methods: DELETE, GET, PUT

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


=back

=head2 C<< employee/nick/:nick/ldap >>


=over

Allowed methods: GET, PUT

This resource enables any employee to perform an LDAP lookup on
any other employee.


=back

=head2 C<< employee/nick/:nick/minimal >>


=over

Allowed methods: GET

This resource enables any employee to get minimal information
on any other employee. Useful for nick to EID conversion or to
look up another employee's email address or name.


=back

=head2 C<< employee/nick/:nick/team >>


=over

Allowed methods: GET

This resource enables administrators to list the nicks of team members
of an arbitrary employee - i.e. that employee\'s direct reports.


=back

=head2 C<< employee/search >>


=over

Allowed methods: CONNECT, DELETE, GET, OPTIONS, POST, PUT, TRACE

See child resources.


=back

=head2 C<< employee/search/nick/:key >>


=over

Allowed methods: GET

Look up employee profiles using a search key, which can optionally contain
a wildcard ('%'). For example:

    GET employee/search/nick/foo%

would return a list of employees whose nick starts with 'foo'.

Note that if the user provides no wildcard characters in the key, they will
implicitly be added. Example: a search for 'foo' would be converted to
'%foo%'. For a literal nick lookup, use the 'employee/nick/:nick' resource.


=back

=head2 C<< employee/sec_id/:sec_id >>


=over

Allowed methods: GET

Retrieves an employee object by the secondary ID (must be an exact match)


=back

=head2 C<< employee/sec_id/:sec_id/minimal >>


=over

Allowed methods: GET

This resource enables any employee to get minimal information
on any other employee. Useful for sec_id to EID conversion or to
look up another employee's email address or name.


=back

=head2 C<< employee/self >>


=over

Allowed methods: GET, POST

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


=back

=head2 C<< employee/self/priv >>


=over

Allowed methods: GET

Displays the "full profile" of the currently logged-in employee. The
information includes the full employee object (taken from the 'current_emp'
property) as well as the employee's current privlevel and schedule, which are
looked up from the database.


=back

=head2 C<< employee/team >>


=over

Allowed methods: GET

This resource enables supervisors to easily list the nicks of
employees in their team - i.e. their direct reports.


=back

=head2 C<< forbidden >>


=over

Allowed methods: CONNECT, DELETE, GET, OPTIONS, POST, PUT, TRACE

This resource returns 403 Forbidden for all allowed methods, regardless of user.

Implementation note: this can be accomplished for any resource by including an 'acl_profile'
property with the value 'undef' or any unrecognized privilege level string (like "foobar").


=back

=head2 C<< genreport >>


=over

Allowed methods: GET, POST

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


=back

=head2 C<< holiday/:tsrange >>


=over

Allowed methods: GET

This resource takes a tsrange and returns a list of holidays (dates) that 
fall within that tsrange.


=back

=head2 C<< interval >>


=over

Allowed methods: CONNECT, DELETE, GET, OPTIONS, POST, PUT, TRACE

Parent for interval resources


=back

=head2 C<< interval/:self/:ts/:psqlint >>


=over

Allowed methods: DELETE, GET

This is just like 'interval/self/:tsrange' except that the time range is
specified by giving a timestamp and a PostgreSQL time interval, e.g "1 week 3 days".


=back

=head2 C<< interval/eid/:eid/:ts/:psqlint >>


=over

Allowed methods: DELETE, GET

This is just like 'interval/eid/:eid/:tsrange' except that the time range is
specified by giving a timestamp and a PostgreSQL time interval, e.g "1 week 3 days".


=back

=head2 C<< interval/eid/:eid/:tsrange >>


=over

Allowed methods: DELETE, GET

With this resource, administrators can retrieve any employee's intervals 
over a given tsrange, and active employees can do the same with their own intervals. 

Before any records are returned, the tsrange is checked to see if it overlaps with
any privlevel or schedule changes - in which case an error is returned. This is so
interval report-generators do not have to handle changes in employee status.

By default, the number of intervals returned is limited to 500. This number
can be changed via the DOCHAZKA_INTERVAL_SELECT_LIMIT site configuration
parameter (set to 'undef' for no limit).


=back

=head2 C<< interval/iid >>


=over

Allowed methods: POST

Enables existing interval objects to be updated by sending a POST request to
the REST server. Along with the properties to be modified, the request body
must include an 'iid' property, the value of which specifies the iid to be
updated.


=back

=head2 C<< interval/iid/:iid >>


=over

Allowed methods: DELETE, GET, PUT

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


=back

=head2 C<< interval/new >>


=over

Allowed methods: POST

This is the resource by which employees add new attendance data to the
database. It takes a request body containing, at the very least, C<aid> and
C<intvl> properties. Additionally, it can contain C<long_desc>, while
administrators can also specify C<eid> and C<remark>.


=back

=head2 C<< interval/nick/:nick/:ts/:psqlint >>


=over

Allowed methods: DELETE, GET

This is just like 'interval/nick/:nick/:tsrange' except that the time range is
specified by giving a timestamp and a PostgreSQL time interval, e.g "1 week 3 days".


=back

=head2 C<< interval/nick/:nick/:tsrange >>


=over

Allowed methods: DELETE, GET

With this resource, administrators can retrieve any employee's intervals 
over a given tsrange, and active employees can do the same with their own intervals. 

Before any records are returned, the tsrange is checked to see if it overlaps with
any privlevel or schedule changes - in which case an error is returned. This is so
interval report-generators do not have to handle changes in employee status.

By default, the number of intervals returned is limited to 500. This number
can be changed via the DOCHAZKA_INTERVAL_SELECT_LIMIT site configuration
parameter (set to 'undef' for no limit).


=back

=head2 C<< interval/self/:tsrange >>


=over

Allowed methods: DELETE, GET

With this resource, employees can retrieve their own attendance intervals 
over a given tsrange. 

Before any records are returned, the tsrange is checked to see if it overlaps with
any privlevel or schedule changes - in which case an error is returned. This is so
interval report-generators do not have to handle changes in employee status.

By default, the number of intervals returned is limited to 500. This number
can be changed via the DOCHAZKA_INTERVAL_SELECT_LIMIT site configuration
parameter (set to 'undef' for no limit).


=back

=head2 C<< interval/summary/eid/:eid/:tsrange >>


=over

Allowed methods: GET

With this resource, employees can generate summaries of their attendance intervals
over a given period. 



=back

=head2 C<< interval/fillup >>


=over

Allowed methods: GET, POST

Parent for interval fillup resources


=back

=head2 C<< lock >>


=over

Allowed methods: CONNECT, DELETE, GET, OPTIONS, POST, PUT, TRACE

Parent for lock resources


=back

=head2 C<< lock/eid/:eid/:tsrange >>


=over

Allowed methods: GET

With this resource, administrators can retrieve any employee's locks 
over a given tsrange. 

There are no syntactical limitations on the tsrange, but if too many records would
be fetched, the return status will be C<DISPATCH_TOO_MANY_RECORDS_FOUND>.


=back

=head2 C<< lock/lid >>


=over

Allowed methods: POST

Enables existing lock objects to be updated by sending a POST request to
the REST server. Along with the properties to be modified, the request body
must include an 'lid' property, the value of which specifies the lid to be
updated.


=back

=head2 C<< lock/lid/:lid >>


=over

Allowed methods: DELETE, GET, PUT

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


=back

=head2 C<< lock/new >>


=over

Allowed methods: POST

This is the resource by which the attendance data entered by an employee 
for a given time period can be "locked" to prevent any subsequent
modifications.  It takes a request body containing, at the very least, an
C<intvl> property specifying the tsrange to lock. Additionally, administrators
can specify C<remark> and C<eid> properties.


=back

=head2 C<< lock/nick/:nick/:tsrange >>


=over

Allowed methods: GET

With this resource, administrators can retrieve any employee's locks 
over a given tsrange. 

There are no syntactical limitations on the tsrange, but if too many records would
be fetched, the return status will be C<DISPATCH_TOO_MANY_RECORDS_FOUND>.


=back

=head2 C<< lock/self/:tsrange >>


=over

Allowed methods: GET

With this resource, employees can retrieve their own attendance locks 
over a given tsrange. 

There are no syntactical limitations on the tsrange, but if too many records would
be fetched, the return status will be C<DISPATCH_TOO_MANY_RECORDS_FOUND>.


=back

=head2 C<< noop >>


=over

Allowed methods: CONNECT, DELETE, GET, OPTIONS, POST, PUT, TRACE

Regardless of anything, this resource does nothing at all.


=back

=head2 C<< param/:type/:param >>


=over

Allowed methods: DELETE, GET, PUT

This resource can be used to look up (GET) meta, core, and site parameters, 
as well as to set (PUT) and delete (DELETE) meta parameters.


=back

=head2 C<< priv >>


=over

Allowed methods: CONNECT, DELETE, GET, OPTIONS, POST, PUT, TRACE

This resource presents a list of subresources, all related to employee privileges.


=back

=head2 C<< priv/eid/:eid/?:ts >>


=over

Allowed methods: GET

This resource retrieves the privlevel of an arbitrary employee specified by EID.

If no timestamp is given, the present privlevel is retrieved. If a timestamp
is present, the privlevel as of that timestamp is retrieved.


=back

=head2 C<< priv/history >>


=over

Allowed methods: CONNECT, DELETE, GET, OPTIONS, POST, PUT, TRACE

This resource presents a list of subresources, all related to privilege histories.


=back

=head2 C<< priv/history/eid/:eid >>


=over

Allowed methods: GET, POST

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


=back

=head2 C<< priv/history/eid/:eid/:tsrange >>


=over

Allowed methods: GET

Retrieves a slice (given by the tsrange argument) of the employee's
"privhistory" (history of changes in privilege level).


=back

=head2 C<< priv/history/nick/:nick >>


=over

Allowed methods: GET, POST

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


=back

=head2 C<< priv/history/nick/:nick/:tsrange >>


=over

Allowed methods: GET

Retrieves a slice (given by the tsrange argument) of the employee's
"privhistory" (history of changes in privilege level).


=back

=head2 C<< priv/history/phid/:phid >>


=over

Allowed methods: DELETE, GET, POST

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


=back

=head2 C<< priv/history/self/?:tsrange >>


=over

Allowed methods: GET

This resource retrieves the "privhistory", or history of changes in
privilege level, of the present employee. Optionally, the listing can be
limited to a specific tsrange such as 

    "[2014-01-01, 2014-12-31)"



=back

=head2 C<< priv/nick/:nick/?:ts >>


=over

Allowed methods: GET

This resource retrieves the privlevel of an arbitrary employee specified by nick.

If no timestamp is given, the present privlevel is retrieved. If a timestamp
is present, the privlevel as of that timestamp is retrieved.


=back

=head2 C<< priv/self/?:ts >>


=over

Allowed methods: GET

This resource retrieves the privlevel of the caller (currently logged-in employee).

If no timestamp is given, the present privlevel is retrieved. If a timestamp
is present, the privlevel as of that timestamp is retrieved.


=back

=head2 C<< schedule >>


=over

Allowed methods: CONNECT, DELETE, GET, OPTIONS, POST, PUT, TRACE

This resource presents a list of "child" resources (subresources), all of which
are related to schedules.  


=back

=head2 C<< schedule/all >>


=over

Allowed methods: GET

This resource returns a list (array) of all schedules for which the 'disabled' field has
either not been set or has been set to 'false'.


=back

=head2 C<< schedule/all/disabled >>


=over

Allowed methods: GET

This resource returns a list (array) of all schedules, regardless of the contents
of the 'disabled' field.


=back

=head2 C<< schedule/eid/:eid/?:ts >>


=over

Allowed methods: GET

This resource retrieves the schedule of an arbitrary employee specified by EID.

If no timestamp is given, the current schedule is retrieved. If a timestamp
is present, the schedule as of that timestamp is retrieved.


=back

=head2 C<< schedule/history >>


=over

Allowed methods: CONNECT, DELETE, GET, OPTIONS, POST, PUT, TRACE

This resource presents a list of subresources, all related to schedule histories.


=back

=head2 C<< schedule/history/eid/:eid >>


=over

Allowed methods: GET, POST

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

It is assumed that schedule histories will be built up record-by-record; 
insertion of multiple history records in a single request is not supported.

=back

Update note: histories can be updated by adding new records and deleting old
ones. Existing history records cannot be changed. Adds/deletes should be
performed with due care - especially with regard to existing employee
attendance data (if any).


=back

=head2 C<< schedule/history/eid/:eid/:tsrange >>


=over

Allowed methods: GET

Retrieves a slice (given by the tsrange argument) of the employee's
"schedule history" (history of changes in schedule).


=back

=head2 C<< schedule/history/nick/:nick >>


=over

Allowed methods: GET, POST

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

It is assumed that schedule histories will be built up record-by-record; 
insertion of multiple history records in a single request is not supported.

=back

Update note: histories can be updated by adding new records and deleting old
ones. Existing history records cannot be changed. Adds/deletes should be
performed with due care - especially with regard to existing employee
attendance data (if any).


=back

=head2 C<< schedule/history/nick/:nick/:tsrange >>


=over

Allowed methods: GET

Retrieves a slice (given by the tsrange argument) of the employee's
"schedule history" (history of changes in schedule). 


=back

=head2 C<< schedule/history/self/?:tsrange >>


=over

Allowed methods: GET

This resource retrieves the "schedule history", or history of changes in
schedule, of the present employee. Optionally, the listing can be
limited to a specific tsrange such as 

    "[2014-01-01, 2014-12-31)"



=back

=head2 C<< schedule/history/shid/:shid >>


=over

Allowed methods: DELETE, GET, POST

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


=back

=head2 C<< schedule/new >>


=over

Allowed methods: POST

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


=back

=head2 C<< schedule/nick/:nick/?:ts >>


=over

Allowed methods: GET

This resource retrieves the schedule of an arbitrary employee specified by nick.

If no timestamp is given, the current schedule is retrieved. If a timestamp
is present, the schedule as of that timestamp is retrieved.


=back

=head2 C<< schedule/scode/:scode >>


=over

Allowed methods: DELETE, GET, PUT

This resource makes it possible to GET, PUT, or DELETE a schedule by its scode.

=over

=item * GET

An integer scode must be given as an URI parameter. If a schedule
with this scode is found, it is returned in the payload.

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
scode will be deleted in an atomic operation. If the operation is sucessful the
return status will be "OK".

=back


=back

=head2 C<< schedule/self/?:ts >>


=over

Allowed methods: GET

This resource retrieves the schedule of the caller (currently logged-in employee).

If no timestamp is given, the current schedule is retrieved. If a timestamp
is present, the schedule as of that timestamp is retrieved.


=back

=head2 C<< schedule/sid/:sid >>


=over

Allowed methods: DELETE, GET, PUT

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
that SID will be deleted in an atomic operation. If the operation is sucessful
the return status will be "OK".

=back


=back

=head2 C<< session >>


=over

Allowed methods: GET

Dumps the current session data (server-side).


=back

=head2 C<< version >>


=over

Allowed methods: GET

Shows the software version running on the present instance. The version displayed
is taken from the C<$VERSION> package variable of the package specified in the
C<MREST_APPLICATION_MODULE> site parameter.


=back

=head2 C<< whoami >>


=over

Allowed methods: GET

Displays the profile of the currently logged-in employee (same as
"employee/current")


=back


=head1 AUTHOR

Nathan Cutler C<ncutler@suse.cz>

=cut
