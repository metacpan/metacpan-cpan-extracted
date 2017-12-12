package App::MonM::Notifier::Helper::Config; # $Id: Config.pm 44 2017-12-01 19:41:48Z abalama $
use strict;

=head1 NAME

App::MonM::Notifier::Helper::Config - Internal helper's methods used by App::MonM::Notifier::Helper module

=head1 VIRSION

Version 1.00

=head1 SYNOPSIS

none

=head1 DESCRIPTION

no public methods

=head2 build, dirs, pool

Main methods. For internal use only

=head1 SEE ALSO

L<App::MonM::Notifier::Helper>

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

=cut

use CTK::Util qw/ :BASE /;
use constant SIGNATURE => "conf";

use vars qw($VERSION);
$VERSION = '1.00';

sub build { # Building
    my $self = shift;

    my $rplc = $self->{rplc};

    $rplc->{FOO} = "foo";
    $rplc->{BAR} = "bar";
    $rplc->{BAZ} = "baz";

    $self->maybe::next::method();
    return 1;
}
sub dirs { # Directories and permissions as array of hashs
    my $self = shift;
    $self->{subdirs}{(SIGNATURE)} = [
        {
            path => 'extra',
            mode => 0755,
        },
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
Name: monotifier.conf
File: monotifier.conf
Mode: 644

# %DOLLAR%Id%DOLLAR%
# GENERATED: %GMT%
#
# See Config::General for details
#

# Activate or deactivate the logging: on/off (yes/no)
# LogEnable off
# LogEnable on

# debug level: debug, info, notice, warning, error, crit, alert, emerg, fatal, except
# LogLevel debug
# LogLevel warning

# Connection mode: local (default), remote (via http API)
# Mode local
# Mode remote

# Expires and Life times
# Expires - for uncompleted records
# Lifetime - for very old records
Expires +1M
Lifetime +1y

# Channel processing timeout
TimeOut 300

Include extra/*.conf
Include conf.d/*.conf

-----END FILE-----

-----BEGIN FILE-----
Name: token.conf
File: extra/token.conf
Mode: 666

#
# Attention!
#
# This is default token. Please generate new token and replace it
#

Token 1fcc156f5bbb7f2f4ccd11366c8b13825e34cad23a63b706f3108a4cccde2ce9
-----END FILE-----

-----BEGIN FILE-----
Name: client.conf
File: conf.d/client.conf
Mode: 644

# Client configuration
<Client>
    ServerURL http://localhost/monotifier
    #UserName  anonymous
    #Password  123456
    TimeOut    180 # Default: 180
</Client>
-----END FILE-----

-----BEGIN FILE-----
Name: store.conf.sample
File: conf.d/store.conf.sample
Mode: 644

# Store configuration
<Store>
    Type    DBI

    DSN     "DBI:mysql:database=monotifier;host=localhost"
    Table   monotifier

    User    root
    Password password

    Connect_to    5     # Connect TimeOut
    Request_to    60    # Request TimeOut

    Set mysql_enable_utf8 1
    Set PrintError 0

    DDL CREATE TABLE IF NOT EXISTS `[TABLE]` ( \
          `id` int(11) NOT NULL COMMENT 'ID', \
          `ip` char(15) NOT NULL COMMENT 'Client IP address', \
          `host` char(128) DEFAULT NULL COMMENT 'Client Host Name', \
          `ident` char(64) DEFAULT NULL COMMENT 'Ident, name', \
          `level` int(8) NOT NULL DEFAULT '0' COMMENT 'Level', \
          `to` char(255) DEFAULT NULL COMMENT 'Recipient address', \
          `from` char(255) DEFAULT NULL COMMENT 'Sender''s address', \
          `subject` text COMMENT 'Subject of the message', \
          `message` text COMMENT 'Message content ', \
          `pubdate` bigint(20) DEFAULT NULL COMMENT 'Date (unixtime) of the publication', \
          `expires` bigint(20) DEFAULT NULL COMMENT 'Date (unixtime) of the expire', \
          `status` char(32) DEFAULT NULL COMMENT 'Status of transaction', \
          `comment` char(255) DEFAULT NULL COMMENT 'Comment', \
          `errcode` int(11) DEFAULT NULL COMMENT 'Error code', \
          `errmsg` text COMMENT 'Error message', \
          PRIMARY KEY (`id`), \
          KEY `I_ID` (`id`) \
        ) ENGINE=MyISAM DEFAULT CHARSET=utf8
    DML SELECT COUNT(`id`) AS `countid` FROM [TABLE]
</Store>
-----END FILE-----

-----BEGIN FILE-----
Name: anonymous.conf
File: conf.d/anonymous.conf
Mode: 644

# User anonymous configuration
<User "anonymous">
    TimeOut 300
    Period  7:00-19:00

    <Channel TestScript>
        Enable  on
        Type    Script
        Level   debug
        Period  8:00-18:00

        # Real To and From
        To      realTo
        From    realFrom

        # Options
        <Options>
            #encoding base64
            Signature yes
            Script "%SITE_BIN%%SPLITTER%testscript.pl"
        </Options>
    </Channel>
</User>
-----END FILE-----

-----BEGIN FILE-----
Name: user.conf.sample
File: conf.d/user.conf.sample
Mode: 644

<User "test">
    TimeOut 300

    # Global period (for all channels as default)
    Period  7:00-19:00

    <Channel MyEmail>
        # Via SMTP server
        Enable  on
        Type    Email

        # Accepted priority level for ingoing messages
        # May be one from: none, debug, info, notice, warning, error,
        #                  crit, alert, emerg, fatal, except
        # Default: debug
        Level   notice

        # Real To and From
        To      test@example.com
        From    root@example.com

        # SMTP options
        <Options>
            encoding base64
            host mail.example.com
            port 25

            # If there are requirements to the register of parameter
            # names, use the Set directive, for example:
            #Set User TeStUser
            #Set Password MyPassword

            User        anonymous
            Password    password
        </Options>

        # Default for this channel only
        Period  7:30-16:30

        # Calendar settings for this channel
        # Sun Mon Tue Wed Thu Fri Sat
        #  ... or:
        # Sunday Monday Tuesday Wednesday Thursday Friday Saturday
        Sun - # disable!
        Mon 7:35-17:45
        Tue 15-19
        Wed -
        Thu 16-18:01
        Fri 18:01-19
        Sat -
    </Channel>
    <Channel TinyEmail>
        # Via sendmail program
        Enable  on
        Type    email
        To      test@example.com
    </Channel>
    <Channel MyFile>
        # Save to file by mask
        Enable  on
        Type    File
        Level   warning,error

        # Real To and From
        To      test
        From    root

        Period  10:00-19:00
        Thu     7:45-14:25
        Sun -
        Fri     0:0-1:0

        # File options
        <Options>
            #encoding base64
            Signature yes
            dir "%ROOT_DIR%%SPLITTER%tmp"
            #dir "C:\\"
            #filemask "file.txt"
        </Options>
    </Channel>
    <Channel TestScript>
        # Send serialized message to STDIN of external program
        Enable  on
        Type    Script
        Level   debug
        Period  8:00-18:00

        # Real To and From
        To      realTo
        From    realFrom

        # Options
        <Options>
            #encoding base64
            Signature yes
            Script "%CONF_DIR%%SPLITTER%testscript.pl"
        </Options>
    </Channel>
</User>
-----END FILE-----

-----BEGIN FILE-----
Name: foo.conf
File: extra/foo.conf
Mode: 644
Type: Windows

# Test for Windows platform

-----END FILE-----
