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

package App::Dochazka::REST::Docs::Workflow;

use 5.012;
use strict;
use warnings;


1;
__END__


=head1 NAME

App::Dochazka::REST::Docs::Workflow - Documentation of REST workflow


=head1 DESCRIPTION

This is a POD-only module containing documentation describing standard Dochazka
workflow scenarios and the REST resources used therein.

It is intended to be used in the functional testing process.

=head1 WORKFLOW SCENARIOS

The workflow scenarios are divided into sections according to the privlevel of
the logged-in employee doing the "work" - i.e., interacting with the Dochazka
REST server.

The workflow scenarios are presented in order of increasing privilege.
Employees with higher privilege can perform all the workflow scenarios
available to those of lower privilege.


=head2 passerby

Passerby is the default privlevel. In other words, employees without any
privhistory entries will automatically be assigned this privlevel.

Passerby employees (which need not be "employees" in a legal sense) can engage
in the following workflows:

=head3 Login

If LDAP authentication is enabled and C<DOCHAZKA_LDAP_AUTOCREATE> is set, a new
passerby employee will be created whenever an as-yet unseen employee logs in
(authenticates herself to the REST server). Otherwise, a passerby employee can
log in only if an administrator has created the corresponding employee profile.

=head3 Explore available resources 

Any logged-in employee is free to explore available resources. The starting
point for such exploration can be C<GET /> (i.e. a GET request for the
top-level resource), which is the same as C<GET /help>. The information
returned is specific to the HTTP method used, so for PUT resources one needs to
use C<PUT /> (or C<PUT /help>), etc.

Only accessible resources are displayed. For example, a passerby employee will
not see admin resources. A few resources (e.g. C<activity/aid/:aid>), have
different ACL profiles depending on which HTTP method is used.

=head3 Retrieve one's own employee profile

Using C<GET employee/self>, any employee can view her own employee profile.
The payload is a valid employee object.

Alternatively, C<GET employee/self/full> can be used, in which case the
employee's current privilege level and schedule are returned along with the
employee object.

=head3 Retrieve one's own current schedule/privlevel

Using C<GET /priv/self/?:ts> and C<GET /schedule/self/?:ts>, any employee 
can retrieve her own current privlevel and schedule. By including a timestamp
she can also retrieve her privlevel and schedule as of any arbitrary date/time.

=head3 Generate reports

Passerby employees can use the C<POST genreport> operation to generate
reports from any report templates (Mason components) with ACL profile
'passerby'.


=head2 inactive

The inactive privlevel is intended for employees who are not currently
attending work, but are expected to resume their attendance at some point in
the future: for example, employees on maternity leave, sabbatical, etc.

Short-term leave situations like medical leave can of course be handled by
having the employee enter attendance intervals according to their schedule, but
using a special activity like, for example, 'SICK_LEAVE'. The 'inactive'
privlevel is appropriate if an employee will be inactive for a longer period,
during which she is not expected to fill out attendance.

Though such employees might not be expected to even log in to Dochazka during
their period of inactivity, if they happen to do so they can engage in the
following workflows (in addition to the passerby workflows described in the
previous section).

=head3 Retrieve one's own schedule/privilege history

Employee schedules and privlevels change over time. To ensure that historical
attendance data is always associated with the schedule and privlevel in effect
at the time the attendance took place, all changes to employee schedules and
privlevels are recorded in a "history table". 

Since inactive employees are still employees (or members of the organization),
they are authorized to view (retrieve) their privilege/schedule histories using
the C<schedule/history/self/?:tsrange> and C<priv/history/self/?:tsrange>
resources. 

=head3 Edit one's own employee profile (certain fields)

Inactive employees are authorized to edit certain fields of their employee
profile (e.g., to change their password or correct the spelling of their full
name, etc.). These fields are configurable via the DOCHAZKA_PROFILE_EDITABLE_FIELDS site
parameter.

=head3 Retrieve one's own attendance/lock intervals

Although inactive employees are not authorized to enter new attendance/lock
intervals, they can retrieve their own past intervals, for example by browsing
in the web client, etc.

=head3 Generate reports

Inactive employees can use the C<POST genreport> operation to generate
reports from any report templates (Mason components) with ACL profile
'inactive' or below.


=head2 active

=head3 Add new attendance intervals

Active employees can add new attendance data ("intervals") subject to the
following limitations: 

=over

=item (a) only their own attendance - not that of other employees,

=item (b) attendance interval must not conflict with an existing lock interval,

=item (c) attendance interval must not extend past the end of the current month and, 

=item (d) attendance interval must not overlap with an existing interval.

=back

    Example 1: Employee 'pepik' tries to insert an attendance interval
               [1985-04-27 08:00, 1985-04-27 12:00) but there is a 
	       lock in place for that date. In such a case, the lock would have
               to be removed by an administrator, or 'pepik' would be out of luck.

    Example 2: Today's date is 2014-10-22 and 'pepik' attempts to insert
               an attendance interval [2014-11-07 08:00, 2014-11-07 08:30) -
	       this will not be possible until 2014-11-01..

New attendance data is added via POST requests on C<interval/new>.

=head3 Add new lock intervals

Active employees are authorized to lock attendance data by adding new lock
intervals subject to the following restrictions:

=over

=item (a) only on their own attendance,

=item (b) only on past attendance and up to the end of the current month,

=item (c) lock interval must not overlap with any other lock intervals.

=back

=head3 Modify one's own unlocked past attendance data

Active employees can modify/delete any existing attendance data, provided the
attendance intervals in question do not conflict with any lock.

=head3 Retrieve list of non-disabled activities

Since attendance data must be associated with a valid activity, active employees
are authorized to retrieve the entire list of non-disabled activities using
a GET request on the C<activity/all> resource.

=head3 Retrieve details of a particular activity

Active employees can look up the details of any activity (including 
disabled activities) by the activity's code or AID using GET requests on
C<activity/aid/:aid> and C<activity/code/:code>.

=head3 Edit one's own employee profile (certain fields)

Depending on the exact setting of the DOCHAZKA_PROFILE_EDITABLE_FIELDS site
parameter, active employees may be authorized to edit more fields than inactive
employees.

=head3 Generate reports

Active employees can use the C<POST genreport> operation to generate
reports from any report templates (Mason components) with ACL profile
'active' or below.


=head2 admin

=head3 Edit any employee's profile

Administrators can edit any employee's profile. The only limitation is that the
EID cannot be changed.

=head3 Create, read, update, and delete Mason components

Mason components are stored in the database and written out to the
filesystem every time the server starts. Since these components pose a
security risk, only administrators can work with them.

Non-administrator employees cannot view component source code, but they can
generate reports using the C<POST genreport> operation, which takes a
top-level component path, provided they have sufficient privileges to use
the component in question.



=head1 AUTHOR

Nathan Cutler C<ncutler@suse.cz>

=cut
