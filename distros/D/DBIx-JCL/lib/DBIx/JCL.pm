##@@JCL.pm,dbixlib
##$$Job Control Library for Data Management Tasks
##author:Brad Adkins
##format:codehtml
##outfile:JCL.html
##title:Job Control Library
##toc:yes
##header:<h1>DBIx-JCL</h1>

=head1 NAME

DBIx::JCL - Job Control Library for database load tasks.

=head1 SYNOPSIS

    # file: test_job.pl
    use strict;
    use warnings;
    use DBIx::JCL qw( :all );

    my $jobname = 'name_of_job';
    sys_init( $jobname );

    # perform database tasks calling DBIx-JCL functions
    # ...

    sys_end();
    exit sys_get_errorlevel();

=head1 DESCRIPTION

This documentation describes the perl module DBIx-JCL.pm and the use of
standardized perl scripts which together provide a common job execution
environment to support database backend load and maintenance tasks.

=head1 RATIONALE

Provide a suite of standard functions that can be shared across all batch
job scripts used to support database back end tasks. Provide a standardized
approach for the development of all back end database job scripts.
Centralize the administration and access to configuration data. Enforce
coding standards and documentation. Abstract the sql used to support back
end processes from the task processing logic, by placing all sqlinto an sql
library. This will make maintenance of back end sql a trivial task. Provide
generalized logging, notification, and system information functions.

If you want to write a robust database extract and load job with complete
support for logging and error notification, and do it in 25 lines of code,
read on.

=head1 OPTIONS

Database maintenance and load jobs written using DBIx-JCL support the following
options out-of-the-box, with no additional work required on your part.

Job Options:

    | -r   | Run job
    | -rb  | Run job in the background
    | -rs  | Run job at requested start time
    | -rr  | Restart job after failure
    | -rde | Run using specified DE number
    | -x   | Pass extra parameters to job script
    | -c   | Specify database connections
    | -v   | Verbose
    | -vv  | Very Verbose
    | -ng  | No greeting
    | -tc  | Test database connections

Logging Options:

    | -lf  | Log filename
    | -lg  | Log generations
    | -ll  | Log log levels
    | -lp  | Log file prefix
    | -lr  | Log archive file radix
    | -cl  | Log console levels

Notificaiton Options:

    | -ne  | Notify email on completion
    | -np  | Notify pager on completion
    | -et  | Email notification to list
    | -el  | Email notification levels
    | -pt  | Pager notification to list
    | -pl  | Pager notification levels

Information Options:

    | -dp  | Display job parameters
    | -dq  | Display job querys
    | -dd  | Display job documentation
    | -dl  | Display last log file
    | -da  | Display archived log files
    | -dj  | Display a list of job scripts
    | -dja | Diaplay jobs active in the system

Utility Options:

    | -se  | Send email message
    | -sp  | Send pager message
    | -um  | Util no move files
    | -h   | Help
    | -ha  | Help on option arguments

Please see L<ADDITIONAL INFORMATION> below.

=head1 CAPABILITIES

The DBIx-JCL modules provides many capabilities commonly needed in support of
database maintenance jobs designed to run in a production environment. Below
is a summary list of features and the types of functions provided to support
those features.

=head2 Features

The following features have been designed in to the DBIx-JCL module:

=over 4

=item * Logging support with log file rotation

=item * Notification support

=item * Simplified DBI interface

=item * Configuration data stored externally

=item * High level functions not available in the DBI

=item * SQL stored in "SQL books"

=item * Job documentation enforced

=item * Job control functions

=item * Plugin support

=back

=head2 Implementation

The features listed above have been implemented by providing [many] functions
for use by your database mantenance jobs:

=over 4

=item * Functions for command line interaction

=item * Functions for initialization, monitoring, and control

=item * Functions for database interaction

=item * Functions for log file access and maintenance

=item * Functions for file manipulation

=back

Please see L<ADDITIONAL INFORMATION> below.

=head1 EXAMPLE JOB

Shown below is the standard approach to writing job scripts.

    ##@@name_of_script.pl,bin
    ##$$Description of this job

    use strict;
    use warnings;
    use DBIx::JCL qw( :all );

    # initialize
    # -------------------------------------------------------------------------

    my $jobname = 'name_of_script';
    sys_init( $jobname );

    my $dbenv1 = 'mydb1';
    my $mysql1 = sys_get_sql( 'query_number_1' );

    # main
    # -------------------------------------------------------------------------

    log_info( sys_get_dbdescr( $dbenv1 ) );
    db_connect( $dbenv1 );

    # do more db stuff here

    # end
    # -------------------------------------------------------------------------

    =begin wiki

    !1 NAME

    Name of script

    ----

    !1 DESCRIPTION

    Describe the job script here.

    ----

    !1 RECOVERY NOTES

    Document recovery notes here.

    ----

    !1 DEPENDENCIES

    Document dependencies here.

    =cut

    __END__

Please see L<ADDITIONAL INFORMATION> below.

=head1 ADDITIONAL INFORMATION

Please see the documentation embedded in this source file for [LOTS!] of
additional details on how to use JCL.pm. You can view this documentation using
WikiText.pm module to format the WikiText content in this file. Hint: download
and install WikiText.pm.

Thank you!

=head1 COPYRIGHT

Copyright 2008 Brad Adkins <dbijcl@gmail.com>.

Permission is granted to copy, distribute and/or modify this document under the
terms of the GNU Free Documentation License, published by the Free Software
Foundation; with no Invariant Sections, with no Front-Cover Texts, and with no
Back-Cover Texts.

=head1 AUTHOR

Brad Adkins, dbijcl@gmail.com

=cut

=begin wiki

!1 Name

DBIx-JCL - Job Control Library for database load tasks.

----

!1 Description

This documentation describes the perl module DBIx::JCL.pm and the use of \
standardized perl scripts which together provide a common job execution \
environment to support database backend maintenance.

----

!1 Synopsis

 % language=Perl
 % # file: test_job.pl
 % use strict;
 % use warnings;
 % use DBIx::JCL qw( :all );
 %
 % my $jobname = 'name_of_job';
 % sys_init( $jobname );
 %
 % # perform database tasks
 %
 % sys_end();
 % exit sys_get_errorlevel();
 %%

For a file named %test_job.pl% the %$jobname% would normally be simply \
%test_job%.

----

!1 Options

Job Options:

| -r   | Run job|
| -rb  | Run job in the background|
| -rs  | Run job at requested start time|
| -rr  | Restart job after failure|
| -rde | Run using specified DE number|
| -x   | Pass extra parameters to job script|
| -c   | Specify database connections|
| -v   | Verbose|
| -vv  | Very Verbose|
| -ng  | No greeting|
| -tc  | Test database connections|

Logging Options:

| -lf  | Log filename|
| -lg  | Log generations|
| -ll  | Log log levels|
| -lp  | Log file prefix|
| -lr  | Log archive file radix|
| -cl  | Log console levels|

Notificaiton Options:

| -ne  | Notify email on completion|
| -np  | Notify pager on completion|
| -et  | Email notification to list|
| -el  | Email notification levels|
| -pt  | Pager notification to list|
| -pl  | Pager notification levels|

Information Options:

| -dp  | Display job parameters|
| -dq  | Display job querys|
| -dd  | Display job documentation|
| -dl  | Display last log file|
| -da  | Display archived log files|
| -dj  | Display a list of job scripts|
| -dja | Diaplay jobs active in the system|

Utility Options:

| -se  | Send email message|
| -sp  | Send pager message|
| -um  | Util no move files|
| -h   | Help|
| -ha  | Help on option arguments|

----

!1 Arguments

Job Params:

| -r   | (on/off)|
| -rb  | (on/off)|
| -rs  | starttime    Example: 17:30|
| -rr  | jobstep      Example: 3|
| -rde | denumber     Example: 64753|
| -x   | extra params Example: -x="a=1 b=2 c=3"|
| -c   | connectdef   Example: mydb:myinst|
| -v   | (on/off)|
| -vv  | (on/off)|
| -ng  | (on/off)|
| -tc  | connectdef   Example: mydb:myinst|

Logging Params:

| -lf  | filename     Example: mylog.log|
| -lg  | numgdg       Example: 10|
| -ll  | loglevels    Example: FATAL,ERROR,WARN or WARN|
| -lp  | logprefix    Example: pre_|
| -lr  | logradix     Example: 3|
| -cl  | loglevels    Example: FATAL,ERROR,WARN,INFO,DEBUG or DEBUG|

Notificaiton Params:

| -ne  | (on/off)|
| -np  | (on/off)|
| -et  | addrlist       Example: me@myhost.com,you@myhost.com|
| -el  | levels         Example: FATAL,ERROR,WARN|
| -pt  | addrlist       Example: me@myhost.com,you@myhost.com|
| -pl  | levels         Example: FATAL,ERROR,WARN|

Information Params:

| -dp  | (on/off)|
| -dq  | (on/off)|
| -dd  | (on/off)|
| -dl  | (on/off)|
| -da  | (on/off)|
| -dj  | (on/off)|
| -dja | (on/off)|

Utility Params:

| -se  | addrlist:msg   Example: "me@myhost.com~Message text"|
| -sp  | addrlist:msg   Example: "me@myhost.com~Message text"|
| -um  | (on/off)|
| -h   | (on/off)|
| -ha  | (on/off)|

----

!1 Rationale

Provide a suite of standard functions that can be shared across all batch \
job scripts used to support database back end tasks. Provide a standardized \
approach for the development of all back end database job scripts. \
Centralize the administration and access to configuration data. Enforce \
coding standards and documentation. Abstract the sql used to support back \
end processes from the task processing logic, by placing all sqlinto an sql \
library. This will make maintenance of back end sql a trivial task. Provide \
generalized logging, notification, and system information functions.

If you want to write a robust database extract and load job with complete \
support for logging and error notification, and do it in 25 lines of code, \
read on.

----

!1 Capabilities

Some of the capabilities provided by DBIx-JCL are: System initialization, \
variables for system-wide use, configuration file interface support, \
command line processing support, command line help interface, sql library \
interface, system documentation in pod form, handy information display \
routines, source filtering for quality control, database connection and \
sql processing, log file access and managment, email and pager notification, \
general file access routines, and a generic plugin interface.

----

!1 Configuration And Environment

Configuration is provided using an enhanced version of ini style \
configuration files. The big difference between the conf files used and \
ini files is that the conf files support here document syntax. This makes \
storing sql querys a trivial task. Several configuration files are used, \
these are described individually below.

!2 Environments

DBIx-JCL can support multiple database environments over multiple file \
systems, with attachments to any number of remote databases. An environment \
is actually a combination of file system and database instance. Remote \
databases and local databases can also be specified on the command line. \
The example conf files define the database environments shown in the \
diagram below.

On each local server, the default combination of database/instance is \
identified by an environment variable (shown in square brackets). The name \
of the environment variable is stored in the C<system.conf> file.

 % language=Ini_Files
 % (-------------------------------------+------------------------------------)
 %                 LOCAL                 |               REMOTE
 % (-------------------------------------+------------------------------------)
 %                                       |
 %   .------------.     .------------.   |       .------------.
 %   | Server 1   |--.--| mydb2/dev1 |-->|   .-->| mydb1/frz  |
 %   '------------'  |  `------------'   |   |   '------------'
 %                   |     [mydev1]      |   |
 %                   |                   |   |
 %                   |  .------------.   |   |   .------------.
 %                   |--| mydb2/dev2 |-->|   +-->| mydb1/prd  |
 %                   |  '------------'   |   |   '------------'
 %                   |     [mydev2]      |   |
 %                   |                   |   |
 %                   |  .------------.   |   |   .------------.
 %                   +--| mydb2/int  |-->|   +-->| mydb3/dev  |
 %                      '------------'   |   |   '------------'
 %                         [myint]       |---+
 %                                       |   |
 %   .------------.     .------------.   |   |   .------------.
 %   | Server 2   |-----| mydb2/frz  |-->|   +-->| mydb3/int  |
 %   '------------'     '------------'   |   |   '------------'
 %                         [myfrz]       |   |
 %                                       |   |
 %   .------------.     .------------.   |   |   .------------.
 %   | Server 3   |-----| mydb2/prd  |-->|   +-->| mydb3/sys  |
 %   '------------'     '------------'   |   |   '------------'
 %                         [myprd]       |   |
 %                                       |   |
 %                                       |   |   +------------.
 %                                       |   +-->| mydb3/prd  |
 %                                       |       '------------'
 %    Key                                |
 %   (-----------------------------)     |
 %    dev  - development region          |
 %    dev1 - development region          |
 %    dev2 - development region          |
 %    int  - integration test region     |
 %    frz  - system test region          |
 %    sys  - system test region          |
 %    prd  - production region           |
 %   (-----------------------------)     |
 %                                       |
 % (-------------------------------------+------------------------------------)
 %%

!2 System Configuration

The /system.conf/ stores information about your installation environment. \
The default database environment related to this file system, a list of \
database environments, and a list of valid job acronyms:

 % language=Ini_Files
 % [system]
 %
 % envvar    = mydbenv1
 % dat_envrs = mydbenv1,mydbenv2,mydbenv3,mydbenv4
 % job_acros = load_,extr_,merg_,vend_,job_,util_,test_,temp_
 %%

Following this section are the directory sections, There is one directory \
section for each type of directory used: bin, lib, log, load, extr, and \
plugin. Each directory section is named as using the form \
%[directory <directory_type>]%. Directory specifications for the the bin \
directory are shown below. For each database environment, you would have \
a directory entry for that particular environment. So for the bin directory, \
the entry would be something like the following:

 % language=Ini_Files
 % [directory bin]
 %
 % mydbenv1 = /home/account/bin/
 % mydbenv2 = /home/account/bin/
 % mydbenv3 = /home/account/bin/
 % mydbenv4 = /home/account/bin/
 %%

The trailing slashes on the directory entries are required.

The last section in the C<system.conf> file is the restart section. This \
stores the last job step attempted. This is set immediately before a job \
is restarted. The example below shows a job restart step of 3.

 % language=Ini_Files
 % [restart]
 %
 % restart=3
 %%

!2 Job Configuration

The /job.conf/ file stores information about specific jobs. The key entry \
is the logfile entry. This entry provides a name to use for this job's log \
file. The entry is placed in a section named after the jobname used in the \
script. If your script uses:

 % language=Perl
 % my $jobname = 'job_number_1';
 % sys_init( $jobname );
 %%

Then the job section for that script would be:

 % language=Ini_Files
 %
 % [job_number_1]
 % logfile=epdw_contractor.log
 %%

There are also several optional entries that can be made for a given job. \
These will be permanent overrides for that particular job. All of these are \
also available as command line options.

 % language=Ini_Files
 % logging_levels=
 % gdg=
 % emailto=
 % pagerto=
 % email_levels=
 % pager_levels=
 %%

This gives you the ability to set up logging and notifications differently \
for every job if you want to (probably not a good idea).

!2 Data Configuration

The /data.conf/ file is possibly the most complex file. This file is used \
to map your databases and database instances, both local and remote, and \
provides a default instance for each database.

Here is a sample /data.conf/ file. In the example below, the C<[instances]> \
section maps the available database instances for each database. The default \
sections %[default ]<database+instance]% maps the primary database \
instance to connect to for each supported database, based on the current \
database environment variable. The last set of sections provide the \
connection parameters for each database/instance combination. (Only one of \
these is shown below.)

Keep in mind when trying to decipher the example below, that database mydb2 \
is in all cases the "local" database (attached to a file system where the \
DBIx-JCL are running. The databases mydb1 and mydb2 are remote databases.

 % language=Ini_Files
 % [databases]
 % databases = mydb1,mydb2,mydb3
 %
 % [names]
 % mydb1 = A Long Name for mydb1
 % mydb2 = A Long Name for mydb2
 % mydb3 = A Long Name for mydb3
 %
 % [instances]
 % mydb1 = prd,frz
 % mydb2 = prd,frz,int,dev1,dev2
 % mydb3 = prd,sys,int,dev
 %
 % [default db2dev1]
 % mydb1 = frz
 % mydb2 = dev1
 % mydb3 = dev
 %
 % [default db2dev2]
 % mydb1 = frz
 % mydb2 = dev2
 % mydb3 = dev
 %
 % default db2int]
 % mydb1 = frz
 % mydb2 = int
 % mydb3 = int
 %
 % [default db2frz]
 % mydb1 = prd
 % mydb2 = frz
 % mydb3 = sys
 %
 % [default db2prd]
 % mydb1 = prd
 % mydb2 = prd
 % mydb3 = prd
 %
 % [mydb2 int]
 % database=dbi:Oracle:db2int
 % username=myaccount
 % password=12345678
 %%

!2 Mail Configuration

The /mail.conf/ file stores settings used when sending email and pager \
notifications. The entries are placed in a section named mail.

 % language=Ini_Files
 % [mail]
 % server=mail.server.com
 % from=me@mycompany.com
 % emailto=me@mycompany.com,you@mycompany.com
 % pagerto=1234567890@somepager.com,0987654321@somepager.com
 % email_levels=FATAL,ERROR,WARN
 % pager_levels=FATAL,ERROR
 %%

!2 Log Configuration

The /log.conf/ file contains settings used by the logging functions. The \
settings are placed in a section named log. The gdg entry specifies the \
default number of log archive files that will be maintained. In case you \
are curious, gdg stands for generation data group.

 % language=Ini_Files
 % [log]
 % default_logfile=job.log
 % logging_levels=FATAL,ERROR,WARN,INFO
 % gdg=5
 %%

!2 Query Configuration

The /query.conf/ file contains all the sql used by DBIx-JCL on your \
installations. Each job has its own section in this file. Querys are \
entered using heredoc syntax, which makes it very easy to cut-and-paste \
sql from other sources into this file, and vice-versa. Abstracting your \
sql into a separate file should make your maintenance life much easier. \
It would be a good idea to put this file under configuration management \
control.

!2 Util Configuration

The /util.conf/ file is currently not used. It is anticipated that there \
will be a need for this file in the future.

----

!1 Logging

One of the real strengths of DBIx-JCL is its support for logging. The goal \
is to log all significant events, including DBI errors. You decide what types \
of events are significant by setting the logging levels prior to running your \
script, or on the command line when starting your script.

!2 Writing to the log

You use the log write functions to write data to the log. If the log \
statement is in the list of logging levels to be output for this script, \
the log statement will be written, if the log statement used is lower than \
any of the set logging levels, it will not be written to the log file. An \
example may clarify. Let's say you have set the logging levels to include \
FATAL,ERROR,WARNING. If your job script calls C<log_info()> or C<log_debug()> \
functions, they would not write to the log file becuase those log levels \
are not in the list of logging levels to be output. If you want to see you \
log messages on the console while your job is running, use the Verbose \
command line option.

The log write functions are:

|%log_fatal()% |outputs FATAL level messages|
|%log_error()% |outputs ERROR level messages|
|%log_warn()%  |outputs WARN  level messages|
|%log_info()%  |outputs INFO  level messages|
|%log_debug()% |outputs DEBUG level messages|

!2 Using Oracle's DBMS_OUTPUT Package

The functions used here to implement stored procedure calls (DBD::Oracle only) \
will gather dbms output automatically. If any is found, these are sent to \
the current log file using an appropriate logging level. To make your log \
files more readable, you should consider using a a custom package for all \
dbms output generated from stored procedures and functions. I've also found \
that if you preceed your dbms output messages with some white space, they \
will look better when viewed in your log files.

----

!1 Notifications

Another real strength of DBIx-JCL is the built-in support for notifications. \
There are two types of notifications, email notifications and pager \
notifications. One of the nice features of email notifications is that the \
log file is included in the email message following the message text. Pager \
notifications are just short versions of email notifications, pager \
notifications never have the contents of the log file appended.

The pager notifications are really just an email message. Your pager device \
must be able to support messaging via email interface to make use of this \
feature. Most cell phone devices and text pagers have this capability.

The severity of the message is included in the message subject line so you \
can immediately see if you need to respond to the message or not.

The log writing functions are hooked into the notification functions. \
Whenever a log write function is called it checks to see if a notification \
should also be sent based on the email and pager severity levels. These work
the same as described above for logging levels, in fact, the same levels are \
used. Care should be exercised when setting the notifications levels, if you \
set them too low you script could generate a lot of email/pager messages. \
Caveat emptor.

----

!1 Database Interface

This module uses the Perl DBI for all database functionality. However you do \
not have to deal with the raw DBI functions. All DBI access thru this module \
is made via a virtual name that you assign to each database connection used \
by your running job script. The virtual name is resolved using entries in a \
configuration file. Furthermore, all calls to DBI functions just require that \
virtual name. Underneath, the module functions handle storage of database \
handles and statement handles automatically for you. This has two benefits, \
it makes writing database job scripts for the novice much simpler, and it \
makes for cleaner, more readable job scripts.

You probably can't fully appreciation the latter until you are reading a \
job script at 2am, trying to figure out what went wrong with a production \
job. Of course, one of the design goals of this module is to make it so you \
never have to read a script when one of your jobs fails. All the information \
you need to diagnose and fix the problem should be in the most recent log \
file, with previous log history right at your finger tips as well.

----

!1 Script Naming Convention

Scripts which use DBIx-JCL are required to use a script naming convention, \
however, the convention chosen is up to you. All scripts using DBIx-JCL \
should be prefixed with an acronym. For example, if you had a script that \
sent a warning message on some condition, you might name it "util_warn.pl" \
where "util_" is the script prefix acronym. You decide what script prefix \
acronyms you want to use, and configure those in the system.conf file. This \
module will check that all invoking scripts adhere to your naming convention. \
DBIx-JCL will complain at runtime if a script is inappropriately named.

Some examples of script acronyms are:

|Acro  |Description|
|load_ |load data script|
|extr_ |extract data script|
|merg_ |merge/update data script|
|job_  |job which runs other scripts|
|util_ |utility script|
|test_ |test script|
|temp_ |temporary scipt|

You should examine the sampel system configuration files that some with \
DBIx-JCL.

----

!1 Installation

The DBIx-JCL module can be installed into a private directory or appended to \
your Perl installation using the normal install process. If you intall into a \
private directory, you'll need to set the environment variable PERL5LIB so \
your scripts can find the module.

/Environment Variables/

The module also uses several envirnoment variables besides PERL5LIB, sample \
export entries are shown below. The module needs to know where your home \
directory is, this should normally be set for you in most installations. The \
module will look for a configuration file named /system.conf/ to start the \
boot-strap process, this location is identified by the JCLCONF environment \
variable. A default database environment needs to be identified. You \
determine what this variable will be called, in the example below the \
variable is named MYDBENV. The name you choose is stored in the \
/system.conf/ file in section %[system]%, under the key %envvar%.

Sample export settings:

 % language=IniFiles
 % export PERL5LIB=/home/myaccount/lib
 % export HOME=/home/myaccount
 % export JCLCONF=/home/myaccount/conf
 % export MYDBENV=dbenv1
 %%

Under a Windows system you will want to set these in yous Control Panel \
under System and Advanced options.

----

!1 Example Script

Shown below is the standard approach to writing job scripts.

 % language=Perl
 % #!perl
 % ##@@name_of_script.pl,bin
 % ##$$Description of the Job
 %
 % use strict;
 % use warnings;
 % use DBIx::JCL qw( :all );
 %
 % # initialize
 % # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 %
 % my $jobname = 'name_of_script';
 % sys_init( $jobname );
 %
 % my $dbenv1 = 'mydb1';
 % my $mysql1 = sys_get_sql( 'query_number_1' );
 %
 % # main
 % # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 %
 % log_info( sys_get_dbdescr( $dbenv1 ) );
 % db_connect( $dbenv1 );
 %
 % # do more db stuff here
 %
 % # end
 % # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 %
 % =begin wiki
 %
 % !1 NAME
 %
 % Name of script
 %
 % ----
 %
 % !1 DESCRIPTION
 %
 % Describe the job script here.
 %
 % ----
 %
 % !1 RECOVERY NOTES
 %
 % Document recovery notes here.
 %
 % ----
 %
 % !1 DEPENDENCIES
 %
 % Document dependencies here.
 %
 % =cut
 %
 % __END__
 %
 %%

The second and third lines of the example are required for every job script. \
The second line identifies the script and the script installation directory. \
The third line provides a brief description of the job and is used by the \
command line option that displays all installed jobs.

----

!1 Functions

The following provides an explanation of each of the functions provided by \
DBIx-JCL.

=cut


# package
# ------------------------------------------------------------------------------

package DBIx::JCL;
use strict;
use warnings;

# package exports
# ------------------------------------------------------------------------------

require Exporter;
use base qw( Exporter );
our @EXPORT_OK = qw(
    sys_init
    sys_init_setuser
    sys_end
    sys_init_plugin
    sys_get_sql
    sys_get_item
    sys_get_hash
    sys_get_array
    sys_get_common_sql
    sys_get_run_control
    sys_get_dbdescr
    sys_get_dbinst
    sys_set_restart
    sys_load_library
    sys_set_verbose
    sys_die
    sys_warn
    sys_info
    sys_ctime2str
    sys_disp_active_jobs
    sys_run_job
    sys_run_job_background
    sys_run_job_wait
    sys_run_job_maxrc
    sys_run_job_reset
    sys_get_path_bin_dir
    sys_get_path_lib_dir
    sys_get_path_log_dir
    sys_get_path_load_dir
    sys_get_path_extr_dir
    sys_get_path_scripts_dir
    sys_get_path_plugin_dir
    sys_get_path_prev_dir
    sys_get_mail_server
    sys_get_mail_from
    sys_get_mail_emailto
    sys_get_mail_pagerto
    sys_get_mail_email_levels
    sys_get_mail_pager_levels
    sys_get_log_file
    sys_get_log_filefull
    sys_get_log_logging_levels
    sys_get_log_console_levels
    sys_get_log_gdg
    sys_get_dataenvr
    sys_get_errorlevel
    sys_get_conf_dir
    sys_get_email_levels
    sys_get_pager_levels
    sys_get_logging_levels
    sys_get_console_levels
    sys_get_commandline
    sys_get_commandline_opt
    sys_get_commandline_val
    sys_get_script_file
    sys_get_user
    sys_get_util_move
    sys_get_maxval
    sys_set_errorlevel
    sys_set_die
    sys_set_warn
    sys_set_conf_file
    sys_set_email_levels
    sys_set_pager_levels
    sys_set_mail_emailto
    sys_set_logging_levels
    sys_set_console_levels
    sys_set_script_file
    sys_set_path_log_dir
    sys_set_path_plugin_dir
    sys_set_maxval
    sys_check_dataenvr
    sys_timer
    sys_wait
    sys_disp_doc
    log_fatal
    log_error
    log_warn
    log_info
    log_debug
    log_close
    log_write_log
    log_write_screen
    db_init
    db_connect
    db_nil
    db_finish
    db_disconnect
    db_prepare
    db_execute
    db_commit
    db_get_sth
    db_get_defenvr
    db_pef
    db_pef_list
    db_fetchrow
    db_bindcols
    db_rollback
    db_insert_from_file
    db_query_to_file
    db_dump_query
    db_dump_table
    db_grant
    db_func
    db_proc
    db_proc_in
    db_proc_out
    db_proc_inout
    db_rowcount_query
    db_sanity_check
    db_rowcount_table
    db_truncate
    db_dbms_output_enable
    db_dbms_output_disable
    db_dbms_output_get
    db_drop_index
    db_drop_table
    db_drop_procedure
    db_drop_function
    db_drop_package
    db_rename_index
    db_rename_table
    db_purge_table
    db_purge_index
    db_update_statistics
    db_sqlloader
    db_sqlloaderx
    db_sqlloaderx_parse_logfile
    db_sqlloaderx_read
    db_sqlloaderx_skipped
    db_sqlloaderx_rejected
    db_sqlloaderx_discarded
    db_sqlloaderx_elapsed_time
    db_sqlloaderx_cpu_time
    db_index_rebuild
    db_exchange_partition
    util_get_filename_load
    util_get_filename_extr
    util_get_filename_log
    util_read_header
    util_read_footer
    util_read_file
    util_write_header
    util_write_footer
    util_move
    util_trim
    util_zsdf
    test_init
    test_ok
    test_results
    test_harness_init
    test_harness_run
    test_harness_results
    $VERSION
    $SQLLDR_SUCC
    $SQLLDR_WARN
    $SQLLDR_FAIL
    $SQLLDR_FTL
);

our %EXPORT_TAGS = (
    all => [
        @EXPORT_OK
    ],
    sys => [ qw(
        sys_init
        sys_init_setuser
        sys_end
        sys_init_plugin
        sys_get_sql
        sys_get_item
        sys_get_hash
        sys_get_array
        sys_get_common_sql
        sys_get_run_control
        sys_get_dbdescr
        sys_get_dbinst
        sys_set_restart
        sys_load_library
        sys_set_verbose
        sys_die
        sys_warn
        sys_info
        sys_ctime2str
        sys_disp_active_jobs
        sys_run_job
        sys_run_job_background
        sys_run_job_wait
        sys_run_job_maxrc
        sys_run_job_reset
        sys_get_path_bin_dir
        sys_get_path_lib_dir
        sys_get_path_log_dir
        sys_get_path_load_dir
        sys_get_path_extr_dir
        sys_get_path_prev_dir
        sys_get_path_scripts_dir
        sys_get_mail_server
        sys_get_mail_from
        sys_get_mail_emailto
        sys_get_mail_pagerto
        sys_get_mail_email_levels
        sys_get_mail_pager_levels
        sys_get_log_file
        sys_get_log_filefull
        sys_get_log_logging_levels
        sys_get_log_console_levels
        sys_get_log_gdg
        sys_get_dataenvr
        sys_get_errorlevel
        sys_get_conf_dir
        sys_get_email_levels
        sys_get_pager_levels
        sys_get_logging_levels
        sys_get_console_levels
        sys_get_commandline
        sys_get_commandline_opt
        sys_get_commandline_val
        sys_get_script_file
        sys_get_path_plugin_dir
        sys_get_util_move
        sys_get_user
        sys_get_maxval
        sys_set_errorlevel
        sys_set_die
        sys_set_warn
        sys_set_email_levels
        sys_set_pager_levels
        sys_set_mail_emailto
        sys_set_logging_levels
        sys_set_console_levels
        sys_set_script_file
        sys_set_conf_file
        sys_set_path_log_dir
        sys_set_path_plugin_dir
        sys_set_maxval
        sys_check_dataenvr
        sys_timer
        sys_wait
        sys_disp_doc
    ) ],
    log => [ qw(
        log_fatal
        log_error
        log_warn
        log_info
        log_debug
        log_close
        log_write_log
        log_write_screen
    ) ],
    db => [ qw(
        db_init
        db_connect
        db_nil
        db_finish
        db_disconnect
        db_prepare
        db_execute
        db_commit
        db_get_sth
        db_get_defenvr
        db_pef
        db_pef_list
        db_fetchrow
        db_bindcols
        db_rollback
        db_insert_from_file
        db_query_to_file
        db_dump_query
        db_dump_table
        db_grant
        db_func
        db_proc
        db_proc_in
        db_proc_out
        db_proc_inout
        db_rowcount_query
        db_sanity_check
        db_rowcount_table
        db_truncate
        db_dbms_output_enable
        db_dbms_output_disable
        db_dbms_output_get
        db_drop_index
        db_drop_table
        db_drop_procedure
        db_drop_function
        db_drop_package
        db_rename_index
        db_rename_table
        db_purge_table
        db_purge_index
        db_update_statistics
        db_sqlloader
        db_sqlloaderx
        db_sqlloaderx_parse_logfile
        db_sqlloaderx_read
        db_sqlloaderx_skipped
        db_sqlloaderx_rejected
        db_sqlloaderx_discarded
        db_sqlloaderx_elapsed_time
        db_sqlloaderx_cpu_time
        db_index_rebuild
        db_exchange_partition
    ) ],
    util => [ qw(
        util_get_filename_load
        util_get_filename_extr
        util_get_filename_log
        util_read_header
        util_read_footer
        util_read_file
        util_write_header
        util_write_footer
        util_move
        util_trim
        util_zsdf
    ) ],
    test => [ qw(
        test_init
        test_ok
        test_results
        test_harness_init
        test_harness_run
        test_harness_results
    ) ],
    const => [ qw(
        $SQLLDR_SUCC
        $SQLLDR_WARN
        $SQLLDR_FAIL
        $SQLLDR_FTL
    ) ],
);

# package imports
# ------------------------------------------------------------------------------

use English qw( -no_match_vars );
use Getopt::Long;
use Config::IniFiles;
use Pod::WikiText;
use IO::File;
use IO::Handle;
use IO::LockedFile;
use Fcntl qw(:flock);
use File::Copy;
use File::Bidirectional;
use File::Basename;
use MIME::Lite;
use Date::Format;
use DBI;
#|++  ## flush print buffer on write

# version
# ------------------------------------------------------------------------------

our $VERSION = "0.12";

# const exports
# ------------------------------------------------------------------------------

our $SQLLDR_SUCC = 0;
our $SQLLDR_WARN = 2;
our $SQLLDR_FAIL = 1;
our $SQLLDR_FTL  = 3;

# state variables
# ------------------------------------------------------------------------------

my $path_bin_dir       = '';
my $path_lib_dir       = '';
my $path_log_dir       = '';
my $path_load_dir      = '';
my $path_extr_dir      = '';
my $path_prev_dir      = '';
my $path_scripts_dir   = '';
my $mail_server        = '';
my $mail_from          = '';
my $mail_emailto       = '';
my $mail_pagerto       = '';
my $mail_email_levels  = '';
my $mail_pager_levels  = '';
my $log_file           = '';
my $log_filefull       = '';
my $log_logging_levels = '';
my $log_console_levels = '';
my $dataenvr           = '';
my $log_gdg            = 0;
my $log_prefix         = '';
my $log_radix          = 2;
my $errorlevel         = 0;
my $util_move          = 1;

# command line variables
# ------------------------------------------------------------------------------

my $opt_run                 = 0;
my $opt_run_background      = 0;
my $opt_run_scheduled       = '';
my $opt_run_restart         = '';
my $opt_connection          = '';
my $opt_run_de              = '';
my $opt_commandline_ext     = '';
my $opt_verbose             = 0;
my $opt_very_verbose        = 0;
my $opt_no_greeting         = 0;
my $opt_test_dbcon          = '';
my $opt_log_file            = '';
my $opt_logging_levels      = '';
my $opt_console_levels      = '';
my $opt_log_gdg             = 0;
my $opt_log_prefix          = '';
my $opt_log_radix           = 0;
my $opt_notify_email_oncomp = 0;
my $opt_notify_pager_oncomp = 0;
my $opt_notify_email_tolist = '';
my $opt_notify_pager_tolist = '';
my $opt_notify_email_levels = '';
my $opt_notify_pager_levels = '';
my $opt_disp_params         = 0;
my $opt_disp_sql            = 0;
my $opt_disp_doc            = 0;
my $opt_disp_sysdoc         = 0;
my $opt_disp_logprev        = 0;
my $opt_disp_logarch        = 0;
my $opt_disp_jobs           = 0;
my $opt_disp_active_jobs    = 0;
my $opt_disp_exec           = 0;
my $opt_send_email          = '';
my $opt_send_pager          = '';
my $opt_util_move           = 0;
my $opt_help                = 0;
my $opt_help_args           = 0;
my $opt_commandline         = join ' ', @ARGV;

# module variables
# ------------------------------------------------------------------------------

use constant QUOTE => q{"};
use constant SPACE => q{ };

my $RC_FATAL = 32;
my $RC_ERROR = 16;
my $RC_WARN  = 8;

my %MONTHS = (
    Jan => 0, Feb => 1, Mar => 2, Apr => 3, May => 4, Jun => 5,
    Jul => 6, Aug => 7, Sep => 8, Oct => 9, Nov => 10, Dec=> 11,
);

my $jobname               = '';   # name used to identify job script
my $pid                   = 0;    # os process id number
my %pidlib                = ();   # hash of info about background jobs
my $pidcnt                = 0;    # count of child pids
my $maxrc                 = 0;    # max return code for foreground jobs
my $osuser                = '';   # os username
my $commandline_ext       = '';   # extended command line
my @plugins               = ();   # loaded plugin information
my %timers                = ();   # hash of timers
my %function_params       = ();   # hash of stored function params
my $wt_seconds            = 0;    # wait seconds
my $wt_start              = time; # init wait start time
my %maxval                = ();   # hash of max values
my $t_num                 = 0;    # test script
my $t_ok                  = 0;    # test script
my $t_notok               = 0;    # test script
my $th_num                = 0;    # test harness
my $th_error              = 0;    # test harness
my $sys_dbms_output       = 0;    # has dbms_output been enabled
my $sys_log_open          = 0;    # is log file open
my $sys_stderr_redirected = 0;    # STDERR has been redirected to /dev/null
my $sys_jobconf_override  = 0;    # using override job conf file
my $sys_jobconf_file      = '';   # override jobconf filename
my $path_plugin_dir       = '';   # path to plugin directory
my $path_conf_dir         = '';   # path to conf file directory
my %sqlloader_results     = ();   # hash of SQL*Loader results
my %log_level_opts        = ();   # hash of logging options

my (%conf_data, %conf_log, %conf_mail, %conf_query, %conf_job, %conf_util);
my (%conf_system, %conf_de, %conf_rcontrols);
my (@databases, @dat_envrs, @job_acros);
my (%dbname, %dbdefenvr, %dbinst, %dbconn, %dbhandles);

my $script_file           = $PROGRAM_NAME;
my $script_filefull       = $script_file;
my $log_ext               = '.log';
my $dbitrace_base         = 'dbitrace';
my $dbitrace_file         = $dbitrace_base . $log_ext;
my $dbitrace_filefull     = '';

$script_file =~ s{^/.*/}{};

$path_conf_dir = $ENV{JCLCONF} || '';
if ( ! defined $path_conf_dir ) {
    sys_die( 'Environment variable JCLCONF not set', 0 );
}

if ( $path_conf_dir =~ m/(.*)\/$/ ) { $path_conf_dir = $1; }

my %db_func_params = (
    db_insert_from_file => {
        TrimLead       => 'no',
        TrimFieldLead  => 'no',
        TrimFieldTrail => 'no',
        CommentChar    => '#',
        SkipComments   => 'no',
        SkipLastField  => 'no',
        UseRegex       => 'no',
    },
    db_insert_from_conf => {
        TrimLead       => 'no',
        TrimFieldLead  => 'no',
        TrimFieldTrail => 'no',
        CommentChar    => '#',
        SkipComments   => 'no',
        SkipLastField  => 'no',
        UseRegex       => 'no',
    },
    db_sqlloader => {
        DatFilePath => '',
        DbEnvr      => '',
        NetService  => '',
    },
);

# public methods
# ------------------------------------------------------------------------------

=begin wiki

!2 System Functions

These functions provide general job information and job managment \
capabilities.

=cut

sub sys_init {
=begin wiki

!3 sys_init

( jobname )

This is the job script initialization function. All job scripts should call \
this function first before any other JCL functions. This will validate a job \
name and does all the other setup work necessary to run a job script. This \
function also provides a standard command line interface and supporting \
functions for the supplied command line options.

=cut
    my ($jn, @cl) = @_;
    $jobname = $jn;
    foreach my $opt ( @cl ) {
        push @ARGV, $opt;   # add additional command line option
    }

    unless ( $jobname ) {
        sys_die( 'Please specify jobname when initializing', 0 );
    }

    _sys_init_vars();

    $log_file = $jobname . $log_ext;
    $log_filefull = $path_log_dir.$log_file;

    push @ARGV, '-r' if $jobname eq "JCL";  # for convenience

    $sys_jobconf_file = _sys_check_de_override( $jobname );

    $sys_jobconf_file .= ".conf";
    _sys_read_conf( $sys_jobconf_file );   # tie %conf_job to job's conf file
    _sys_read_job();   # read job specific settings from %conf_job

    GetOptions( "r"     => \$opt_run,
                "rb"    => \$opt_run_background,
                "rs=s"  => \$opt_run_scheduled,
                "rr=s"  => \$opt_run_restart,
                "rde=s" => \$opt_run_de,
                "x=s"   => \$opt_commandline_ext,
                "c=s"   => \$opt_connection,
                "v"     => \$opt_verbose,
                "vv"    => \$opt_very_verbose,
                "ng"    => \$opt_no_greeting,
                "tc=s"  => \$opt_test_dbcon,
                "lf=s"  => \$opt_log_file,
                "lg=i"  => \$opt_log_gdg,
                "lp=s"  => \$opt_log_prefix,
                "lr=i"  => \$opt_log_radix,
                "ll=s"  => \$opt_logging_levels,
                "cl=s"  => \$opt_console_levels,
                "ne"    => \$opt_notify_email_oncomp,
                "np"    => \$opt_notify_pager_oncomp,
                "et=s"  => \$opt_notify_email_tolist,
                "el=s"  => \$opt_notify_email_levels,
                "pt=s"  => \$opt_notify_pager_tolist,
                "pl=s"  => \$opt_notify_pager_levels,
                "dp"    => \$opt_disp_params,
                "dq"    => \$opt_disp_sql,
                "dd"    => \$opt_disp_doc,
                "dl"    => \$opt_disp_logprev,
                "da"    => \$opt_disp_logarch,
                "dj"    => \$opt_disp_jobs,
                "dja"   => \$opt_disp_active_jobs,
                "se=s"  => \$opt_send_email,
                "sp=s"  => \$opt_send_pager,
                "um"    => \$opt_util_move,
                "h"     => \$opt_help,
                "ha"    => \$opt_help_args,
    ) || _sys_help(0);

    if ( $opt_connection ) {
        foreach my $connectdef ( split m/,/, $opt_connection ) {
            my ($db, $inst) = split m/:/, $connectdef;
            _check_array_val( $db, \@databases )
                || sys_die( "Invalid database: [$db]", 0 );
            _check_array_val( $inst, [split m/,/, $dbinst{$db}] )
                || sys_die( "Invalid database instance: [$db.$inst]", 0 );
            ## update default connection data
            $dbdefenvr{$db} = $inst;
        }
    }

    # create dbitrace file if not found
    if ( ! -e $dbitrace_filefull ) {
        open my $fh, ">", $dbitrace_filefull
            || sys_die( 'Unable to open dbitrace file', 0 );
        close $fh;
    }

    if ( $opt_help                ) {
        _sys_help( 1 ); }
    if ( $opt_help_args           ) {
        _sys_help( 2 ); }
    if ( $opt_run_background      ) {
        _sys_run_background(); }
    if ( $opt_run_scheduled       ) {
        _sys_run_scheduled(); }
    if ( $opt_run_de              ) {
        _sys_run_de( $opt_run_de ); }
    if ( $opt_run_restart         ) {
        _sys_run_restart(); }
    if ( $opt_test_dbcon          ) {
        _sys_test_dbcon( $opt_test_dbcon); }
    if ( $opt_commandline_ext     ) {
        $commandline_ext = $opt_commandline_ext; }
    if ( $opt_logging_levels      ) {
        $log_logging_levels = _sys_check_severity_levels( $opt_logging_levels ); }
    if ( $opt_console_levels      ) {
        $log_console_levels = _sys_check_severity_levels( $opt_console_levels ); }
    if ( $opt_log_gdg             ) {
        $log_gdg = _sys_check_log_gdg( $opt_log_gdg ); }
    if ( $opt_log_prefix          ) {
        $log_prefix = $opt_log_prefix; }
    if ( $opt_log_radix           ) {
        $log_radix = _sys_check_log_radix( $opt_log_radix ); }
    if ( $opt_notify_email_tolist ) {
        $mail_emailto = $opt_notify_email_tolist; }
    if ( $opt_notify_pager_tolist ) {
        $mail_pagerto = $opt_notify_pager_tolist; }
    if ( $opt_notify_email_levels ) {
        $mail_email_levels = _sys_check_severity_levels( $opt_notify_email_levels ); }
    if ( $opt_notify_pager_levels ) {
        $mail_pager_levels = _sys_check_severity_levels( $opt_notify_pager_levels ); }
    if ( $opt_disp_logprev        ) {
        _sys_disp_logprev(); }
    if ( $opt_disp_logarch        ) {
        _sys_disp_logarch(); }
    if ( $opt_disp_exec           ) {
        _sys_disp_exec(); }
    if ( $opt_disp_sql            ) {
        _sys_disp_sql(); }
    if ( $opt_disp_params         ) {
        _sys_disp_params(); }
    if ( $opt_disp_doc            ) {
        _sys_disp_doc(); }
    if ( $opt_disp_jobs           ) {
        _sys_disp_jobs(); }
    if ( $opt_disp_active_jobs    ) {
        _sys_disp_active_jobs( 0 ); }
    if ( $opt_send_email          ) {
        _sys_send_email_message($opt_send_email); }
    if ( $opt_send_pager          ) {
        _sys_send_pager_message($opt_send_pager); }
    if ( $opt_util_move           ) {
        $util_move = 0; }

    # must have a Run option to continue
    if ( ! $opt_run ) {
        _sys_help(1);
    }

    $log_file = $log_prefix . $jobname . $log_ext;  # default

    if ( $osuser ) {  # custom
        $log_file = $log_prefix . $jobname . '_' . $osuser . $log_ext;
    }
    $log_filefull = $path_log_dir . $log_file;

    if ( $opt_log_file ) {  # override
        $log_file = $opt_log_file;
        $log_filefull = $path_log_dir . $log_file;
    }

    _log_init_log_file();  # log rotation handler

    # validate script name using configured acros
    my ($base, $path, $type) = fileparse( $script_file );
    if ( $base =~ m/^([a-z]+_)/x ) {  ## acro + underscore
        $base = $1;
    }
    _check_array_val($base, \@job_acros) || sys_die( "Not a valid job acro", 0 );

    _sys_init_source_validation();

    sys_timer( 'start', '__default_timer' );

    log_info( "Start: $jobname" ) unless $opt_no_greeting;

    if ( $opt_very_verbose ) { $opt_verbose = 1; }
    if ( $opt_verbose ) {
        log_info( 'Running in verbose mode' );
        log_info( "Process: $pid" );
        log_info( "Options: $opt_commandline" );
    }

    if ( $sys_jobconf_override ) {
        log_info( "Jobconf override: $sys_jobconf_file" );
    }

    _sys_job_init();

    return 0;
}

sub sys_init_setuser {
=begin wiki

!3 sys_init_setuser

( jn, cl )

Please write this documentation.

=cut
    my ($jn, @cl) = @_;
    $osuser = getlogin || 'unknown';
    sys_init( $jn, @cl );
    return 0;
}

sub sys_end {
=begin wiki

!3 sys_end

No Parameters

Please write this documentation.

=cut
    _sys_job_end();

    if ( $opt_no_greeting ) { return 0; }

    sys_timer( 'stop', '__default_timer' );

    log_info( "Errorlevel: $errorlevel" );
    log_info( "Elapsed time: " . sys_timer( 'elapsed', '__default_timer' ) );
    log_info( "End: $jobname" ) unless $opt_no_greeting;

    return 0;
}

sub sys_load_library {
=begin wiki

!3 sys_load_library

( conf_filename )

Give the user an opportunity to load a different conf file replacing the \
contents of sys_common.conf with the requested conf file contents.

=cut
    my $conf_filename = shift;

    ## load a conf file replacing the contents of sys_common.conf
    tie %conf_query, 'Config::IniFiles', ( -file => $path_conf_dir.'/'.$conf_filename )
        or sys_die( "Unable to load conf file $conf_filename", 0 );
    return 0;
}

sub sys_init_plugin {
=begin wiki

!3 sys_init_plugin

( plugin_file, package_name )

Provide plugin support. This function accepts a plugin filename and attempts \
to load a plugin file by that name from the plugin directory. Plugins are \
standard Perl modules with nothing exported. The package name used by the \
module is also passed in to this function and is used to call an \
initialization function named start.

Plugins should always implement a start and an end function, these take no \
parameters. All plugins should also implement a main plugin function named \
odly enough, plugin_main. The start and end functions should not take any \
parameters. The main plugin function can be written to accept whatever \
parameters are needed.

This little bit of deep magic by merlyn gleened from the Perl Monastery was \
very educational (I almost had it before finding this):

 % language=Perl
 %    my %codeRefs = map {
 %       "Package"->can($_) || sub { die "can't find $_" }
 %   } qw(subroutine1 subroutine2 subroutine3);
 %%

Merlyn, aka, Tom Christensen???

=cut
    my ($plugin_file, $package_name) = @_;

    my $plugin_filefull = $path_plugin_dir.$plugin_file.'.pm';
    unless ( -f $plugin_filefull ) { sys_die( "Plugin not found: $plugin_file", 0 ); }

    require $plugin_filefull;

    push @plugins, join '~', ($package_name, $plugin_file, $plugin_filefull);
    $package_name->start($path_conf_dir, $path_plugin_dir, $dataenvr);
    return $package_name->can('plugin_main');   ## deep magic
}

sub sys_ctime2str {
=begin wiki

!3 sys_time2str

( format )

This is an interface to the Data::Format::time2str function. This simply \
provides an easier way for the job script to make use of the time2str \
function for acquiring a formatted current date/time. You can pass as a \
format string any of the following meta characters.

|%% |PERCENT|
|%a |day of the week abbr|
|%A |day of the week|
|%b |month abbr|
|%B |month|
|%c |MM/DD/YY HH:MM:SS|
|%C |ctime format: Sat Nov 19 21:05:57 1994|
|%d |numeric day of the month, with leading zeros (eg 01..31)|
|%e |numeric day of the month, without leading zeros (eg 1..31)|
|%D |MM/DD/YY|
|%G |GPS week number (weeks since January 6, 1980)|
|%h |month abbr|
|%H |hour, 24 hour clock, leading 0's)|
|%I |hour, 12 hour clock, leading 0's)|
|%j |day of the year|
|%k |hour|
|%l |hour, 12 hour clock|
|%L |month number, starting with 1|
|%m |month number, starting with 01|
|%M |minute, leading 0's|
|%n |NEWLINE|
|%o |ornate day of month -- "1st", "2nd", "25th", etc.|
|%p |AM or PM|
|%P |am or pm (Yes %p and %P are backwards :)|
|%q |Quarter number, starting with 1|
|%r |time format: 09:05:57 PM|
|%R |time format: 21:05|
|%s |seconds since the Epoch, UCT|
|%S |seconds, leading 0's|
|%t |TAB|
|%T |time format: 21:05:57|
|%U |week number, Sunday as first day of week|
|%w |day of the week, numerically, Sunday == 0|
|%W |week number, Monday as first day of week|
|%x |date format: 11/19/94|
|%X |time format: 21:05:57|
|%y |year (2 digits)|
|%Y |year (4 digits)|
|%Z |timezone in ascii. eg: PST|
|%z |timezone in format -/+0000|

/end of table/

=cut
    my $format = shift;
    return time2str($format, time);
}

sub sys_die {
=begin wiki

!3 sys_die

Parameters: ( message, notify )

Print a message to STDOUT and then exit returning $errorlevel $RC_FATAL. The \
message is printed to STDOUT because STDERR is redirected while running.

=cut
    my ($message, $notify) = @_;
    $notify = 0 unless defined $notify;
    $errorlevel = $RC_FATAL;

    _log_write_to_screen( 'FATAL', $notify, $message );

    if ( $sys_log_open ) {
        _log_write_to_log( 'FATAL', $notify, $message );
    }

    ## save a call if possible
    if ( $notify ) { _log_send_notifications( 'FATAL', $notify, $message ); }

    _sys_job_end();

    exit $errorlevel;
}

sub sys_warn {
=begin wiki

!3 sys_warn

Parameters: ( message, notify )

Print a message to STDOUT and then return to caller setting $errorlevel \
$RC_WARN. The message is printed to STDOUT because STDERR is redirected \
while running.

=cut
    my ($message, $notify) = @_;
    $notify = 1 unless defined $notify;
    $errorlevel = $RC_WARN;

    ## force write to screen
    _log_write_to_screen( 'WARN', 1, $message );

    ## force write to log if log is open
    if ( $sys_log_open ) {
        _log_write_to_log( 'WARN', 1, $message );
    }

    ## force notifications if notification requested
    if ( $notify ) { _log_send_notifications( 'WARN', 1, $message ); }

    return $errorlevel;
}

sub sys_info {
=begin wiki

!3 sys_info

Parameters: ( message, notify )

=cut
    my ($message, $extmsg, $notify, $nolog) = @_;
    $notify = 1 unless defined $notify;
    $nolog = 0 unless defined $nolog;

    ## get destination email address from job conf
    my $emailto = sys_get_item( 'sys_info_emailto' );
    my $mail_emailto_save = $mail_emailto;
    $mail_emailto = $emailto;

    log_info( $message, $extmsg, $nolog );
    _log_send_notifications( 'INFO', 1, $message ) if $notify;

    $mail_emailto = $mail_emailto_save;
    return 0;
}

sub sys_disp_active_jobs {
=begin wiki

!3 sys_disp_active_jobs

No Parameters

Please write this documentation.

=cut
    _sys_disp_active_jobs( 1 );
    return 0;
}

sub sys_run_job {
=begin wiki

!3 sys_run_job

Parameters: (jobname, job_maxrc, params )

|$job    |name of script or application to execute|
|@params |list of parameters to pass to the executed process|

This function usese the built-in Perl system function to invoke a JCL script \
(or other application). As such, this function will wait until the child \
completes before returning to the caller.

A reasonable attempt is made to insure that the process execute is invoked \
via a shell. This is accomplished by passing the system function the \
paramaters as a quoted string, rather than as a list.

Returns: Process return code from the script/application executed.

=cut
    my ($jobname, $job_maxrc, @params) = @_;

    my @args = ($jobname, @params);
    system(@args);
    my $childrc = $CHILD_ERROR >> 8;

    if ( $childrc > $job_maxrc ) {
        sys_die( "Process failed with return code $childrc" );
    }

    if ( $job_maxrc > $maxrc ) { $maxrc = $job_maxrc; }

    return $childrc;
}

sub sys_run_job_background {
=begin wiki

!3 sys_run_job_background

Parameters: ( jobname, maxrc, params )

Please write this documentation.

Returns:

=cut
    my ($jobname, $maxrc, @params) = @_;
    $maxrc = 0 unless $maxrc;

    my $pid = _sys_forkexec( $jobname, @params );
    $pidlib{$pid} = { jobname => $jobname,
                      maxrc   => $maxrc,
                      retcd   => 0
                    };
    $pidcnt++;
    return $pid;
}

sub sys_run_job_wait {
=begin wiki

!3 sys_run_job_wait

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    return 0 if $pidcnt < 1;
    while (1) {
        my $pid = _sys_reap_child();
        $pidcnt--;
        my $childrc = $pidlib{$pid}{retcd};
        my $msg = "Complete $pidlib{$pid}{jobname}. Return code: $childrc.";
        if ( $childrc > $pidlib{$pid}{maxrc} ) {
            ## log_warn sets errorlevel
            log_warn( "$msg Max allowed: $pidlib{$pid}{maxrc}." );
        } else {
            log_info( $msg );
        }
        last if $pidcnt < 1;
    }
    return $pidcnt;
}

sub sys_run_job_maxrc {
=begin wiki

!3 sys_run_job_maxrc

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    ## return the max of either the current background max return code or the
    ## current foreground max return code
    my $tmprc = 0;
    foreach my $pid ( keys %pidlib ) {
        if ( $pidlib{$pid}{retcd} > $tmprc ) { $tmprc = $pidlib{$pid}{retcd}; }
    }

    ( $tmprc >= $maxrc ) ? return $tmprc : return $maxrc;
}

sub sys_run_job_reset {
=begin wiki

!3 sys_run_job_reset

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    $pidcnt = 0;   ## reset background jobs count
    %pidlib = ();  ## reset background jobs info hash
    $maxrc = 0;    ## reset foreground jobs max return code
    return 0;
}

sub sys_get_path_bin_dir {
=begin wiki

!3 sys_get_path_bin_dir

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    return $path_bin_dir;
}

sub sys_get_path_lib_dir {
=begin wiki

!3 sys_get_path_lib_dir

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    return $path_lib_dir;
}

sub sys_get_path_log_dir {
=begin wiki

!3 sys_get_path_log_dir

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    return $path_log_dir;
}

sub sys_get_path_load_dir {
=begin wiki

!3 sys_get_path_load_dir

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    return $path_load_dir;
}

sub sys_get_path_extr_dir {
=begin wiki

!3 sys_get_path_extr_dir

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    return $path_extr_dir;
}

sub sys_get_path_prev_dir {
=begin wiki

!3 sys_get_path_prev_dir

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    return $path_prev_dir;
}

sub sys_get_path_scripts_dir {
=begin wiki

!3 sys_get_path_scripts_dir

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    return $path_scripts_dir;
}

sub sys_get_path_plugin_dir {
=begin wiki

!3 sys_get_path_plugin_dir

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    return $path_plugin_dir;
}

sub sys_get_mail_server {
=begin wiki

!3 sys_get_mail_server

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    return $mail_server;
}

sub sys_get_mail_from {
=begin wiki

!3 sys_get_mail_from

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    return $mail_from;
}

sub sys_get_mail_emailto {
=begin wiki

!3 sys_get_mail_emailto

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    return $mail_emailto;
}

sub sys_get_mail_pagerto {
=begin wiki

!3 sys_get_mail_pagerto

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    return $mail_pagerto;
}

sub sys_get_mail_email_levels {
=begin wiki

!3 sys_get_mail_email_levels

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    return $mail_email_levels;
}

sub sys_get_mail_pager_levels {
=begin wiki

!3 sys_get_mail_pager_levels

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    return $mail_pager_levels;
}

sub sys_get_log_file {
=begin wiki

!3 sys_get_log_file

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    return $log_file;
}

sub sys_get_log_filefull {
=begin wiki

!3 sys_get_log_filefull

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    return $log_filefull;
}

sub sys_get_log_logging_levels {
=begin wiki

!3 sys_get_log_logging_levels

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    return $log_logging_levels;
}

sub sys_get_log_console_levels {
=begin wiki

!3 sys_get_log_console_levels

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    return $log_console_levels;
}

sub sys_get_log_gdg {
=begin wiki

!3 sys_get_log_gdg

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    return $log_gdg;
}

sub sys_get_dataenvr {
=begin wiki

!3 sys_get_dataenvr

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    return $dataenvr;
}

sub sys_get_errorlevel {
=begin wiki

!3 sys_get_errorlevel

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    return $errorlevel;
}

sub sys_get_dbdescr {
=begin wiki

!3 sys_get_dbdescr

Parameters: ( dbacro )

Accept a database acro and return a database description string which \
consists of database name, acro, and current instance.

Returns:

=cut
    my $dbacro = shift;

    my $dbdescr = 'Database: acronym not found';
    foreach my $acro ( @databases ) {
        if ( $acro eq $dbacro ) {
            $dbdescr = 'Database Connection: ' . $dbname{$dbacro} . ' (' .
            $dbacro . '/' . $dbdefenvr{$dbacro} . ')';
        }
    }
    return $dbdescr;
}
sub sys_get_dbinst {
=begin wiki

!3 sys_get_dbinst

Parameters: ( dbacro )

Please write this documentation.

Returns:

=cut
    my $dbacro = shift;

    my $dbdescr = 'Database: instance not found';
    foreach my $acro ( @databases ) {
        if ( $acro eq $dbacro ) {
            $dbdescr = $dbacro . '/' . $dbdefenvr{$dbacro};
        }
    }
    return uc($dbdescr);
}

sub sys_get_conf_dir {
=begin wiki

!3 sys_get_conf_dir

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    return $path_conf_dir . '/';
}

sub sys_get_sql {
=begin wiki

!3 sys_get_sql

Parameters: ( sqlname, alternate_job_name )

Return the sql query from the query.conf file using the sqlname provided. \
If the requested sql name is not found, the name gets 'sql:' prepended and \
then another attempt is made. This allows entries of the form 'name' or \
alternately 'sql:name' to be used in the query.conf file.

The user may also pass in an optionl section name which will override the \
default section name. (Default section name is the current $jobname.)

Returns:

=cut
    my ($sqlname, $altsection) = @_;
    my $section = $altsection || 'sql';

    if ( ! $conf_job{$section}{$sqlname} ) {
        $sqlname = 'sql:'.$sqlname;
        if ( ! $conf_job{$section}{$sqlname} ) {
            sys_die( "The job conf file does not contain a query named [$sqlname]", 0 );
        }
    }
    return $conf_job{$section}{$sqlname};
}

sub sys_get_item {
=begin wiki

!3 sys_get_item

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my ($item, $altsection) = @_;
    my $section = $altsection || 'job';

    my $value = $conf_job{$section}{$item};

    if ( ! defined $value ) {
        sys_die( "Job conf missing entry [$item] in section [$section]", 0 );
    }

    if ( $value eq '0' ) {
        return $conf_job{$section}{$item};
    }

    return $value;
}

sub sys_get_hash {
=begin wiki

!3 sys_get_hash

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my ($section, $entry, $delim) = @_;
    $delim = ':' unless $delim;

    my ($pseudo, %hash);

    if ( $conf_job{$section}{$entry} ) {
        $pseudo = $conf_job{$section}{$entry};
    } else {
        sys_die( "No job conf entry found for $entry in section $section" );
    }

    ## construct a real hash from the pseudo hash
    foreach my $item ( split "\n", $pseudo ) {
        my ($key, $value) = split m/$delim/, $item;
        $hash{$key} = $value;
    }

    return \%hash;  ## ref to hash
}

sub sys_get_array {
=begin wiki

!3 sys_get_array

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my ($section, $entry, $delim) = @_;
    $delim = ':' unless $delim;

    my ($pseudo, @array);

    if ( $conf_job{$section}{$entry} ) {
        $pseudo = $conf_job{$section}{$entry};
    } else {
        sys_die( "No job conf entry found for $entry in section $section" );
    }

    ## construct a real array from the pseudo array
    foreach my $item ( split "\n", $pseudo ) {
        push @array, $item;
    }

    return \@array;  ## ref to an array
}

sub sys_get_common_sql {
=begin wiki

!3 sys_get_common_sql

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my ($sqlname, $altsection) = @_;
    my $section = $altsection || 'sql';

    if ( ! $conf_query{$section}{$sqlname} ) {
        $sqlname = 'sql:'.$sqlname;
        if ( ! $conf_query{$section}{$sqlname} ) {
            sys_die( 'Common sql conf missing query by that name', 0 );
        }
    }
    return $conf_query{$section}{$sqlname};
}

sub sys_get_run_control {
=begin wiki

!3 sys_get_run_control

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my ($jobname, $section, $default) = @_;

    my $rcontrol = $default || 0;
    if ( ! $conf_rcontrols{$section}{$jobname} ) {
        return $rcontrol;
    }

    return $conf_rcontrols{$section}{$jobname};
}

sub sys_get_email_levels {
=begin wiki

!3 sys_get_email_levels

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    return $mail_email_levels;
}

sub sys_get_pager_levels {
=begin wiki

!3 sys_get_pager_levels

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    return $mail_pager_levels;
}

sub sys_get_logging_levels {
=begin wiki

!3 sys_get_logging_levels

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    return $log_logging_levels;
}

sub sys_get_console_levels {
=begin wiki

!3 sys_get_console_levels

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    return $log_console_levels;
}

sub sys_get_commandline {
=begin wiki

!3 sys_get_commandline

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    return join ' ', @ARGV;
}

sub sys_get_commandline_opt {
=begin wiki

!3 sys_get_commandline_opt

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $target_opt = shift;
    foreach my $option ( @ARGV ) {
        my ($opt,$val) = split m/=/, $option;
        $opt =~ s/^-\s*//x;
        $opt =~ s/\s+$//x;
        if ( $opt =~ m/^$target_opt$/ix ) {
            return 1;
        }
    }
    return 0;
}

sub sys_get_commandline_val {
=begin wiki

!3 sys_get_commandline_val

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my ($target_opt,$default_value) = @_;
    ## handle:
    ##   >script.pl -r -- -batchsize=10
    foreach my $option ( @ARGV ) {
        $option =~ s/\s+=/=/x;
        $option =~ s/=\s+/=/x;
        my ($opt,$val) = split m/=/, $option;
        $opt =~ s/^-\s*//x;
        $opt =~ s/\s+$//x;
        if ( $opt =~ m/^$target_opt$/ix ) {
            #$val =~ s/^\s*//;
            #$val =~ s/\s*$//;
            return $val;
        }
    }
    return $default_value;
}

sub sys_get_script_file {
=begin wiki

!3 sys_get_script_file

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    return $script_file;
}

sub sys_get_util_move {
=begin wiki

!3 sys_get_util_move

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    return $util_move;
}

sub sys_get_user {
=begin wiki

!3 sys_get_user

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    return getlogin || 'unknown';
}

sub sys_get_maxval {
=begin wiki

!3 sys_get_maxval

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $key = shift;
    return $maxval{$key} || 0;
}

sub sys_set_restart {
=begin wiki

!3 sys_set_restart

Parameters: ( restart_option )

Write the requested restart_option to the the system.conf file. This value \
is the last step attempted by the calling script.

Returns:

=cut
    my $restart_option = shift;

    if ( $restart_option !~ m/^\d+/x ) {
        sys_die( 'Restart option is not numeric', 0 );
        return 1;
    }

    my $rtconf = $path_conf_dir.'/'.$jobname.'.running';
    my $conf = new Config::IniFiles( -file => $rtconf );
    unless ( defined $conf ) { sys_die( "Error opening runtime jobconf file", 0 ); }
    $conf->setval( 'restart', 'restart', $restart_option );
    $conf->RewriteConfig;

    return 0;
}

sub sys_set_verbose {
=begin wiki

!3 sys_set_verbose

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    $opt_verbose = 1;
    return 0;
}

sub sys_set_errorlevel {
=begin wiki

!3 sys_set_errorlevel

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $errlvl = shift;

    if ( $errlvl !~ /^\d+$/ ) {
        sys_die( "Invalid value passed to sys_set_errorlevel()" );
    }

    my $save_errlvl = $errorlevel;
    $errorlevel = $errlvl;
    return $save_errlvl;
}

sub sys_set_warn {
=begin wiki

!3 sys_set_warn

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    $errorlevel = $RC_WARN;
    return $RC_WARN;
}

sub sys_set_die {
=begin wiki

!3 sys_set_die

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    $errorlevel = $RC_FATAL;
    return $RC_FATAL;
}

sub sys_set_email_levels {
=begin wiki

!3 sys_set_email_levels

Parameters: ( email_levels )

Accept a comma delimited list of message levels to use as the source for \
determing which message levels will generate a notification, and which \
message levels will be ignored when email notification is invoked.

Valid values for the list are: FATAL,ERROR,WARN,INFO,DEBUG,NONE

Returns:

=cut
    my $email_levels = shift || "FATAL";
    $mail_email_levels = _sys_check_severity_levels( $email_levels );
    return $mail_email_levels;
}

sub sys_set_pager_levels {
=begin wiki

!3 sys_set_pager_levels

Parameters: ( pager_levels )

Accept a comma delimited list of message levels to use as the source for \
determing which message levels will generate a notification, and which \
message levels will be ignored when pager notification is invoked.

Valid values for the list are: FATAL,ERROR,WARN,INFO,DEBUG,NONE

Returns:

=cut
    my $pager_levels = shift || "FATAL";
    $mail_pager_levels = _sys_check_severity_levels( $pager_levels );
    return $mail_pager_levels;
}

sub sys_set_mail_emailto {
=begin wiki

!3 sys_set_mail_emailto

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $new_emailto = shift;
    my $old_emailto = $mail_emailto;
    $mail_emailto = $new_emailto;
    return $old_emailto;
}

sub sys_set_logging_levels {
=begin wiki

!3 sys_set_logging_levels

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $logging_levels = shift || "FATAL,ERROR,WARN,INFO";
    $log_logging_levels = _sys_check_severity_levels( $logging_levels );
    return $log_logging_levels;
}

sub sys_set_console_levels {
=begin wiki

!3 sys_set_console_levels

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $console_levels = shift || "FATAL,ERROR,WARN,INFO";
    $log_console_levels = _sys_check_severity_levels( $console_levels );
    return $log_console_levels;
}

sub sys_set_script_file {
=begin wiki

!3 sys_set_script_file

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $file = shift || $script_file;
    $script_file = $file;
    return $script_file;

}

sub sys_set_conf_file {
=begin wiki

Parameters: ( jobconf )

Manage the job conf file.

Set the value of the job conf filename and read the corresponding file. If \
no job conf filename is given, set the job conf filename back to the default \
value and reread the default job conf file (perform a reset).

Returns:

=cut
    my $jobconf = shift || '';

    if ( $jobconf ) {
        ## change jobconf file and read
        $sys_jobconf_file = $jobconf . '.conf';
        _sys_read_conf( $sys_jobconf_file );  ## tie %conf_job to job conf file
        _sys_read_job();  ## read job specific settings from %conf_job
    } else {
        ## reset jobconf file to default and reread
        $sys_jobconf_file = _sys_check_de_override( $jobname . '.conf' );
        _sys_read_conf( $sys_jobconf_file );  ## tie %conf_job to job conf file
        _sys_read_job();  ## read job specific settings from %conf_job
    }
    return 0;
}

sub sys_set_path_log_dir {
=begin wiki

!3 sys_set_path_log_dir

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $path = shift || $path_log_dir;
    $path_log_dir = $path;
    return $path_log_dir;
}

sub sys_set_path_plugin_dir {
=begin wiki

!3 sys_set_path_plugin_dir

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $path = shift || $path_plugin_dir;
    $path_plugin_dir = $path;
    return $path_plugin_dir;
}

sub sys_set_maxval {
=begin wiki

!3 sys_set_maxval

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my ($key, $val) = @_;
    if ( $maxval{$key} ) {
        if ( $val > $maxval{$key} ) {
            $maxval{$key} = $val;
        }
        return $val;
    }
    $maxval{$key} = $val;
    return $val;
}

sub sys_check_dataenvr {
=begin wiki

!3 sys_check_dataenvr

Parameters:

 /data_envrs/ = dataenvrs to check

Accept either a dataenvr or a ref to an array of dataenvrs. If \
/data_envrs/ contains the current dataenvr, return true, otherwise return \
false.

Returns:

=cut
    my $data_envrs = shift;
    my @check_envrs;

    if ( ref $data_envrs eq 'ARRAY' ) {
        @check_envrs = map { $_ } @{$data_envrs};
    } else {
        push @check_envrs, $data_envrs;  ## single entry
    }

    ## is current data environment in the list of acceptable environments
    if ( grep { $_ eq $dataenvr } @check_envrs ) {
        return 1;
    }

    return 0;
}

sub sys_disp_doc {
=begin wiki

!3 sys_disp_doc

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    return _sys_disp_doc();
}

sub sys_timer {
=begin wiki

!3 sys_timer

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my ($opt, $timer_name) = @_;
    $timer_name = 't1' unless $timer_name;

    if ( $opt =~ m/start/ix ) {
        $timers{$timer_name.'_start'} = time;
        return $timers{$timer_name.'_start'};
    }
    if ( $opt =~ m/stop/ix ) {
        $timers{$timer_name.'_stop'} = time;
        return $timers{$timer_name.'_stop'};
    }
    if ( $opt =~ m/elapsed/ix ) {
        my $estart = $timers{$timer_name.'_start'};
        my $estop = $timers{$timer_name.'_stop'};
        my $eelapsed = $estop - $estart;
        my $ehours = int $eelapsed / 3600;
        my $emins  = int $eelapsed / 60 % 60;
        my $esecs  = int $eelapsed % 60;
        return sprintf "%02d:%02d:%02d", $ehours, $emins, $esecs;
    }
    if ( $opt =~ /elapsed_seconds/i ) {
        my $sstart = $timers{$timer_name.'_start'};
        my $sstop = $timers{$timer_name.'_stop'};
        my $selapsed = $sstop - $sstart;
        return $selapsed;
    }
    return 'TIMER ERROR';
}

sub sys_wait {
=begin wiki

!3 sys_wait

Parameters: ( $action, $minutes )

$action can be either:

* 'init' - initialize wait's start time and elapsed time
* 'wait' - wait until $minutes has elapsed since start time

Example:

 % language=Perl
 % sys_wait( 'init', 3 );
 % ... do some work
 % sys_wait( 'wait' );
 %%

Returns:

=cut
    my ($action, $minutes) = @_;

    if ( $action =~ /^init$/i ) {
        $wt_start = time;
        $wt_seconds = 0;
        return 0 unless $minutes =~ /^\d+$/;
        $wt_seconds = $minutes * 60;
    }

    if ( $action =~ /^wait$/i ) {
        while ( 1 ) {
            my $currtime = time;
            my $elapsedt = $currtime - $wt_start;
            log_info( "Waiting $wt_seconds, Elapsed: $elapsedt" );
            if ( ($currtime - $wt_start) < $wt_seconds ) {
                sleep 10;
            } else {
                last;
            }
        }
    }

    return 0;
}

=begin wiki

!2 Logging Functions

These functions provide logging and notification capabilities.

=cut

sub log_fatal {
=begin wiki

!3 log_fatal

Parameters: ( message )

Call lower level logging functions using severity level FATAL.

Returns:

=cut
    my ($message, $extmsg) = @_;
    $errorlevel = $RC_FATAL;
    _log_write_to_log( 'FATAL', 0, $message, $extmsg);
    _log_write_to_screen( 'FATAL', 0, $message, $extmsg);
    return $errorlevel;
}

sub log_error {
=begin wiki

!3 log_error

Parameters: ( message )

Call lower level logging functions using severity level ERROR.

Returns:

=cut
    my ($message, $extmsg) = @_;
    $errorlevel = $RC_ERROR;
    _log_write_to_log( 'ERROR', 0, $message, $extmsg);
    _log_write_to_screen( 'ERROR', 0, $message, $extmsg);
    return $errorlevel;
}

sub log_warn {
=begin wiki

!3 log_warn

Parameters: ( message )

Call lower level logging functions using severity level WARN.

Returns:

=cut
    my ($message, $extmsg) = @_;
    $errorlevel = $RC_WARN;
    _log_write_to_log( 'WARN', 0, $message, $extmsg);
    _log_write_to_screen( 'WARN', 0, $message, $extmsg);
    return $errorlevel;
}

sub log_info {
=begin wiki

!3 log_info

Parameters: ( message )

Call lower level logging functions using severity level INFO.

Returns:

=cut
    my ($message, $extmsg, $nolog) = @_;
    $nolog = 0 unless $nolog;
    return 0 if $nolog;
    _log_write_to_log( 'INFO', 0, $message, $extmsg);
    _log_write_to_screen( 'INFO', 0, $message, $extmsg);
    return 0;
}

sub log_debug {
=begin wiki

!3 log_debug

Parameters: ( message )

Call lower level logging functions using severity level DEBUG.

Returns:

=cut
    my ($message, $extmsg) = @_;
    _log_write_to_log( 'DEBUG', 0, $message, $extmsg);
    _log_write_to_screen( 'DEBUG', 0, $message, $extmsg);
    return 0;
}

sub log_close {
=begin wiki

!3 log_close

Parameters: ( message )

Close the currently open log file.

Returns: 0

=cut
    my ($message, $extmsg) = @_;

    _log_write_to_log( 'INFO', 0, $message, $extmsg);
    _log_write_to_screen( 'INFO', 0, $message, $extmsg);
    $sys_log_open = 0;

    return 0;
}

sub log_write_screen {
=begin wiki

!3 log_write_screen

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $message = shift;
    _log_write_to_screen( 'INFO', 1, $message);
    return 0;
}

sub log_write_log {
=begin wiki

!3 log_write_log

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $message = shift;
    _log_write_to_log( 'INFO', 1, $message);
    return 0;
}

=begin wiki

!2 Database Functions

These functions provide the database interface and data manipulation \
capabilities.

=cut

sub db_init {
=begin wiki

!3 db_init

Parameters: ( )

User interface to settings used by the various db functions. Requested \
settings are validated against those held in the db_func_parmas hash.

Returns:

=cut
    my ($id, %params) = @_;
    if ( ! defined $db_func_params{$id} ) {
        sys_die( "Param $id to db_init is invalid")
    }
    foreach my $key ( keys %params ) {
        if ( ! defined $db_func_params{$id}{$key} ) {
            sys_die( "Param $key to db_init is invalid" );
        }
        $db_func_params{$id}{$key} = $params{$key};
    }
    return 0;
}

sub db_connect {
=begin wiki

!3 db_connect

Parameters: ( vdn )

This function accepts a virtual database name and makes a connection to the \
database resource identified by that name. The desired database instance has \
already been determined and stored before this function is called.

This function sets the DBI tracing mode so that we have a dbitrace.log file \
with pertinent history in it. This file will get large, so it should be \
rotated frequently. Contrary to what I've read, this does not supress \
output to STDERR. It appears that this just forces DBI to write errors to \
both STDERR and the dbitrace file. To fix that, this function redirects \
STDERR to /dev/null. This is an ugly hack. So until I can figure out if I \
read the docs wrong, or if DBI is just broken in this regard, I need to \
leave this to prevent garbage output. It's garbage because I always check \
and log DBI errors anyway.

Returns:

=cut
    my ($vdn, %connect_params) = @_;
    my ($starttime, $dbh, $instance);

    ## time increment is secs, action is either 'run' or 'fail'
    my $dependent_jobname = $connect_params{dependent_jobname} || '';
    my $wait_duration     = $connect_params{wait_duration}     || 60;
    my $wait_max_secs     = $connect_params{wait_max_secs}     || 60*60;
    my $wait_action       = $connect_params{wait_action}       || 'fail';
    my $retry_duration    = $connect_params{retry_duration}    || 0;
    my $retry_max_secs    = $connect_params{retry_max_secs}    || 0;

    if ( $vdn =~ m/:/x ) {  ## vdn contains instance definiton
        my ($db, $inst) = split m/:/, $vdn;
        _check_array_val( $db, \@databases )
            || sys_die( "Invalid database: [$db]", 0 );
        _check_array_val( $inst, [split m/,/, $dbinst{$db}] )
            || sys_die( "Invalid database instance: [$db.$inst]", 0 );
        $dbdefenvr{$db} = $inst;  ## update default connection data
        $vdn = $db;  ## vdn gets true vdn
    }

    ## check for dependent job
    _db_connect_check_dependent(
        $dependent_jobname, $wait_duration, $wait_max_secs, $wait_action
    );

    ## get database parameters
    my ($db, $un, $pw) = _db_vdn('connect', $vdn);
    DBI->trace( 1, $dbitrace_filefull );
    open STDERR, '>', '/dev/null' unless $opt_very_verbose;

    ## connect with retry
    $dbh = _db_connect_retry(
        $db, $un, $pw, $retry_duration, $retry_max_secs
    );

    ## connection established
    $dbhandles{$vdn}{'dbh'} = $dbh;   ## store handle for cleanup on exit

    db_nil( $vdn );
    return 0;
}

sub db_nil {
=begin wiki

!3 db_nil

Parameters: ( )

This is just a convenience function. When running in test mode, this will \
call the internal C<_db_vdn> to function for force closure of all database \
connections immediately.

Returns:

=cut
    my $vdn = shift;
    my ($dbh, $sth) = _db_vdn( 'nil', $vdn);
    return 0;
}

sub db_disconnect {
=begin wiki

!3 db_disconnect

Parameters: ( vdn )

Accept a virtual database name and disconnect from the datatabase specified \
by the virtual database name.

Returns:

=cut
    my $vdn = shift;
    my ($dbh, $sth) = _db_vdn( 'disconnect', $vdn);

    if ( $dbh ) {
        $dbh->disconnect;
        if ( DBI->errstr ) {
            log_warn( DBI->errstr );
            return 1;
        }
    }
    $dbhandles{$vdn}{'dbh'} = 0;
    return 0;
}

sub db_finish {
=begin wiki

!3 db_finish

Parameters: ( vdn )

Accept a virtual database name and close the current statement handle for \
the database specified by the virtual database name.

Returns:

=cut
    my $vdn = shift;
    my ($dbh, $sth) = _db_vdn( 'finish', $vdn);

    if ( $sth ) {
        $sth->finish;
        if ( DBI->errstr ) {
            log_warn( DBI->errstr );
            return 1;
        }
    }
    $dbhandles{$vdn}{'sth'} = 0;
    return 0;
}

sub db_prepare {
=begin wiki

!3 db_prepare

Parameters: ( vdn, sql_query )

Accept a virtual database name and an sql query and prepares the query for \
database processing. This function stores the resulting statement handle for \
subsequent access under the via the virtual database name.

Returns:

=cut
    my ($vdn, $sql, $longrlen) = @_;
    $longrlen = 0 unless $longrlen;
    my $sth_name = 'sth_default';  ## default statement handle name
    if ( $vdn =~ m/\./x ) {
        ($vdn, $sth_name) = split m/\./x, $vdn;
        if ( $sth_name eq 'sth_default' ) {
            sys_die( 'Invalid statement handle name', 0 );
        }
    }

    my ($dbh, $sth) = _db_vdn('prepare', $vdn);

    if ( $longrlen > 0 ) { $dbh->{LongReadLen} = $longrlen; }

    $sth = $dbh->prepare( $sql )
        or sys_die( $dbh->errstr );

    ## store statement handle for this vdn
    $dbhandles{$vdn}{$sth_name} = $sth;

    return 0;
}

sub db_truncate {
=begin wiki

!3 db_truncate

Parameters: ( vdn, table_name )

Accept a virtual database name and a table name. Truncate the specified \
table. This function returns number of rows truncated.

Returns:

=cut
    my ($vdn, $table_name) = @_;
    my ($dbh, $sth) = _db_vdn('truncate', $vdn);

    my $sql = "truncate table $table_name";
    $dbh->do( $sql )
        or sys_die( DBI->errstr );

    return 0;
}

sub db_execute {
=begin wiki

!3 db_execute

Parameters: ( vdn, sql_substitution_paramaters )

Accept a virtual database name and sql substitution parameters. Execute \
the query against the stored statement handle associated with the supplied \
virtual database name. The statement handle needs to be prepard before this \
function is called.

Returns:

=cut
    my ($vdn, @params) = @_;
    my ($dbh, $sth) = _db_vdn('execute', $vdn);

    $sth->execute( @params )
        or sys_die( $sth->errstr );

    return 0;
}

sub db_get_sth {
=begin wiki

!3 db_get_sth

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $vdn = shift;
    my $sth_name = 'sth_default';  ## default statement handle name
    if ( $vdn =~ m/\./x ) {
        ($vdn, $sth_name) = split m/\./x, $vdn;
    }
    return $dbhandles{$vdn}{$sth_name};
}

sub db_get_defenvr {
=begin wiki

!3 db_get_defenvr

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $vdn = shift;

    if ( $dbdefenvr{$vdn} ) {
        return $dbdefenvr{$vdn};
    }

    return '';
}

sub db_bindcols {
=begin wiki

!3 db_bindcols

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
#
# interface:
#   interface to sth->bind_columns()
#
# accepts:
#   1st position
#     a raw statement handle
#     a vdn which is used to obtain a default statment handle (one per vdn)
#     a vdn, named statement handle pair in the form vdn||nsth
#   remaining
#     any number of references to scalars
#
# returns:
#   0 = success
#   errors handled internally
#
    my ($vdn,@colrefs) = @_;
    my $sth;
    if ( ref $vdn ) {
        $sth = $vdn;  ## received a raw sth
    } else {
        my $sth_name = 'sth_default';  ## default statement handle name
        if ( $vdn =~ m/\./x ) {  ## dot notation vdn.sthn
            ($vdn, $sth_name) = split m/\./x, $vdn;
        }
        $sth = $dbhandles{$vdn}{$sth_name};
    }
    foreach my $colref ( @colrefs ) {
        if ( ! ref $colref ) { sys_die( "Received bad ref in db_bindcols" ); }
    }
    $sth->bind_columns( @colrefs );
    return 0;
}

sub db_pef {
=begin wiki

!3 db_pef

Parameters: ( )

Prepare, Execute, Fetch a scalar value

This function always returns the first element of the first row of the
result set.

Returns:

=cut
    my ($vdn, $sqlname, @params) = @_;

    my $sql = sys_get_sql( $sqlname );
    db_prepare( $vdn, $sql );
    db_execute( $vdn, @params );
    my $row = db_fetchrow( $vdn );

    return @{$row}[0];
}

sub db_pef_list {
=begin wiki

!3 db_pef_list

Parameters: ( )

Prepare, Execute, Fetch a result set as a list of scalars

This function returns a list of the first element from each row of the \
result set.

Returns:

=cut
    my ($vdn, $sqlname, @params) = @_;
    my @rsalist;

    my $sql = sys_get_sql( $sqlname );
    db_prepare( $vdn, $sql );
    db_execute( $vdn, @params );
    while ( my $row = db_fetchrow( $vdn ) ) {
        push @rsalist, @{$row}[0];
    }

    return \@rsalist;  ## return result set asa list
}

sub db_fetchrow {
=begin wiki

!3 db_fetchrow

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
#
# interface:
#   interface to sth->fetchrow_arrayref()
#
# accepts:
#   a raw statement handle
#   a vdn which is used to obtain a default statment handle (one per vdn)
#   a vdn, named statement handle pair in the form vdn||nsth
#
# note:
#   If you are going to make lots of calls to db_fetchrow for the
#   same execute cycle, you will get better performance using a raw
#   statement handle over a statement handle name
#
# returns:
#   reference to an array
#
    my $vdn = shift;
    my $sth;
    if ( ref $vdn ) {
        $sth = $vdn;  ## received a raw sth
    } else {
        my $sth_name = 'sth_default';  ## default statement handle name
        if ( $vdn =~ m/\./x ) {
            ($vdn, $sth_name) = split m/\./x, $vdn;
        }
        $sth = $dbhandles{$vdn}{$sth_name};
    }
    return $sth->fetchrow_arrayref();
}

sub db_commit {
=begin wiki

!3 db_commit

Parameters: ( virtual_database_name )

Accept a virtual database name and perform a commit against the specified \
database connection.

Returns:

=cut
    my ($vdn) = shift;
    my ($dbh, $sth) = _db_vdn('commit', $vdn);

    $dbh->commit;
    if ( DBI->errstr ) {
        sys_die( DBI->errstr );
        return 1;   ## test harness returns from sys_die
    }
    return 0;
}

sub db_rollback {
=begin wiki

!3 db_rollback

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my ($vdn) = shift;
    my ($dbh, $sth) = _db_vdn('rollback', $vdn);

    $dbh->rollback;
    if ( DBI->errstr ) {
        sys_die( DBI->errstr );
        return 1;   ## test harness returns from sys_die
    }
    return 0;
}

sub db_rowcount_table {
=begin wiki

!3 db_rowcount_table

Parameters: ( vdn, table_name )

Accept a virtual database name and a tablename and using the table name, \
do a select count(*) query against that table to get the current rowcount.

Returns:

=cut
    my ($vdn, $table_name) = @_;
    my ($dbh, $sth) = _db_vdn('rowcount_table', $vdn);

    my $sql = "select count(*) from $table_name";
    my $count = $dbh->selectrow_array( $sql );
    return $count;
}

sub db_rowcount_query {
=begin wiki

!3 db_rowcount_query

Parameters: ( vdn, sql )

Using a supplied query that does a select count(*), get a row count. This \
function will accept optional params for the query.

Returns:

=cut
    my ($vdn, $sql, @params ) = @_;
    my ($dbh, $sth) = _db_vdn('rowcount_query', $vdn);

    if ( @params ) {
        my $tmp_sth = $dbh->prepare( $sql )
            or sys_die( $dbh->errstr );
        $tmp_sth->execute( @params )
            or sys_die( $sth->errstr );
        my @row = $tmp_sth->fetchrow_array();
        return $row[0];
    } else {
        my $count = $dbh->selectrow_array( $sql );
        return $count;
    }
}

sub db_sanity_check {
=begin wiki

!3 db_sanity_check

Parameters: ( vdn, query_name, notify )

 /vdn/        - virtual database name
 /query_name/ - name of query in job conf file
 /notify/     - send notification on warning

Verify that table contents are within acceptable range limits for a given \
column value.

This function utilizes information stored in the current job conf file. The \
query executed to perform each range limit test is passed as a parameter in \
/query_name/. That query is executed for each test stored in the \
"checkpoints" array in conf section "thereshold" in the job conf file.

A checkpoints array should be defined for each database environment. This \
function will look for a checkpoints by database environment by combining \
the name of the current database environment with the liter string \
"checkpoints". If you have four database environments, you should have \
four checkpoint entries in your job conf file. The name of the current \
database environment is determined using the function sys_get_dataenvr().

Once the range limit query and all of the checkpoint values have been \
obtained, the parameter vdn is used to execute the range limit query.

Each checkpoint entry takes the form:

COLUMN_VALUE = count:percent_deviation

The range limit query will be executed for each COLUMN_VALUE entry. The \
actual count returned will be compared to the checkpoint count, if the \
count returned is within the percent range specified by the checkpoint \
percent_deviation, the test will pass, otherwise the test will fail and a \
log warning will be generated.

A percent_deviation of 0 (zero) represents a special case. If a \
percent_deviation of 0 is used, this instructs db_sanity_check to accept \
any positive value for count as a valid value. Typically, this behavior \
would be invoked by using a column value entry of "1:0".

An expected value of 0 (zero) represents a special case as well. When the \
expected value is 0, checking for that column value will be bypassed. In \
this way you can "turn off" sanity checking for an entire database \
environment by making all of the column value entries equal to "0:0".

If the /notify/ parameter is set, a notification will be sent in addition \
to a log warning.

Returns:

=cut
    my ($vdn, $query_name, $notify) = @_;
    $notify = 0 unless $notify;

    my $warnings = 0;
    my $lead = "Sanity check:";
    my $okay = " Ok            ";
    my $outofbounds = " Out Of Bounds ";
    my $disabled = " Disabled      ";

    ## get checkpoints
    my $checkpoints;
    my $conf_entry = sys_get_dataenvr . '_checkpoints';
    if ( $conf_job{threshold}{$conf_entry} ) {
        $checkpoints = $conf_job{threshold}{$conf_entry};
    } else {
        log_warn( "No threshold checkpoints found in job conf for: $conf_entry" );
        return 1;
    }

    ## prepare range limit query
    my $query = sys_get_sql( $query_name );
    db_prepare( $vdn, $query );

    log_info( "$lead Status        [Test] Expected/Actual/Threshold(%)/Threshold(#)" );

    ## perform checkpoint tests
    foreach my $chkpt ( split "\n", $checkpoints ) {
        my ($param,$rest) = split m/=/, $chkpt;
        my ($exp,$range) = split m/:/, $rest;
        $param = _trim($param);  ## col to check
        $exp   = _trim($exp);    ## expected value
        $range = _trim($range);  ## range/tolerance

        db_execute( $vdn, $param );
        my $row = db_fetchrow( $vdn );
        my $act = @{$row}[0];                   ## actual value
        my $dev = int $exp * ( $range / 100 );  ## deviation as a percent

        my $status = "[$param] $exp/$act/$range/$dev ";

        if ( $exp == 0 ) {  ## checking has been disabled
            log_info( $lead . $disabled . $status );
            next;
        }

        if ( $range == 0 ) {  ## any positive value for actual is acceptable
            if ( $act > 0 ) {
                log_info( $lead . $okay . $status );
                next;
            }
            $warnings++;
            log_info( $lead . $outofbounds . $status );
            next;
        }

        if ( $act < $exp ) {  ## actual is below threshold
            if ( $act < $exp - $dev ) {
                log_info( $lead . $outofbounds . $status );
                $warnings++;
                next;
            }
        }

        if ( $act > $exp ) { ## actual is above threshold
            if ( $act > $exp + $dev ) {
                log_info( $lead . $outofbounds . $status );
                $warnings++;
                next;
            }
        }

        log_info( $lead . $okay . $status );
    }

    ## send out notifications if there are warnings
    if ( $warnings && $notify ) {
        _log_send_notifications( "WARN", 1, "Sanity check threshold exceeded" );
    }

    return 0;
}

sub db_drop_index {
=begin wiki

!3 db_drop_index

Parameters: ( vdn, index_name )

Accept a virtual database name and an index name. Drop the index identified \
by index name. If there was a database error, we check last error. If the \
last error indicates that the index we are trying to drop did not exist, \
then the error is ignored, otherwise the error is logged.

Returns:

=cut
    my ($vdn, $index_name) = @_;
    my ($dbh, $sth) = _db_vdn('drop_index', $vdn);

    my $tmp_sth = $dbh->prepare("drop index $index_name")
        or sys_die( DBI->errstr );


    $tmp_sth->execute;
    if ( DBI->err && DBI->err != 1418 ) {   ## ORA-00942: specified index does not exist
        sys_die( DBI->errstr );
    }

    return 0;
}

sub db_drop_table {
=begin wiki

!3 db_drop_table

Parameters: ( vdn, table_name )

Accept a virtual database name and a table name. Drop the table identified \
by table name. If there was a database error, we check last error. If the \
last error indicates that the table we are trying to drop did not exist, \
then the error is ignored, otherwise the error is logged.

Returns:

=cut
    my ($vdn, $table_name) = @_;
    my ($dbh, $sth) = _db_vdn('drop_table', $vdn);

    my $tmp_sth = $dbh->prepare("drop table $table_name" )
        or sys_die( DBI->errstr );

    $tmp_sth->execute;
    if ( DBI->err && DBI->err != 942 ) {   ## ORA-00942: specified table does not exist
        sys_die( DBI->errstr );
    }
    $tmp_sth->finish;
    return 0;
}

sub db_drop_procedure {
=begin wiki

!3 db_drop_procedure

Parameters: ( vdn, procedure_name )

Accept a virtual database name and a procedure name. Drop the procedure \
identified by the given name. Check the last error, if it indicates the \
procedure did not exist, then the error is ignored, otherwise the error is \
logged.

Returns:

=cut
    my ($vdn, $procedure_name) = @_;
    my ($dbh, $sth) = _db_vdn('drop_procedure', $vdn);

    my $tmp_sth = $dbh->prepare("drop procedure $procedure_name")
        or sys_die( DBI->errstr );

    $tmp_sth->execute;
    if ( DBI->err && DBI->err != 4043 ) {   ## ORA-04043: object does not exist
        sys_die( DBI->errstr );
    }
    $tmp_sth->finish;
    return 0;
}

sub db_drop_function {
=begin wiki

!3 db_drop_function

Parameters: ( $vdn, $function_name )

Accept a virtual database name and a function name. Drop the function \
identified by the given name. Check the last error, if it indicates the \
function did not exist, then the error is ignored, otherwise the error is \
logged.

Returns:

=cut
    my ($vdn, $function_name) = @_;
    my ($dbh, $sth) = _db_vdn('drop_function', $vdn);

    my $tmp_sth = $dbh->prepare("drop function $function_name")
        or sys_die( DBI->errstr );

    $tmp_sth->execute;
    if ( DBI->err && DBI->err != 4043 ) {   ## ORA-04043: object does not exist
        sys_die( DBI->errstr );
    }
    $tmp_sth->finish;
    return 0;
}

sub db_drop_package {
=begin wiki

!3 db_drop_package

Parameters: ( vdn, package_name )

Accept a virtual database name and a package name. Drop the package \
identified by the given name. Check the last error, if it indicates \
that the the package we are trying to drop did not exist, then the error \
is ignored, otherwise the error is logged.

Returns:

=cut
    my ($vdn, $package_name) = @_;
    my ($dbh, $sth) = _db_vdn('drop_package', $vdn);

    my $tmp_sth = $dbh->prepare("drop package $package_name")
        or sys_die( DBI->errstr );

    $tmp_sth->execute;
    if ( DBI->err && DBI->err != 4043 ) {   ## ORA-04043: object does not exist
        sys_die( DBI->errstr );
    }
    $tmp_sth->finish;
    return 0;
}

sub db_rename_index {
=begin wiki

!3 db_rename_index

Parameters: ( vdn, oldndxname, newndxname )

Please write the documentation.

Returns:

=cut
    my ($vdn, $oldname, $newname) = @_;
    my ($dbh, $sth) = _db_vdn('rename_index', $vdn);

    my $tmp_sth = $dbh->prepare("alter index $oldname rename to $newname")
        or sys_die( DBI->errstr );

    $tmp_sth->execute;
    if ( DBI->err ) {
        sys_die( DBI->errstr );
    }

    return 0;
}

sub db_rename_table {
=begin wiki

!3 db_rename_table

Parameters: ( vdn, oldtabname, newtabname )

Please write this documentation.

Returns:

=cut
    my ($vdn, $oldname, $newname) = @_;
    my ($dbh, $sth) = _db_vdn('rename_table', $vdn);

    my $tmp_sth = $dbh->prepare("alter table $oldname rename to $newname" )
        or sys_die( DBI->errstr );

    $tmp_sth->execute;
    if ( DBI->err ) {
        sys_die( DBI->errstr );
    }
    $tmp_sth->finish;
    return 0;
}

sub db_purge_table {
=begin wiki

!3 db_purge_table

Parameters: ( vdn, table_name )

Please write this documentations.

Returns:

=cut
    my ($vdn, $table_name) = @_;
    my ($dbh, $sth) = _db_vdn('purge_table', $vdn);

    my $tmp_sth = $dbh->prepare("purge table $table_name" )
        or sys_die( DBI->errstr );

    $tmp_sth->execute;
    if ( DBI->err && DBI->err != 38307 ) {   ## ORA-38307: object not in recycle bin
        sys_die( DBI->errstr );
    }
    $tmp_sth->finish;
    return 0;
}

sub db_purge_index {
=begin wiki

!3 db_purge_index

Parameters: ( vdn, index_name )

Please write this documentation.

Returns:

=cut
    my ($vdn, $table_name) = @_;
    my ($dbh, $sth) = _db_vdn('purge_index', $vdn);

    my $tmp_sth = $dbh->prepare("purge index $table_name")
        or sys_die( DBI->errstr );

    $tmp_sth->execute;
    if ( DBI->err && DBI->err != 38307 ) {   ## ORA-38307: object not in recycle bin
        sys_die( DBI->errstr );
    }

    return 0;
}

sub db_grant {
=begin wiki

!3 db_grant

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
   my ($vdn, $priv, $objname, $ag) = @_;
   my ($dbh, $sth) = _db_vdn('grant', $vdn);

   unless ( $priv =~ m/^r$|^u$/x ) {
       log_warn( "Privilege to db_grant must be either 'r' or 'u'" );
       return 1;
   }
   my $sql;
   if ( $priv eq 'r' ) {
      $sql = qq{begin execute immediate 'grant select on $objname to $ag'; end;};
   }
   if ( $priv eq 'u' ) {
      $sql = qq{begin execute immediate 'grant update, insert, delete on $objname to $ag'; end;};
   }

   my $tmp_sth = $dbh->prepare( $sql )
       or sys_die( DBI->errstr );
   $tmp_sth->execute
       or sys_die( DBI->errstr );
    $tmp_sth->finish;
    return 0;
}

sub db_update_statistics {
=begin wiki

!3 db_update_statistics

Parameters: ( vdn, table_name )

Please write this documentation.

Returns:

=cut
    my ($vdn, $table_name) = @_;
    my ($dbh, $sth) = _db_vdn('update_statistics', $vdn);

    unless ( _db_is_oracle($vdn) ) {
        sys_die( 'Not an Oracle database connection in db_update_statistics', 0 );
    }

    my $sql = "BEGIN dbms_stats.gather_table_stats('','"
            . "$table_name',NULL,NULL,FALSE,'FOR ALL COLUMNS SIZE 1'"
            . ",NULL,'DEFAULT',TRUE); END;";

    my $tmp_sth = $dbh->prepare( $sql );
    if ( DBI->errstr ) { sys_die( DBI->errstr ); }
    $tmp_sth->execute;
    if ( DBI->errstr ) { sys_die( DBI->errstr ); }
    $tmp_sth->finish;
    return 0;
}

sub db_insert_from_file {
=begin wiki

!3 db_insert_from_file

Parameters: ( vdn, file_name, delim )

* /vdn/       - Virtual Database Name
* /file_name/ - File containing data to read
* /delim/     - Field delimiter (can be a regex)

Accept a virtual database name, file name, and field delimiter. Insert records \
from specified file into the database table using the statement handle tied \
to the virtual database name. The file name should include full path \
information.

It is desireable to call db_init before using this function. There are several \
advanced options implemented by this function that can be configured by call \
db_init first.

By default the field delimiter is not interpreted as a Regular Expression, \
however by calling db_init first, you can make this function treat your \
delimiter as a regex, in that case the delimiter can be more than one \
character in length.

SQL used by this function should be prepared before calling this function.

Returns:

=cut
    my ($vdn, $file_name, $delim) = @_;
    my ($dbh, $sth) = _db_vdn('insert_from_file', $vdn);

    my $id = 'db_insert_from_file';
    my $TrimLead       = _is_yes($db_func_params{$id}{'TrimLead'});
    my $TrimFieldLead  = _is_yes($db_func_params{$id}{'TrimFieldLead'});
    my $TrimFieldTrail = _is_yes($db_func_params{$id}{'TrimFieldTrail'});
    my $SkipComments   = _is_yes($db_func_params{$id}{'SkipComments'});
    my $SkipLastField  = _is_yes($db_func_params{$id}{'SkipLastField'});
    my $UseRegex       = _is_yes($db_func_params{$id}{'UseRegex'});
    my $CommentChar    = $db_func_params{$id}{'CommentChar'};

    my ($count, @row);
    open my $fh, "<", $file_name or sys_die( "Error opening $file_name" );

    my $regex = "\Q$delim\E";  # escape regex meta chars
    if ( $UseRegex ) {
        $regex = $delim;  # do escaping meta chars
    }

    while ( <$fh> ) {
        my $line = $_;
        chomp $line;
        if ( $TrimLead ) {
            $line = _trim_lead($line);
        }
        if ( $SkipComments ) {
            if ( substr($line,0,1) eq $CommentChar ) { next; }
        }

        @row = split($regex,$line,-1);  # -1 preserves trailing null fields

        if ( $SkipLastField ){
            pop @row;
        }
        if ( $TrimFieldLead ) {
            for (my $i=0;$i<@row;$i++) {
                $row[$i]=_trim_lead($row[$i]);
            }
        }
        if ( $TrimFieldTrail ) {
            for (my $i=0;$i<@row;$i++) {
                $row[$i]=_trim_trail($row[$i]);
            }
        }

        $sth->execute( @row );
        if ( DBI->errstr ) {
            print DBI->errstr;
            log_warn( DBI->errstr );
            my $errrec = 'RECORD: ' . join "~", @row;
            log_warn( $errrec );
            sys_die( 'Aborting' );
        }
        $count++;
    }

    db_commit( $vdn );
    close $fh or sys_die( "Error closing $file_name" );

    return $count;
}

sub db_insert_from_query {
=begin wiki

!3 db_insert_from_query

Parameters: ( source_vdn, target_vdn )

Accept a virtual database name for a source and target databases and insert \
rows into the target database from the source database.

Note: This needs to be rewritten to use fetchrow_arrayref() instead for \
better performance.

Returns:

=cut
    my ($src_vdn, $des_vdn, $plugin) = @_;
    $plugin = 0 unless $plugin;

    ## set up array of plugins
    my @plugins;
    if ( ref $plugin eq 'ARRAY' ) {
        @plugins = map { $_ } @{$plugin};  ## copy plugin list to plugin array
    } else {
        push @plugins, $plugin;  ## copy single plugin entry to plugin array
    }

    my ($src_dbh, $src_sth) = _db_vdn('insert_from_query', $src_vdn);
    my ($des_dbh, $des_sth) = _db_vdn('insert_from_query', $des_vdn);

    my $count = 0;
    while ( my $row = $src_sth->fetchrow_arrayref() ) {   ## fetch insert loop
        my @tmprow = @{$row};

        my $plugin_result = 0;
        foreach my $plugin ( @plugins ) {  ## call each plugin
            my $result = $plugin->( \@tmprow ) if $plugin;
            if ( $result > 1000 ) { $plugin_result = 1; }  ## plugin bad return
        }
        next if $plugin_result;  ## if any plugin complains, skip the record

        $des_sth->execute( @tmprow );
        if ( DBI->errstr ) {
            log_warn( DBI->errstr );
            my $errrec = 'RECORD: ' . join "~", @{$row};
            log_warn( $errrec );
            sys_die( 'Aborting' );
        }
        $count++;
    }
    return $count;
}

sub db_query_to_file {
=begin wiki

!3 db_query_to_file

Parameters: ( vdn, file_name, delim )

Accept a virtual database name and a file name and write the result set to \
the requested file. This function should be passed a file name that includes \
full path information. The specified delimiter is used as a field separator \
when writing the result set to the file.

Plugins

Plugins can be called for each row returned in the record set. Plugins can \
return a value, any value returned that is greater than 1000 will cause the \
current record to be skiped rather than written to the output file.

Returns:

=cut
    my ($vdn, $file_name, $delim, $append, $plugin, $protect) = @_;
    $delim = '~' unless $delim;
    $append  = 0 unless $append;
    $plugin  = 0 unless $plugin;   ## unblessed ref to a plugin or ref to array
    $protect = 0 unless $protect;  ## ref to array of cols to protect

    ## set up array of plugins
    my @plugins;
    if ( ref $plugin eq 'ARRAY' ) {
        @plugins = map { $_ } @{$plugin};  ## copy plugin list to plugin array
    } else {
        push @plugins, $plugin;  ## copy single plugin entry to plugin array
    }

    my ($dbh, $sth) = _db_vdn('query_to_file', $vdn);

    my $mode;
    if ( $append ) {
        $mode = '>>';
    } else {
        $mode = '>';
    }

    my $count = 0;
    open my $fh, $mode, $file_name or sys_die( "Error opening $file_name" );
    while ( my $row = $sth->fetchrow_arrayref() ) {
        my @outrow = @{$row};

        my $plugin_result = 0;
        foreach my $plugin ( @plugins ) {  ## call each plugin in turn
            my $result = $plugin->( \@outrow ) if $plugin;
            if ( $result > 1000 ) { $plugin_result = 1; }  ## bypass this record
        }
        next if $plugin_result;

        _db_query_to_file_protect( \@outrow, $protect ) if $protect;
        print {$fh} join $delim, @outrow;
        print {$fh} "\n";
        $count++;
    }
    close $fh or sys_die( "Error closing $file_name" );

    return $count;
}

sub db_dump_query {
=begin wiki

!3 db_dump_query

Parameters: ( vdn, columns )

Accept a virtual database name and a list of column names, dump the \
query showing column names and field values.

Returns:

=cut
    my ($vdn, $cols) = @_;
    my ($dbh, $sth) = _db_vdn('dump_query', $vdn);

    while ( my @row = $sth->fetchrow_array() ) {
        print "RECORD:\n";
        for my $i ( 0 .. $#row ) {
            print "\t", $cols->[$i], '=', _db_null( $row[$i] ), "\n";
        }
    }

    return 0;
}

sub db_dump_table {
=begin wiki

!3 db_dump_table

Parameters: ( vdn, table_name, max_rows )

Accept a virtual database name and a table name, dump the contents of the \
requested table showing column names and field values. If optional paramater \
max rows is provided, query output will be limited to that many rows. There \
is an upper limit on the number of rows that this query will return, this \
is set rather high, so in most cases you should probably supply a max rows \
limit.

Returns:

=cut
    my ($vdn, $table_name, $max_rows) = @_;
    my ($dbh, $sth) = _db_vdn('dump_table', $vdn);
    $max_rows = 999_999 unless defined $max_rows;

    $table_name = uc $table_name;
    my $col_sql = "select column_name " .
                  "  from all_tab_columns " .
                  " where table_name = '$table_name'";
    my ( $tmp_sth, @cols );

    $tmp_sth = $dbh->prepare( $col_sql )
        or sys_die( DBI->errstr );
    $tmp_sth->execute
        or sys_die( DBI->errstr );
    while ( my @row = $tmp_sth->fetchrow_array() ) {
        push @cols, $row[0];
    }
    $tmp_sth->finish;

    my $columns = join ', ', @cols;
    my $tab_sql = "select $columns " .
                  "  from $table_name";
    $tmp_sth = $dbh->prepare( $tab_sql )
        or sys_die( DBI->errstr );
    $tmp_sth->execute
        or sys_die( DBI->errstr );

    my $row_count = 0;
    while ( my @row = $tmp_sth->fetchrow_array() ) {
        print "RECORD:\n";
        for my $i ( 0 .. $#row ) {
            print "\t", $cols[$i], "=", _db_null( $row[$i] ), "\n";
        }
        last if ++$row_count >= $max_rows;
    }
    $tmp_sth->finish;

    return 0;
}

sub db_sqlloader {
=begin wiki

!3 db_sqlloader

Parameters: ( vdn, datfile, ctlname, maxerrors )

* /vdn/       - Virtual Database Name
* /datfile/   - SQL*Loader data file
* /ctlname/   - Job conf key for control file input
* /maxerrors/ - Maximum number of errors allowed

This is a convenience function which provides a simplified method for calling \
the various db_sqlloader functions. This will invoke SQL*Loader and handle \
the various execution and output parsing that whould otherwise have to be \
handled by calling the db_sqlloader functions directly (which certainly you \
can if you prefer).

Execute SQL*Loader using the supplied paramaters. The Virtual Database \
Name is used to obtain login credentials. This will launch SQL*Loader \
and wait for it to finish, returning the SQL*Loader return code to the \
caller.

Data file name must be fully qualified. Path provided by data file name \
will be used for out, bad, and dis files.

Return: One of

* SQLLDR_SUCC
* SQLLDR_WARN
* SQLLDR_FAIL

=cut
    my ($vdn, $datfile, $ctlname, $maxerrors) = @_;

    my $id = 'db_sqlloader';
    my $datfilepath = $db_func_params{$id}{DatFilePath};
    my $dbenvr = $db_func_params{$id}{DbEnvr};
    my $netservice = $db_func_params{$id}{NetService};

    my $datfilefull = $datfilepath . $datfile;

    my ($sqlldr_retcd, $sqlldr_result);

    log_info( "Executing SQLLoader" );
    if ( $dbenvr =~ /$netservice/ ) {
        log_info( "Using netservice db connection symantics" );
        $sqlldr_retcd = db_sqlloaderx( "$vdn:$dbenvr", $datfilefull, $ctlname, $maxerrors );
    } else {
        log_info( "Using local db connection symantics" );
        $sqlldr_retcd = db_sqlloaderx( $vdn, $datfilefull, $ctlname, $maxerrors );
    }

    $sqlldr_result = db_sqlloaderx_parse_logfile( $datfilefull );
    log_info( "SQLLoader Output:", $sqlldr_result );

    if ( $sqlldr_retcd == $SQLLDR_SUCC ) {
        log_info( "Load data file $datfile completed successfully" );
    }
    if ( $sqlldr_retcd == $SQLLDR_WARN ) {
        log_warn( "Load data file $datfile completed with warnings" );
    }
    if ( $sqlldr_retcd == $SQLLDR_FTL || $sqlldr_retcd == $SQLLDR_FAIL ) {
        $sqlldr_retcd = $SQLLDR_FAIL;
        log_warn( "Load data file $datfile failed" );
    }

    my $rej_count = db_sqlloaderx_rejected();
    if ( $rej_count > 0 ) {
        log_warn( "SQLLoader rejected $rej_count records loading $datfile to " . sys_get_dbinst( $vdn ) );
    }

    if ( $rej_count > $maxerrors ) {
        log_warn( "SQLLoader failed loading $datfile to " . sys_get_dbinst( $vdn ) . " due to max rejected records" );
    }

    return $sqlldr_retcd;
}

sub db_sqlloaderx {
=begin wiki

!3 db_sqlloaderx

See: db_sqlloader for Parameters and Return Values.

=cut
    my ($vdn, $datfile, $ctlname, $maxerrors) = @_;

    my $defenvr = $dbdefenvr{$vdn};
    my $netservice = _db_netservice( $vdn );
    my ($db, $un, $pw) = _db_vdn('connect', $vdn);

    $maxerrors = $maxerrors || 50;

    ## validate the data file exists
    if ( ! -e $datfile ) { sys_die( "Data file $datfile not found" ); }

    ## get control file input from job conf
    my $key = $ctlname;
    my $section = 'sqlloader';
    if ( ! $conf_job{$section}{$key} ) {
        $key = 'control_file:' . $key;
        if ( ! $conf_job{$section}{$key} ) {
            sys_die( "No loader definition found in [$section] for key [$ctlname]", 0 );
        }
    }
    my $control = $conf_job{$section}{$key};

    my ($base,$path,$type) = fileparse($datfile,qr{\.dat|\.txt});
    my $ctlfile = $path.$base.'.ctl';
    my $parfile = $path.$base.'.par';
    my $badfile = $path.$base.'.bad';
    my $disfile = $path.$base.'.dis';
    my $outfile = $path.$base.'.out';

    ## build control file
    open my $fh, ">", $ctlfile || sys_die( 'Unable to create SQLLoader ctlfile', 0 );
    print $fh $control;
    close $fh;

    ## build params file
    open $fh, ">", $parfile || sys_die( 'Unable to create SQLLoader parfile', 0 );
    print $fh "userid=$un/$pw$netservice\n";
    print $fh "control=$ctlfile\n";
    print $fh "silent=(all)\n";
    print $fh "data=$datfile\n";
    print $fh "log=$outfile\n";
    print $fh "bad=$badfile\n";
    print $fh "discard=$disfile\n";
    close $fh;

    my @args = ("sqlldr", "PARFILE=$parfile errors=$maxerrors");
    system @args;
    my $sqlldr_retcd = $CHILD_ERROR >> 8;

    ## Normalize os dependent return codes. Why Oracle returns an os dependent
    ## return code from a cross-platform product is a mystery to me...
    if ( $OSNAME eq 'MSWin32' ) {
        if ( $sqlldr_retcd == 3 ) { $sqlldr_retcd = 1; }
        if ( $sqlldr_retcd == 4 ) { $sqlldr_retcd = 3; }
    }

    unlink $parfile;
    unlink $ctlfile;

    return $sqlldr_retcd;
}

sub db_sqlloaderx_parse_logfile {
=begin wiki

!3 db_sqlloaderx_parse_logfile

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $datfile = shift;

    my ($base,$path,$type) = fileparse($datfile,qr{\.dat|\.txt});
    my $outfile = $path.$base.'.out';

    return _db_sqlloaderx_parse_logfile( $outfile );
}

sub db_sqlloaderx_skipped {
=begin wiki

!3 db_sqlloaderx_skipped

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    if ( defined $sqlloader_results{'skipped'} ) {
        return $sqlloader_results{'skipped'}
    } else {
        return -1;
    }
}

sub db_sqlloaderx_read {
=begin wiki

!3 db_sqlloaderx_read

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    if ( defined $sqlloader_results{'read'} ) {
        return $sqlloader_results{'read'}
    } else {
        return -1;
    }
}

sub db_sqlloaderx_rejected {
=begin wiki

!3 db_sqlloaderx_rejected

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    if ( defined $sqlloader_results{'rejected'} ) {
        return $sqlloader_results{'rejected'}
    } else {
        return -1;
    }
}

sub db_sqlloaderx_discarded {
=begin wiki

!3 db_sqlloaderx_discarded

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    if ( defined $sqlloader_results{'discarded'} ) {
        return $sqlloader_results{'discarded'}
    } else {
        return -1;
    }
}

sub db_sqlloaderx_elapsed_time {
=begin wiki

!3 db_sqlloaderx_elapsed_time

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    if ( defined $sqlloader_results{'elapsed_time'} ) {
        return $sqlloader_results{'elapsed_time'}
    } else {
        return 'error';
    }
}

sub db_sqlloaderx_cpu_time {
=begin wiki

!3 db_sqlloaderx_cpu_time

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    if ( defined $sqlloader_results{'cpu_time'} ) {
        return $sqlloader_results{'cpu_time'}
    } else {
        return 'error';
    }
}

sub db_func {
=begin wiki

!3 db_func

Parameters: ( )

This function executes an Oracle stored procedure that takes no input \
parameters and returns a result via RETURN. This interface is Oracle \
specific, so a check is performed to make sure that the supplied vdn is \
pointing to an Oracle database. If a database error is raised it is \
trapped and reported. The existing vdn statement handle is preserved.

Returns:

=cut
    my ($vdn, $package, $proc_name) = @_;
    my ($dbh, $sth) = _db_vdn('funcx', $vdn);

    unless ( _db_is_oracle($vdn) ) {
        sys_die( 'Not an Oracle database connection in db_funcx' );
    }

    if ( $package ) { $proc_name = $package. '.' .$proc_name; }
    my $sql = 'BEGIN :result := ' . $proc_name . '; END;';

    my $result;
    my $tmp_sth = $dbh->prepare( $sql );
    if ( DBI->errstr ) { sys_die( DBI->errstr ); }

    $tmp_sth->bind_param_inout( ':result', \$result, 100 );
    $tmp_sth->execute;
    if ( DBI->errstr ) { sys_die( DBI->errstr ); }
    $tmp_sth->finish;

    return $result;
}

sub db_proc {
=begin wiki

!3 db_proc

Parameters: ( vdn, package, proc_name )

This function executes an Oracle stored procedure that takes no input \
parameters and returns no output. This interface is Oracle specific, so a \
check is performed to make sure that the supplied vdn is pointing to an \
Oracle database. If a database error is raised it is trapped and reported. \
The existing vdn statement handle is preserved.

Returns:

=cut
    my ($vdn, $package, $proc_name) = @_;
    my ($dbh, $sth) = _db_vdn('procx', $vdn);

    unless ( _db_is_oracle($vdn) ) {
        sys_die( 'Not an Oracle database connection in db_procx' );
    }

    if ( $package ) { $proc_name = $package . '.' . $proc_name; }
    my $sql = 'BEGIN ' . $proc_name . '; END;';

    my $tmp_sth = $dbh->prepare( $sql );
    if ( DBI->errstr ) { sys_die( DBI->errstr ); }
    $tmp_sth->execute;
    if ( DBI->errstr ) { sys_die( DBI->errstr ); }
    $tmp_sth->finish;

    return 0;
}

sub db_proc_in {
=begin wiki

!3 db_proc_in

Parameters: ( vdn, package, proc_name, parameters )

This function executes an Oracle stored procedure that takes any number of \
IN parameters and returns no output. This interface is Oracle specific, so a \
check is performed to make sure that the supplied vdn is pointing to an \
Oracle database. If a database error is raised it is trapped and reported. \
The existing vdn statement handle is preserved.

Returns:

=cut
    my ($vdn, $package, $proc_name, $params) = @_;
    unless ( ref $params eq 'ARRAY' ) {
        sys_die( 'Invalid type in call to db_procx_in' );
    }
    my ($dbh, $sth) = _db_vdn('procx_in', $vdn);

    unless ( _db_is_oracle($vdn) ) {
        sys_die( 'Not an Oracle database connection in db_procx_in' );
    }

    my $sql = _db_proc_build_sql( $package, $proc_name, $params );
    my $tmp_sth = $dbh->prepare( $sql );
    if ( DBI->errstr ) { sys_die( DBI->errstr ); }

    $tmp_sth = _db_proc_bind_inparams( $tmp_sth, $params );
    $tmp_sth->execute;
    if ( DBI->errstr ) { sys_die( DBI->errstr ); }
    $tmp_sth->finish;

    return 0;
}

sub db_proc_out {
=begin wiki

!3 db_proc_out

Parameters: ( vdn, package, proc_name, parameters )

This function executes an Oracle stored procedure that takes no input and \
returns any number of OUT parameters. This interface is Oracle specific, so \
a check is performed to make sure that the supplied vdn is pointing to an \
Oracle database. If a database error is raised it is trapped and reported. \
The existing vdn statement handle is preserved.

Returns:

=cut
    my ($vdn, $package, $proc_name, $params) = @_;
    unless ( ref $params eq 'ARRAY' ) {
        sys_die( 'Invalid type in call to db_procx_out' );
    }
    my ($dbh, $sth) = _db_vdn('procx_out', $vdn);

    unless ( _db_is_oracle($vdn) ) {
        sys_die( 'Not an Oracle database connection in db_procx_out' );
    }

    my $sql = _db_proc_build_sql( $package, $proc_name, $params );
    my $tmp_sth = $dbh->prepare( $sql );
    if ( DBI->errstr ) { sys_die( DBI->errstr ); }

    $tmp_sth = _db_proc_bind_outparams( $tmp_sth, $params);
    $tmp_sth->execute;
    if ( DBI->errstr ) { sys_die( DBI->errstr ); }
    $tmp_sth->finish;

    return 0;
}

sub db_proc_inout {
=begin wiki

!3 db_proc_inout

Parameters: ( vdn, package, proc_name, parameters )

This function executes an Oracle stored procedure that takes any combination \
of IN, IN OUT, or OUT parameters. This interface is Oracle specific, so a \
check is performed to make sure that the supplied vdn is pointing to an \
Oracle database. If a database error is raised it is trapped and reported. \
The existing vdn statement handle is preserved.

Returns:

=cut
    my ($vdn, $package, $proc_name, $params) = @_;
    unless ( ref $params eq 'ARRAY' ) {
        sys_die( 'Invalid type in call to db_procx_inout' );
    }
    my ($dbh, $sth) = _db_vdn('procx_inout', $vdn);

    unless ( _db_is_oracle($vdn) ) {
        sys_die( 'Not an Oracle database connection in db_procx_inout' );
    }

    my $sql = _db_proc_build_sql( $package, $proc_name, $params );
    my $tmp_sth = $dbh->prepare( $sql );
    if ( DBI->errstr ) { sys_die( DBI->errstr ); }

    $tmp_sth = _db_proc_bind_inoutparams( $tmp_sth, $params);
    $tmp_sth->execute;
    if ( DBI->errstr ) { sys_die( DBI->errstr ); }
    $tmp_sth->finish;

    return 0;
}

sub db_dbms_output_enable {
=begin wiki

!3 db_dbms_output_enable

Parameters: ( vdn, output_buffer_size)

This function enables dbms_output in the database. You may send this \
function an output buffer size if desired. If no buffersize is provided, \
a default buffer size of 1000000 is used. This interface is Oracle specific, \
so a check is performed to make sure that the supplied vdn is pointing to \
an Oracle database.

Returns:

=cut
    my ($vdn, $bufsize) = shift;
    my ($dbh, $sth) = _db_vdn('enable_dbms_output', $vdn);

    unless ( _db_is_oracle($vdn) ) {
        sys_die( 'Not an Oracle database connection in db_dbms_output_get' );
    }

    $sys_dbms_output = 1;
    $bufsize = 1_000_000 unless $bufsize;
    $dbh->func($bufsize, 'dbms_output_enable');
    if ( DBI->errstr ) { log_warn( DBI->errstr ); return 1; }

    return 0;
}

sub db_dbms_output_disable {
=begin wiki

!3 db_dbms_output_disable

Parameters: ( vdn )

This function disables dbms_output retrieval. It does this by setting a \
module flag value. This interface is Oracle specific, so a check is \
performed to make sure that the supplied vdn is pointing to an Oracle \
database.

Returns:

=cut
    my $vdn = shift;

    unless ( _db_is_oracle($vdn) ) {
        sys_die( 'Not an Oracle database connection in db_dbms_output_get' );
    }

    $sys_dbms_output = 0;
    return 0;
}

sub db_dbms_output_get {
=begin wiki

!3 db_dbms_output_get

Parameters: ( vdn )

This function retrieves the current dbms_output buffer and returns it to \
the caller as a reference to an array. This interface is Oracle specific, \
so a check is performed to make sure that the supplied vdn is pointing to \
an Oracle database. You need to call db_dbms_output_enable first.

Returns:

=cut
    my $vdn = shift;
    my ($dbh, $sth) = _db_vdn('get_dbms_output', $vdn);

    unless ( _db_is_oracle($vdn) ) {
        sys_die( 'Not an Oracle database connection in db_dbms_output_get' );
    }

    my @arr;
    unless ( $sys_dbms_output ) {
        log_warn( 'Output option has not been enabled' );
        return \@arr;
    }

    @arr = $dbh->func('dbms_output_get');
    if ( DBI->errstr ) { log_warn( DBI->errstr ); }

    return \@arr;
}

sub db_index_rebuild {
=begin wiki

!3 db_index_rebuild

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my ($vdn, $index_name) = @_;
    my ($dbh, $sth) = _db_vdn('ora_index_rebuild', $vdn);

    unless ( _db_is_oracle($vdn) ) {
        sys_die( 'Not an Oracle database connection in function index_rebuild', 0 );
    }

    my $sql = "ALTER INDEX $index_name REBUILD";

    my $tmp_sth = $dbh->prepare( $sql );
    if ( DBI->errstr ) { sys_die( DBI->errstr ); }

    $tmp_sth->execute;
    if ( DBI->errstr ) { sys_die( DBI->errstr ); }

    $tmp_sth->finish;
    return 0;
}

sub db_exchange_partition {
=begin wiki

!3 db_exchange_partition

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my ($vdn, $to_table, $from_table, $partition) = @_;
    my ($dbh, $sth) = _db_vdn('ora_swap_partition', $vdn);

    unless ( _db_is_oracle($vdn) ) {
        sys_die( 'Not an Oracle database connection in function swap_partition', 0 );
    }

    ## REPAIR REQUIRED need to figure out why this is required...
    db_commit( $vdn );
    sleep 3;

    my $sql = "ALTER TABLE $to_table "
            . "EXCHANGE PARTITION $partition "
            . "WITH TABLE $from_table "
            . "INCLUDING INDEXES "
            . "WITH VALIDATION";

    my $tmp_sth = $dbh->prepare( $sql );
    if ( DBI->errstr ) { sys_die( DBI->errstr ); }

    $tmp_sth->execute;
    if ( DBI->errstr ) { sys_die( DBI->errstr ); }

    $tmp_sth->finish;
    return 0;
}

=begin wiki

!2 Utility Functions

These functions provide the general purpose file access capabilities.

=cut

sub util_get_filename_load {
=begin wiki

!3 util_get_filename_load

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my ($base, $ext) = @_;
    my $filename = $base . '.' . $ext;
    if ( $osuser ) {
        $filename = $base . '_' . $osuser . '.' . $ext;
    }
    return $path_load_dir . $filename;
}

sub util_get_filename_extr {
=begin wiki

!3 util_get_filename_extr

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my ($base, $ext) = @_;
    my $filename = $base . '.' . $ext;
    if ( $osuser ) {
        $filename = $base . '_' . $osuser . '.' . $ext;
    }
    return $path_extr_dir . $filename;
}

sub util_get_filename_log {
=begin wiki

!3 util_get_filename_log

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $base = shift;
    return $path_log_dir . $base . $log_ext;
}

sub util_read_header {
=begin wiki

!3 util_read_header

Parameters: ( filename, format )

Please write this documentation.

Returns:

=cut
    my ($filename, $format) = @_;
    my $fh = File::Bidirectional->new($filename, {origin => 1} )
        or sys_die( "Unable to open file $filename" );
    my $head = $fh->readline();
    $fh->close;
    return $head;
}

sub util_read_footer {
=begin wiki

!3 util_read_footer

Parameters: ( filename, format_string )

Please write this documentation.

Returns:

=cut
    my ($filename, $format) = @_;
    my $fh = File::Bidirectional->new($filename, {origin => -1} )
        or sys_die( "Unable to open file $filename" );
    my $foot = $fh->readline();
    $fh->close;
    return $foot;
}

sub util_read_file {
=begin wiki

Parameters: ( )

Slurp a file in one go and return a return a reference to the text contained \
in the file.

Returns:

=cut
    my $file = shift;
    open( my $fh, $file ) or return 0;
    my $text = do { local( $/ ) ; <$fh> } ;
    return \$text;
}

sub util_write_header {
=begin wiki

!3 util_write_header

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my ($filename, $header, $append) = @_;
    $header = 'HEADER' unless $header;
    my $mode = ">>";
    $mode = ">" unless $append;
    open my $fh, $mode, $filename or sys_die( "Error writing header to $filename" );
    print {$fh} "$header\n";
    close $fh or sys_die( "Error closing $filename" );
    return 0;
}

sub util_write_footer {
=begin wiki

!3 util_write_footer

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my ($filename, $footer) = @_;
    $footer = 'FOOTER' unless $footer;
    open my $fh, ">>", $filename or sys_die( "Error writing footer to $filename" );
    print {$fh} "$footer\n";
    close $fh or sys_die( "Error closing $filename" );
    return 0;
}

sub util_move {
=begin wiki

Parameters: ( )

The move function also takes two parameters: the current name and the \
intended name of the file to be moved. If the destination already exists \
and is a directory, and the source is not a directory, then the source \
file will be renamed into the directory specified by the destination.

If possible, move() will simply rename the file. Otherwise, it copies the \
file to the new location and deletes the original. If an error occurs \
during this copy-and-delete process, you may be left with a (possibly \
partial) copy of the file under the destination name.

Returns:

=cut
    my ($from, $to) = @_;

    return 0 unless $util_move;
    my $result = move($from, $to);
    return $result;
}

sub util_trim {
    my $str = shift;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    return $str;
}

sub util_zsdf {
=begin wiki

Parameters: ( )

This regex was taken from the book "Regular Expression Recipes", by Nathan \
A. Good. The idea for util_zsdf (Zero Supress Decimal Format) came from my \
first mentor, Ed Bowlen.

Returns:

=cut
    my ($number, $width) = @_;
    $number =~ s/(?<=\d)(?=(\d{3})+(?!\d))/,/g;
    return sprintf '%*s', $width, $number;
}

=begin wiki

!2 Testing Functions

These functions some basic test capabilities. These can be used to write simple
database test scripts.

=cut

sub test_init {
=begin wiki

!3 test_init

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    $t_ok       = 0;
    $t_notok    = 0;
    return 0;
}

sub test_ok {
=begin wiki

!3 test_ok

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my ($actual,$expected,$description) = @_;

    $t_num++;
    if ($actual eq $expected) {
        $t_ok++;
        log_info("ok $t_num");
    } else {
        $t_notok++;
        sys_set_errorlevel(sys_get_errorlevel()+1);
        log_info("not ok $t_num - $description");
    }

    return 0;
}

sub test_results {
=begin wiki

!3 test_results

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    log_info("Test script: passed $t_ok, failed $t_notok");
    if ( $t_notok == 0 ) {
        log_info("Test script: PASS");
    } else {
        log_info("Test script: FAIL");
    }
    return 0;
}

sub test_harness_init {
=begin wiki

!3 test_harness_init

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    $th_num = 0;
    return 0;
}

sub test_harness_run {
=begin wiki

!3 test_harness_run

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $test_scripts = shift;

    foreach my $ts ( @{$test_scripts} ) {
        $th_num++;
        log_info("Test script: $ts");
        my $retcd = sys_run_job($ts, 8, '-r', '-v');
        if ( $retcd > 0 ) {
            sys_set_errorlevel( sys_get_errorlevel() + $retcd );
        }
    }

    return 0;
}

sub test_harness_results {
=begin wiki

!3 test_harness_results

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $test_scripts = shift;

    my ($ts_passed, $ts_failed);
    my $th_result = 'PASS';
    my $th_passed = 0;
    my $th_failed = 0;

    foreach my $ts ( @{$test_scripts} ) {
        $ts =~ s/\.pl$//;
        my $tsfull = util_get_filename_log( $ts );
        my $log = util_read_file( $tsfull );
        if ( ! $log ) {
            log_info( "Error reading log for test script: $ts" );
            next;
        }

        $ts_passed = 0;
        $ts_failed = 0;
        $th_num++;

        $$log =~ m#.{19,19} Test script: (PASS|FAIL|DUBIOUS)#;
        my $ts_result = $1;

        $$log =~ m#.{19,19} Test script: passed (\d+), failed (\d+)#;
        $ts_passed = $1;
        $ts_failed = $2;

        if ( $ts_result eq 'PASS' ) {
            $th_passed++;
        }
        if ( $ts_result eq 'FAIL' ) {
            $th_failed++;
            $th_result = 'FAIL';
        }

        log_info( "Test harness: script $ts, passed $ts_passed, failed $ts_failed, $ts_result" );
    }

    log_info( "Test harness: passed $th_passed, failed $th_failed" );
    log_info( "Test harness: $th_result" );

    return 0;
}

sub test_harness_summary {
=begin wiki

!3 test_harness_summary

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $test_harnesses = shift;

    foreach my $th ( @{$test_harnesses} ) {
        $th =~ s/\.pl$//;
        my $thfull = util_get_filename_log( $th );
        my $log = util_read_file( $thfull );
        if ( ! $log ) {
            log_info( "Error reading log for test harness: $th" );
            next;
        }

        log_info( "Test harness summary: $th" );

    }

    return 0;
}

# private methods
# -----------------------------------------------------------------------------

=begin wiki

!2 Private Functions

These functions provide internal module support.

=cut

sub _sys_init_vars {
=begin wiki

!3 _sys_init_vars

Parameters: ( )

This function provides variable initialization for a particular jobname. \
Once sys_init has been called with a jobname, this function is called to \
initialize or reinitialize system variables. It is possible, although not \
recommended, to stack jobs in a single perl script. my callling sys_init with \
different jobnames each time. This feature has not been thoroughly tested.

Returns:

=cut
    $pid = $PROCESS_ID;
    $errorlevel = 0;
    @plugins = ();
    $sys_dbms_output = 1;
    $sys_log_open = 0;
    $sys_jobconf_override = 0;
    $sys_jobconf_file = '';

    %log_level_opts = (
        FATAL => 'FATAL',
        ERROR => 'FATAL,ERROR',
        WARN  => 'FATAL,ERROR,WARN',
        INFO  => 'FATAL,ERROR,WARN,INFO',
        DEBUG => 'FATAL,ERROR,WARN,INFO,DEBUG',
        NONE  => 'NONE',
    );

    _sys_read_conf( 'sys_data.conf' );
    _sys_read_conf( 'sys_log.conf' );
    _sys_read_conf( 'sys_mail.conf' );
    _sys_read_conf( 'sys_common.conf' );
    _sys_read_conf( 'sys_util.conf' );
    _sys_read_conf( 'sys_environment.conf' );
    _sys_read_conf( 'sys_de.conf');
    _sys_read_conf( 'sys_run_controls.conf');

    my $envvar = uc $conf_system{'system'}{'envvar'};
    $dataenvr = lc $ENV{$envvar};
    if ( ! defined $dataenvr ) {
        sys_die( "Environment variable $dataenvr not set", 0 );
    }

    $path_bin_dir       = $conf_system{"$OSNAME directory bin"}{$dataenvr};
    $path_lib_dir       = $conf_system{"$OSNAME directory lib"}{$dataenvr};
    $path_log_dir       = $conf_system{"$OSNAME directory log"}{$dataenvr};
    $path_load_dir      = $conf_system{"$OSNAME directory load"}{$dataenvr};
    $path_extr_dir      = $conf_system{"$OSNAME directory extr"}{$dataenvr};
    $path_prev_dir      = $conf_system{"$OSNAME directory prev"}{$dataenvr};
    $path_scripts_dir   = $conf_system{"$OSNAME directory scripts"}{$dataenvr};
    $mail_server        = $conf_mail{'mail'}{'server'};
    $mail_from          = $conf_mail{'mail'}{'from'};
    $mail_emailto       = $conf_mail{'mail'}{'emailto'};
    $mail_pagerto       = $conf_mail{'mail'}{'pagerto'};
    $mail_email_levels  = $conf_mail{'mail'}{'email_levels'} || "FATAL";
    $mail_pager_levels  = $conf_mail{'mail'}{'pager_levels'} || "FATAL";
    $log_file           = $conf_log{'log'}{'default_logfile'};
    $log_filefull       = $path_log_dir . $log_file;
    $log_logging_levels = $conf_log{'log'}{'logging_levels'} || "FATAL,ERROR,WARN,INFO";
    $log_console_levels = $conf_log{'log'}{'console_levels'} || "FATAL,ERROR,WARN,INFO";
    $log_gdg            = $conf_log{'log'}{'gdg'} || 5;

    $path_plugin_dir = $conf_system{"$OSNAME directory plugin"}{$dataenvr};
    if ( $osuser ) {
        $dbitrace_file = $dbitrace_base . '_' . $osuser . $log_ext;
    }
    $dbitrace_filefull = $path_log_dir.$dbitrace_file;

    ## load data structures
    @databases = split m/,/, $conf_data{'databases'}{'databases'};
    @dat_envrs = split m/,/, $conf_system{'system'}{'dat_envrs'};
    @job_acros = split m/,/, $conf_system{'system'}{'job_acros'};

    foreach my $db ( @databases ) {
        $dbname{$db} = $conf_data{'names'}{$db};
    }
    foreach my $db ( @databases ) {
        $dbdefenvr{$db} = $conf_data{'default '.$dataenvr}{$db};
    }
    foreach my $db ( @databases ) {
        $dbhandles{$db}{'dbh'} = 0;
        $dbhandles{$db}{'sth'} = 0;
    }
    foreach my $db ( @databases ) {
        $dbinst{$db} = $conf_data{'instances'}{$db};
    }
    foreach my $db ( @databases ) {
        foreach my $inst ( split m/,/, $conf_data{'instances'}{$db} ) {
            $dbconn{$db}{$inst}{'netservice'} = $conf_data{"$db $inst"}{'netservice'};
            $dbconn{$db}{$inst}{'database'  } = $conf_data{"$db $inst"}{'database'};
            $dbconn{$db}{$inst}{'username'  } = $conf_data{"$db $inst"}{'username'};
            $dbconn{$db}{$inst}{'password'  } = $conf_data{"$db $inst"}{'password'};
        }
    }

    return 0;
}

sub _sys_job_init {
=begin wiki

!3 _sys_job_init

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $rtconf = $path_conf_dir.'/'.$jobname.'.'.$pid.'.running';

    ## create runtime conf file
    open my $cfile, '>', $rtconf or sys_die( "Error creating runtime jobconf file" );
    close $cfile;

    my $conf = new Config::IniFiles( -file => $rtconf );
    unless ( defined $conf ) { sys_die( "Error opening runtime jobconf file" ); }

    my $starttime = time;
    $conf->newval( 'pid', 'pid', $pid );
    $conf->newval( 'starttime', 'starttime', $starttime );
    $conf->newval( 'restart', 'restart', 0 );
    $conf->RewriteConfig;
    return 0;
}

sub _sys_job_end {
=begin wiki

!3 _sys_job_end

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $rtconf = $path_conf_dir.'/'.$jobname.'.'.$pid.'.running';
    if ( -e $rtconf ) {
        unlink $rtconf;
    }
    return 0;
}

sub _sys_job_dependent {
=begin wiki

!3 _sys_job_dependent

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $dependent_jobname = shift;
    return 0 unless $dependent_jobname;

    my $conf = new Config::IniFiles( -file => $path_conf_dir.'/sys_environment.conf' );
    unless ( defined $conf ) { sys_die( "Error opening sys_environment.conf (4)" ); }
    my $params = join '~', $conf->Parameters( 'jobs' );
    if ( $params =~ m/$dependent_jobname/x ) {   ## case sensitive
        ## one or more instances of dependent job is currently running
        log_info( "Job name $dependent_jobname is active in the system, waiting" );
        return 1;
    }
    return 0;
}

sub _sys_read_conf {
=begin wiki

!3 _sys_read_conf

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $conf = shift;
    my $conf_filefull = $path_conf_dir . '/' . $conf;

    my $msg1 = "Probably syntax error, unable to load";

    if ( $conf =~ m/^sys_data/x ) {
        tie %conf_data, 'Config::IniFiles', ( -file => $conf_filefull )
            or sys_die( "$msg1 data conf: $conf", 0 );
    }
    if ( $conf =~ m/^sys_log/x ) {
        tie %conf_log, 'Config::IniFiles', ( -file => $conf_filefull )
            or sys_die( "$msg1 log conf: $conf", 0 );
    }
    if ( $conf =~ m/^sys_mail/x ) {
        tie %conf_mail, 'Config::IniFiles', ( -file => $conf_filefull )
            or sys_die( "$msg1 mail conf: $conf", 0 );
    }
    if ( $conf =~ m/^sys_common/x ) {
        tie %conf_query, 'Config::IniFiles', ( -file => $conf_filefull )
            or sys_die( "$msg1 query conf: $conf", 0 );
    }
    if ( $conf =~ m/^sys_util/x ) {
        tie %conf_util, 'Config::IniFiles', ( -file => $conf_filefull )
            or sys_die( "$msg1 util conf: $conf", 0 );
    }
    if ( $conf =~ m/^sys_environment/x ) {
        tie %conf_system, 'Config::IniFiles', ( -file => $conf_filefull )
            or sys_die( "$msg1 environment conf: $conf", 0 );
    }
    if ( $conf =~ m/^sys_test/x ) {
        tie %conf_job, 'Config::IniFiles', ( -file => $conf_filefull )
            or sys_die( "$msg1 test conf: $conf", 0 );
    }
    if ( $conf =~ m/^sys_de/x ) {
        tie %conf_de, 'Config::IniFiles', ( -file => $conf_filefull )
            or sys_die( "$msg1 de conf: $conf", 0 );
    }
    if ( $conf =~ m/^sys_run_controls/x ) {
        tie %conf_rcontrols, 'Config::IniFiles', ( -file => $conf_filefull )
            or sys_die( "$msg1 run controls conf: $conf", 0 );
    }
    ## job specific conf file
    if ( $conf !~ m/^sys_/x ) {
        tie %conf_job, 'Config::IniFiles', ( -file => $conf_filefull )
            or sys_die( "$msg1 job conf: $conf", 0 );
    }
    return 0;
}

sub _sys_read_job {
=begin wiki

!3 _sys_read_job

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    if ( $conf_job{job}{'logfile'} ) {
        $log_file = $conf_job{job}{'logfile'};
    }
    if ( $conf_job{job}{'logging_levels'} ) {
        $log_logging_levels = $conf_job{job}{'logging_levels'};
    }
    if ( $conf_job{job}{'console_levels'} ) {
        $log_console_levels = $conf_job{job}{'console_levels'};
    }
    if ( $conf_job{job}{'log_gdg'} ) {
        $log_gdg = $conf_job{job}{'log_gdg'};
    }
    if ( $conf_job{job}{'log_prefix'} ) {
        $log_prefix = $conf_job{job}{'log_prefix'};
    }
    if ( $conf_job{job}{'emailto'} ) {
        $mail_emailto = $conf_job{job}{'emailto'};
    }
    if ( $conf_job{job}{'pagerto'} ) {
        $mail_pagerto = $conf_job{job}{'pagerto'};
    }
    if ( $conf_job{job}{'email_levels'} ) {
        $mail_email_levels = $conf_job{job}{'email_levels'};
    }
    if ( $conf_job{job}{'pager_levels'} ) {
        $mail_pager_levels = $conf_job{job}{'pager_levels'};
    }
    return 0;
}

sub _sys_init_source_validation {
=begin wiki

!3 _sys_init_source_validation

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    open my $fh, "<", $script_filefull
        || sys_die( "Unable to open $script_file for validatation", 0 );
    my @r = <$fh>;
    close $fh;
    my $source = join '', @r;

    my $errm1 = "$script_file failed source validation, id tag ";
    my $errm2 = "$script_file failed source validation, pod section ";
    my $errm3 = " is missing or invalid";
    my $checkfor;

    $checkfor = "FILENAME";
    $source =~ m/^\#\#@@.*/m
        or sys_die( $errm1.$checkfor.$errm3, 0 );

    $checkfor = "SOURCETITLE";
    $source =~ m/^\#\#\$\$.*/m
        or sys_die( $errm1.$checkfor.$errm3, 0 );

    $checkfor = "NAME";
    $source =~ m/^!1 $checkfor\n\n[A-Za-z]/m
        or sys_die( $errm2.$checkfor.$errm3, 1 );

    $checkfor = "DESCRIPTION";
    $source =~ m/^!1 $checkfor\n\n[A-Za-z]/m
        or sys_die( $errm2.$checkfor.$errm3, 1 );

    $checkfor = "RECOVERY NOTES";
    $source =~ m/^!1 $checkfor\n\n[A-Za-z]/m
        or sys_die( $errm2.$checkfor.$errm3, 1 );

    $checkfor = "ENVIRONMENT NOTES";
    $source =~ m/^!1 $checkfor\n\n[A-Za-z]/m
        or sys_die( $errm2.$checkfor.$errm3, 1 );

    $checkfor = "DEPENDENCIES";
    $source =~ m/^!1 $checkfor\n\n[A-Za-z]/m
        or sys_die( $errm2.$checkfor.$errm3, 1 );

    $checkfor = "HISTORY";
    $source =~ m/^!1 $checkfor\n\n[A-Za-z0-9\*]/m
        or sys_die( $errm2.$checkfor.$errm3, 1 );

    return 0;
}

sub _sys_run_background {
=begin wiki

!3 _sys_run_background

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    if ( $OSNAME eq 'MSWin32' ) {
        sys_die( 'Background run mode not available on Windows', 0 );
    }
    $opt_commandline =~ s{-rb }{-r };
    $opt_commandline =~ s{-rb$}{-r};
    print "$script_filefull $opt_commandline".' &';
    exit 0;
}

sub _sys_run_scheduled {
=begin wiki

!3 _sys_run_scheduled

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    ## this die is temporary should use sys_die
    die "Not yet implemented\n\n";
}

sub _sys_run_de {
=begin wiki

!3 _sys_run_de

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $de = shift;
    my $conf_file = $jobname . '.' . $de . '.conf';
    _sys_read_conf( $conf_file );  ## tie %conf_job to job specific conf file
    _sys_read_job();  ## read job specific settings from %conf_job
    return 0;
}

sub _sys_run_restart {
=begin wiki

!3 _sys_run_restart

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    ## this die is temporary should use sys_die
    die "Not yet implemented\n\n";
}

sub _sys_forkexec {
=begin wiki

!3 _sys_forkexec

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my ($jobname, @params) = @_;
    my $pid;
    if ( $pid = fork ) {
        return $pid;
        ## this is the parent, so return the pid, everything below here is
        ## either the child or a major system failure
    }
    elsif ( defined $pid ) {
        exec $jobname, @params;
        ## shouldn't reach this unless exec fails, we exit here (not return)
        ## becuase we are in the child
        exit 0;
    } else {
        log_warn( "Could not fork $!" );
        return 0;
    }
}

sub _sys_reap_child {
=begin wiki

!3 _sys_reap_child

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $pid = 0;
    if ( ($pid = waitpid(-1, 0)) > 0 ) {
        $pidlib{$pid}{retcd} = $? >> 8;
    }
    return $pid;
}

sub _sys_test_dbcon {
=begin wiki

!3 _sys_test_dbcon

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $connections = shift;
    ## open dbi trace file
    DBI->trace(1, $dbitrace_filefull );
    foreach my $connectdef ( split m/,/, $connections ) {
        my ($db, $inst) = split m/:/, $connectdef;
        _check_array_val( $db, \@databases )
            || sys_die( "Invalid database: [$db]", 0 );
        _check_array_val( $inst, [split m/,/, $dbinst{$db}] )
            || sys_die( "Invalid database instance: [$db.$inst]", 0 );
        my $database = $dbconn{$db}{$inst}{'database'};
        my $username = $dbconn{$db}{$inst}{'username'};
        my $password = $dbconn{$db}{$inst}{'password'};
        print "Connecting to: $db/$inst\n";
        my $dbh = DBI->connect( $database, $username, $password, { RaiseError => 0, AutoCommit => 0 } )
            or sys_die( DBI->errstr, 0 );
        ## push resulting handle onto handle stack for cleanup on exit
        $dbhandles{$db}{'dbh'} = $dbh;
        print "Success\n\n";
    }
    exit 0;
}

sub _sys_check_severity_levels {
=begin wiki

!3 _sys_check_severity_levels

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $lvls_str = shift;

    ## levls_str can be either a single value or a comma delimited list
    if ( $lvls_str =~ /,/ ) {
        ## received a list of severity levels
        my @loglvls = split m/,/, $lvls_str;
        foreach my $level ( @loglvls ) {
            if ( $level !~ /FATAL|ERROR|WARN|INFO|DEBUG|NONE/ ) {
                sys_die( 'Invalid logging/notification severity list', 0 );
            }
        }
        return $lvls_str;
    } else {
        ## received a single severity level to be translated to a list
        if ( $lvls_str =~ /^FATAL$/i ) {
            $lvls_str = 'FATAL';
            return $lvls_str;
        }
        if ( $lvls_str =~ /^ERROR$/i ) {
            $lvls_str = 'FATAL,ERROR';
            return $lvls_str;
        }
        if ( $lvls_str =~ /^WARN$/i ) {
            $lvls_str = 'FATAL,ERROR,WARN';
            return $lvls_str;
        }
        if ( $lvls_str =~ /^INFO$/i ) {
            $lvls_str = 'FATAL,ERROR,WARN,INFO';
            return $lvls_str;
        }
        if ( $lvls_str =~ /^DEBUG$/i ) {
            $lvls_str = 'FATAL,ERROR,WARN,INFO,DEBUG';
            return $lvls_str;
        }
        if ( $lvls_str =~ /^NONE$/i ) {
            $lvls_str = '';
            return $lvls_str;
        }
        sys_die( 'Invalid logging/notification severity level', 0 );
    }
    return 0;
}

sub _sys_check_log_gdg {
=begin wiki

!3 _sys_check_log_gdg

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    if ( $opt_log_gdg =~ /[0-9]{1,3}/ ) {
        sys_die( 'Invalid log gdg specified', 0 );
    }
    return $opt_log_gdg;
}

sub _sys_check_log_radix {
=begin wiki

!3 _sys_check_log_radix

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    if ( $opt_log_radix < 1 || $opt_log_radix > 4 ) {
        sys_die( 'Invalid log radix specified', 0 );
    }
    return $opt_log_radix;
}

sub _sys_check_de_override {
=begin wiki

!3 _sys_check_de_override

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $tmp_jobname = shift;
    my $tmp_jobconf_file = $tmp_jobname;
    my $delist = $conf_de{jobname}{$tmp_jobname};
    if ( $delist ) {   ## possible override of job conf
        my $de = '0000';
        if ( $delist =~ /(\d\d\d\d\d)\s?$/ ) {
            $de = $1;
        }
        my $overenvs = $conf_de{$de}{'env'};
        if ( $overenvs =~ /$dataenvr/i ) {
            ## as a side-effect, sys_jobconf_override gets set here...
            $sys_jobconf_override = 1;   ## so we know override is effective
            $tmp_jobconf_file .= ".$de";
        }
    }
    return $tmp_jobconf_file;
}

sub _sys_disp_logprev {
=begin wiki

!3 _sys_disp_logprev

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    if ( $opt_log_file ) { $log_file = $opt_log_file; }
    $log_filefull = $path_log_dir . $log_file;
    if ( -e $log_filefull ) {
        print "Log: $log_filefull\n";
        system "cat $log_filefull";
        print "\n";
        exit 0;
    }
    print "No previous log file found\n\n";
    return 0;
}

sub _sys_disp_logarch {
=begin wiki

!3 _sys_disp_logarch

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    if ( $opt_log_file ) { $log_file = $opt_log_file; }
    $log_filefull = $path_log_dir . $log_file;
    my @logs = glob $log_filefull . '.*';
    if ( @logs ) {
        foreach my $log ( sort @logs ) {
            print "Log: $log\n";
            system "cat $log";
        }
        print "\n";
        exit 0;
    }
    print "No archived log files found\n\n";
    return 0;
}

sub _sys_disp_jobs {
=begin wiki

!3 _sys_disp_jobs

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my @jobs = glob $path_bin_dir.'*.pl';
    if ( @jobs ) {
        foreach my $job ( sort @jobs ) {
            my $description = 'No description found';
            open my $fh, "<", $job or sys_die( "Unable to open $job", 0 );
            while ( <$fh> ) {
                chomp;
                if ( /^\#\#\$\$/ ) {
                    $description = substr $_, 4;
                }
            }
            close $fh;
            $job =~ s{^\/.*\/}{};
            print "Job: $job\n";
            print "     $description\n";
        }
        print "\n";
        exit 0;
    }
    print "No archived job files found\n\n";
    return 0;
}

sub _sys_disp_active_jobs {
=begin wiki

!3 _sys_disp_active_jobs

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $logging = shift;  ## needs implementing

    my @actjobs = glob $path_conf_dir.'/*.running';
    print 'Jobs currently active: ' . scalar @actjobs . "\n";
    if ( @actjobs ) {
        foreach my $job ( sort @actjobs ) {
            my $conf = new Config::IniFiles( -file => $job );
            unless ( defined $conf ) { sys_die( "Error opening $job" ); }
            my $pid = $conf->val( 'pid', 'pid' );
            ## NOTE: use Unix::PID to determine if pid is still runninng...
            ## If pid is no longer running, replace "Job:" with "???:".
            my $starttime = $conf->val( 'starttime', 'starttime' );
            my $fmtdtime = time2str( '%Y/%m/%d %T', $starttime );
            $job =~ s{^\/.*\/}{};
            $job =~ s{\.\d+\.running$}{};
            print "Job: $job\n";
            print "     pid=$pid\n";
            print "     starttime=$fmtdtime\n";
            $conf = undef;
        }
    }
    print "\n";
    exit 0;
}

sub _sys_disp_doc {
=begin wiki

!3 _sys_disp_doc

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    if ( -e $script_filefull ) {
        my %podparams = (
            infile  => $script_filefull,
            outfile => "STDOUT",
        );
        wikipod2text( %podparams );
    } else {
        print "File not found $script_filefull\n\n";
    }
    exit 0;
}

sub _sys_disp_sql {
=begin wiki

!3 _sys_disp_sql

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my @query_names = keys %{$conf_query{$jobname}};
    if ( @query_names ) {
        foreach my $query_name ( sort @query_names ) {
            my $query = $conf_query{$jobname}{$query_name};
            print "Query: $query_name\n";
            print $query;
            print "\n\n";
        }
    } else {
        print "No querys found\n\n";
    }
    exit 0;
}

sub _sys_disp_params {
=begin wiki

!3 _sys_disp_params

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $dblen = 0;
    foreach my $db ( @databases ) {
        if ( length $dbname{$db} > $dblen ) { $dblen = length $dbname{$db}; }
    }
    print "\n" . uc($dataenvr) . " Database Connections:\n";
    foreach my $db ( @databases ) {
        my $dbstr =  sprintf "%-${dblen}s", $dbname{$db};
        $dbstr .= ' = ' . $db . '/' . $dbdefenvr{$db};
        print "    $dbstr\n",;
    }

    print "\n" . uc($dataenvr) . " Job Settings:\n";
    print "    Job Name           = ", $jobname, "\n";
    print "    Log File           = ", $log_file, "\n";
    print "    Log Logging Levels = ", $log_logging_levels, "\n";
    print "    Log Console Levels = ", $log_console_levels, "\n";
    print "    Log Gdg            = ", $log_gdg, "\n";
    print "    Path Bin Dir       = ", $path_bin_dir, "\n";
    print "    Path Log Dir       = ", $path_log_dir, "\n";
    print "    Path Lib Dir       = ", $path_lib_dir, "\n";
    print "    Path Conf Dir      = ", $path_conf_dir, "\n";
    print "    Path Plugin Dir    = ", $path_plugin_dir, "\n";
    print "    Path Load Dir      = ", $path_load_dir, "\n";
    print "    path Extract Dir   = ", $path_extr_dir, "\n";
    print "    path Prev Dir      = ", $path_prev_dir, "\n";
    print "    path Scripts Dir   = ", $path_scripts_dir, "\n";
    print "    Mail Server        = ", $mail_server, "\n";
    print "    Mail Email From    = ", $mail_from, "\n";
    print "    Mail Email To      = ", $mail_emailto, "\n";
    print "    Mail Pager To      = ", $mail_pagerto, "\n";
    print "    Mail Email Levels  = ", $mail_email_levels, "\n";
    print "    Mail Pager Levels  = ", $mail_pager_levels, "\n";
    print "\n";
    exit 0;
}

sub _sys_send_email_message {
=begin wiki

!3 _sys_send_email_message

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $params = shift;
    my ($addrlist, $message) = split m/~/, $params;
    $mail_emailto = $addrlist;
    _log_send_mail($message, 'MESSAGE');
    exit 0;
}

sub _sys_send_pager_message {
=begin wiki

!3 _sys_send_pager_message

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $params = shift;
    my ($addrlist, $message) = split m/~/, $params;
    $mail_pagerto = $addrlist;
    _log_send_page($message, 'MESSAGE');
    exit 0;
}

sub _sys_help {
=begin wiki

!3 _sys_help

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $verbose = shift;
    $verbose = 0 unless $verbose;
    my $section;

    if ( $verbose == 0 ) {
        print "\nUSAGE\n      $script_file [options]\n\n";
        print "Use option -h   for help with options\n";
        print "Use option -hp  for help with option parameters\n";
        print "Use option -man for system documentation\n";
        exit 1;
    }

    if ( $verbose == 1 ) { $section = 'OPTIONS'; };
    if ( $verbose == 2 ) { $section = 'ARGUMENTS'; };

    print "\n";
    my %podparams = (
        infile  => $path_lib_dir."DBIx/JCL.pm",
        outfile => "STDOUT",
        section => $section,
    );
    wikipod2text( %podparams );
    exit 1;
}

sub _log_init_log_file {
=begin wiki

!3 _log_init_log_file

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    ## log file rotation if generations > 0
    if ( -e $log_filefull && $log_gdg > 0 ) {
        _log_rotate();
    }

    ## create new locked log file
    ## if the file is already locked, will wait until the file is unlocked
    my $fh = new IO::LockedFile(">$log_filefull")
        or sys_die( 'Failed opening log file', 0 );
    ## close and unlock the file
    $fh->close();

    $sys_log_open = 1;

    return 0;
}

sub _log_write_to_log {
=begin wiki

!3 _log_write_to_log

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my ($level, $force, $msg, $exmsg) = @_;
    my ($message,$exmessage);

    if ( ref $exmsg eq 'ARRAY' ) {
        my $lead = ' ' x 18;
        $lead .= '+ ';
        my @output = map { $lead . $_ . "\n" } @{$exmsg};
        my $exmessage = join '', @output;
        $exmessage =~ s/\n$//ms;
        $message = $msg . "\n" . $exmessage;
    } else {
        $message = $msg;
        $message =~ s/\n/ /g;
    }

    if ( $log_logging_levels =~ /$level/ || $force ) {
        _log_print_log( $level, $message );
    }

    _log_send_notifications( $level, $force, $msg );

    return 0;
}

sub _log_write_to_screen {
=begin wiki

!3 _log_write_to_screen

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my ($level, $force, $msg, $exmsg) = @_;
    my ($message,$exmessage);

    if ( ref $exmsg eq 'ARRAY' ) {
        my $lead = ' ' x 18;
        $lead .= '+ ';
        my @output = map { $lead . $_ . "\n" } @{$exmsg};
        my $exmessage = join '', @output;
        $message = $msg . "\n" . $exmessage;
    } else {
        $message = $msg;
        $message =~ s/\n/ /g;
    }

    $message = _log_trim_msg( $message );

    if ( $opt_verbose ) {
        print "$message\n";
    } else {
        if ( $log_console_levels =~ /$level/ || $force ) {
            print "$message\n";
        }
    }

    return 0;
}

sub _log_print_log {
=begin wiki

!3 _log_print_log

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my ($level, $message) = @_;

    my $preamble = time2str( '%Y/%m/%d %T', time );
    if ( $level eq 'FATAL' ) { $preamble .= ' FATAL'; }
    if ( $level eq 'ERROR' ) { $preamble .= ' ERROR'; }
    if ( $level eq 'WARN'  ) { $preamble .= ' WARNING'; }

    ## open locked log file for appending
    ## if the file is already locked, will wait until the file is unlocked
    my $fh = new IO::LockedFile(">>$log_filefull")
        or sys_die( 'Failed opening log file', 0 );
    print {$fh} "$preamble $message\n";
    ## close and unlock the file
    $fh->close();
    return 0;
}

sub _log_trim_msg {
=begin wiki

!3 _log_trim_msg

Parameters: ( message )

Format log file text so that it looks good when printed to STDOUT.  This \
function is only called from the logging functions. This takes message \
text that was previously retrieved by dbms_output_get and stringified by \
a logging function and removes the leading whitespace from each line of \
text, if there is any. This is made necessary due to the fact that this \
text started life as an array of lines retrieved from dbms_output_get(), \
and each of these lines had leading whitespace to make them more readable \
in the log file.

Returns:

=cut
    my $msg = shift;
    my $trimmed = '';
    if ( $msg =~ /\n/ms ) {   ## trim leading spaces from multi-line messages
        foreach my $m ( split m/\n/, $msg ) {
            $m =~ s/^\s+//;
            $trimmed .= $m."\n";
        }
        $trimmed =~ s/\n$//ms;
    } else {
        $trimmed = $msg;
    }
    return $trimmed;
}

sub _log_send_notifications {
=begin wiki

!3 _log_send_notifications

Parameters: ( message, severity_level )

Send email and pager notifications based on supplied severity. If the \
severity levels for email and or pager notifications are at or below the \
severity level supplied to this function, a notification will be sent.

Note: if running under test harness (different than test mode), all \
messages are logged, but no notifications of any severity will be generated. \
Generation of actual email and pager notices is not testable using the test \
harness.

Returns:

=cut
    my ($level, $force, $message) = @_;

#    if ( $tst_harness ) {
#        return 0;
#    }

    if ( $mail_email_levels =~ /$level/ || $force ) {
        _log_send_mail( $message, $level );
    }
    if ( $mail_pager_levels =~ /$level/ || $force ) {
        _log_send_page( $message, $level );
    }
    return 0;
}

sub _log_send_mail {
=begin wiki

!3 _log_send_mail

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my ($message, $severity) = @_;
    return 0 unless $mail_emailto;
    return 0 if $mail_emailto =~ /NONE/i;

    my ($subject, $job);

    if ( $severity eq 'MESSAGE' ) {
        $subject = 'Message from ' . uc $dataenvr;
    } else {
        $subject = uc($dataenvr). ' Batch Notice';
        $message = time2str("%Y/%m/%d %H:%M:%S : ", time) . uc($severity) . " : $script_file : $message";
    }

    ## get the log file contents and append to message
    if ( ! $severity eq 'MESSAGE' ) {
        if ( -e $log_filefull ) {
            $message .= "\nLog Entries:\n";
            open my $fh, "<", $log_filefull;
            while ( <$fh> ) {
                $message .= $_;
            }
            close $fh;
        }
    }

    MIME::Lite->send('smtp', $mail_server, Timeout => 60);

    my $msg = MIME::Lite->new(
        From     => $mail_from,
        To       => $mail_emailto,
        Subject  => $subject,
        Data     => $message
    );
    $msg->send;
    return 0;
}

sub _log_send_page {
=begin wiki

!3 _log_send_page

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my ($message, $severity) = @_;
    return 0 unless $mail_pagerto;
    return 0 if $mail_pagerto =~ /NONE/i;

    my ($subject, $job);

    if ( $severity eq 'MESSAGE' ) {
        $subject = 'Message from ' . uc $dataenvr;
    } else {
        my $subject = uc($dataenvr). ' Batch Notice';
        $message = time2str("%Y/%m/%d %H:%M:%S : ", time) . uc($severity) . " : $script_file : $message";
    }

    MIME::Lite->send('smtp', $mail_server, Timeout => 60);

    my $msg = MIME::Lite->new(
        From     => $mail_from,
        To       => $mail_pagerto,
        Subject  => $subject,
        Data     => $message
    );
    $msg->send;
    return 0;
}

sub _log_rotate {
=begin wiki

!3 _log_rotate

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my ($prev,$next,$i,$j);

    my $curr = $log_filefull;
    my $currn = $curr;

    for ($i = $log_gdg; $i > 1; $i--) {
        $j = $i - 1;
            my $nextgen = sprintf("%0${log_radix}d", $i);
            my $prevgen = sprintf("%0${log_radix}d", $j);
            $next = "${currn}." . $nextgen; ##. $ext;
            $prev = "${currn}." . $prevgen; ##. $ext;
        if ( -r $prev && -f $prev ) {
            move($prev,$next) or sys_die( "Log move failed: ($prev,$next)" );
        }
    }

    ## copy current to next incremental
    my $nextgen = sprintf("%0${log_radix}d", 1);
    $next = "${currn}." . $nextgen;
    copy($curr, $next);

    ## preserve permissions and status
    my @stat = stat $curr;
    chmod( $stat[2], $next )           or sys_warn( "log chmod failed: ($next)" );
    utime( $stat[8], $stat[9], $next ) or sys_warn( "log utime failed: ($next)" );
    chown( $stat[4], $stat[5], $next ) or sys_warn( "log chown failed: ($next)" );

    ## now truncate the file
    truncate $curr, 0 or sys_die( "Could not truncate $curr" );

    return 0;
}

sub _db_connect_check_dependent {
=begin wiki

!3 _db_connect_check_dependent

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my ($dependent_jobname,$wait_duration,$wait_max_secs,$wait_action) = @_;
    my $starttime = time;
    while ( 1 ) {
        if ( _sys_job_dependent($dependent_jobname) ) {
            sleep $wait_duration;
            my $curtime = time;
            if ( $curtime - $starttime > $wait_max_secs ) {
                if ( $wait_action =~ m/^run$/ix ) {
                    log_info( "Maximum dependent job wait time exceeded, starting" );
                    last;
                } else {
                    sys_die( "Maximum dependent job wait time exceeded, aborting" );
                    return 1;   ## reachable if $sys_test_harness
                }
            }
        } else {
            last;
        }
    }
    return 0;
}

sub _db_connect_retry {
=begin wiki

!3 _db_connect_retry

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my ($db,$un,$pw,$retry_duration,$retry_max_secs) = @_;
    my $dbh = 0;
    my $starttime = time;
    while ( 1 ) {
        $dbh = DBI->connect( $db, $un, $pw, { RaiseError => 0, AutoCommit => 0 } );
        if ( DBI->errstr ) {
            if ( $retry_max_secs < 1 ) {
                sys_die( DBI->errstr );
                return 1;   ## reachable if $sys_test_harness
            }
            if ( DBI->err == 1017 ) {   ## ora invalid account or password
                sys_die( DBI->errstr );
                return 1;   ## reachable if $sys_test_harness
            }
            log_info( DBI->errstr );
            log_info( "Connection retry requested, waiting" );
            sleep $retry_duration;
            my $curtime = time;
            if ( $curtime - $starttime > $retry_max_secs ) {
                sys_die( "Maximum connection retry time exceeded, aborting" );
                return 1;   ## reachable if $sys_test_harness
            }
        } else {
            last;
        }
    }
    return $dbh;
}

sub _db_vdn {
=begin wiki

!3 _db_vdn

Parameters: ( caller_id_string, vdn )

This function accepts a caller id string and a virtual database name. A \
virtual database name is a text string which identifies a database \
connection. If we are running in test mode and the caller is not the \
db_connect function, this function will gracefully shut-down. Otherwise \
it returns either raw database connection information or it returns the \
appropriate database handle and statement handle for the named database.

Returns:

=cut
    my ($caller, $vdn) = @_;

    my $sth_name = 'sth_default';  ## default statement handle name

    ## does vdn contains explicit statement handle?
    if ( $vdn =~ /\./ ) {
        ($vdn, $sth_name) = split /\./, $vdn;
    }

    my ($this_db, $this_inst);

    if ( $vdn =~ m/:/x ) {  ## does vdn contain explicit instance?
        ($this_db, $this_inst) = split m/:/, $vdn;
    } else {
        $this_db = $vdn;
        $this_inst = $dbdefenvr{$vdn};
    }

    if ( ! $dbname{$this_db} ) {
        sys_die( "Virtual database name [$vdn] is invalid" );
    }

    ## special return values if caller is 'connect'
    if ( $caller eq 'connect' ) {
        my $database = $dbconn{$this_db}{$this_inst}{'database'};
        my $username = $dbconn{$this_db}{$this_inst}{'username'};
        my $password = $dbconn{$this_db}{$this_inst}{'password'};
        return ($database, $username, $password);
    }

#    ## shutdown gracefully if running under the 'test connections' flag
#    if ( $opt_test ) {
#        log_close( "End connection test: $jobname" );
#        sys_end();
#        exit 0;
#    }

    ## return database and statement handles for this vdn
    my $dbh = $dbhandles{$this_db}{'dbh'};
    my $sth = $dbhandles{$vdn}{$sth_name};
    return ($dbh, $sth);
}

sub _db_netservice {
=begin wiki

!3 _db_netservice

Parameters: ( vdn )

This function accepts a virtual database name that contains an explicit \
instance. A virtual database name is a text string which identifies a \
database connection. The "network service", i.e., remote database \
connection string is returned from sys_data.conf for the provided instance.

Returns:

=cut
    my ($vdni) = shift;

    my $netservice = '';

    if ( $vdni =~ m/:/x ) {  ## vdn contains instance definiton
        my ($db, $inst) = split m/:/, $vdni;
        _check_array_val( $db, \@databases )
            || sys_die( "Invalid database: [$db]", 0 );
        _check_array_val( $inst, [split m/,/, $dbinst{$db}] )
            || sys_die( "Invalid database instance: [$db.$inst]", 0 );
        $netservice = $dbconn{$db}{$inst}{netservice};
    }

    return $netservice;
}

sub _db_proc_build_sql {
=begin wiki

!3 _db_proc_build_sql

Parameters: ( package_name, procedure_name, parameters)

* /parameters/ - parameters is a reference to an array

This function builds a sql statement to execute an Oracle Stored Procedure. \
The sql statement uses generated variable names, e.g., :p1, :p2, :p3, etc. \
This works because functions that use this sql statement all pass parameters \
to the requested stored procedure positionally. The function accepts a \
reference to an array of param in parameters. This is used only to get a \
count of the number of parameters in the procedure's signature.

Returns:

=cut
    my ($package, $proc_name, $params) = @_;
    my $numparams = scalar @{$params};
    if ( $package ) { $proc_name = $package . '.' . $proc_name; }

    my $sql = 'BEGIN ' . $proc_name . '(';
    for my $i ( 0 .. $numparams - 1 ) {
        $sql .= ':p'.$i;
        if ( $i < $numparams - 1 ) { $sql .= ','; }
    }
    $sql .= '); END;';
    return $sql;
}

sub _db_sqlloaderx_parse_logfile {
=begin wiki

!3 _db_sqlloaderx_parse_logfile

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $logfile = shift;
    %sqlloader_results = ();  ## hash of SQL*Loader results

    ## default values
    $sqlloader_results{'skipped'}      = "Problem obtaining value";
    $sqlloader_results{'read'}         = $sqlloader_results{'skipped'};
    $sqlloader_results{'rejected'}     = $sqlloader_results{'skipped'};
    $sqlloader_results{'discarded'}    = $sqlloader_results{'skipped'};
    $sqlloader_results{'elapsed_time'} = $sqlloader_results{'skipped'};
    $sqlloader_results{'cpu_time'}     = $sqlloader_results{'skipped'};

    my $log = new IO::File "<$logfile";
    if (! defined $log) {
        sys_warn( "Failed to open SQL*Loader log file $logfile" );
        return 1;
    }

    ## skip the first line, check the second for the SQL*Loader declaration
    my $line = <$log>;
    $line = <$log>;
    unless ($line =~ /^SQL\*Loader/) {
        sys_warn( 'File does not appear to be a valid SQL*Loader log file' );
        return 1;
    }

    while (<$log>) {
        chomp;
        if ( m/^Total logical records skipped:\s+(\d+)/ ) {
            $sqlloader_results{'skipped'} = $1;
            next;
        }
        if ( m/^Total logical records read:\s+(\d+)/ ) {
            $sqlloader_results{'read'} = $1;
            next;
        }
        if ( m/^Total logical records rejected:\s+(\d+)/ ) {
            $sqlloader_results{'rejected'} = $1;
            next;
        }
        if ( m/^Total logical records discarded:\s+(\d+)/ ) {
            $sqlloader_results{'discarded'} = $1;
            next;
        }
        if( m/^Elapsed time was:\s+(.+)/ ) {
            $sqlloader_results{'elapsed_time'} = $1;
            next;
        }
        if( m/^CPU time was:\s+(.+)/ ) {
            $sqlloader_results{'cpu_time'} = $1;
            next;
        }
    }

    $log->close;

    my @results;

    push @results, "Skipped: "      . $sqlloader_results{'skipped'};
    push @results, "Read: "         . $sqlloader_results{'read'};
    push @results, "Rejected: "     . $sqlloader_results{'rejected'};
    push @results, "Discarded: "    . $sqlloader_results{'discarded'};
    push @results, "Elapsed Time: " . $sqlloader_results{'elapsed_time'};
    push @results, "CPU Time: "     . $sqlloader_results{'cpu_time'};

    ## return ref to array of results
    return \@results;
}

sub _db_proc_bind_inparams {
=begin wiki

!3 _db_proc_bind_inparams

Parameters: ( statement_handle, parameters )

This function binds parameters to a prepared statement. The parameters are \
passed as a ref to an array. This uses the same parameter names as those \
defined by the build_sql function. All parameters are bound as type IN \
parameters.

Returns:

=cut
    my ($sth, $params) = @_;
    my $numparams = scalar @{$params};

    for my $i ( 0 .. $numparams - 1 ) {
        my $var = ':p'.$i;
        $sth->bind_param( $var, ${$params}[$i] );
    }
    return $sth;
}

sub _db_proc_bind_outparams {
=begin wiki

!3 _db_proc_bind_outparams

Parameters ( )

This function binds parameters to a prepared statement. The parameters are \
passed as a ref to an array. This uses the same parameter names as those \
defined by the build_sql function. All parameters are bound as type IN \
OUT/OUT parameters.

Returns:

=cut
    my ($sth, $params) = @_;
    my $numparams = scalar @{$params};

    for my $i ( 0 .. $numparams - 1 ) {
        my $var = ':p'.$i;
        $sth->bind_param_inout( $var, @{$params}[$i], 100 );
    }
    return $sth;
}

sub _db_proc_bind_inoutparams {
=begin wiki

!3 _db_proc_bind_inoutparams

Parameters: ( )

This function binds parameters to a prepared statement. The parameters are \
passed as a ref to an array. This uses the same parameter names as those \
defined by the build_sql function. All parameters are bound as type IN or \
as type IN OUT/OUT. If the user passes a ref as an array member, that element \
will be bound as IN OUT/OUT. If the users passes a scalar as an array member, \
that element will be bound as a type IN parameter.

Returns:

=cut
    my ($sth, $params) = @_;
    my $numparams = scalar @{$params};

    for my $i ( 0 .. $numparams - 1 ) {
        my $var = ':p'.$i;
        if ( ref @{$params}[$i] eq 'SCALAR' ) {
            $sth->bind_param_inout( $var, @{$params}[$i], 100 );
        } else {
            $sth->bind_param( $var, ${$params}[$i] );
        }
    }
    return $sth;
}

sub _db_is_oracle {
=begin wiki

!3 _db_is_oracle

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $vdn = shift;
    my $inst = $dbdefenvr{$vdn};
    my $database = $dbconn{$vdn}{$inst}{'database'};  ## e.g., dbi:Oracle:myinst
    if ( $database=~ /^dbi:Oracle:/ ) {
        return 1;
    }
    return 0;
}

sub _db_null {
=begin wiki

!3 _db_null

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my $val = shift;
    return '<NULL>' unless defined $val;
    return $val;
}

sub _db_query_to_file_protect {
=begin wiki

!3 _db_query_to_file_protect

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my ($row, $protect) = @_;

    return 0 if scalar @{$protect} < 1;

    foreach my $i ( @{$protect} ) {
        my $len = length @{$row}[$i];
        my $fil = '*'x$len;
        @{$row}[$i] = $fil;
    }

    return 0;
}

sub _check_array_val {
=begin wiki

!3 _check_array_val

Parameters: ( p1, p2, p3 )

Please write this documentation.

Returns:

=cut
    my ($val, $arr) = @_;
    if ( grep { $_ eq $val } @{$arr} ) {
        return 1;
    }
    return 0;
}

sub _trim {
=begin wiki

!3 _trim

Parameters: ( str )

Trim leading and trailing spaces from a string. Return the trimmed string.

Returns:

=cut
    my $str = shift;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    return $str;
}

sub _trim_lead {
=begin wiki

!3 _trim_lead

Parameters: ( str )

Trim leading spaces from a string. Return the trimmed string.

=cut
    my $str = shift;
    $str =~ s/^\s+//;
    return $str;
}

sub _trim_trail {
=begin wiki

!3 _trim_trail

Parameters: ( str )

Trim trailing spaces from a string. Return the trimmed string.

Results:

=cut
    my $str = shift;
    $str =~ s/\s+$//;
    return $str;
}

sub _is_yes {
=begin wiki

!3 _is_yes

Parameters: ( str )

Examing a string and determine if the string indicates 'YES'. The string is \
examined as case insensitive and must be either a 'y' or 'yes'. If so, the \
function returns true (1), otherwise it returns false (0).

You can use this as a conversion function to make tests simpler using a \
technique like this:

 % language=Perl
 % my $truth = 'Y';
 % $truth = _is_yes( $truth );
 % # later
 % if ( $truth ) {
 %     # do something
 % }
 %%

=cut
    my $str = shift;
    if ( $str =~ /^y$|^yes$/i ) { return 1; }
    return 0;
}

sub _is_no {
=begin wiki

!3 _is_no

Parameters: ( str )

Examing a string and determine if the string indicates 'NO'. The string is \
examined as case insensitive and must be either a 'n' or 'no' exactly. If so, \
the function returns true (1), otherwise it returns false (0).

Returns:

=cut
    my $str = shift;
    if ( $str =~ /^n$|^no$/i ) { return 1; }
    return 0;
}

sub END {
=begin wiki

!3 END

Parameters: None

Close all open statement handles and database handles. Statement handles and \
Database handles are stored for us by the database connection function. The \
end function in each loaded plugin is also called here. They are called in \
reverse load order. Send exit notifications if any have been requested.

Returns:

=cut
    ## remove job information from sys_environment.conf
    _sys_job_end();

    ## disconnect any open database handles
    foreach my $vdn ( keys %dbhandles ) {
        my $dbh = $dbhandles{$vdn}{'dbh'};
        my $sth = $dbhandles{$vdn}{'sth'};
        if ( defined $sth && $sth ) { $sth->finish; }
        if ( defined $dbh && $dbh ) { $dbh->disconnect; }
    }

    ## call plugin end functions
    while ( my $pluginf = pop @plugins ) {
        my ($pp, $pf, $pff) = split m/~/, $pluginf;
        $pp->end();
    }

    ## send completion notifications
    unless ( defined $jobname ) { $jobname = '?'; }
    my $msg = "Job $jobname ($script_file) has completed ($errorlevel).";
    if ( $opt_notify_email_oncomp ) {
        _log_send_mail($msg, 'MESSAGE' );
    }
    if ( $opt_notify_pager_oncomp ) {
        _log_send_page($msg, 'MESSAGE' );
    }
}

1;

=begin wiki

----

!1 Dependencies

The following modules are all used by DBIx-JCL.

* English
* Getopt::Long
* Config::IniFiles
* IO::File
* IO::Handle
* IO::LockedFile
* Fcntl
* File::Copy
* File::Bidirectional
* File::Basename
* MIME::Lite
* Date::Format
* Pod::WikiText
* DBI

----

!1 Incompatibilities

None currently documented. Please feel free to notify the author if you have \
concern that you would like to see addressed.

----

!1 Test Support

There are a number of test functions built-in to DBIx-JCL. Please see the \
function reference section for descriptions of all the testing functions.

----

!1 Tips

Here are some tips for using job scripts. (A job script is any perl script \
that uses the DBIx-JCL Module.

!2 Verbose and Very Verbose

If you are running jobs from the console and you want tactile feedback, use \
the Verbose C<-v> option. If your job is failing and your not sure why, turn \
on the Very Verbose C<-vv> option. Very Verbose gives you everything that \
Verbose gives you, plus more.

!2 Required Options

A "Run job" option is always required. This is to avoid accidentally invoking \
a job script.

!2 Built-in Display Features

There are several built-in display features that you will find useful. When \
you use the Help option, C<-h> and C<-ha>, these will be listed under the \
heading of "Information Options". The most useful is possibly the C<-dl> \
option, which will display the last log file generated by the script that you \
are currently running.

!2 Use the Test Options

Use the /-t/ option to invoke the job script and run it to the point of \
database connection and then exit after database connections have been made.

Use the /-tc/ option to test any database connection interactively without \
invoking the current job script. Very handy for diagnostic purposes.

!2 Multiple Database Connections

You can set up jobs that make multiple connections to the same database. To \
do that, you simply add another set of connection parameters in your data.conf \
file. So if for example you have a database named 'xyz1' in your list of \
databases in %data.conf%, add another database named 'xyz2' and duplicate all \
other connection parameters from 'xyz1' under the new key 'xyz2'.

!2 Global Variables

There are a number of global variables that are automatically imported into \
your script's namespace. These are listed below with a brief explanation of \
each.

* %$path_bin_dir        # path to bin directory%
* %$path_lib_dir        # path to lib directory%
* %$path_log_dir        # path to log directory%
* %$path_load_dir       # path to load directory%
* %$path_extr_dir       # path to extract directo%ry
* %$path_prev_dir       # path to store previous vrsion files%
* %$path_scripts_dir    # path to scripts directory%
* %$mail_server         # mail server address%
* %$mail_from           # from email address%
* %$mail_emailto        # email to address list%
* %$mail_pagerto        # pager to address list%
* %$mail_email_levels   # log levels which initiate email notifications%
* %$mail_pager_levels   # log levels which initiate pager notifications%
* %$log_file            # log file filename%
* %$log_filefull        # full path to log filename%
* %$log_logging_levels  # log levels which initiate log mesages%
* %$log_console_levels  # log levels which initiate console messages%
* %$log_gdg             # number of log archive files to maintain%

Default values for all of these are defined in system conf files. The value \
of many of these can be set at runtime using command line options.

A special global variable defines the current database environment. This is \
the $dataenvr variable.

----

!1 Source Code Validation

In order to help maintain consistency across an entire library of job \
scripts. Several aspects of script files are check for compliance before \
the job will be executed. The following rules are checked before a job \
will be run by DBIx-JCL

/Header Checks/

There must be valid %##@@% and %##$$% statements. These statements can be \
used to help manage script libraries. The %##$$% statement is also used by \
the display jobs option to provide a brief description of each job.

/Documentation Checks/

There needs to be valid Pod containing at least a DESCRIPTION section, a \
RECOVERY NOTES section, and a DEPENDENCIES section in each job script.

----

!1 File And Directory Permissions

This information is here to document one approach to file and directory \
permissions. You should not adopt these for your use without careful \
consideration and testing.

All files owned by the account which processes batch jobs should be set to \
permission level 750, which will give owner rwx, group r-x, and all others no \
access.

 % language=Ini_Files
 % >chmod 750 filename
 %
 % 7 - owner permissions (rwx) i.e., read & write & execute
 % 5 - group permissions (r-x) i.e., read & execute
 % 0 - world permissions (---) i.e., none
 %%

All directories owned by the account which processes batch jobs should \
normally be set to permission level 750.

Permission reference table:

|0 |--- |no access|
|1 |--x |execute|
|2 |-w- |write|
|3 |-wx |write and execute|
|4 |r-- |read|
|5 |r-x |read and execute|
|6 |rw- |read and write|
|7 |rwx |read write execute (full access)|

----

!1 Plugins

DBIx-JCL supports plugin modules using a simple plugin architecture. This \
will allow you to write your own modules and have them loaded at runtime to \
provide additional functionality for your job scripts. For example, you might \
want to write a module that uses http to turn off your web site before some \
processing in your batch job occurs.

Plugin modules are simple Perl modules with no exported functions or \
variables. Here is a trivial example of a plugin module:

 % language=Perl
 % package TestPlugin1;
 %
 % use strict;
 % use warnings;
 %
 % my $tp_num = 0;
 %
 % sub start {
 %     my ($path_conf_dir, $path_plugin_dir, $dataenvr) = @_;
 %     $tp_num = 100;
 %     print "TestPlugin1 start function\n";
 % }
 %
 % sub plugin_main {
 %     my $n = shift;
 %     $tp_num += $n;
 %     return $tp_num;
 % }
 %
 % sub tp_add {
 %     my $n = shift;
 %     $tp_num += $n;
 %     return $tp_num;
 % }
 %
 % sub end {
 %     print "TestPlugin1 end function\n";
 % }
 %
 % 1;
 %%

There are three functions that plugin modules are required to implement, a \
C<start()>, a C<plugin_main()>, and an C<end()>. The start and end functions \
are called automatically for you on load and script termination. The address \
to the C<plugin_main()> function is returned to you when your plugin is \
loaded. All of your plugin code can be implemented in C<plugin_main()>, or in \
additional functions that you supply. The decision will vary depending on \
your plugin's needs. All functions in your plugin module are callable, but \
the symantics vary.

!2 Loading your plugin

Your plugin is loaded using the C<sys_load_plugin()> function. This function \
takes two parameters, The file name used by your plugin (without the .pm \
extension) and the package name used by your plugin. All plugins need to be \
installed in a plugins directory which has been specified in the system.conf \
file. For example, if you created the plugin shown above and placed it in a \
file named TestPlugin1.pm, you would load the plugin like this:

    sys_init_plugin( 'TestPlugin1', 'TestPlugin1' );

or

    my $plugin1 = 'TestPlugin1';
    sys_init_plugin( $plugin1, $plugin1 );

!2 Calling functions in plugin modules

There are three ways (probably more) to call functions in your plugin.

B<I<Package name calling>>

Use the fully qualified package name and function name.

    sys_init_plugin( 'TestPlugin1', 'TestPlugin1' );

later

    TestPlugin1::tp_add(1);

B<I<Coderef to package name calling>>

If you are going to call your plugin from serveral places in your script, \
you might prefer to take this approach.

    sys_init_plugin( 'TestPlugin1', 'TestPlugin1' );
    my $plug_1 = \&TestPlugin1::tp_add;

later

    $plug_1->(1);

B<I<Using plugin_main()>>

Probably the simplest approach it to implement as much of your plugin's code \
as possible within the C<plugin_main()> function. Then use the supplied \
coderef to execute your plugin.

    my $plug1 = sys_init_plugin( 'TestPlugin1', 'TestPlugin1' );

later

    $plug1->(1);

----

!1 Exported Variables

The following variables are available for use in job scripts and are \
exported by default.

|!Variable             |Mod?|Description|
|%$path_bin_dir%       |No  |path to bin directory|
|%$path_lib_dir%       |No  |path to lib directory|
|%$path_log_dir%       |No  |path to log directory|
|%$path_load_dir%      |No  |path to load data directory|
|%$path_extr_dir%      |No  |path to extract data directory|
|%$path_prev_dir%      |No  |path to previous version files|
|%$path_scripts_dir%   |No  |path to scripts directory|
|%$mail_server%        |.   |mail server|
|%$mail_from%          |.   |mail from address|
|%$mail_emailto%       |.   |email to address list|
|%$mail_pagerto%       |.   |pager to address list|
|%$mail_email_levels%  |.   |email severity/notification levels|
|%$mail_pager_levels%  |.   |pager severity/notification levels|
|%$log_file%           |No  |name of log file|
|%$log_filefull%       |No  |full name including path of log file|
|%$log_logging_levels% |.   |severity levels for log file logging|
|%$log_console_levels% |.   |severity levels for console logging|
|%$log_gdg%            |.   |number of generations for log archiving|
|%$dataenvr%           |No  |environment variable which holds default datbase/instance |
|%$commandline_ext%    |No  |extra command variables passed to job script|
|%$errorlevel%         |No  |.|

Variables with "No" should not be modified.

----

!1 Bugs And Limitations

Please report all bugs to the author. Every attempt will be made to \
incorporate bug fixes into future releases of this package.

----

!1 Author

Brad Adkins brad.j.adkins@gmail.com.

You may contact the author regarding this module at dbijcl@gmail.com.

----

!1 License And Copyright

Copyright (c) 2008, Brad Adkins. All rights reserved.

This software may be freely distributed under the same terms as Perl itself.

----
=cut
