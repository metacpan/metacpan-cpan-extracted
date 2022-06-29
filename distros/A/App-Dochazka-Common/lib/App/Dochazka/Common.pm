# ************************************************************************* 
# Copyright (c) 2014-2020, SUSE LLC
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
# Model module
# ------------------------

package App::Dochazka::Common;

use 5.012;
use strict;
use warnings;

use Exporter 'import';
use Time::Piece;
use Time::Seconds;



=head1 NAME

App::Dochazka::Common - Dochazka Attendance and Time Tracking System shared modules




=head1 VERSION

Version 0.210

=cut

our $VERSION = '0.210';




=head1 SYNOPSIS

Sic transit gloria mundi.




=head1 DESCRIPTION

This distro contains modules that are used by both the server
L<App::Dochazka::REST> and the command-line client L<App::Dochazka::CLI>.




=head1 DOCHAZKA DATA MODEL

This section describes the Dochazka data model. Conceptually, Dochazka data
can be seen to exist in the following classes of objects, all of which are
implemented by this module:

=over

=item * Policy (parameters set when database is first created)

=item * Employee (an individual employee)

=item * Privhistory (history of changes in an employee's privilege level)

=item * Schedule (a schedule)

=item * Schedhistory (history of changes in an employee's schedule)

=item * Activities (what kinds of work are recognized)

=item * Intervals (the "work", or "attendance", itself)

=item * Locks (determining whether a reporting period is locked or not)

=item * Components (Mason components, i.e. report templates)

=back

These classes are described in the following sections.


=head2 Policy

Dochazka is configurable in a number of ways. Some configuration parameters
are set once at installation time and, once set, can never be changed --
these are referred to as "site policy" parameters.  Others, referred to as
"site configuration parameters" or "site params", are set in configuration
files such as C<Dochazka_SiteConfig.pm> (see L</SITE CONFIGURATION>) and
can be changed more-or-less at will.

The key difference between site policy and site configuration is that
site policy parameters cannot be changed, because changing them would
compromise the referential integrity of the underlying database.

Site policy parameters are set at installation time and are stored, as a
single JSON string, in the C<Policy> table. This table is rendered
effectively immutable by a trigger.

For details, see L<App::Dochazka::REST::Model::Policy>.


=head2 Employee

Users of Dochazka are referred to as "employees" regardless of their
legal status -- in reality they might be independent contractors, or
students, or even household pets, but as far as Dochazka is concerned they
are employees. You could say that "employee" is the Dochazka term for "user".

The purpose of the Employee table/object is to store whatever data the site
is accustomed to use to identify its employees.

Within Dochazka itself, employees are distinguished by an internal employee ID
number (EID), which is assigned by Dochazka itself when the employee record is
created. In addition, four other fields/properties are provided to identify
the employee: 

=over

=item * nick

=item * sec_id

=item * fullname

=item * email

=back

All four of these, plus the C<eid> field, have C<UNIQUE> constraints defined at
the database level, meaning that duplicate entries are not permitted. However,
of the four, only C<nick> is required.

Depending on how authentication is set up, employee passwords may also be
stored in this table, using the C<passhash> and C<salt> fields.

For details, see L<App::Dochazka::REST::Model::Employee>.


=head2 Privhistory

Dochazka has four privilege levels: C<admin>, C<active>, C<inactive>, and
C<passerby>: 

=over

=item * C<admin> -- employee can view, modify, and place/remove locks on her
own attendance data as well as that of other employees; she can also
administer employee accounts and set privilege levels of other employees

=item * C<active> -- employee can view her own profile, attendance data,
modify her own unlocked attendance data, and place locks on her attendance
data

=item * C<inactive> -- employee can view her own profile and attendance data

=item * C<passerby> -- employee can view her own profile

=back

Dochazka's C<privhistory> object is used to track changes in an employee's
privilege level over time. Each time an employee's privilege level changes,
a Dochazka administrator (i.e., an employee whose current privilege level is
'admin'), a record is inserted into the database (in the C<privhistory>
table). Ordinary employees (i.e. those whose current privilege level is
'active') can read their own privhistory.

Thus, with Dochazka it is possible not only to determine not only an employee's
current privilege level, but also to view "privilege histories" and to
determine employees' privilege levels for any date (timestamp) in the past.

For details, see L<App::Dochazka::REST::Model::Privhistory> and L<When
history changes take effect>.


=head2 Schedule

In addition to actual attendance data, Dochazka sites may need to store
schedules. Dochazka defines the term "schedule" as a series of
non-overlapping "time intervals" (or "timestamp ranges" in PostgreSQL
terminology) falling within a single week. These time intervals express the
times when the employee is "expected" or "supposed" to work (or be "at work")
during the scheduling period.

Example: employee "Barb" is on a weekly schedule. That means her
scheduling period is "weekly" and her schedule is an array of
non-overlapping time intervals, all falling within a single week.

B<In its current form, Dochazka is only capable of handling weekly schedules
only.> Some sites, such as hospitals, nuclear power plants, fire departments,
and the like, might have employees on more complicated schedules such as "one
week on, one week off", alternating day and night shifts, "on call" duty, etc.

Dochazka can still be used to track attendance of such employees, but if their
work schedule cannot be expressed as a series of non-overlapping time intervals
contained within a contiguous 168-hour period (i.e. one week), then their
Dochazka schedule should be set to NULL.

For details, see L<App::Dochazka::REST::Model::Schedule>.


=head2 Schedhistory

The C<schedhistory> table contains a historical record of changes in the
employee's schedule. This makes it possible to determine an employee's
schedule for any date (timestamp) in the past, as well as (crucially) the
employee's current schedule.

Every time an employee's schedule is to change, a Dochazka administrator
must insert a record into this table. (Employees who are not administrators
can only read their own history; they do not have write privileges.) For
more information on privileges, see L</AUTHORIZATION>.

For details, see L<App::Dochazka::REST::Model::Schedhistory>.


=head2 Activity

While on the job, employees "work" -- i.e., they engage in various activities
that are tracked using Dochazka. The C<activities> table contains definitions
of all the possible activities that may be entered in the C<intervals> table. 

The initial set of activities is defined in the site install configuration
(C<DOCHAZKA_ACTIVITY_DEFINITIONS>) and enters the database at installation
time. Additional activities can be added later (by administrators), but
activities can be deleted only if no intervals refer to them.

Each activity has a code, or short name (e.g., "WORK") -- which is the
primary way of referring to the activity -- as well as an optional long
description. Activity codes must be all upper-case.

For details, see L<App::Dochazka::REST::Model::Activity>.


=head2 Interval

Intervals are the heart of Dochazka's attendance data. For Dochazka, an
interval is an amount of time that an employee spends doing an activity.
In the database, intervals are represented using the C<tsrange> range
operator introduced in PostgreSQL 9.2.

Optionally, an interval can have a C<long_desc> (employee's description
of what she did during the interval) and a C<remark> (admin remark).

For details, see L<App::Dochazka::REST::Model::Interval>.


=head2 Lock

In Dochazka, a "lock" is a record in the "locks" table specifying that
a particular user's attendance data (i.e. activity intervals) for a 
given period (tsrange) cannot be changed. That means, for intervals in 
the locked tsrange:

=over

=item * existing intervals cannot be updated or deleted

=item * no new intervals can be inserted

=back

Employees can create locks (i.e., insert records into the locks table) on their
own EID, but they cannot delete or update those locks (or any others).
Administrators can insert, update, or delete locks at will.

How the lock is used will differ from site to site, and some sites may not
even use locking at all. The typical use case would be to lock all the
employee's attendance data within the given period as part of pre-payroll
processing. For example, the Dochazka client application may be set up to
enable reports to be generated only on fully locked periods. 

"Fully locked" means either that a single lock record has been inserted
covering the entire period, or that the entire period is covered by multiple
locks.

Any attempts (even by administrators) to enter activity intervals that 
intersect an existing lock will result in an error.

Clients can of course make it easy for the employee to lock entire blocks
of time (weeks, months, years . . .) at once, if that is deemed expedient.

For details, see L<App::Dochazka::REST::Model::Lock>.


=head2 Component

L<Reports are generated|"REPORT GENERATION"> from
L<Mason|https://metacpan.org/pod/Mason> templates which consist of
components. Mason expects these components to be stored in text files under
a directory called the "component root". For the purposes of Dochazka, the
component root is created under the Dochazka state directory, which is
determined from the C<DOCHAZKA_STATE_DIR> site parameter (defaults to
C</var/lib/dochazka>). When the server starts, this Mason state in the
filesystem is wiped and re-created from the database. The C<Component>
class is used to manipulate Mason components.

This rather complicated setup is designed to enable administrators to
develop their own report templates.



=head1 PACKAGE VARIABLES AND EXPORTS

=cut

our ( $t, $today, $yesterday, $tomorrow );

our @EXPORT_OK = qw( 
    $t
    $today
    $yesterday
    $tomorrow
    init_timepiece
);



=head1 FUNCTIONS


=head2 init_timepiece

(Re-)initialize the date/time-related package variables

=cut

sub init_timepiece {
    #print "Entering " . __PACKAGE__ . "::init_timepiece\n";
    $t = localtime;
    $today = $t->ymd;
    $yesterday = ($t - ONE_DAY)->ymd;
    $tomorrow = ($t + ONE_DAY)->ymd;
}


1;
