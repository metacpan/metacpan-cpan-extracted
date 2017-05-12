# ************************************************************************* 
# Copyright (c) 2014-2016, SUSE LLC
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
# "CLI Guide" module
#
package App::Dochazka::CLI::Guide;

=head1 NAME

App::Dochazka::CLI::Guide - Dochazka CLI Guide



=head1 VERSION

Version 0.238

=cut

our $VERSION = '0.238';



=head1 CLI COMMANDS


=head2 Introduction

The CLI commands can be divided into four categories:

=over

=item L<"Commands for generating HTTP requests">

=item L<"Commands for Dochazka administrators">

=item L<"Commands for Dochazka supervisors">

=item L<"Commands for Dochazka users">

=back


=head2 Commands for generating HTTP requests

The CLI enables the user to generate HTTP requests to an L<App::Dochazka::REST>
server and view the server's responses. Commands in this category -- also known
as "REST test" commands -- have a direct correlation with the REST server
resources, always starting with one of the four basic HTTP methods supported by
the REST server: C<GET>, C<PUT>, C<POST>, C<DELETE>. These commands
are useful mainly for Dochazka developers, but may also be used by
administrators and normal users -- e.g., for troubleshooting and ad hoc
testing, or for doing things that the "normal" commands do not support. A "best
effort" has been made to support all the REST resources.

Commands in this category start with the HTTP method and continue 
with the resource (except it is written with spaces instead of forward
slashes) and concludes with the request entity, if any.

All CLI commands must be written on a single line of input, and
commands in this category are no exception.

Examples:

=over

=item DELETE INTERVAL IID 24

The equivalent of C<< DELETE interval/iid/24 >>

=item POST DOCU TEXT "employee/eid/:eid"

The equivalent of C<< POST docu/text >> with the request entity shown.

=item POST EMPLOYEE EID { "eid" : 15, "sec_id" : 340 }

Update the secondary ID of the employee with EID 15.

=back

A full list of REST test commands can be found in the source code of the
L<App::Dochazka::CLI::CommandMap> module.


=head2 Commands for Dochazka administrators

Dochazka administrators have access to all of Dochazka's resources and can
call them directly by generating appropriate HTTP requests. This can be a bit
tedious, however, so "real" CLI commands have been implemented for the more
commonly used administrative procedures, like changing an employee's privilege
level or schedule, removing locks, viewing attendance data entered by
employees, etc.

These commands are detailed in the L<"ADMINISTRATOR WORKFLOWS"> section.


=head2 Commands for Dochazka supervisors

Supervisors are Dochazka users who, in "real life", are in charge of a group of
employees who report to them. The idea here is that the supervisor can view and
modify the attendance data and other records of their reports (i.e. of the
employees in their team or department). The commands used for this purpose are
a subset of the administrator commands.

These commands are detailed in the L<"SUPERVISOR WORKFLOWS"> section.


=head2 Commands for Dochazka users

Finally there are the core, day-to-day commands used by Dochazka users
(employees of the organization) to enter attendance data, generate reports,
etc.

These commands are detailed in the L<"USER WORKFLOWS"> section.



=head1 ADMINISTRATOR WORKFLOWS


=head2 Activities


=head3 View all activities, including disabled

    ACTIVITY ALL DISABLED

Displays a list of B<all> activities, including disabled activities.


=head3 Add a new activity

From time to time, new activities will need to be added:

    PUT activity code $CODE { "long_desc" : "activity description here" }

Optionally, a "remark" property can be included as well.


=head3 Disable an activity

To accomplish this, we can use a REST test command:

    PUT activity aid $AID { "disabled" : "t" }
    PUT activity code $CODE { "disabled" : "t" }

=head3 Re-enable an activity

To accomplish this, we can use a REST test command:

    PUT activity aid $AID { "disabled" : "f" }
    PUT activity code $CODE { "disabled" : "f" }

=head3 Delete an activity

Assuming nothing points to it, an activity can be deleted:

    DELETE activity aid $AID
    DELETE activity code $CODE


=head2 Employees

=head3 Specify an employee

Wherever it is necessary to specify an employee, the command is shown as 

    EMPLOYEE_SPEC

This has a special meaning and is not meant to be typed in verbatim.
C<EMPLOYEE_SPEC> can be given in any of the following ways:

    EMPLOYEE=$NICK
    EMPLOYEE=$SEC_ID
    EMPLOYEE=$EID

(where C<$NICK> is an employee nick, C<$SEC_ID> is an employee secondary ID, 
and C<$EID> is an employee ID (EID))

If, for some reason, this does not lead to the desired result, you can 
force a lookup on a particular property:

    NICK=$NICK
    SEC_ID=$SEC_ID
    EID=$EID

Note that there must not be any whitespace before or after the equal sign.


=head3 Get list of employees

Commands to list all employees, or just those with a given
privilege level:

    EMPLOYEE LIST             # lists all employees
    EMPLOYEE LIST admin
    EMPLOYEE LIST active
    EMPLOYEE LIST inactive
    EMPLOYEE LIST passerby

Only nicks are shown, in alphabetical order.


=head3 Create a new employee 

If you are using LDAP authentication, your employees are in the LDAP database
and you can turn on DOCHAZKA_LDAP_AUTOCREATE. Then employees will be created
automatically the first time they log in. Alternatively, employees can be
created manually:

    PUT employee nick $NICK { "fullname" : "King George III" }

In addition to "fullname", the following properties can be specified inside
the curly brackets:

    sec_id
    email
    password
    remark

For example, to add an employee with nick 'nancy' the command might look like
this:

    PUT employee nick nancy { "fullname" : "Nancy Bright Red", "email" : "nancy@identity.org" }
   
The new employee will have passerby privileges only until a privhistory record
is created (see L<"Add privilege history record">, below).


=head3 Set employee secondary ID

To manually change an employee's secondary ID, do one of the following:

    EMPLOYEE_SPEC SEC_ID $SEC_ID
    EMPLOYEE_SPEC SET SEC_ID $SEC_ID

Example:

    EMPLOYEE=joe SET SEC_ID 4553


=head3 Set employee full name

To manually change an employee's full name, do one of the following:

    EMPLOYEE_SPEC FULLNAME $WHATEVER
    EMPLOYEE_SPEC SET FULLNAME $WHATEVER

Examples:

    EMPLOYEE=baird FULLNAME Joseph Baird
    EMPLOYEE=baird FULLNAME JUDr. Joseph Peacock Baird LLM, Esq.

Do not use any quotes in or around the full name.


=head3 Set employee password

To manually change an employee's password, do:

    EMPLOYEE_SPEC PASSWORD
    EMPLOYEE_SPEC SET PASSWORD

You will be asked to type in the new password twice. This updates the password
that Dochazka stores in the 'employees' table. Whether this has any effect on
the user's ability to log in depends on what authentication method is being
used and where the passwords for that method are stored.


=head2 Schedules

=head3 View all schedules (including disabled schedules)

All existing schedules can be dumped to the screen:

    SCHEDULES FETCH ALL

Note that this does not include disabled schedules. To include those in the
listing, use this command:

    SCHEDULES FETCH ALL DISABLED

=head3 View an individual schedule (by SID or SCODE)

If the SID or SCODE of a schedule is known, it can be looked up like so:

    SID=12 SHOW
    SCODE=SAMPLE SHOW

The first example looks up the schedule with SID 12, and the second looks
up the schedule with SCODE "SAMPLE".

=head3 Define a new schedule

The following commands can be used to "create" a schedule, i.e. define it and
save it in the database. The idea is to first build up the schedule in memory
and then, when this "working" schedule is complete, submit it to the REST
server.

=head4 View working schedule

To see the current state of the working schedule, do:

    SCHEDULE DUMP
    SCHEDULE MEMORY

=head4 Add a line to the working schedule

Each line of the working schedule corresponds to a time interval. Time
intervals are defined by specifying when they begin and end. Ordinarily,
this format should be sufficient:

    SCHEDULE MON 8:00-12:00

(This sets up a time interval that begins on Monday 8:00 a.m. and ends
at 12:00 noon that same day.)

This method might not work if the interval starts and ends on different days -
in which case we would use a different format:

    SCHEDULE MON 23:00 TUE 03:30
    SCHEDULE MON 23:00 - TUE 03:30

Note that it is possible for the working schedule to contain overlapping
or otherwise nonsensical intervals.

=head4 Quickly add identical intervals MON-FRI

If your schedule has the same intervals for all five days of the standard work
week (Monday through Friday), the process of defining the schedule can be
accelerated by using the keyword ALL instead of MON, TUE, WED, etc.

    SCHEDULE ALL 8:00-12:00
    SCHEDULE ALL 12:30-16:30

Example:

Dochazka(2015-04-08) root ADMIN> schedule all 8:00-12:00
[ MON 08:00, MON 12:00 )
[ TUE 08:00, TUE 12:00 )
[ WED 08:00, WED 12:00 )
[ THU 08:00, THU 12:00 )
[ FRI 08:00, FRI 12:00 )

Dochazka(2015-04-08) root ADMIN> schedule all 12:30-16:30
[ MON 08:00, MON 12:00 )
[ MON 12:30, MON 16:30 )
[ TUE 08:00, TUE 12:00 )
[ TUE 12:30, TUE 16:30 )
[ WED 08:00, WED 12:00 )
[ WED 12:30, WED 16:30 )
[ THU 08:00, THU 12:00 )
[ THU 12:30, THU 16:30 )
[ FRI 08:00, FRI 12:00 )
[ FRI 12:30, FRI 16:30 )


=head4 Add an scode to the working schedule

Schedules are distinguished from eachother by their Schedule ID (SID)
and by their code (scode). To associate an scode with the working schedule,
do this:

    SCHEDULE SCODE $SCODE

Example:

    SCHEDULE SCODE 9_TO_5

The scode may not contain whitespace.

=head4 Submit working schedule to REST server

Once you are satisfied with your working schedule, submit it to the REST server
like this:

    SCHEDULE NEW

This is the "moment of truth" when you find out if the schedule is "kosher"
enough to make it into the database.

Example with overlapping intervals:

Dochazka(2015-04-08) root ADMIN> schedule memory
[ MON 23:00, TUE 03:30 )
[ MON 23:00, TUE 03:40 )

Dochazka(2015-04-08) root ADMIN> schedule new
*** Anomaly detected ***
Status:      500 Internal Server Error
ERR: DBI reports DBD::Pg::st execute failed: ERROR:  conflicting key value violates exclusion constraint "schedintvls_ssid_intvl_excl"DETAIL:  Key (ssid, intvl)=(11, ["2015-03-23 23:00:00+01","2015-03-24 03:40:00+01")) conflicts with existing key (ssid, intvl)=(11, ["2015-03-23 23:00:00+01","2015-03-24 03:30:00+01")). at /usr/lib/perl5/site_perl/5.20.1/App/Dochazka/REST/Model/Schedintvls.pm line 183.

=head4 Clear the working schedule

The working schedule can be cleared:

    SCHEDULE CLEAR


=head3 Add a remark to a schedule

Once you manage to get a schedule into the database, you can add a remark to
it:

    SCHEDULE_SPEC REMARK $REMARK
    SCHEDULE_SPEC SET REMARK $REMARK

The remark can contain whitespace, but should not contain any quotation marks.
The same command can be used to change an existing remark. To delete an existing
remark, leave out C<$REMARK>.


=head3 Set or modify scode

Once you manage to get a schedule into the database, you can set or modify its
scode:

    SCHEDULE_SPEC SCODE $REMARK
    SCHEDULE_SPEC SET SCODE $REMARK

The scode may contain only ASCII letters, numerals, underscores, and hyphens.


=head3 Disable a schedule

Assuming we know the SID or scode of the schedule, we can disable it:

    PUT SCHEDULE SID $SID { "disabled" : "t" }
    PUT SCHEDULE SCODE $SCODE { "disabled" : "t" }


=head3 Re-enable a schedule

To re-enable a disabled schedule:

    PUT SCHEDULE SID $SID { "disabled" : "f" }
    PUT SCHEDULE SCODE $SCODE { "disabled" : "f" }


=head2 Histories

Maintaining/updating employee history records (recording changes in privilege
level and schedule, primarily) is a typical administrator workflow.


=head3 Add privilege history record

    EMPLOYEE_SPEC PRIV_SPEC _TIMESTAMP
    EMPLOYEE_SPEC SET PRIV_SPEC _TIMESTAMP
    EMPLOYEE_SPEC PRIV_SPEC EFFECTIVE _TIMESTAMP
    EMPLOYEE_SPEC SET PRIV_SPEC EFFECTIVE _TIMESTAMP

(In other words, the SET and EFFECTIVE keywords can be omitted.)

Examples:

Employee joe becomes an active employee as of 2015-06-30 00:00:

    EMPLOYEE=joe active 2015-06-30

The employee with secondary ID 634 becomes a passerby as of 1958-04-27

    SEC_ID=634 passerby EFFECTIVE 1958-04-27

=head3 Add schedule history record

    EMPLOYEE_SPEC SCHEDULE_SPEC _TIMESTAMP
    EMPLOYEE_SPEC SET SCHEDULE_SPEC _TIMESTAMP
    EMPLOYEE_SPEC SCHEDULE_SPEC EFFECTIVE _TIMESTAMP
    EMPLOYEE_SPEC SET SCHEDULE_SPEC EFFECTIVE _TIMESTAMP

(In other words, the SET and EFFECTIVE keywords can be omitted.)

Examples:

Employee joe goes on schedule KOBOLD as of 2015-06-30 00:00:

    EMPLOYEE=joe scode=KOBOLD 2015-06-30

The employee with secondary ID 634 goes on the schedule with SID 32 as of 1958-04-27

    SEC_ID=634 SET SID=32 EFFECTIVE 1958-04-27


=head3 Add remark to history record

Privilege and schedule history records can have remarks associated with them, 
which can be a handy way to remember why the privelege/schedule took place.
The first column of the history listing:

    EMPL=joe PRIV HISTORY

is either PHID (Privilege History ID) or SHID (Schedule History ID). To add a
remark to PHID 352, do the following:

    PHID=352 REMARK Employee fired by Big Bad Boss

For schedule history remarks, do this:

    SHID=652 REMARK Employee goes onto a different schedule

or, in general:

    PHISTORY_SPEC [SET] REMARK $REMARK
    SHISTORY_SPEC [SET] REMARK $REMARK



=head1 SUPERVISOR WORKFLOWS


=head2 Employees


=head3 View profile of an employee in my team

Assuming the employee really is in your team, you can do any of the following:

    EMPLOYEE_SPEC
    EMPLOYEE_SPEC PROFILE
    EMPLOYEE_SPEC SHOW

For the meaning of C<EMPLOYEE_SPEC>, see L<"Specifying an employee">, above.

For example, to view the profile of team member joe, just type:

    EMPLOYEE=joe

or

    EMPLOYEE=joe PROFILE


=head2 Privilege levels

=head3 View an employee's privilege level

Although C<EMPLOYEE_SPEC PROFILE> shows the employee's privilege level, there
is also a dedicated command:

    EMPLOYEE_SPEC PRIV


=head2 Schedules

=head3 View an employee's schedule

Provided the employee has a schedule defined, it can be displayed by typing:

    EMPLOYEE_SPEC SCHEDULE


=head2 Histories

For each employee, Dochazka maintains two "histories": privilege history and
schedule history. Each time an employee's privilege or schedule status changes,
a history record should be added.


=head3 View an employee's privilege history

    EMPLOYEE_SPEC PRIV HISTORY


=head3 View an employee's schedule history

    EMPLOYEE_SPEC SCHEDULE HISTORY



=head1 USER WORKFLOWS


=head2 Activities


=head3 View a list of all activities

To view a list of all activities, do:

    ACTIVITIES
    ACTIVITIES ALL


=head2 Employees


=head3 View own employee profile

Each Dochazka employee has a "profile" with some basic information. One's own
profile can be viewed by doing any of the following:

    EMPLOYEE
    EMPLOYEE PROFILE
    EMPLOYEE SHOW


=head3 Set own password

To manually change your password, do:

    EMPLOYEE PASSWORD
    EMPLOYEE SET PASSWORD

You will be asked to type in the new password twice. If you still can't log in
after doing this, contact your local Dochazka administrator.


=head2 Privilege levels

=head3 View one's own privilege level

Although C<EMPLOYEE PROFILE> shows the employee's privilege level, there
is also a dedicated command:

    PRIV

Example

    Dochazka(2015-04-08) demo PASSERBY> priv
    The current privilege level of demo (EID 2) is passerby


=head2 Schedules

=head3 View one's own schedule

Provided the employee has a schedule defined, it can be displayed by typing:

    SCHEDULE


=head3 Display an arbitrary schedule



=head2 Histories

=head3 View own privilege history

    PRIV HISTORY

=head3 View own schedule history

    SCHEDULE HISTORY



=head2 Intervals

=head3 Enter an interval

=head4 "Canonical" form

The canonical way to enter an attendance interval:

    INTERVAL $TIME_BEGIN $TIME_END $ACTIVITY_CODE $DESCRIPTION
    INTERVAL $TIME_BEGIN - $TIME_END $ACTIVITY_CODE $DESCRIPTION

Use the above command variant if you need to enter the date along with the
time, or if the interval begins and ends on a different date. Example:

    INTERVAL 2015-04-27 08:00 - 2015-04-27 12:00 WORK Prepare notes for meeting

If the date is omitted, the "prompt date" will be used:

    INTERVAL 08:00 - 12:00 WORK Prepare notes for meeting

If a beginning date is specified, but no ending date, the beginning date will
be applied to the end as well:

    INTERVAL 2015-04-28 12:30 - 16:30 WORK Wait for Godot
    
=head4 Time range

Another way to omit the date (default to the prompt date) is to enter a time range:

    INTERVAL $TIME_RANGE $ACTIVITY_CODE $DESCRIPTION

Example:

    INTERVAL 8:00-9:00 MEDICAL_LEAVE Doctor's appointment

Optionally, a date can be specified before the time range:

    INTERVAL 2015-04-28 8:00-9:00 MEDICAL_LEAVE Doctor's appointment


=head3 Fetch (i.e., view) intervals 

There are many commands for viewing intervals. In all cases, the term FETCH is optional

=head4 All intervals on the prompt date

    INTERVAL [FETCH]

The simplest form; displays the list of intervals for the
prompt date.

=head4 All intervals on a specified date

    INTERVAL [FETCH] $DATE

Fetch all intervals on the given date. Example:

    INTERVAL FETCH 2015-04-28

=head4 All intervals between a range of dates

    INTERVAL [FETCH] $DATE_BEGIN $DATE_END
    INTERVAL [FETCH] $DATE_BEGIN - $DATE_END

Fetch all intervals from C<$DATE_BEGIN> to C<$DATE_END>.

=head4 All intervals in a given month

    INTERVAL [FETCH] $MONTH
    INTERVAL [FETCH] $MONTH $YEAR

The month can be given either in English (only first three letters are
necessary) or as a numeric value. Example:

    INTERVAL APR
    INTERVAL FETCH 4

Both of these commands fetch all the employee's intervals that fall within
April of the prompt year.

=cut

1;
