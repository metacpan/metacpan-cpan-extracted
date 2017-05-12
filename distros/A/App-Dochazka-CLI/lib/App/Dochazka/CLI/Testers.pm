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
# Documentation for volunteer testers
#
package App::Dochazka::CLI::Testers;

use 5.012;
use strict;
use warnings;




=head1 NAME

App::Dochazka::CLI::Testers - Documentation for volunteer testers



=head1 PREREQUISITES


=head2 Prereq 1: Add home:smithfarm repo

The Dochazka packages and their dependencies currently live in the
C<home:smithfarm> repo on the OBS. To fulfill this prereq, add the right
repo for your operating system:
L<http://software.opensuse.org/download.html?project=home%3Asmithfarm&package=perl-App-Dochazka-CLI>.


=head2 Prereq 2: Install/configure servers

Before you start, you will need to install and set up PostgreSQL and the
Dochazka REST server. There are two ways to accomplish this:
the Docker way and the "traditional" way.

=over

=item L<"The Docker way">

is arguably simpler, because you don't install as many
packages and there is little or no setup work involved. However, quite a
lot of data (on the order of hundreds of MB) will be downloaded from Docker
Hub. (To handle this, it may be a good idea to put C</var/lib/docker> on a
separate partition.)

=item L<"The traditional way">

is to install and configure PostgreSQL and the
Dochazka REST server in your testing environment. This is somewhat more
complicated and involves installing and operating a PostgreSQL server on
the machine where you will be running the tests.

=back

Both ways are described below, but you only need to do one or the other!

=head3 The Docker way

=over

=item Install Docker

For testing purposes, you can use the Dockerized REST server. For this, you
will need to have Docker installed and running:

    zypper install docker
    systemctl start docker.service

=item Get and run test drive script

The REST server Docker image depends on the official PostgreSQL image and
must be run with certain parameters. A script is provided to make this
easy. Download and run the script:

    wget https://raw.githubusercontent.com/smithfarm/dochazka-rest/master/test-drive.sh
    sh test-drive.sh

If you have never run Docker containers before, you may be surprised that
the script downloads quite a lot of data from Docker Hub. The script should
complete without any error messages.

=item Web browser test

When the C<test-drive.sh> script completes, you should be able to access
the REST server by pointing your browser at L<http://localhost:5000>. At
the login dialog, enter username "demo" and password "demo".

=back


=head3 The traditional way

Alternatively, if you don't like Docker or can't use it for some reason,
you can install and set up PostgreSQL and the Dochazka REST server
yourself.

=over

=item Install server packages

    zypper install postgresql postgresql-server postgresql-contrib 
    zypper install perl-App-Dochazka-REST 

=item PostgreSQL setup

Follow the instructions at
L<https://metacpan.org/pod/App::Dochazka::REST::Guide#PostgreSQL-setup>.

=item Site configuration

Follow the instructions at
L<https://metacpan.org/pod/App::Dochazka::REST::Guide#Site-configuration>.

=item Database initialization

This step is very simple. Just run the C<dochazka-dbinit> command:

    # dochazka-dbinit
    Dochazka database reset to pristine state

=item Start the server

To actually do anything, the server needs to be running:

    # dochazka-rest
    Starting Web::MREST ver. 0.283
    App distro is App-Dochazka-REST
    App module is App::Dochazka::REST::Dispatch
    Distro sharedir is /usr/lib/perl5/site_perl/5.20.1/auto/share/dist/App-Dochazka-REST
    Local site configuration directory is /etc/dochazka-rest
    Loading configuration parameters from /etc/dochazka-rest
    Setting up logging
    Logging to /home/smithfarm/mrest.log
    Calling App::Dochazka::REST::Dispatch::init()
    Starting server
    HTTP::Server::PSGI: Accepting connections at http://0:5000/

=item Web browser test

After completing the above, you should be able to access the REST server by
pointing your browser at L<http://localhost:5000>. At the login dialog,
enter username "demo" and password "demo".

=back


=head2 Prereq 3: Install Dochazka CLI client

Now that the server part is working, install the CLI:

    zypper install perl-App-Dochazka-CLI

You should now be able to start the CLI and login as "demo" with password
"demo":

    $ dochazka-cli -u demo -p demo
    Loading configuration files from
    /usr/lib/perl5/vendor_perl/5.18.2/auto/share/dist/App-Dochazka-CLI
    Cookie jar: /root/.cookies.txt
    URI base http://localhost:5000 set from site configuration
    Authenticating to server at http://localhost:5000 as user root
    Server is alive
    Dochazka(2016-01-12) demo PASSERBY>

Exit the CLI by issuing the C<exit> command:

    Dochazka(2016-01-12) demo PASSERBY> exit
    $

Congratulations! You have passed the first test.


=head1 SESSION 1: CREATE AN EMPLOYEE

Before you do anything, L<make sure the server is running|"Start the server">.


=head2 Try with insufficient privileges

To create an employee, you will need to be logged in as an administrator.
The "demo" employee is not an administrator, but let's try anyway. First,
log in according to L<"Verify success">, above. Then, issue the C<employee
list> command:

    Dochazka(2016-01-12) demo PASSERBY> employee list
    *** Anomaly detected ***
    Status:      403 Forbidden
    Explanation: ACL check failed for resource employee/list/?:priv (ERR)

This output indicates that the REST server returned a C<403 Forbidden> error,
which is to be expected because the C<demo> employee has insufficient
privileges.

Next, try to create an employee:

    Dochazka(2016-01-12) demo PASSERBY> PUT employee nick george { "fullname" : "King George III" }
    HTTP status: 403 Forbidden
    Non-suppressed headers: {
      'X-Web-Machine-Trace' => 'b13,b12,b11,b10,b9,b8,b7'
    }
    Response:
    {
       "payload" : {
          "http_code" : 403,
          "uri_path" : "employee/nick/george",
          "permanent" : true,
          "found_in" : {
             "file" : "/usr/lib/perl5/vendor_perl/5.22.0/App/Dochazka/REST/Auth.pm",
             "package" : "App::Dochazka::REST::Auth",
             "line" : 431
          },
          "resource_name" : "employee/nick/:nick",
          "http_method" : "PUT"
       },
       "text" : "ACL check failed for resource employee/nick/:nick",
       "level" : "ERR",
       "code" : "DISPATCH_ACL_CHECK_FAILED"
    }

Here, the error is the same C<403 Forbidden> but the output is more detailed.
This is because we used a special type of command that is ordinarily only
used to test the REST API.

=head2 Log in as root

For the rest of this session, we will be logged in as the C<root> employee, 
which has a special status in that it is created when the database is
initialized and it is difficult or impossible to delete. In a freshly
initialized database, the C<root> employee's password is "immutable".

The username and password need not be specified on the command line.
Try it this way:

    $ dochazka-cli
    Loading configuration files from /usr/lib/perl5/vendor_perl/5.18.2/auto/share/dist/App-Dochazka-CLI
    Cookie jar: /root/.cookies.txt
    URI base http://localhost:5000 set from site configuration
    Username: root
    Authenticating to server at http://localhost:5000 as user root
    Password: 
    Server is alive
    Dochazka(2016-01-12) root ADMIN>

=head2 List employees

A list of all employees in the database can be obtained using the C<employee
list> command, which is documented at L<App::Dochazka::CLI::Guide|"Get list of
employees">:

    Dochazka(2016-01-12) root ADMIN> employee list

    List of employees with priv level ->all<-
        demo
        root

Actually, there is no priv level "all" - this just means that all employees are
listed, regardless of their priv level.

You can also try listing employees by priv level as per the documentation.

=head2 Create an employee

At the moment there is no CLI command to create a new employee. Hence we use
the REST API testing command as described in
L<App::Dochazka::CLI::Guide|"Create a new employee">:

    Dochazka(2016-01-12) root ADMIN> PUT employee nick george { "fullname" : "King George III" }
    HTTP status: 200 OK
    Non-suppressed headers: {
      'X-Web-Machine-Trace' => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,c4,d4,e5,f6,g7,g8,h10,i12,l13,m16,n16,o16,o14,p11,o20,o18,o18b'
    }
    Response:
    {
       "code" : "DOCHAZKA_CUD_OK",
       "count" : 1,
       "payload" : {
          "email" : null,
          "remark" : null,
          "eid" : 3,
          "passhash" : null,
          "supervisor" : null,
          "sec_id" : null,
          "salt" : null,
          "nick" : "george",
          "fullname" : "King George III"
       },
       "text" : "DOCHAZKA_CUD_OK",
       "DBI_return_value" : 1,
       "level" : "OK"
    }

=head2 Employee profile

The properties, or attributes, of the C<employee> class can be seen in the
output of the previous command (under "payload"). A more comfortable way to
display the properties of any employee is the C<employee profile> command:

    Dochazka(2016-01-12) root ADMIN> employee profile

    Full name:    Root Immutable
    Nick:         root
    Email:        root@site.org
    Secondary ID: (not set)
    Dochazka EID: 1
    Reports to:   (not set)

In this form, it displays the profile of the logged-in employee. To show the
profile of a different employee, use this form:

    Dochazka(2016-01-12) root ADMIN> emp=demo profile

    Full name:    Demo Employee
    Nick:         demo
    Email:        demo@dochazka.site
    Secondary ID: (not set)
    Dochazka EID: 2
    Reports to:   (not set)

Here, the "emp=demo" is an employee spec. This is explained in
L<App::Dochazka::CLI::Guide/"Specify an employee">.

Finally, try various combinations of the following commands to get
information about the new employee you just created:

    employee list
    employee profile
    emp=... profile
    nick=... profile
    eid=... profile

=cut


=head1 SESSION 2: EMPLOYEE PRIVILEGES AND PASSWORD

Before you do anything, L<make sure the server is running|"Start the server">.


=head2 Verify state

If you are continuing from Session 1, you can skip this step.

If you are starting over (or from scratch), run the following script to
bring your database into the proper state:

    #!/bin/sh
    cat <<EOF | dochazka-cli -u root -p immutable
    PUT employee nick george { "fullname" : "King George III" }
    EOF


=head2 View employee profile

Let us see the state of a freshly created employee:

    Dochazka(2016-01-27) root ADMIN> emp=george profile

    Full name:    King George III
    Nick:         george
    Email:        (not set)
    Secondary ID: (not set)
    Dochazka EID: 5
    Reports to:   (not set)

This only tells us the state of the employee object. Most objects in the
Dochazka database are associated with an employee via the Dochazka EID
value (5 in this example). We can get the same information by typing:

    Dochazka(2016-01-27) root ADMIN> eid=5 profile

    Full name:    King George III
    Nick:         george
    Email:        (not set)
    Secondary ID: (not set)
    Dochazka EID: 5
    Reports to:   (not set)


=head2 Log in as george

Now, exit the CLI and run it again as C<george>, our new employee.

    $ dochazka-cli 
    ...
    Username: george
    Authenticating to server at http://localhost:5000 as user george
    Password: 
    MREST_CLI_UNAUTHORIZED (ERR) MREST_CLI_UNAUTHORIZED
    Response: '401 Unauthorized'

This happens because there is no password set for C<george>.


=head2 Assign george a password

Fortunately, Dochazka admins can assign any password to any user. This
capability may or may not be useful, depending on whether LDAP
authentication is active at the site. In our current testing scenario, LDAP
authentication is disabled, so the password is taken from the Dochazka
database. So, let's give george a password:

    $ dochazka-cli -u root -p immutable
    ...
    Dochazka(2016-01-27) root ADMIN> emp=george password
    It is important that the new password really be what you intended.
    Therefore, we are going to ask you to enter the desired password
    twice, so you have a chance to double-check. 

    New password      : <type george>
    New password again: <type george again>
    Password changed

Now you can log in with credentials C<george/george>:

    $ dochazka-cli -u george -p george
    ...
    Authenticating to server at http://localhost:5000 as user george
    Server is alive
    Dochazka(2016-01-27) george PASSERBY>




=head1 SESSION 3: EMPLOYEE PRIVILEGE HISTORY

Before you do anything, L<make sure the server is running|"Start the server">.


=head2 Verify state

If you are continuing from Session 2, you can skip this step.

If you are starting over (or from scratch), run the following script to
bring your database into the proper state:

    #!/bin/sh
    cat <<EOF | dochazka-cli -u root -p immutable
    PUT employee nick george { "fullname" : "King George III", "salt" : "a054d158a23c3a07ad0163107ad72a8649597d71", "passhash" : "5cf2c3a23de9db43d2d846172966150e9197717ecd0304bafef3f23fc159df942021dd3aec7b4dbcde87d8a44c1bd905bbba3862989065d012bb46a1e2b9ac5c" }
    EOF


=head2 Log in as the test employee

This just demonstrates that the test employee can log in.

    $ dochazka-cli -u george -p george
    ...
    Authenticating to server at http://localhost:5000 as user george
    Server is alive
    Dochazka(2016-01-27) george PASSERBY>


=head2 Concepts (Dochazka prompt, employee priv levels)

Let's review the information presented in the prompt:

=over

=item Prompt date in parentheses (defaults to current date)

=item Logged-in employee (george)

=item Privilege level of logged-in employee (passerby)

=back

The privilege level deserves closer attention. Dochazka has four privilege
levels:

=over

=item passerby

=item inactive

=item active

=item admin

=back


=head2 George the passerby

The current privilege level is determined by consulting the employee's
privilege history, which is a database table containing records for each
change in the employee's status. Employee status changes, for example, when
the employee is hired, leaves the company, goes on parental leave, etc.

Now, our test employee "george" has a password and can log in. However, he
has no privilege history so his priv level defaults to "passerby" - the
lowest possible level.

In this section, we see that passers-by cannot do much at all in Dochazka:

    $ dochazka-cli -u george -p george
    Dochazka(2016-01-29) george PASSERBY> emp=root profile
    *** REST ERROR ***

    Error encountered on attempted operation "Employee lookup"
    REST operation: GET employee/nick/root/minimal
    HTTP status: 403 Forbidden
    Explanation: DISPATCH_KEEP_TO_YOURSELF: Detected attempt by
    insufficiently privileged user to meddle in another user's affairs
    Permanent? YES

    Dochazka(2016-01-29) george PASSERBY> interval
    *** REST ERROR ***

    Error encountered on attempted operation "Get intervals for employee
    george (EID 3) in range [ 2016-01-29 00:00, 2016-01-29 24:00 )"
    REST operation: GET interval/eid/3/[ 2016-01-29 00:00, 2016-01-29 24:00
    )
    HTTP status: 403 Forbidden
    Explanation: DISPATCH_ACL_CHECK_FAILED: ACL check failed for resource
    interval/eid/:eid/:tsrange
    Permanent? YES

    Dochazka(2016-01-29) george PASSERBY> priv history
    *** Anomaly detected ***
    Status:      403 Forbidden
    Explanation: ACL check failed for resource priv/history/eid/:eid (ERR)

There are some things passers-by can do, but it is quite limited.


=head2 Make george an employee

Employees can be either "active" or "inactive". An employee is considered
inactive, for example, when she is on parental leave. The typical employee
in Dochazka will have priv level "active", so let's give george this level
of privilege.

Log in as root:

    $ dochazka-cli -u root -p immutable

Confirm the current priv level using the C<EMP=george PRIV> command:

    Dochazka(2016-01-27) root ADMIN> emp=george priv
    Privilege level of george (EID 5) as of now: passerby

Display george's priv history (which is still empty at this point):

    Dochazka(2016-01-27) root ADMIN> emp=george priv history
    *** Anomaly detected ***
    Status:      404 Not Found
    Explanation: No history for EID 5  (ERR)

Add a priv history record:

    Dochazka(2016-01-28) root ADMIN> emp=george active 2015-01-02
    Privilege history record (PHID 3) added

Display george's priv history again:

    Dochazka(2016-01-29) root ADMIN> emp=george priv history
    Privilege history of george (EID 3):

    PHID Effective date Privlevel Remark
    2    2015-01-02     active          

Log out and log back in as george, try commands that didn't work before,
when the priv level was "passerby":

    Dochazka(2016-01-29) george ACTIVE> priv history
    Privilege history of george (EID 3):

    PHID Effective date Privlevel Remark
    2    2015-01-02     active          



=head1 SESSION 4: SCHEDULES

Before you do anything, L<make sure the server is running|"Start the server">.


=head2 Verify state

If you are continuing from Session 3, you can skip this step.

If you are starting over (or from scratch), run the following script to
bring your database into the proper state:

    #!/bin/sh
    cat <<EOF | dochazka-cli -u root -p immutable
    PUT employee nick george { "fullname" : "King George III", "salt" : "a054d158a23c3a07ad0163107ad72a8649597d71", "passhash" : "5cf2c3a23de9db43d2d846172966150e9197717ecd0304bafef3f23fc159df942021dd3aec7b4dbcde87d8a44c1bd905bbba3862989065d012bb46a1e2b9ac5c" }
    emp=george active 2015-01-02
    EOF


=head2 Try to enter an attendance interval

At this point, one might be tempted to start entering attendance intervals,
so let's give it a try:

    Dochazka(2016-01-29) george ACTIVE> interval 8:00-9:00 work Pushing pencils
    *** REST ERROR ***

    Error encountered on attempted operation "Insert new attendance
    interval"
    REST operation: POST interval/new
    HTTP status: 500 Internal Server Error
    Explanation: DOCHAZKA_DBI_ERR: DBI reports DBD::Pg::st execute failed:
    ERROR:  employee schedule for this interval cannot be determined at
    /usr/lib/perl5/site_perl/5.20.1/App/Dochazka/REST/Model/Shared.pm line
    247.

    Permanent? YES

The command C<interval 8:00-9:00 work Pushing pencils> means to add an
attendance interval from 8:00 to 9:00 a.m. on the prompmt date, with
activity WORK and description "Pushing pencils". The error indicates that
the employee has no schedule defined for that date.


=head2 Concepts (schedules, schedule history)

As we saw before, employees can and will have different statuses during
their careers with the company. An employee may be hired, then leave for
some reason, and then come back.

Similarly, employee schedules may change, and Dochazka has a mechanism
(schedule history) for tracking and reflecting those changes. At this point
in our testing, our employee (george) not have any schedule history
records. More importantly, there are no schedules defined. Before we can
assign george a schedule, we will need to add one.

Verify that there are no schedules:

    Dochazka(2016-01-29) george ACTIVE> schedule fetch all
    *** Anomaly detected ***
    Status:      404 Not Found
    Explanation: There are no active schedules in the database (ERR)

And that there is no schedule history:

    Dochazka(2016-01-29) george ACTIVE> schedule history
    *** Anomaly detected ***
    Status:      404 Not Found
    Explanation: No history for EID 3  (ERR)


=head2 Define a schedule

To add a new schedule to the database, we will have to be logged in as an
administrator. For now, that means "root".

    $ dochazka-cli -u root -p immutable
    ...
    Dochazka(2016-01-29) root ADMIN> 

To define a schedule, we first build it up in memory by adding intervals.

    Dochazka(2016-01-29) root ADMIN> schedule mon 8:00-12:00
    [ MON 08:00, MON 12:00 )

Every time we add an interval, the entire schedule is displayed. Remember,
this is a temporary, working schedule that exists on the client side only
(until we commit it to the database).
 
Add more intervals. Let's imagine that george is a part time employee:

    Dochazka(2016-01-29) root ADMIN> schedule tue 13:00-17:00
    [ MON 08:00, MON 12:00 )
    [ TUE 13:00, TUE 17:00 )

Now there are two intervals in memory. At any time, we can dump the working
schedule using the C<SCHEDULE DUMP> command:

    Dochazka(2016-01-29) root ADMIN> schedule dump
    [ MON 08:00, MON 12:00 )
    [ TUE 13:00, TUE 17:00 )

Finish up by adding intervals for a full 8-hour day on Wednesday, a
short on Thursday, and we'll let george have Friday off:

    Dochazka(2016-01-29) root ADMIN> schedule wed 8:00-12:00
    Dochazka(2016-01-29) root ADMIN> schedule wed 13:00-17:00
    Dochazka(2016-01-29) root ADMIN> schedule thu 7:00-10:00

What does the schedule look like now?

    Dochazka(2016-01-29) root ADMIN> schedule dump
    [ MON 08:00, MON 12:00 )
    [ TUE 13:00, TUE 17:00 )
    [ WED 08:00, WED 12:00 )
    [ WED 13:00, WED 17:00 )
    [ THU 07:00, THU 10:00 )

In the next section, we'll commit this schedule to the database.


=head2 Commit in-memory schedule to the server

The command to save the schedule is C<SCHEDULE NEW>, but before we issue
that command, let's add an "scode" (schedule code) to the schedule to make
it more easy to refer to. Each schedule has a unique numeric identifier
(SID) that is assigned by the server, and optionally an scode as well.

    Dochazka(2016-01-29) root ADMIN> schedule scode VPP-1
    Schedule code: VPP-1

    [ MON 08:00, MON 12:00 )
    [ TUE 13:00, TUE 17:00 )
    [ WED 08:00, WED 12:00 )
    [ WED 13:00, WED 17:00 )
    [ THU 07:00, THU 10:00 )

And now we can commit:

    Dochazka(2016-01-29) root ADMIN> schedule new
    HTTP status: 201 Created
    Schedule ID (SID): 1
    Schedule code (scode): VPP-1
    [ MON 08:00, MON 12:00 )
    [ TUE 13:00, TUE 17:00 )
    [ WED 08:00, WED 12:00 )
    [ WED 13:00, WED 17:00 )
    [ THU 07:00, THU 10:00 )


=head1 SESSION 5: SCHEDULE HISTORY

Before you do anything, L<make sure the server is running|"Start the server">.


=head2 Verify state

If you are continuing from Session 4, you can skip this step.

If you are starting over (or from scratch), run the following script to
bring your database into the proper state:

    #!/bin/sh
    cat <<EOF | dochazka-cli -u root -p immutable
    PUT employee nick george { "fullname" : "King George III", "salt" :
    "a054d158a23c3a07ad0163107ad72a8649597d71", "passhash" :
    "5cf2c3a23de9db43d2d846172966150e9197717ecd0304bafef3f23fc159df942021dd3aec7b4dbcde87d8a44c1bd905bbba3862989065d012bb46a1e2b9ac5c"
    }
    emp=george active 2015-01-02
    schedule mon 8:00-12:00
    schedule tue 13:00-17:00
    schedule wed 8:00-12:00
    schedule wed 13:00-17:00
    schedule thu 7:00-10:00
    schedule scode VPP-1
    schedule new
    EOF


=head2 List schedules as active employee

The C<SCHEDULE FETCH ALL> generates a C<GET schedule/all> REST request to
list all schedules in the database:

    Dochazka(2016-01-30) george ACTIVE> schedule fetch all
    Schedule ID (SID): 1
    Schedule code (scode): VPP-1
    [ MON 08:00, MON 12:00 )
    [ TUE 13:00, TUE 17:00 )
    [ WED 08:00, WED 12:00 )
    [ WED 13:00, WED 17:00 )
    [ THU 07:00, THU 10:00 )

At a real Dochazka site, this might produce a lot of output. If you know
the SID or scode of a particular schedule, you can fetch just a single
schedule. Either of the following commands should produce the same output
as the one above:

    Dochazka(2016-01-30) george ACTIVE> scode=VPP-1 fetch
    ...
    Dochazka(2016-01-30) george ACTIVE> sid=1 fetch
    ...


=head2 List schedules as passerby

These commands use C<GET schedule/...> REST operations whose ACL profile is
"inactive". This can be verified by logging in as the employee C<demo>
(password C<demo>):

    $ dochazka-cli -u demo -p demo
    Dochazka(2016-01-30) demo PASSERBY> schedule fetch all
    *** Anomaly detected ***
    Status:      403 Forbidden
    Explanation: ACL check failed for resource schedule/all (ERR)

    Dochazka(2016-01-30) demo PASSERBY> scode=VPP-1 fetch
    *** Anomaly detected ***
    Status:      403 Forbidden
    Explanation: ACL check failed for resource schedule/scode/:scode (ERR)

    Dochazka(2016-01-30) demo PASSERBY> sid=1 fetch
    *** Anomaly detected ***
    Status:      403 Forbidden
    Explanation: ACL check failed for resource schedule/sid/:sid (ERR)


=head2 View schedule history as passerby

If we ask to see the schedule history of employee george, we get a slightly
different error:

    Dochazka(2016-01-30) demo PASSERBY> emp=george schedule history
    *** REST ERROR ***

    Error encountered on attempted operation "Employee lookup"
    REST operation: GET employee/nick/george
    HTTP status: 403 Forbidden
    Explanation: DISPATCH_KEEP_TO_YOURSELF: Detected attempt by
    insufficiently privileged user to meddle in another user's affairs
    Permanent? YES

Though the HTTP status is the same as before, the format of the error
message indicates that processing got a little further - this is because
the ACL profile of the C<GET employee/nick/:nick> operation is "passerby".

But this is not a discussion of Dochazka internals - let's get on to
inserting a schedule history record for george. 


=head2 Create schedule history record

Log in as root:

    $ dochazka-cli -u root -p immutable
    Dochazka(2016-01-30) root ADMIN> emp=george schedule history
    *** Anomaly detected ***
    Status:      404 Not Found
    Explanation: No history for EID 3  (ERR)

Schedule histories work analogously to privilege histories:

    Dochazka(2016-01-30) root ADMIN> emp=george scode=VPP-1 2015-01-02
    Schedule history record (SHID 1) added
    Dochazka(2016-01-30) root ADMIN> emp=george schedule history
    Schedule history of george (EID 3):

    SHID Effective date SID scode Remark
    1    2015-01-02     1   VPP-1       

This completes the setup of employee george as an active employee. He can
now enter attendance intervals, do fillup, generate monthly reports, etc.


=head1 SESSION 6: ACTIVITIES AND SITE PARAMETERS

Before you do anything, L<make sure the server is running|"Start the server">.


=head2 Verify state

If you are continuing from Session 5, you can skip this step.

If you are starting over (or from scratch), run the following script to
bring your database into the proper state:

    #!/bin/sh
    cat <<EOF | dochazka-cli -u root -p immutable
    PUT employee nick george { "fullname" : "King George III", "salt" : "a054d158a23c3a07ad0163107ad72a8649597d71", "passhash" : "5cf2c3a23de9db43d2d846172966150e9197717ecd0304bafef3f23fc159df942021dd3aec7b4dbcde87d8a44c1bd905bbba3862989065d012bb46a1e2b9ac5c" }
    emp=george active 2015-01-02
    schedule mon 8:00-12:00
    schedule tue 13:00-17:00
    schedule wed 8:00-12:00
    schedule wed 13:00-17:00
    schedule thu 7:00-10:00
    schedule scode VPP-1
    schedule new
    emp=george scode=VPP-1 2015-01-02
    EOF


=head2 Concepts (activities and attendance intervals)

The purpose of Dochazka is to keep records of how work time is spent -
typically for payroll purposes (i.e. calculation of wages). 

Employees are paid not only for time spent at work, but also (according to
their contract and governing legislation) for time B<not> spent at work.
For example, if an employee is not feeling well, she can stay home and the
employer will tolerate this (and even pay wages in some cases). This time
needs to be distinguished as "sick leave".

Thus, sites typically have different categories for tracking time - e.g. "work",
"vacation", "sick leave", etc. In Dochazka, these categories are called
"activities", and every attendance interval in the database is connected
with one, and only one, activity.


=head2 List all activities

The command for listing all activites is C<ACTIVITY ALL>:

    Dochazka(2016-02-02) george ACTIVE> activity all

    1 WORK               Work
    2 OVERTIME_WORK      Overtime work
    3 PAID_VACATION      Paid vacation
    4 UNPAID_LEAVE       Unpaid leave
    5 DOCTOR_APPOINTMENT Doctor appointment
    6 CTO                Compensation Time Off
    7 SICK_DAY           Discretionary sick leave
    8 MEDICAL_LEAVE      Statutory medical leave


=head2 Concepts (database initialization, site parameters)

In the previous section we listed some activities, but where do they come
from? We started from a pristine database and only entered an employee, a
priv history record, a schedule, and a schedule history record.

Indeed. Dochazka has a mechanism called "site parameters", and there is a
site parameter called C<DOCHAZKA_ACTIVITY_DEFINITIONS> which defaults to
the following:

    # DOCHAZKA_ACTIVITY_DEFINITIONS
    #    Initial set of activity definitions - sample only - override this 
    #    with _your_ site's activities in Dochazka_SiteConfig.pm
    set( 'DOCHAZKA_ACTIVITY_DEFINITIONS', [
        { code => 'WORK', long_desc => 'Work' },
        { code => 'OVERTIME_WORK', long_desc => 'Overtime work' },
        { code => 'PAID_VACATION', long_desc => 'Paid vacation' },
        { code => 'UNPAID_LEAVE', long_desc => 'Unpaid leave' },
        { code => 'DOCTOR_APPOINTMENT', long_desc => 'Doctor appointment' },
        { code => 'CTO', long_desc => 'Compensation Time Off' },
        { code => 'SICK_DAY', long_desc => 'Discretionary sick leave' },
        { code => 'MEDICAL_LEAVE', long_desc => 'Statutory medical leave' },
    ] );   

When the database is initialized for the first time, the initialization
routine reads this site parameter and creates an initial set of activities.
That is what you are seeing.

This can be confirmed by peeking at the C<GET param/site/DOCHAZKA_ACTIVITY_DEFINITIONS> 
resource:

    Dochazka(2016-02-02) root ADMIN> get param site DOCHAZKA_ACTIVITY_DEFINITIONS
    ...


=head2 Create a new activity

Since this is not expected to be a frequent operation, no special command
has been implemented. We use the REST resource directly:

    Dochazka(2016-02-02) root ADMIN> PUT activity code TESTACT { "long_desc" : "testing" }
    HTTP status: 200 OK
    ...
    Response:
    {  
       "payload" : {
          "disabled" : 0,
          "code" : "TESTACT",
          "aid" : 9,
          "remark" : null,
          "long_desc" : "testing"
       },
       "code" : "DOCHAZKA_CUD_OK",
       "DBI_return_value" : 1,
       "level" : "OK",
       "count" : 1,
       "text" : "DOCHAZKA_CUD_OK"
    }

And confirm that TESTACT is now present:

    Dochazka(2016-02-02) root ADMIN> activity all
    ...


=head2 Disable an activity

In the course of events, it might happen that an activity becomes obsolete or
deprecated. If there are no attendance intervals associated with it, it can be
deleted outright. This is probably not the case, but we can still cause the 
activity to disappear from the listing by disabling it:

    Dochazka(2016-02-02) root ADMIN> PUT activity code TESTACT { "disabled" : "t" }
    HTTP status: 200 OK
    ...

Now, it's gone from the list:

    Dochazka(2016-02-02) root ADMIN> activity all
    ...

List all activites B<including> disabled ones:

    Dochazka(2016-02-02) root ADMIN> activity all disabled
    ...

Now, re-enable TESTACT:

    Dochazka(2016-02-02) root ADMIN> PUT activity code TESTACT { "disabled" : "f" }
    HTTP status: 200 OK
    ...

It's back:

    Dochazka(2016-02-02) root ADMIN> activity all
    ...


=head2 Modify an activity

Activities can be modified. 

    Dochazka(2016-02-02) root ADMIN> PUT activity aid 9 { "remark" : "Bike shed" }
    ...

See the effects:

    Dochazka(2016-02-02) root ADMIN> GET activity aid 9
    ...

For fun, try out various silly ideas:

    Dochazka(2016-02-02) root ADMIN> PUT activity aid 9 { "code" : "Bikeshed" }
    ...
    Dochazka(2016-02-02) root ADMIN> PUT activity aid 9 { "code" : "Bike shed" }
    ...
    Dochazka(2016-02-02) root ADMIN> PUT activity aid 9 { "aid" : 100 }
    ...
    Dochazka(2016-02-02) root ADMIN> PUT activity aid 9 { "aid" : null }
    ...
    Dochazka(2016-02-02) root ADMIN> PUT activity aid 9 { "remark" : null }
    ...


=head2 Delete an activity

OK, now we've had our fun. Delete this fiasco and get back to work!

    Dochazka(2016-02-02) root ADMIN> DELETE activity aid 9
    ... 

The activity can be deleted because no attendance intervals point to it.



=head1 SESSION 7: ATTENDANCE INTERVALS

Before you do anything, L<make sure the server is running|"Start the server">.


=head2 Verify state

If you are continuing from Session 6, you can skip this step.

If you are starting over (or from scratch), run the following script to
bring your database into the proper state:

    #!/bin/sh
    cat <<EOF | dochazka-cli -u root -p immutable
    PUT employee nick george { "fullname" : "King George III", "salt" : "a054d158a23c3a07ad0163107ad72a8649597d71", "passhash" : "5cf2c3a23de9db43d2d846172966150e9197717ecd0304bafef3f23fc159df942021dd3aec7b4dbcde87d8a44c1bd905bbba3862989065d012bb46a1e2b9ac5c" }
    emp=george active 2015-01-02
    schedule mon 8:00-12:00
    schedule tue 13:00-17:00
    schedule wed 8:00-12:00
    schedule wed 13:00-17:00
    schedule thu 7:00-10:00
    schedule scode VPP-1
    schedule new
    emp=george scode=VPP-1 2015-01-02
    EOF


=head2 Add a single attendance interval

Finally, we have completed all the administrative setup work necessary for
employees (or their private secretaries) to be able to start entering
attendance data.

Let's say that George spent the whole morning pushing pencils. This can be
entered into the database like so:

    $ dochazka-cli -u george -p george
    ...
    Dochazka(2016-02-03) george ACTIVE> interval 8:00-12:00 work Push pencils
    Interval IID 1
    ["2016-02-03 08:00:00+01","2016-02-03 12:00:00+01") WORK Push pencils

The server response includes the Interval ID (IID), the full canonical
"tsrange with time zone" (see PostgreSQL documentation for details), the
activity (WORK), and the description ("Push pencils") entered by the user.

The first interval object is now in the database. Let's examine it:

    Dochazka(2016-02-03) george ACTIVE> GET interval iid 1
    HTTP status: 200 OK
    Response:
    {  
       "level" : "OK",
       "code" : "DISPATCH_INTERVAL_FOUND",
       "payload" : {
          "long_desc" : "Push pencils",
          "partial" : null,
          "intvl" : "[\"2016-02-03 08:00:00+01\",\"2016-02-03 12:00:00+01\")",
          "iid" : 1,
          "aid" : 1,
          "remark" : null,
          "eid" : 3,
          "code" : null
       },
       "text" : "Found an interval"
    }

The attributes under the "payload" are from the interval object. The "code"
attribute is null in this case because it is not stored in the database. It is
populated on an as-needed basis.


=head2 Modify an interval

We can modify intervals in the same way that we modified the "bike shed"
activity:

    Dochazka(2016-02-03) george ACTIVE> PUT interval iid 1 { "remark" : "BIKESHED" }
    ...

We can even set the "code" attribute to a bogus value in this way:

    Dochazka(2016-02-03) george ACTIVE> PUT interval iid 1 { "code" : "BIKESHED" }
    ...

It does not get stored in the database, however:

    Dochazka(2016-02-03) george ACTIVE> GET interval iid 1 { "code" : "BIKESHED" }
    HTTP status: 200 OK
    Response:
    ...
          "code" : null,
    ...


=head2 Add another interval

Very good, and enough fiddling. In the meantime, George went to lunch, and then
spent the afternoon looking out the window:

    Dochazka(2016-02-03) george ACTIVE> interval 12:30-16:30 work Look out window
    ...
    Interval IID 2
    ["2016-02-03 12:30:00+01","2016-02-03 16:30:00+01") WORK Look out window

Now let's admire George's work. The command INTERVAL should list all
existing intervals for the prompt date:

    Dochazka(2016-02-03) george ACTIVE> interval
    Attendance intervals of george (EID 3)
    in the range [ 2016-02-03 00:00, 2016-02-03 24:00 )

    IID Begin            End              Code Description
    1   2016-02-03 08:00 2016-02-03 12:00 WORK Push pencils
    2   2016-02-03 12:30 2016-02-03 16:30 WORK Look out window


=head2 Concepts (Prompt date)

Let's review once again the information provided by the Dochazka prompt:

=over

=item Prompt date (defaults to current date)

=item Logged-in employee (george in this case)

=item Privilege level of logged-in employee (passerby)

=back

The prompt date defaults to today's date.


=head2 Set the prompt date

The prompt date can be set by the user to any valid date:

    Dochazka(2016-02-03) george ACTIVE> prompt 2016-01-18
    Prompt date changed to 2016-01-18
    Dochazka(2016-01-18) george ACTIVE> prompt 203-12-31
    *** Anomaly detected ***
    Explanation: Encountered invalid date or time ->203-12-31<- (ERR)
    Dochazka(2016-02-03) george ACTIVE> prompt 2016-01-33
    Prompt date changed to 2016-01-33

Oops! (This is a bug.)

=cut

1;
