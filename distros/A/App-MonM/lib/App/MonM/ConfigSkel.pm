package App::MonM::ConfigSkel; # $Id: ConfigSkel.pm 90 2019-07-18 09:47:29Z abalama $
use strict;
use utf8;

=encoding utf8

=head1 NAME

App::MonM::ConfigSkel - Configuration skeleton for App::MonM

=head1 VIRSION

Version 1.01

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

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use constant SIGNATURE => "config";

use vars qw/ $VERSION /;
$VERSION = '1.01';

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

##############################################################################
##
## General
##
##############################################################################

#
# Expire data in database
#
Expire +1M


##############################################################################
##
## Logging
##
##############################################################################

#
# Activate or deactivate the logging: on/off (yes/no). Default: on
#
LogEnable on

#
# Loglevel: debug, info, notice, warning, error,
#              crit, alert, emerg, fatal, except
# Default: debug
#
LogLevel warning

#
# LogIdent string. Default: none
#
LogIdent %PREFIX%

#
# LogFile: path to log file
#
# Default: using syslog
#
#LogFile /var/log/%PREFIX%.log


##############################################################################
##
## SendMail & SMSGW
##
##############################################################################

<SendMail>
    To          to@example.com
    Cc          cc@example.com
    From        from@example.com

    # SMTP server
    SMTP        192.168.0.1
    # Authorization SMTP
    #SMTPuser   user
    #SMTPpass   password
</SendMail>

#
# GateWay for sending SMS
#
#   [PHONE]   -- Phone number
#   [SUBJECT] -- Subject of message
#   [MESSAGE] -- SMS body
#
# SMSGW "sendalertsms "[NUMBER]" "[SUBJECT]" "[MESSAGE]""
# SMSGW "monm_dbi -s SIDNAME -u USER -p PASSWORD -q "SELECT SMS_FUNCTION('[PHONE]', '[MESSAGE]') FROM DUAL" [PHONE]"
# SMSGW "smsbox -D /tmp/smsbox create [PHONE] "[MESSAGE]""
SMSGW "echo "[NUMBER]; [SUBJECT]; [MESSAGE]" >> ./fakesmsgw.txt"


##############################################################################
##
## MonM database interface
##
##############################################################################

#
# !!! WARNING !!!
#
# Before using the third-party database, please create the monm table
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

# Section for connection with Your database.
# Recommended for use follow databases: SQLite, MySQL, Oracle or PostgreSQL
# Default: SQLite

# SQLite example:
#<DBI>
#    DSN "dbi:SQLite:dbname=/tmp/monm/monm.db"
#    Set RaiseError     0
#    Set PrintError     0
#    Set sqlite_unicode 1
#</DBI>

# MySQL example:
#<DBI>
#    DSN "DBI:mysql:database=monm;host=mysql.example.com"
#    User username
#    Password password
#    Set RaiseError          0
#    Set PrintError          0
#    Set mysql_enable_utf8   1
#</DBI>

# Oracle Example
#<DBI>
#    DSN "dbi:Oracle:MYSID"
#    User username
#    Password password
#    Set RaiseError 0
#    Set PrintError 0
#</DBI>

Include conf.d/*.conf

-----END FILE-----

-----BEGIN FILE-----
Name: checkit-foo.conf.sample
File: conf.d/checkit-foo.conf.sample
Mode: 644

<Checkit "foo">

    #
    # Switch of checkit section
    #
    # Default: no
    #
    Enable      yes

    #
    # The definition of "What is bad!"
    #
    # Default: !!perl/regexp (?i-xsm:^\s*(0|error|fail|no|false))
    #
    #IsFalse   !!perl/regexp (?i-xsm:^\s*(0|error|fail|no|false))
    #IsFalse   ERROR
    #IsFalse   ERROR.

    #
    # The definition of "What is good!"
    #
    # Default: !!perl/regexp (?i-xsm:^\s*(1|ok|pass|yes|true))
    #
    #IsTrue    !!perl/regexp (?i-xsm:^\s*(1|ok|pass|yes|true))
    #IsTrue    OK
    #IsTrue    Ok.

    #
    # Direct sort order of resolution
    #
    # Default: "true, false"
    #
    #OrderBy   true, false
    #OrderBy   ASC # Is same as: "true, false"
    #OrderBy   ASC

    #
    # Reverse Sort Order
    #
    #OrderBy   false, true
    #OrderBy   DESC # Is same as: "false, true"

    #
    # Request type
    #
    # Default: http
    #
    #Type      http
    #Type      dbi
    #Type      command

    ###################################
    ## For HTTP requests             ##
    ###################################

    #
    # URL of resource for request
    #
    #URL   http://user:password@www.example.com
    URL    http://www.example.com

    #
    # The HTTP method: HTTP, GET, POST, PUT, HEAD, PATCH, DELETE, and etc.
    #
    # Default: GET
    #
    #Method    GET
    #Method    HEAD
    #Method    POST

    #
    # Timeout of HTTP request, secs
    #
    # Default: 180
    #
    #Timeout    180

    #
    # Target of the analysis
    #
    # Default: content
    #
    #Target    content # Status is ok, when: ok, yes (see IsTrue/IsFalse)
    #Target    code # HTTP status code, rc (response code)
    #Target    status # HTTP status (status is ok, when: 1xx, 2xx, 3xx)

    #
    # HTTP request headers
    #
    #Set User-Agent  "MyAgent/1.00"
    #Set X-Token     "mdffltrtkmdffltrtk"

    #
    # POST/PUT/PATCH content
    #
    #Content  "Content for HTTP request"
    #Set Content-Type text/plain

    ##################################
    ## For DBI requests             ##
    ##################################

    DSN         DBI:mysql:database=DATABASE;host=HOSTNAME
    #SQL       "SELECT 'OK' AS OK FROM DUAL" # By default
    User        USER
    Password    PASSWORD
    #Timeout    180 # Connect and request timeout, secs

    #
    # DBI Attributes
    #
    #Set RaiseError     0
    #Set PrintError     0
    #Set sqlite_unicode 1

    ##################################
    ## For system command requests  ##
    ##################################

    Command     "ls -la"
    IsTrue      !!perl/regexp (?i-xsm:README)
    #Content    "STDIN content for Command"

    #
    # Target of the analysis
    #
    # Default: status
    #
    #Target    content # Status is ok, when: ok, yes (see IsTrue/IsFalse)
    #Target    code # Exit status code
    #Target    status # Status (0 or 1)

    #
    # Recipient List
    #
    #SendTo  foo@example.com
    #SendTo  bar@example.com
    #SendTo  baz@example.com

    # ...and SMS phone numbers
    #SendTo  +11231230001
    #SendTo  11231230002
    #SendTo  +1 (123) 123-00-03

    # ...and a notify user (if App::MonM::Notifier is installed)
    #SendTo  user1 user2
    #SendTo  user3

    #
    # Triggers: system commands
    #
    # [SUBJECT], [SUBJ] -- Subject
    # [MESSAGE], [MSG] -- Message
    # [SOURCE] -- Source
    # [NAME] -- Checkit section name
    # [TYPE] -- Checkit type: http/dbi/command
    # [STATUS] -- 0/1
    #
    #Trigger  "mycommand1 \"[SUBJECT]\" \"[MESSAGE]\""
    #Trigger  "mycommand2 \"[MESSAGE]\""
    #Trigger  "mycommand3"

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
    URL         http://www.example.com
    Target      code
    IsTrue      200
</Checkit>

-----END FILE-----
