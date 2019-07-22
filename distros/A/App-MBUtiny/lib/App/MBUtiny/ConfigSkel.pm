package App::MBUtiny::ConfigSkel; # $Id: ConfigSkel.pm 131 2019-07-16 18:45:44Z abalama $
use strict;
use utf8;

=encoding utf8

=head1 NAME

App::MBUtiny::ConfigSkel - Configuration skeleton for App::MBUtiny

=head1 VIRSION

Version 1.01

=head1 SYNOPSIS

none

=head1 DESCRIPTION

Configuration skeleton for App::MBUtiny

no public methods

=head2 build, dirs, pool

Main methods. For internal use only

=head1 SEE ALSO

L<App::MBUtiny>, L<CTK::Skel>

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
            path => 'hosts',
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
# The number of daily archives
# This is the number of stored past the daily archives.
# Default: 3
#
BUday 3

#
# The number of weekly archives
# This is the last weekly number of stored files. Weekly archives are those daily
# archives that were created on Sunday.
# Default: 3
#
BUweek 3

#
# Number of monthly archives
# This amount of stored past monthly archives. Monthly Archives are those daily archives
# that were created on the first of each month.
# Default: 3
#
BUmonth 3

#
# Definitions of required hosts for reporting
# Default: none
#
#Require foo bar baz quux


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
## Archiving
##
## See also: https://metacpan.org/pod/CTK::Plugin::Archive#REPLACING-KEYS
##
##############################################################################

#
# Tape ARchive + GNU Zip
#
<Arc>
    ext         .tar.gz
    create      tar -cpf \"[NAME].tar\" [LIST]
    append      tar -rpf \"[NAME].tar\" [LIST]
    postprocess gzip \"[NAME].tar\"
    extract     tar -zxpf \"[FILE]\" -C \"[DIRDST]\"
</Arc>

#
# Tape ARchive + BZip2
#
#<Arc>
#    ext         .tar.bz2
#    create      tar -cpf \"[NAME].tar\" [LIST]
#    append      tar -rpf \"[NAME].tar\" [LIST]
#    postprocess bzip2 \"[NAME].tar\"
#    extract     tar -jxpf \"[FILE]\" -C \"[DIRDST]\"
#</Arc>

#
# Tape ARchive + LZMA2
#
#<Arc>
#    ext         .tar.xz
#    create      tar -cpf \"[NAME].tar\" [LIST]
#    append      tar -rpf \"[NAME].tar\" [LIST]
#    postprocess xz \"[NAME].tar\"
#    extract     tar -Jxpf \"[FILE]\" -C \"[DIRDST]\"
#</Arc>

#
# ZIP
#
#<Arc>
#    ext        .zip
#    create     zip -rqqy \"[FILE]\" \"[LIST]\"
#    extract    unzip -uqqoX \"[FILE]\" -d \"[DIRDST]\"
#</Arc>

#
# RAR
#
#<Arc>
#    ext        .rar
#    create     rar a \"[FILE]\" \"[LIST]\"
#    extract    rar x -y \"[FILE]\" \"[DIRDST]\"
#</Arc>


##############################################################################
##
## SendMail
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
# Reporting flags
# Default: off
#
SendReport no
SendErrorReport no


##############################################################################
##
## Collector
##
##############################################################################

#
# Collector definitions (multiple blocks can be specified)
# Default: local collector, see "collector database interface"
#
#<Collector>
#    URL         https://user:password@collector.example.com/collector.cgi
#    Comment     Collector said blah-blah-blah # Optional for collector
#    #TimeOut    180
#</Collector>


##############################################################################
##
## Collector database interface
##
## See also collector.cgi.sample file
##
##############################################################################

#
# !!! WARNING !!!
#
# Before using the collector-server, please check your DataBase and create the mbutiny table
#

#-- For SQLite DB
#CREATE TABLE IF NOT EXISTS mbutiny (
#  `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
#  `type` INTEGER DEFAULT 0,         -- 0=internal/1=external
#  `time` NUMERIC DEFAULT 0,         -- unix time()
#  `name` CHAR(255) DEFAULT NULL,    -- name of mbutiny host
#  `addr` CHAR(45) DEFAULT NULL,     -- client ip addr
#  `status` INTEGER DEFAULT 0,       -- backup status
#  `file` CHAR(255) DEFAULT NULL,    -- backup filename
#  `size` INTEGER DEFAULT 0,         -- size of backup file
#  `md5` CHAR(32) DEFAULT NULL,      -- md5-checksum of backup file
#  `sha1` CHAR(40) DEFAULT NULL,     -- sha1-checksum of backup file
#  `error` TEXT DEFAULT NULL,        -- error message
#  `comment` TEXT DEFAULT NULL       -- comment
#);

#-- For MySQL DB
#CREATE TABLE `mbutiny` (
#  `id` int(11) NOT NULL auto_increment,
#  `type` int(2) default '0' COMMENT '0=internal/1=external',
#  `time` int(11) default '0' COMMENT 'unix time()',
#  `name` varchar(255) default NULL COMMENT 'name of mbutiny host',
#  `addr` varchar(45) default NULL COMMENT 'client ip addr',
#  `status` int(2) default '0' COMMENT 'backup status: 0=error/1=ok',
#  `file` varchar(255) default NULL COMMENT 'backup filename',
#  `size` int(11) default '0' COMMENT 'size of backup file',
#  `md5` varchar(32) default NULL COMMENT 'md5-checksum of backup file',
#  `sha1` varchar(40) default NULL COMMENT 'sha1-checksum of backup file',
#  `error` text default NULL COMMENT 'error message',
#  `comment` text default NULL COMMENT 'comment',
#  PRIMARY KEY  (`id`),
#  UNIQUE KEY `id` (`id`)
#) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

# Section for connection with Your database.
# Recommended for use follow databases: SQLite, MySQL, Oracle or PostgreSQL
# Default: SQLite

# SQLite example:
#<DBI>
#    DSN "dbi:SQLite:dbname=/var/lib/mbutiny/mbutiny.db"
#    Set RaiseError     0
#    Set PrintError     0
#    Set sqlite_unicode 1
#</DBI>

# MySQL example:
#<DBI>
#    DSN "DBI:mysql:database=mbutiny;host=mysql.example.com"
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

Include hosts/*.conf

-----END FILE-----

-----BEGIN FILE-----
Name: foo.conf.sample
File: hosts/foo.conf.sample
Mode: 644

<Host foo>
    Enable          yes

    #
    # SendMail settings (optional, see general config file)
    #
    #<SendMail>
    #    To          to@example.com
    #    #Cc          cc@example.com
    #    #From        from@example.com
    #
    #    # SMTP server
    #    #SMTP        192.168.0.1
    #    # Authorization SMTP
    #    #SMTPuser   user
    #    #SMTPpass   password
    #</SendMail>

    #
    # Reporting flags (optional, see general config file)
    # Default: off
    #
    SendReport      no
    SendErrorReport yes

    #
    # Archivator configuration (optional, see general config file)
    #
    #<Arc>
    # ...
    #</Arc>

    #
    # Backup general settings
    #
    ArcMask         [HOST]-[YEAR]-[MONTH]-[DAY][EXT]
    BUday           3
    BUweek          3
    BUmonth         3

    #
    # Triggers
    #
    Trigger test -d ./test || mkdir ./test
    Trigger ls -la > ./test/my.lst
    Trigger test -d ./test/foo || mkdir ./test/foo
    Trigger echo test > ./test/foo/test1.txt
    Trigger echo test > ./test/foo/test2.txt
    Trigger ls -la > ./test/foo/dir.lst
    Trigger test -d ./test/bar || mkdir ./test/bar
    Trigger echo test > ./test/bar/test1.txt
    Trigger echo test > ./test/bar/test2.txt
    Trigger echo test > ./test/bar/test3.txt
    Trigger ls -la > ./test/bar/dir.lst
    Trigger test -d ./test/bar/exc || mkdir ./test/bar/exc
    Trigger ls -la > ./test/bar/exc/dir.lst
    #Trigger mysqldump -f -h mysql.host.com -u user --port=3306 --password=password \
    #        --add-drop-table --default-character-set=utf8 \
    #        --databases databasename > ./test/databasename.sql

    #
    # Objects (source files and directories)
    #
    Object ./test/dir.lst
    Object ./test/foo

    #
    # Exlusive objects (multiple blocks can be specified)
    #
    <Exclude "my_exclude">
        # Source file or directory
        Object ./test/bar

        # Destination directory for processed files and directories (optional)
        #Target ./test/exc_target

        # Excluded object list (files and directories)
        Exclude test1.txt
        Exclude exc/dir.lst
    </Exclude>

    #
    # Collector definitions (multiple blocks can be specified)
    # Also see general config file
    #
    #<Collector>
    #    URL         https://user:password@collector.example.com/collector.cgi
    #    Comment     Collector said blah-blah-blah # Optional for collector
    #    #TimeOut    180
    #</Collector>

    #
    # Local storage (multiple blocks can be specified)
    #
    <Local>
        FixUP       off
        Localdir    ./test/mbutimy-local1
        Localdir    ./test/mbutimy-local2
        Comment     Local storage said blah-blah-blah # Optional for collector
    </Local>

    #
    # SFTP storage (multiple blocks can be specified)
    #
    #<SFTP>
    #    FixUP       on
    #    URL         sftp://user@example.com:22/path/to/backup/dir1
    #    URL         sftp://user@example.com:22/path/to/backup/dir2
    #    Set         timeout  180
    #    Set         key_path  /path/to/private/file.key
    #    Comment     SFTP storage said blah-blah-blah # Optional for collector
    #</SFTP>

    #
    # FTP storage (multiple blocks can be specified)
    #
    #<FTP>
    #    FixUP       on
    #    URL         ftp://user:password@example.com:21/path/to/backup/dir1
    #    URL         ftp://user:password@example.com:21/path/to/backup/dir2
    #    Set         Passive 1
    #    Set         Debug 1
    #    Comment     FTP storage said blah-blah-blah # Optional for collector
    #</FTP>

    #
    # HTTP storage (multiple blocks can be specified)
    # See eg/server.cgi example file on CPAN web site
    #
    #<HTTP>
    #    FixUP       on
    #    URL         https://user:password@example.com/mbuserver/path/to/backup/dir1
    #    URL         https://user:password@example.com/mbuserver/to/backup/dir2
    #    Set         User-Agent TestServer/1.00
    #    Set         X-Test Foo Bar Baz
    #    Comment     HTTP storage said blah-blah-blah # Optional for collector
    #</HTTP>

    #
    # Command storage (multiple blocks can be specified)
    #
    #<Command>
    #    FixUP       on
    #    test        "test -d ./mbucmd  && ls -1 ./mbucmd || mkdir ./mbucmd"
    #    put         "cp [FILE] ./mbucmd/[NAME]"
    #    get         "cp ./mbucmd/[NAME] [FILE]"
    #    del         "test -e ./mbucmd/[NAME] && unlink ./mbucmd/[NAME] || true"
    #    list        "ls -1 ./mbucmd"
    #    comment     Command storage said blah-blah-blah # Optional for collector
    #</Command>
</Host>

-----END FILE-----

-----BEGIN FILE-----
Name: collector.cgi.sample
File: collector.cgi.sample
Mode: 644

#!/usr/bin/perl -w
use strict;
use utf8;

use CGI;
use App::MBUtiny::Collector::Server "/mbutiny";

my $q = new CGI;
my $server = new App::MBUtiny::Collector::Server(
    project => "MBUtiny",
    ident   => "mbutiny",
    log     => "on",
    logfd   => fileno(STDERR),
);
$server->status or die($server->error);
print $server->call($q->request_method, $q->request_uri, $q) or die($server->error);

%ENDSIGN%
-----END FILE-----
