package App::MonM::ConfigSkel; # $Id: ConfigSkel.pm 134 2022-09-09 10:33:00Z abalama $
use strict;
use utf8;

=encoding utf8

=head1 NAME

App::MonM::ConfigSkel - Configuration skeleton for App::MonM

=head1 VIRSION

Version 1.02

=head1 SYNOPSIS

none

=head1 DESCRIPTION

Configuration skeleton for App::MonM

no public methods

=head2 build, dirs, pool

Main methods. For internal use only

=head1 SEE ALSO

L<App::MonM>, L<CTK::Skel>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use constant SIGNATURE => "config";

use vars qw/ $VERSION /;
$VERSION = '1.02';

sub build { # Building
    my $self = shift;

    my $rplc = $self->{rplc};
    $rplc->{ENDSIGN} = "__END__"; # END signature

    $self->maybe::next::method();
    return 1;
}
sub dirs { # Directories and permissions as array of hashs
    my $self = shift;
    $self->{subdirs}{(SIGNATURE)} = [
        {
            path => 'conf.d',
            mode => 0755,
        },
    ];
    $self->maybe::next::method();
    return 1;
}
sub pool { # Multipart pool of files
    my $self = shift;
    my $pos =  tell DATA;
    my $data = scalar(do { local $/; <DATA> });
    seek DATA, $pos, 0;
    $self->{pools}{(SIGNATURE)} = $data;
    $self->maybe::next::method();
    return 1;
}

1;

__DATA__

-----BEGIN FILE-----
Name: %PREFIX%.conf
File: %PREFIX%.conf
Mode: 644

#
# This file contains data for %PREFIX% configuration
# See Config::General for syntax details
#

#
# Expires of data in database
# Default: 1d
#
#Expires 1d

#
# Use extended notifier (monotifier)
# Default: no
#
#UseMonotifier no

#
# Activate or deactivate the logging: on/off (yes/no).
# Default: off
#
LogEnable on

#
# Defines log level
# Allowed levels: debug, info, notice, warning, error,
#     crit, alert, emerg, fatal, except
# Default: debug
#
LogLevel warning

#
# Defines LogIdent string
# Default: none
#
LogIdent %PREFIX%

#
# Defines path to custom log file
# Default: use syslog
#
#LogFile /var/log/%PREFIX%.log

#
# Defines workers number
#
# Default: 3
#
#Workers 3

#
# Defines worker interval. This interval determines how often
# the cycle of checks will be started.
#
# Default: 20
#
#Interval 20

#
# Defines a username and groupname for daemon working
#
# Default: monmu
#
#DaemonUser monmu
#DaemonGroup monmu

#
# MonM database options
#
# NOTE! Before using the third-party database, please create the monm table
#
#-- For SQLite DB
#CREATE TABLE IF NOT EXISTS monm (
#    `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
#    `time` NUMERIC DEFAULT 0,         -- time()
#    `name` CHAR(255) DEFAULT NULL,    -- name of checkit section
#    `type` CHAR(32) DEFAULT NULL,     -- http/dbi/command
#    `source` CHAR(255) DEFAULT NULL,  -- URL/DSN/Command
#    `status` INTEGER DEFAULT 0,       -- status value
#    `message` TEXT DEFAULT NULL       -- message
#)
#
#-- For MySQL DB
#CREATE TABLE `monm` (
#  `id` int(11) NOT NULL auto_increment,
#  `time` int(11) default '0' COMMENT 'unix time()',
#  `name` varchar(255) default NULL COMMENT 'name of checkit section',
#  `type` varchar(32) default NULL COMMENT 'http/dbi/command',
#  `source` varchar(255) default NULL COMMENT 'URL/DSN/Command',
#  `status` int(3) default '0' COMMENT 'status value',
#  `message` text default NULL COMMENT 'message',
#  PRIMARY KEY  (`id`),
#  UNIQUE KEY `id` (`id`)
#) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
#

#
# Section for connection with Your database.
# Recommended for use follow databases: SQLite, MySQL or PostgreSQL
#
# Default: SQLite
#
# SQLite example:
# <Store>
#    DSN "dbi:SQLite:dbname=/tmp/monm/monm.db"
#    Set RaiseError     0
#    Set PrintError     0
#    Set sqlite_unicode 1
# </Store>
#
# MySQL example:
# <Store>
#    DSN "DBI:mysql:database=monm;host=mysql.example.com"
#    User username
#    Password password
#    Set RaiseError          0
#    Set PrintError          0
#    Set mysql_enable_utf8   1
#    Set mysql_auto_reconnect 1
# </Store>
#

#
# REQUIRED channel (SendMail) that defines default options for sending
# email-notifications and email-reports
#
<Channel SendMail>
    Type    Email
    Enable  on

    # Real Email addresses
    To      to@example.com
    #Cc     cc@example.com
    #Bcc    bcc@example.com
    From    from@example.com

    # MIME options
    Encoding base64

    # SMTP extra headers
    #<Headers>
    #    X-Foo foo
    #    X-Bar bar
    #</Headers>

    # Attachments
    #<Attachment>
    #    Filename    screenshot.png
    #    Type        image/png
    #    Encoding    base64
    #    Disposition attachment
    #    Path        ./screenshot.png
    #</Attachment>
    #<Attachment>
    #    Filename    payment.pdf
    #    Type        application/pdf
    #    Encoding    base64
    #    Disposition attachment
    #    Path        ./payment.pdf
    #</Attachment>

    # SMTP options
    # If there are requirements to the case sensitive of parameter
    # names, use the "Set" directives
    Set host 192.168.0.1
    Set port 25
    #Set sasl_username TestUser
    #Set sasl_password MyPassword
    Set timeout 20
</Channel>

#
# OPTIONAL channel (SMSGW) that defines default options for sending
# SMS-notifications
#
<Channel SMSGW>
    Type    Command
    Enable  on

    #At Sun-Sat[08:00-19:00]

    # Default phone number (MSISDN)
    To +1-424-254-5300

    # SMS Gateway timeout (to SMDP server, eg.)
    Timeout 10s

    # Command for sending
    #Command "echo "[MSISDN]; [SUBJECT]; [MESSAGE]" >> /tmp/fakesms.txt"
    #Command "sendalertsms "[MSISDN]" "[SUBJECT]" "[MESSAGE]""
    #Command "monm_dbi -s SIDNAME -u USER -p PASSWORD -q "SELECT SMS_FUNCTION('[MSISDN]', '[MESSAGE]') FROM DUAL" [MSISDN]"
    #Command "smsbox -D /tmp/smsbox create [MSISDN] "[MESSAGE]""
    #Command curl -d "[MESSAGE]" "https://sms.com/?[MSISDN]"
    Command "echo "[MSISDN];[MESSAGE]" >> /tmp/fakesms.txt"

    #
    # Replacement variables:
    #
    #   [ID]      -- Internal ID of the message
    #   [MSISDN]  -- Phone number
    #   [SUBJECT] -- Subject of message
    #   [MESSAGE] -- SMS body (reality this is also a subject)
    #

</Channel>

#
# Named users
#
#
#<User Bob>
#    Enable on
#
#    At Sun[off];Mon-Thu[08:30-12:30,13:30-18:00];Fri[10:00-20:30];Sat[off]
#
#    <Channel SendMail>
#        To bob@example.com
#    </Channel>
#
#    <Channel MySMS>
#        BasedOn SMSGW
#        To +1-424-254-5301
#        At Mon-Fri[08:30-18:30]
#    </Channel>
#</User>
#
#<User Alice>
#    Enable on
#
#    At Mon-Fri[08:30-18:30]
#
#    <Channel SendMail>
#        To alice@example.com
#    </Channel>
#
#    <Channel AliceGW>
#        Type    Command
#        To  +1-424-254-5301
#        Content email
#        Command "tee /tmp/alice.msg > /dev/null"
#    </Channel>
#</User>
#
#<User Ted>
#    Enable on
#
#    <Channel SendMail>
#        Enable  on
#    </Channel>
#    <Channel SMSGW>
#        Enable  on
#    </Channel>
#</User>
#
#<User Fred>
#    Enable on
#    <Channel FredFile>
#        Type    File
#
#        To      fred@example.com
#
#        # MIME options
#        Encoding base64
#
#        # File options
#        Dir     /tmp
#        File    [ID].[EXT]
#    </Channel>
#</User>
#
#<User Carol>
#    Enable on
#
#    <Channel SMSGW>
#        Command "echo "[MSISDN];[MESSAGE]" >> /tmp/carolsms.txt"
#    </Channel>
#</User>
#
#<User Dave>
#    Enable on
#
#    <Channel Mail>
#        BasedOn SendMail
#        At Sun-Sat[off]
#        To dave@example.com
#    </Channel>
#</User>
#
#<User Eve>
#    Enable off
#</User>

#
# Named groups
#
#
#<Group Foo>
#    Enable on
#    User Bob, Alice
#    User Ted
#</Group>
#
#<Group Bar>
#    Enable on
#    User Ted, Fred, Carol
#</Group>
#
#<Group Baz>
#    Enable off
#    User Dave, Eve
#</Group>
#
#<Group All>
#    Enable on
#    User Bob, Alice, Ted, Fred, Carol, Dave, Eve
#</Group>


Include conf.d/*.conf

-----END FILE-----

-----BEGIN FILE-----
Name: checkit-foo.conf.sample
File: conf.d/checkit-foo.conf.sample
Mode: 644

<Checkit foo>

    #
    # The main switcher of the checkit section
    #
    # Default: off
    #
    Enable      on

    #
    # The definition of "What is bad?"
    #
    # Default: !!perl/regexp (?i-xsm:^\s*(0|error|fail|no|false))
    #
    #IsFalse   !!perl/regexp (?i-xsm:^\s*(0|error|fail|no|false))
    #IsFalse   0
    #IsFalse   Error.

    #
    # The definition of "What is good?"
    #
    # Default: !!perl/regexp (?i-xsm:^\s*(1|ok|pass|yes|true))
    #
    #IsTrue    !!perl/regexp (?i-xsm:^\s*(1|ok|pass|yes|true))
    #IsTrue    1
    #IsTrue    Ok.

    #
    # Controls the order in which True and False are evaluated.
    # The OrderBy directive, along with the IsTrue and IsFalse directives,
    # controls a two-pass resolve system. The first pass processes IsTrue
    # or IsFalse directive, as specified by the OrderBy directive.
    # The second pass parses the rest of the directive (IsFalse or IsTrue).
    #
    # Ordering is one of:
    #
    #   OrderBy True,False
    #
    # First, IsTrue directive is evaluated. Next, IsFalse directive is evaluated.
    # If matches IsTrue, the check's result sets to true (PASSED), otherwise
    # result sets to false (FAILED)
    #
    #   OrderBy False,True
    #
    # First, IsFalse directive is evaluated. Next, IsTrue directive is evaluated.
    # If matches IsFalse, the check's result sets to false (FAILED), otherwise
    # result sets to true (PASSED)
    #
    # Default: "True,False"
    #
    #OrderBy   True,False
    #OrderBy   ASC # Is same as: "True,False"
    #OrderBy   False,True
    #OrderBy   DESC # Is same as: "False,True"

    #
    # Defines checking type. As of today, three types are supported:
    #   http(s), command and dbi(db)
    #
    # Default: http
    #
    #Type      http
    #Type      dbi
    #Type      command

    #
    # Defines the target for analysis of results
    #
    #   status  - the status of the check operation is analyzed
    #   code    - the return code is analyzed (HTTP code, error code and etc.)
    #   content - the content is analyzed (data from HTTP response, data
    #             from command's STDOUT or data from DB)
    #   message - the message is analyzed (HTTP message, eg.)
    #
    # Default: status
    #
    #Target    content

    #
    # Defines the time interval between two checks
    #
    #  Default: 0
    #
    # Format for time can be in any of the following forms:
    #
    #   20   -- in 20 seconds
    #   180s -- in 180 seconds
    #   2m   -- in 2 minutes
    #   12h  -- in 12 hours
    #   1d   -- in 1 day
    #   3M   -- in 3 months
    #   2y   -- in 2 years
    #   3m   -- 3 minutes ago(!)
    #
    #Interval 20s

    #
    # Defines triggers (system commands) that runs before sending notifications
    # There can be several such directives
    # Each trigger can contents the variables for auto replacement, for example:
    #
    #   Trigger  "mycommand1 "[MESSAGE]""
    #
    # Replacement variables:
    #
    #   [ID]        -- Internal ID of the message
    #   [MESSAGE], [MSG] -- The checker message content
    #   [MSISDN]    -- Phone number, recipient
    #   [NAME]      -- Checkit section name
    #   [NOTE]      -- The checker notes
    #   [RESULT]    -- The check result: PASSED/FAILED
    #   [SOURCE], [SRC]  -- Source string (URL, Command, etc.)
    #   [STATUS]    -- The checker status: OK/ERROR
    #   [SUBJECT], [SBJ] -- Subject of message (MIME)
    #   [TYPE]      -- Type of checkit: http/dbi/command
    #
    #Trigger  "curl http://mywebcam.com/[NAME]/[ID]?[MSISDN] >/tmp/snapshot.jpg"

    #
    # Defines a List of Recipients for notifications.
    # There can be several such directives
    #
    # Email addresses for sending notifications directly (See Channel SendMail)
    #SendTo  foo@example.com
    #SendTo  bar@example.com
    #
    # ...or SMS phone numbers (See Channel SMSGW):
    #SendTo 11231230002
    #SendTo +11231230001
    #SendTo +1-123-123-0003
    #
    # ...or a notify users:
    #SendTo Bob, Alice
    #SendTo Fred
    SendTo  Alice
    #
    # ...or a notify groups:
    #SendTo @Foo, @Bar
    #SendTo @Baz



    ###################################
    ## For HTTP requests (Type http) ##
    ###################################

    #
    # Defines the URL for HTTP/HTTPS requests
    #
    # Default: http://localhost
    #
    #URL   https://user:password@www.example.com
    URL    https://www.example.com

    #
    # Defines the HTTP method: GET, POST, PUT, HEAD, PATCH, DELETE, and etc.
    #
    # Default: GET
    #
    #Method    GET

    #
    # Defines the timeout of HTTP requests
    #
    # Default: 180
    #
    #Timeout    180

    #
    # Defines HTTP request headers.
    # This directive allows you set case sensitive HTTP headers.
    # There can be several such directives.
    #
    # Set User-Agent  "MyAgent/1.00"
    # Set X-Token     "mdffltrtkmdffltrtk"

    #
    # Specifies POST/PUT/PATCH request content
    #
    # Set Content-Type text/plain
    # Content  "Content for HTTP request"
    #
    # Default: no content

    #
    # Defines the proxy URL for a http/https requests
    #
    # Default: no proxy
    #
    #Proxy http://http.example.com:8001/



    ##################################
    ## For DBI requests (Type dbi)  ##
    ##################################

    #
    # Sets Database DSN string
    #
    # Default: dbi:Sponge:
    #
    #DSN     DBI:mysql:database=DATABASE;host=HOSTNAME

    #
    # Specifies the SQL query string (content)
    #
    # Default: "SELECT 'OK' AS OK FROM DUAL"
    #
    #SQL "SELECT 'OK' AS OK FROM DUAL"

    #
    # Defines database credential: username and password
    #
    #User        USER
    #Password    PASSWORD

    #
    # Defines the timeout of DBI requests
    #
    # Default: off
    #
    #Timeout    20s

    #
    # Defines DBI Attributes.
    # This directive allows you set case sensitive DBI Attributes.
    # There can be several such directives.
    #
    #Set sqlite_unicode 1
    #
    #Set RaiseError     0
    #Set PrintError     0



    #######################################
    ## For system command (Type command) ##
    #######################################

    #
    # Defines full path to external program (command line)
    #
    # Default: none
    #
    Command     perl -w

    #
    # Sets the content for command STDIN
    #
    # Default: no content
    #
    Content     "print q/Blah-Blah-Blah/"

    #
    # Defines the execute timeout
    #
    # Default: off
    #
    #Timeout    1m

</Checkit>

-----END FILE-----

-----BEGIN FILE-----
Name: checkit-foo.conf
File: conf.d/checkit-foo.conf
Mode: 644

#
# See checkit-foo.conf.sample and general documentation for details
#
<Checkit "foo">
    Enable      yes
    URL         https://www.example.com
    Target      code
    IsTrue      200
</Checkit>

-----END FILE-----
