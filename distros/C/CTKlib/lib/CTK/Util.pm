package CTK::Util;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

CTK::Util - CTK Utilities

=head1 VERSION

Version 2.83

=head1 SYNOPSIS

    use CTK::Util;
    use CTK::Util qw( :BASE ); # Export only BASE subroutines. See TAGS section

    my @ls = ls(".");

=head1 DESCRIPTION

Public utility functions. No function is not exported by default!

=head2 FUNCTIONS

All subroutines are listed in alphabetical order

=head3 basetime

    $secs = basetime();

The time at which the program began running, in seconds.
This function returns result of expression:

    time() - $^T

Tags: BASE, DATE

=head3 bload, file_load

    $bindata = bload( $file_or_fh, $onutf8 );

Reading file in binary mode as ':raw:utf8' layer (if $onutf8 is true) or regular binary layer.

Tags: BASE, FILE, ATOM

=head3 bsave, file_save

    $status = bsave( $file_or_fh, $bindata, $onutf8 );

Saving file in binary mode as ':raw:utf8' layer (if $onutf8 is true) or regular binary layer.

Tags: BASE, FILE, ATOM

=head3 cachedir

    my $value = cachedir();

For example value can be set as: /var/cache

/var/cache is intended for cached data from applications. Such data is locally generated as a result of
time-consuming I/O or calculation. The application must be able to regenerate or restore the data. Unlike
/var/spool, the cached files can be deleted without data loss. The data must remain valid between invocations
of the application and rebooting the system.

Files located under /var/cache may be expired in an application specific manner, by the system administrator,
or both. The application must always be able to recover from manual deletion of these files (generally because of
a disk space shortage). No other requirements are made on the data format of the cache directories.

See L<Sys::Path/"cachedir">

Tags: CORE, BASE, FILE

=head3 cdata

    $cdatatext = cdata( $text );

Returns a string "<![CDATA[$text]]>" for plain XML documents.

Tags: BASE, FORMAT

=head3 correct_date

    $mydate = correct_date( $date );

Returns date in format dd.mm.yyyy or null ('') if $date is wrongly.

Tags: BASE, DATE

=head3 correct_dig

    $mydig = correct_dig( $string );

Returns digits only from string or 0 if string is not correctly.

Tags: BASE, FORMAT

=head3 correct_number

    $mynumber = correct_number( $string, $sep );

Placement of separators discharges among digits. For example 1`234`567 if $sep is char "`" (default)

Tags: BASE, FORMAT

=head3 current_date

    $date = current_date();

Returns current date in format dd.mm.yyyy

Tags: BASE, DATE

=head3 current_date_time

    $datetime = current_date_time();

Returns current date in format dd.mm.yyyy hh.mm.ss

Tags: BASE, DATE

=head3 date2dig

    $dd = date2dig( $date );

Returns $date (or current) in format yyyymmdd

Tags: BASE, DATE

=head3 date2localtime

    $time = date2localtime( $date );

Returns time from date format dd.mm.yyyy in time() value in seconds since the system epoch
(Midnight, January 1, 1970 GMT on Unix, for example).

See L<Time::Local/"timelocal">

Tags: BASE, DATE

=head3 datef

See L</"dtf">

Tags: BASE, DATE

=head3 date_time2dig

    $dtd = date_time2dig( $datetime );

Returns $datetime (or current) in format yyyymmddhhmmss

Tags: BASE, DATE

=head3 datetime2localtime

    $time = datetime2localtime( $datetime );

Returns time from datetime format dd.mm.yyyy hh.mm.ss in time() value in seconds since the system epoch
(Midnight, January 1, 1970 GMT on Unix, for example).

See L<Time::Local/"timelocal">

Tags: BASE, DATE

=head3 datetimef

See L</"dtf">

Tags: BASE, DATE

=head3 dformat

    $string = dformat( $mask, \%replacehash );

Replace substrings "[...]" in mask and
returns replaced result. Data for replacing get from \%replacehash

For example:

    # -> 01-foo-bar.baz.tgz
    $string = dformat( "01-[NAME]-bar.[EXT].tgz", {
                NAME => 'foo',
                EXT  => 'baz',
            } );

See also L</"fformat"> for working with files

Tags: BASE, FORMAT

=head3 dig2date

    $date = dig2date_time( $dd );

Returns date (or current) from format yyyymmdd in format dd.mm.yyyy

Tags: BASE, DATE

=head3 dig2date_time

    $datetime = dig2date_time( $dtd );

Returns date (or current) from format yyyymmddhhmmss in format dd.mm.yyyy hh.mm.ss

Tags: BASE, DATE

=head3 docdir

    my $value = docdir();

For example value can be set as: /usr/share/doc

See L<Sys::Path/"docdir">

Tags: CORE, BASE, FILE

=head3 dtf

    $datetime = dtf( $format, $time );
    $datetime = dtf( $format, $time, 1 ); # in GMT context
    $datetime = dtf( $format, $time, 'MSK' ); # TimeZone (Z) = MSK
    $datetime = dtf( $format, $time, 'GMT' ); # TimeZone (Z) = GMT

Returns time in your format.
Each conversion specification is replaced by appropriate characters as described in the following list.

    s, ss, _s - Seconds
    m, mm, _m - Minutes
    h, hh, _h - Hours
    D, DD, _D - Day of month
    M, MM, _M - Month
    Y, YY, YYY, YYYY - Year
    w       - Short form of week day (Sat, Tue and etc)
    W       - Week day (Saturdat, Tuesday and etc)
    MON, mon - Short form of month (Apr, May and etc)
    MONTH, month - Month (April, May and etc)
    Z       - short name of local TimeZone
    G       - short name of TimeZone GMT (for GMT context only)
    U       - short name of TimeZone UTC (for GMT context only)

Examples:

    # RFC822 (RSS)
    $dt = dtf("%w, %D %MON %YY %hh:%mm:%ss %G", time(), 1); # Tue, 3 Sep 2013 12:31:40 GMT

    # RFC850
    $dt = dtf("%W, %DD-%MON-%YY %hh:%mm:%ss %G", time(), 1); # Tuesday, 03-Sep-13 12:38:41 GMT

    # RFC1036
    $dt = dtf("%w, %D %MON %YY %hh:%mm:%ss %G", time(), 1); # Tue, 3 Sep 13 12:44:08 GMT

    # RFC1123
    $dt = dtf("%w, %D %MON %YYYY %hh:%mm:%ss %G", time(), 1); # Tue, 3 Sep 2013 12:50:42 GMT

    # RFC2822
    $dt = dtf("%w, %DD %MON %YYYY %hh:%mm:%ss +0400"); # Tue, 12 Feb 2013 16:07:05 +0400
    $dt = dtf("%w, %DD %MON %YYYY %hh:%mm:%ss ".tz_diff());

    # W3CDTF, ATOM (Same as RFC 3339/ISO 8601) -- Mail format
    $dt = dtf("%YYYY-%MM-%DDT%hh:%mm:%ss+04:00"); # 2013-02-12T16:10:28+04:00

    # CTIME
    $dt = dtf("%w %MON %_D %hh:%mm:%ss %YYYY"); # Tue Feb  2 16:15:18 2013

    # CTIME with TimeZone
    $dt = dtf("%w %MON %_D %hh:%mm:%ss %YYYY %Z", time(), 'MSK'); # Tue Feb 12 17:21:50 2013 MSK

    # Russian date and time format
    $dt = dtf("%DD.%MM.%YYYY %hh:%mm:%ss"); # 12.02.2013 16:16:53

    # DIG form
    $dt = dtf("%YYYY%MM%DD%hh%mm%ss"); # 20130212161844

    # HTTP headers format (See CGI::Util::expires)
    $dt = dtf("%w, %DD %MON %YYYY %hh:%mm:%ss %G", time, 1); # Tue, 12 Feb 2013 13:35:04 GMT

    # HTTP/cookie format (See CGI::Util::expires)
    $dt = dtf("%w, %DD-%MON-%YYYY %hh:%mm:%ss %G", time, 1); # Tue, 12-Feb-2013 13:35:04 GMT

    # COOKIE (RFC2616 as rfc1123-date)
    $dt = dtf("%w, %DD %MON %YYYY %hh:%mm:%ss %G", time, 1); # Tue, 12 Feb 2013 13:35:04 GMT

For more features please use L<Date::Format>, L<DateTime> and L<POSIX/strftime>

Tags: BASE, DATE

=head3 eqtime

    eqtime("source/file", "destination/file");

Sets modified time of destination to that of source.

Tags: BASE, FILE, ATOM

=head3 escape

    $safe = escape("10% is enough\n");

Replaces each unsafe character in the string "10% is enough\n" with the corresponding
escape sequence and returns the result. The string argument should
be a string of bytes.

See also L<URI::Escape>

Tags: BASE, FORMAT

=head3 execute, exe

    $out = execute( "ls -la" );
    $out = execute( "ls -la", $in, \$err, $binmode );

Executing external (system) command with IPC::Open3 using.

Variables $in, $err and $binmode is OPTIONAL.

$binmode set up binary mode layer as ':raw:utf8' layer (if $binmode is ':raw:utf8', for example) or
regular binary layer (if $binmode is true).

See also L<IPC::Open3>

Tags: UTIL, EXT, ATOM

=head3 fformat

    $file = fformat( $mask, $filename );

Replace substrings "[FILENAME]", "[NAME]", "[FILEEXT]", "[EXT]" and "[FILE]" in mask and
returns replaced result. Data for replacing get from filename:

    [FILENAME] -- Fileneme only
    [NAME]     -- Fileneme only
    [FILEEXT]  -- Extension only
    [EXT]      -- Extension only
    [FILE]     -- = "[FILENAME].[FILEEXT]" ($filename)

For example:

    $file = fformat( "01-[NAME]-bar.[EXT].tgz", "foo.baz" ); # -> 01-foo-bar.baz.tgz

See also L</"dformat">

Tags: BASE, FORMAT

=head3 file_lf_normalize, file_nl_normalize

    file_lf_normalize( "file.txt" ) or die("Can't normalize file");

Runs C<"lf_normalize"> for every string of the file and save result to this file

Tags: BASE, FORMAT

=head3 fload, load_file

    $textdata = fload( $file );

Reading file in regular text mode

Tags: BASE, FILE, ATOM

=head3 from_utf8

    $win1251_text = from_utf8( $utf8_text )
    $win1251_text = from_utf8( $utf8, "Windows-1251" )

Encodes a string from Perl's internal form into I<ENCODING> and returns
a sequence of octets.  ENCODING can be either a canonical name or
an alias. For encoding names and aliases, see L<Encode>.

Tags: BASE, FORMAT

=head3 fsave, save_file

    $status = fsave( $file, $textdata );

Saving file in regular text mode

Tags: BASE, FILE, ATOM

=head3 ftp

    %ftpct = (
        ftphost     => '192.168.1.1',
        ftpuser     => 'login',
        ftppassword => 'password',
        ftpdir      => '~/',
        voidfile    => './void.txt',
        #ftpattr    => {}, # See Net::FTP
    );

    $ftpct  = ftp( \%ftpct, 'connect' ); # Returns the connect's object
    $rfiles = ftp( \%ftpct, 'ls' ); # Returns reference to array of directory listing
    @remotefiles = $rfiles ? grep {!(/^\./)} @$rfiles : ();

    ftp( \%ftpct, 'delete', $rfile ); # Delete remote file
    ftp( \%ftpct, 'get', $rfile, $lfile ); # Get remote file to local file
    ftp( \%ftpct, 'put', $lfile, $rfile ); # Put local file to remote file

Simple working with FTP.

See also L<Net::FTP>

Tags: UTIL, EXT, ATOM

=head3 ftpgetlist

    $rfiles = ftpgetlist( \%ftpct, $mask);

Returns reference to array of remote source listing by mask (as regexp, optional)

See L</"ftp">

Tags: UTIL, EXT, ATOM

=head3 ftptest

    $status = ftptest( \%ftpct );

FTP connect testing.

See L</"ftp">

Tags: UTIL, EXT, ATOM

=head3 getdirlist

    $listref = getdirlist( $dir, $mask );

Returns reference to array directories of directory $dir by $mask (regexp or scalar string).

See also L</"ls">

Tags: BASE, FILE, ATOM

=head3 getfilelist, getlist

    $listref = getlist( $dir, $mask );

Returns reference to array files of directory $dir by $mask (regexp or scalar string).

See also L</"ls">

Tags: BASE, FILE, ATOM

=head3 getsyscfg, syscfg

Returns all hash %Config from system module L<Config> or one value of this hash

    my %syscfg = syscfg();
    my $prefix = syscfg( "prefix" );

See L<Config> module for details

Tags: API, BASE

=head3 isos

Returns true or false if the OS name is of the current value of C<$^O>

    isos('mswin32') ? "OK" : "NO";

See L<Perl::OSType> for details

Tags: API, BASE

=head3 isostype

Given an OS type and OS name, returns true or false if the OS name is of the
given type.

    isostype('Windows') ? "OK" : "NO";
    isostype('Unix', 'dragonfly') ? "OK" : "NO";

See L<Perl::OSType/"is_os_type">

Tags: API, BASE

=head3 isFalseFlag

    print "Disabled" if isFalseFlag("off");

If specified argument value is set to false then will be normalised to 1.

The following values will be considered as false:

    no, off, 0, false, disable

This effect is case-insensitive, i.e. both "No" or "no" will result in 1.

Tags: BASE, UTIL

=head3 isTrueFlag

    print "Enabled" if isTrueFlag("on");

If specified argument value is set to true then will be normalised to 1.

The following values will be considered as true:

    yes, on, 1, true, enable

This effect is case-insensitive, i.e. both "Yes" or "yes" will result in 1.

Tags: BASE, UTIL

=head3 lf_normalize, nl_normalize

    my $normalized_string = lf_normalize( $string );

Returns CR/LF normalized string

Tags: BASE, FORMAT

=head3 localedir

    my $value = localedir();

For example value can be set as: /usr/share/locale

See L<Sys::Path/"localedir">

Tags: CORE, BASE, FILE

=head3 localstatedir

    my $value = localstatedir();

For example value can be set as: /var

/var - $Config::Config{'prefix'}

/var contains variable data files. This includes spool directories and files, administrative and logging data, and
transient and temporary files.
Some portions of /var are not shareable between different systems. For instance, /var/log, /var/lock, and
/var/run. Other portions may be shared, notably /var/mail, /var/cache/man, /var/cache/fonts, and
/var/spool/news.

/var is specified here in order to make it possible to mount /usr read-only. Everything that once went into /usr
that is written to during system operation (as opposed to installation and software maintenance) must be in /var.
If /var cannot be made a separate partition, it is often preferable to move /var out of the root partition and into
the /usr partition. (This is sometimes done to reduce the size of the root partition or when space runs low in the
root partition.) However, /var must not be linked to /usr because this makes separation of /usr and /var
more difficult and is likely to create a naming conflict. Instead, link /var to /usr/var.

Applications must generally not add directories to the top level of /var. Such directories should only be added if
they have some system-wide implication, and in consultation with the FHS mailing list.

See L<Sys::Path/"localstatedir">

Tags: CORE, BASE, FILE

=head3 localtime2date

    $date = localtime2date( time() )

Returns time in format dd.mm.yyyy

Tags: BASE, DATE

=head3 localtime2date_time

    $datetime = localtime2date_time( time() )

Returns time in format dd.mm.yyyy hh.mm.ss

Tags: BASE, DATE

=head3 lockdir

    my $value = lockdir();

For example value can be set as: /var/lock

Lock files should be stored within the /var/lock directory structure.
Lock files for devices and other resources shared by multiple applications, such as the serial device lock files that
were originally found in either /usr/spool/locks or /usr/spool/uucp, must now be stored in /var/lock.
The naming convention which must be used is "LCK.." followed by the base name of the device. For example, to
lock /dev/ttyS0 the file "LCK..ttyS0" would be created. 5

The format used for the contents of such lock files must be the HDB UUCP lock file format. The HDB format is
to store the process identifier (PID) as a ten byte ASCII decimal number, with a trailing newline. For example, if
process 1230 holds a lock file, it would contain the eleven characters: space, space, space, space, space, space,
one, two, three, zero, and newline.

See L<Sys::Path/"lockdir">

Tags: CORE, BASE, FILE

=head3 ls

    @list = ls( $dir);
    @list = ls( $dir, $mask );

A function returns list content of directory $dir by $mask (regexp or scalar string)

Tags: BASE, FILE, ATOM

=head3 prefixdir

    my $value = prefixdir();

For example value can be set as: /usr

/usr - $Config::Config{'prefix'}

Is a helper function and should not be used directly.

/usr is the second major section of the filesystem. /usr is shareable, read-only data. That means that /usr
should be shareable between various FHS-compliant hosts and must not be written to. Any information that is
host-specific or varies with time is stored elsewhere.

Large software packages must not use a direct subdirectory under the /usr hierarchy.

See L<Sys::Path/"prefix">

Tags: CORE, BASE, FILE

=head3 preparedir

    $status = preparedir( $dir );
    $status = preparedir( \@dirs );
    $status = preparedir( \%dirs );
    $status = preparedir( $dir, $chmode );

Preparing directory: creation and permission modification.
The function returns true or false.

The $chmode argument should be a octal value, for example:

    $status = preparedir( [qw/ foo bar baz /], 0777 );

Tags: BASE, FILE, ATOM

=head3 randchars

    $rand = randchars( $n ); # default chars collection: 0..9,'a'..'z','A'..'Z'
    $rand = randchars( $n, \@collection ); # Defined chars collection

Returns random sequence of casual characters by the amount of n

For example:

    $rand = randchars( 8, [qw/a b c d e f/]); # -> cdeccfdf

Tags: BASE, UTIL

=head3 randomize

    $rand = randomize( $n );

Returns random number of the set amount of characters

Tags: BASE, UTIL

=head3 read_attributes

Smart rearrangement of parameters to allow named parameter calling.
We do the rearrangement if the first parameter begins with a "-", but
since 2.82 it is optional condition

    my @args = @_;
    my ($content, $maxcnt, $timeout, $timedie, $base, $login, $password, $host, $table_tmp);
    ($content, $maxcnt, $timeout, $timedie, $base, $login, $password, $host, $table_tmp) =
    read_attributes([
        ['DATA','CONTENT','USERDATA'],
        ['COUNT','MAXCOUNT','MAXCNT'],
        ['TIMEOUT','FORBIDDEN','INTERVAL'],
        ['TIMEDIE','TIME'],
        ['BD','DB','BASE','DATABASE'],
        ['LOGIN','USER'],
        ['PASSWORD','PASS'],
        ['HOST','HOSTNAME','ADDRESS','ADDR'],
        ['TABLE','TABLENAME','NAME','SESSION','SESSIONNAME']
    ],@args) if defined $args[0];

See L<CGI::Util>

Tags: API, BASE

=head3 rundir

    my $value = rundir();

For example value can be set as: /var/run

This directory contains system information data describing the system since it was booted. Files under this
directory must be cleared (removed or truncated as appropriate) at the beginning of the boot process. Programs
may have a subdirectory of /var/run; this is encouraged for programs that use more than one run-time file. 7
Process identifier (PID) files, which were originally placed in /etc, must be placed in /var/run. The naming
convention for PID files is <program-name>.pid. For example, the crond PID file is named
/var/run/crond.pid.

See L<Sys::Path/"rundir">

Tags: CORE, BASE, FILE

=head3 scandirs

    @dirs = scandirs( $dir, $mask );

A function returns all directories of directory $dir by $mask (regexp or scalar string) in
format: [$path, $name]

Tags: BASE, FILE, ATOM

=head3 scanfiles

    @files = scanfiles( $dir, $mask );

A function returns all files of directory $dir by $mask (regexp or scalar string) in
format: [$path, $name]

Tags: BASE, FILE, ATOM

=head3 sendmail, send_mail

    my $sent = sendmail(
        -to       => 'to@example.com',
        -cc       => 'cc@example.com',     ### OPTIONAL
        -from     => 'from@example.com',
        -subject  => 'My subject',
        -message  => 'My message',
        -type     => 'text/plain',
        -charset  => 'utf-8',              ### OPTIONAL
        -smtp     => '192.168.1.1',        ### OPTIONAL
        -smtpuser => '',                   ### OPTIONAL
        -smtppass => '',                   ### OPTIONAL
        -sendmail => '/usr/bin/sendmail -t', ### OPTIONAL, NOT RECOMMENDED
        -smtpargs => { Debug=> 1, ... },   ### OPTIONAL
        -attach   => [                     ### OPTIONAL
            {
                Type=>'text/plain',
                Data=>'document 1 content',
                Filename=>'doc1.txt',
                Disposition=>'attachment',
            },
            {
                Type=>'text/plain',
                Data=>'document 2 content',
                Filename=>'doc2.txt',
                Disposition=>'attachment',
            },
            {
                Type=>'text/html',
                Data=>'blah-blah-blah',
                Filename=>'response.htm',
                Disposition=>'attachment',
            },
            {
                Type=>'image/gif',
                Path=>'aaa000123.gif',
                Filename=>'logo.gif',
                Disposition=>'attachment',
            },
            ### ... ###
          ],
    );
    print($sent ? 'mail has been sent :)' : 'mail was not sent :(');

Send UTF-8 E-mail. See L<MIME::Lite> for details

Tags: UTIL, EXT, ATOM

=head3 sharedir

    my $value = sharedir();

For example value can be set as: /usr/share

The /usr/share hierarchy is for all read-only architecture independent data files. 10
This hierarchy is intended to be shareable among all architecture platforms of a given OS; thus, for example, a
site with i386, Alpha, and PPC platforms might maintain a single /usr/share directory that is
centrally-mounted. Note, however, that /usr/share is generally not intended to be shared by different OSes or
by different releases of the same OS.

Any program or package which contains or requires data that doesn't need to be modified should store that data
in /usr/share (or /usr/local/share, if installed locally). It is recommended that a subdirectory be used in
/usr/share for this purpose.

Game data stored in /usr/share/games must be purely static data. Any modifiable files, such as score files,
game play logs, and so forth, should be placed in /var/games.

See L<Sys::Path/"datadir">

Tags: CORE, BASE, FILE

=head3 sharedstatedir

    my $value = sharedstatedir();

For example value can be set as: /var/lib

This hierarchy holds state information pertaining to an application or the system. State information is data that
programs modify while they run, and that pertains to one specific host. Users must never need to modify files in
/var/lib to configure a package's operation.

State information is generally used to preserve the condition of an application (or a group of inter-related
applications) between invocations and between different instances of the same application. State information
should generally remain valid after a reboot, should not be logging output, and should not be spooled data.

An application (or a group of inter-related applications) must use a subdirectory of /var/lib for its data. There
is one required subdirectory, /var/lib/misc, which is intended for state files that don't need a subdirectory;
the other subdirectories should only be present if the application in question is included in the distribution.

/var/lib/<name> is the location that must be used for all distribution packaging support. Different
distributions may use different names, of course.

See L<Sys::Path/"sharedstatedir">

Tags: CORE, BASE, FILE

=head3 shuffle

    @cards = shuffle(0..51); # 0..51 in a random order

Returns the elements of LIST in a random order

Pure-Perl implementation of Function List::Util::PP::shuffle
(Copyright (c) 1997-2009 Graham Barr <gbarr@pobox.com>. All rights reserved.)

See also L<List::Util>

Tags: BASE, UTIL

=head3 slash

    $slashed = slash( $string );

Escaping symbols \ and ' and returns strings \\ and \'

Tags: BASE, FORMAT

=head3 spooldir

    my $value = spooldir();

For example value can be set as: /var/spool

/var/spool contains data which is awaiting some kind of later processing. Data in /var/spool represents
work to be done in the future (by a program, user, or administrator); often data is deleted after it has been
processed.

See L<Sys::Path/"spooldir">

Tags: CORE, BASE, FILE

=head3 srvdir

    my $value = srvdir();

For example value can be set as: /srv

/srv contains site-specific data which is served by this system.

See L<Sys::Path/"srvdir">

Tags: CORE, BASE, FILE

=head3 sysconfdir

    my $value = sysconfdir();

For example value can be set as: /etc

The /etc hierarchy contains configuration files. A "configuration file" is a local file used to control the operation
of a program; it must be static and cannot be an executable binary.

See L<Sys::Path/"sysconfdir">

Tags: CORE, BASE, FILE

=head3 syslogdir

    my $value = syslogdir();

For example value can be set as: /var/log

This directory contains miscellaneous log files. Most logs must be written to this directory or an appropriate
subdirectory.

See L<Sys::Path/"logdir">

Tags: CORE, BASE, FILE

=head3 tag

    $detagged = tag( $string );

<, >, " and ' chars convert to &lt;, &gt;, &quot; and &#39; strings.

Tags: BASE, FORMAT

=head3 tag_create

    $string = tag_create( $detagged );

Reverse function L</"tag">

Tags: BASE, FORMAT

=head3 to_base64

    $base64_text = to_base64( $utf8_text );

Function to encode strings into the base64 encoding specified in
RFC 2045 - I<MIME (Multipurpose Internet
Mail Extensions)>. The base64 encoding is designed to represent
arbitrary sequences of octets in a form that need not be humanly
readable. A 65-character subset ([A-Za-z0-9+/=]) of US-ASCII is used,
enabling 6 bits to be represented per printable character.

See also L<MIME::Base64>

Tags: BASE, FORMAT

=head3 to_cp1251, to_windows1251

    $win1251_text = to_windows1251( $utf8_text )
    $win1251_text = to_windows1251( $utf8, "Windows-1251" )

Encodes a string from Perl's internal form into I<ENCODING> (Windows-1251) and returns
a sequence of octets ($win1251_text).  ENCODING can be either a canonical name or
an alias. For encoding names and aliases, see L<Encode>.

Tags: BASE, FORMAT

=head3 to_utf8

    $utf8_text = to_utf8( $win1251_text )
    $utf8_text = to_utf8( $win1251_text, "Windows-1251" )

Decodes a sequence of octets ($win1251_text) assumed to be in I<ENCODING> (Windows-1251) into Perl's
internal form and returns the resulting string.  As in encode(),
ENCODING can be either a canonical name or an alias. For encoding names
and aliases, see L<Encode>.

Tags: BASE, FORMAT

=head3 touch

    touch( "file" );

Makes file exist, with current timestamp

Tags: BASE, FILE, ATOM

=head3 trim

    print '"'.trim( "    string " ).'"'; # "string"

Returns the string with all leading and trailing whitespace removed. Trim on undef returns undef.
Original this function see L<String::Util>

Tags: BASE, FORMAT

=head3 C<tz_diff>

    print tz_diff( time );

Returns TimeZone difference value

    print dtf("%w, %DD %MON %YYYY %hh:%mm:%ss ".tz_diff(time), time);

Prints RFC-2822 format date

Tags: BASE, DATE

=head3 unescape

    $str = unescape(escape("10% is enough\n"));

Returns a string with each %XX sequence replaced with the actual byte (octet).

This does the same as:

    $string =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;

See also L<URI::Escape>

Tags: BASE, FORMAT

=head3 variant_stf

    $fixlenstr = variant_stf( "qwertyuiop", 3 ); # -> q.p
    $fixlenstr = variant_stf( "qwertyuiop", 7 ); # -> qw...op

Returns a line the fixed length from 3 to the n chars

Tags: BASE, FORMAT

=head3 visokos

    $lybool = visokos( 2012 );

Returns a leap-year or not

Tags: BASE, DATE

=head3 webdir

    my $value = webdir();

For example value can be set as: /var/www

Directory where distribution put static web files.

See L<Sys::Path/"webdir">

Tags: CORE, BASE, FILE

=head3 where

    my @ls = which( "ls" );

Get all paths to specified command. Same as which() but will return all the matches.

Based on L<File::Which>

Tags: UTIL, EXT, ATOM

=head3 which

    my $ls = which( "ls" );

Get full path to specified command

First argument is the name used in the shell to call the program, e.g., perl.

If it finds an executable with the name you specified, which() will return
the absolute path leading to this executable, e.g., /usr/bin/perl or C:\Perl\Bin\perl.exe.

If it does not find the executable, it returns undef.

Based on L<File::Which>

Tags: UTIL, EXT, ATOM

=head2 TAGS

=over 8

=item B<:ALL>

Exports all functions

=item B<:API>

Exports functions:

L</"getsyscfg">,
L</"isos">,
L</"isostype">,
L</"read_attributes">,
L</"syscfg">

=item B<:ATOM>

Exports all function FILE and EXT

=item B<:BASE>

Exports all function API, FILE, FORMAT, DATE and:

L</"randchars">,
L</"randomize">,
L</"shuffle">

=item B<:CORE>

Exports functions:

L</"cachedir">,
L</"docdir">,
L</"localedir">,
L</"localstatedir">,
L</"lockdir">,
L</"prefixdir">,
L</"rundir">,
L</"sharedir">,
L</"sharedstatedir">,
L</"spooldir">,
L</"srvdir">,
L</"sysconfdir">,
L</"syslogdir">,
L</"webdir">

=item B<:DATE>

Exports functions:

L</"basetime">,
L</"correct_date">,
L</"current_date">,
L</"current_date_time">,
L</"date_time2dig">,
L</"date2dig">,
L</"date2localtime">,
L</"datef">,
L</"datetime2localtime">,
L</"datetimef">,
L</"dig2date">,
L</"dig2date_time">,
L</"dtf">,
L</"localtime2date">,
L</"localtime2date_time">,
L</"tz_diff">,
L</"visokos">

=item B<:EXT>

Exports functions:

L</"exe">,
L</"execute">,
L</"ftp">,
L</"ftpgetlist">,
L</"ftptest">,
L</"send_mail">,
L</"sendmail">,
L</"where">,
L</"which">

=item B<:FILE>

Exports all function CORE and:

L</"bload">,
L</"bsave">,
L</"eqtime">,
L</"file_load">,
L</"file_save">,
L</"fload">,
L</"fsave">,
L</"getdirlist">,
L</"getfilelist">,
L</"getlist">,
L</"load_file">,
L</"ls">,
L</"preparedir">,
L</"save_file">,
L</"scandirs">,
L</"scanfiles">,
L</"touch">

=item B<:FORMAT>

Exports functions:

L</"cdata">,
L</"correct_dig">,
L</"correct_number">,
L</"dformat">,
L</"escape">,
L</"fformat">,
L</"file_lf_normalize">,
L</"file_nl_normalize">,
L</"from_utf8">,
L</"lf_normalize">,
L</"nl_normalize">,
L</"slash">,
L</"tag">,
L</"tag_create">,
L</"to_base64">,
L</"to_cp1251">,
L</"to_utf8">,
L</"to_windows1251">,
L</"trim">,
L</"unescape">,
L</"variant_stf">,

=item B<:UTIL>

Exports all function EXT and:

L</"isFalseFlag">,
L</"isTrueFlag">,
L</"randchars">,
L</"randomize">,
L</"shuffle">

=back

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<Config>, L<Cwd>, L<Encode>, L<File::Path>, L<File::Spec>, L<IPC::Open3>,
L<MIME::Base64>, L<MIME::Lite>, L<Net::FTP>, L<Perl::OSType>, L<Symbol>,
L<Time::Local>, L<List::Util>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<CGI::Util>, L<IPC::Open3>, L<List::Util>, L<MIME::Lite>, L<Net::FTP>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use constant {
    DEBUG     => 1, # 0 - off, 1 - on, 2 - all (+ http headers and other)
    WIN       => $^O =~ /mswin/i ? 1 : 0,
    NULL      => $^O =~ /mswin/i ? 'NUL' : '/dev/null',
    TONULL    => $^O =~ /mswin/i ? '>NUL 2>&1' : '>/dev/null 2>&1',
    ERR2OUT   => '2>&1',
    VOIDFILE  => 'void.txt',
    DTF       => {
                    DOW  => [qw/Sunday Monday Tuesday Wednesday Thursday Friday Saturday/],
                    DOWS => [qw/Sun Mon Tue Wed Thu Fri Sat/],
                    MOY  => [qw/January February March April May June
                             July August September October November December/],
                    MOYS => [qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/],

                },
};

use vars qw/$VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS/;
$VERSION = '2.83';

use Encode;
use Time::Local;
use File::Spec::Functions qw/
        catdir catfile rootdir tmpdir updir curdir
        path splitpath splitdir abs2rel rel2abs
    /;
use MIME::Base64;
use MIME::Lite;
use Net::FTP;
use File::Path; # mkpath / rmtree
use IPC::Open3;
use Symbol;
use Cwd;

use Carp qw/carp croak cluck confess/;
# carp    -- as warn
# croak   -- as die
# cluck   -- as extended warn
# confess -- as extended die

use base qw /Exporter/;
my @est_api = qw(
        read_attributes
        syscfg getsyscfg isos isostype
    );
my @est_core = qw(
        prefixdir localstatedir sysconfdir srvdir
        sharedir docdir localedir cachedir syslogdir spooldir rundir lockdir sharedstatedir webdir
    );
my @est_util = qw(
        randomize randchars shuffle isTrueFlag isFalseFlag
    );
my @est_encoding = qw(
        to_utf8 to_windows1251 to_cp1251 to_base64 from_utf8
    );
my @est_format = qw(
        escape unescape slash tag tag_create cdata dformat fformat
        lf_normalize nl_normalize file_lf_normalize file_nl_normalize
        correct_number correct_dig
        variant_stf trim
    );
my @est_datetime = qw(
        current_date current_date_time localtime2date localtime2date_time correct_date date2localtime
        datetime2localtime visokos date2dig dig2date date_time2dig dig2date_time basetime
        dtf datetimef datef tz_diff
    );
my @est_file = qw(
        load_file save_file file_load file_save fsave fload bsave bload touch eqtime
    );
my @est_dir = qw(
        ls scandirs scanfiles getlist getfilelist getdirlist
        preparedir
    );
my @est_ext = qw(
        sendmail send_mail
        ftp ftptest ftpgetlist
        exe execute where which
    );

@EXPORT = (); # Defaults none

@EXPORT_OK = ( # All
        @est_api, @est_core, @est_encoding, @est_format, @est_datetime,
        @est_file, @est_dir, @est_ext, @est_util
    );

%EXPORT_TAGS = (
        DEFAULT => [@EXPORT],
        ALL     => [@EXPORT_OK],
        API     => [
                @est_api
            ],
        CORE    => [
                @est_core,
            ],
        FORMAT  => [
                @est_encoding,
                @est_format,
            ],
        DATE    => [
                @est_datetime,
            ],
        FILE    => [
                @est_core,
                @est_file,
                @est_dir,
            ],
        EXT     => [
                @est_ext,
            ],
        UTIL    => [
                @est_ext,
                @est_util,
            ],
        ATOM   => [
                @est_file, @est_dir,
                @est_ext,
            ],
        BASE    => [
                @est_api,
                @est_core, @est_file, @est_dir,
                @est_encoding, @est_format,
                @est_datetime,
                @est_util,
            ],
    );

# Backend class
push @CTK::Util::ISA, qw/CTK::Util::SysConfig/;

my $CRLF = _crlf();

#
# Format functions
#

sub to_utf8 { # Default: Windows-1251
    my $ss = shift;
    my $ch = shift || 'Windows-1251';
    my $ret = "";
    Encode::_utf8_on($ret);
    return $ret unless defined($ss);
    return Encode::decode($ch,$ss)
}
sub from_utf8 { # Default: Windows-1251
    my $ss = shift;
    my $ch = shift || 'Windows-1251';
    my $ret = "";
    Encode::_utf8_off($ret);
    return $ret unless defined($ss);
    return Encode::encode($ch,$ss)
}
sub to_windows1251 {
    return from_utf8(shift, 'Windows-1251');
}
sub to_cp1251 { goto &to_windows1251 };
sub to_base64 {
    # Converts UTF-8 string to base64 (RFC 2047)
    my $ss = shift; # Сообщение
    return '=?UTF-8?B??=' unless defined($ss);
    return sprintf('=?UTF-8?B?%s?=', MIME::Base64::encode(Encode::encode('UTF-8', $ss), ''));
}
sub slash {
    # \ -> \\
    # ' -> \'
    my $data_staring = shift;
    return '' unless defined($data_staring);
    $data_staring =~ s/\\/\\\\/g;
    $data_staring =~ s/'/\\'/g;
    return $data_staring;
}
sub tag {
    # <, >, " and ' chars convert to &lt;, &gt;, &quot; and &#39; strings
    my $data_staring = shift;
    return '' unless defined($data_staring);
    $data_staring =~ s/</&lt;/g;
    $data_staring =~ s/>/&gt;/g;
    $data_staring =~ s/\"/&quot;/g;
    $data_staring =~ s/\'/&#39;/g;
    return $data_staring;
}
sub tag_create {
    # &lt -> < and etc. See tag
    my $data_staring = shift;
    return '' unless defined($data_staring);
    $data_staring =~ s/\&#39\;/\'/g;
    $data_staring =~ s/\&lt\;/\</g;
    $data_staring =~ s/\&gt\;/\>/g;
    $data_staring =~ s/\&quot\;/\"/g;
    return $data_staring;
}
sub cdata {
    my $s = shift;
    my $ss  = to_utf8('<![CDATA[');
    my $sf  = to_utf8(']]>');
    if (defined $s) {
        return $ss.$s.$sf;
    }
    return to_utf8('');
}
sub escape { # Percent-encoding, also known as URL encoding
    my $toencode = shift;
    return '' unless defined($toencode);
    $toencode =~ s/([^a-zA-Z0-9_.~-])/uc(sprintf("%%%02x",ord($1)))/eg;
    return $toencode;
}
sub unescape { # Percent-decoding, also known as URL decoding
    my $todecode = shift;
    return '' unless defined($todecode);
    $todecode =~ tr/+/ /; # pluses become spaces
    $todecode =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
    return $todecode;
}
sub lf_normalize {
    # line feed normalize in string
    my $s = shift // return '';
    $s =~ s/(\x0D*\x0A)|(\x0D)/_proxy_crlf($CRLF)/ges;
    return $s;
}
sub nl_normalize { goto &lf_normalize }
sub file_lf_normalize {
    # line feed normalize in file. Original: dos2unix
    my $f = shift // return 0;
    return 0 unless -e $f;
    return 0 if -d $f;
    return 0 unless -w $f;
    return 0 unless -r $f;
    return 0 if -B $f;

    local $\;

    my $temp = sprintf('%s.%d.tmp',$f,$$);
    open ORIG, $f or do { carp "Can't open $f: $!"; return 0 };
    open TEMP, ">$temp" or do { carp "Can't create $temp: $!"; return 0 };
    binmode(TEMP);
    while (my $line = <ORIG>) {
        print TEMP lf_normalize($line);
    }
	close ORIG;
	close TEMP;
	rename $temp, $f;
    return 1;
}
sub file_nl_normalize { goto &file_lf_normalize }
sub dformat {
    my $fmt = shift // '';
    my $fd  = shift || {};
    $fmt =~ s/\[([a-z0-9_\-.]+?)\]/(defined($fd->{uc($1)}) ? $fd->{uc($1)} : "[$1]")/ieg;
    return $fmt;
}
sub fformat {
    # [FILENAME] -- Filename only
    # [NAME]     -- =FILENAME
    # [FILEEXT]  -- File extension only
    # [EXT]      -- =FILEEXT
    # [FILE]     -- Filename and extension
    my $fmt = shift // ''; # [FILENAME]-blah-blah-blah.[FILEEXT]
    my $fin = shift // ''; # void.txt
    my ($fn,$fe) = ($fin =~ /^(.+)\.([0-9a-zA-Z]+)$/) ? ($1,$2) : ($fin,'');
    $fmt =~ s/\[FILENAME\]/$fn/ig;
    $fmt =~ s/\[NAME\]/$fn/ig;
    $fmt =~ s/\[FILEEXT\]/$fe/ig;
    $fmt =~ s/\[EXT\]/$fe/ig;
    $fmt =~ s/\[FILE\]/$fin/ig;
    return $fmt; # void-blah-blah-blah.txt
}
sub correct_number {
    my $var = shift || 0;
    my $sep = shift || "`";
    1 while $var=~s/(\d)(\d\d\d)(?!\d)/$1$sep$2/;
    return $var;
}
sub correct_dig {
    my $dig = shift || 0;
    if ($dig =~ /^\s*(\d+)\s*$/) {
        return $1;
    }
    return 0;
}
sub trim {
    my $val = shift;
    return unless defined $val;
    $val =~ s|^\s+||s; # trim left
    $val =~ s|\s+$||s; # trim right
    return $val;
}

#
# Date and time
#

sub localtime2date {
    # localtime2date ( time() ) # => 02.12.2010
    my $dandt = shift || time();
    my @dt = localtime($dandt);
    return sprintf (
        "%02d.%02d.%04d",
        $dt[3], # Day
        $dt[4]+1, # Month
        $dt[5]+1900 # Year
    );
}
sub localtime2date_time {
    my $dandt = shift || time();
    my @dt = localtime($dandt);
    return sprintf (
        "%02d.%02d.%04d %02d:%02d:%02d",
        $dt[3], # Day
        $dt[4]+1, # Month
        $dt[5]+1900, # Year
        $dt[2], # Hour
        $dt[1], # Min
        $dt[0]  # Sec
    );
}
sub current_date { localtime2date() }
sub current_date_time { localtime2date_time() }
sub correct_date {
    my $date = shift;
    if ($date  =~/^\s*(\d{1,2})\D+(\d{1,2})\D+(\d{4})\s*$/) {
        my $dd = (($1<10)?('0'.($1/1)):$1);
        my $mm = (($2<10)?('0'.($2/1)):$2);
        my $yyyy=$3;
        if (($dd > 31) or ($dd <= 0)) {return ''};
        if (($mm > 12) or ($mm <= 0)) {return ''};
        my @aday = (31,28+visokos($yyyy),31,30,31,30,31,31,30,31,30,31);
        if ($dd > $aday[$mm-1]) {return ''}
        return "$dd.$mm.$yyyy";
    } else {
        return '';
    }
}
sub date2localtime {
    my $dtin= shift || return 0;
    if ($dtin=~/^\s*(\d{1,2})\.+(\d{1,2})\.+(\d{4}).*$/) {
        return timelocal(0,0,0,$1,$2-1,$3-1900);
    }
    return 0
}
sub datetime2localtime {
    my $dtin= shift || return 0;
    if ($dtin=~/^\s*(\d{1,2})\.+(\d{1,2})\.+(\d{4})\s+(\d{1,2})\:(\d{1,2})\:(\d{1,2}).*$/) {
        return timelocal(
                $6 || 0,
                $5 || 0,
                $4 || 0,
                $1 || 1,
                $2 ? $2-1 : 0,
                $3 ? $3-1900 : 0,
            );
    }
    return 0
}
sub visokos {
    my $arg = shift || 1;
    if ((($arg % 4) == 0 ) and not ( (($arg % 100) == 0) and (($arg % 400) != 0) )) {
        return 1;
    } else {
        return 0;
    }
}
sub date2dig {
    # date2dig( $date ) # 02.12.2010 => 20101202
    my $val = shift || &localtime2date();
    my $stat=$val=~s/^\s*(\d{1,2})\.+(\d{1,2})\.+(\d{4}).*$/$3$2$1/;
    $val = '' unless $stat;
    return $val;
}
sub dig2date {
    my $val = shift || date2dig();
    my $stat=$val=~s/^\s*(\d{4})(\d{2})(\d{2}).*$/$3.$2.$1/;
    $val = '' unless $stat;
    return $val;
}
sub date_time2dig {
    my $val = shift || current_date_time();
    my $stat=$val=~s/^\s*(\d{2})\.+(\d{2})\.+(\d{4})\D+(\d{2}):(\d{2}):(\d{2}).*$/$3$2$1$4$5$6/;
    $val = '' unless $stat;
    return $val;
}
sub dig2date_time {
    my $val = shift || date_time2dig();
    my $stat=$val=~s/^\s*(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2}).*$/$3.$2.$1 $4:$5:$6/;
    $val = '' unless $stat;
    return $val;
}
sub basetime {
    return time() - $^T
}
sub dtf {
    my $f = shift || '';
    my $t = shift || time();
    my $g = shift || 0; # GMT time switch
    my $z = ($g && $g =~ /^[\-+]?[1-9]$/) ? 'GMT' : ($g || '');

    my (@dt,%dth, %dth2);
    @dt = ($g && $z =~ /GMT|UTC/) ? gmtime($t) : localtime($t);
    $dth{'%s'}     = $dt[0] || 0;
    $dth{'%ss'}    = sprintf('%02d',$dth{'%s'});
    $dth{'%_s'}    = sprintf('%2d',$dth{'%s'});
    $dth{'%m'}     = $dt[1] || 0;
    $dth{'%mm'}    = sprintf('%02d',$dth{'%m'});
    $dth{'%_m'}    = sprintf('%2d',$dth{'%m'});
    $dth{'%h'}     = $dt[2] || 0;
    $dth{'%hh'}    = sprintf('%02d',$dth{'%h'});
    $dth{'%_h'}    = sprintf('%2d',$dth{'%h'});
    $dth{'%D'}     = $dt[3] || 0;
    $dth{'%DD'}    = sprintf('%02d',$dth{'%D'});
    $dth{'%_D'}    = sprintf('%2d',$dth{'%D'});
    $dth{'%M'}     = $dt[4] || 0; $dth{'%M'}++;
    $dth{'%MM'}    = sprintf('%02d',$dth{'%M'});
    $dth{'%_M'}    = sprintf('%2d',$dth{'%M'});
    $dth{'%Y'}     = $dt[5] || 0; $dth{'%Y'}+=1900;
    $dth{'%YY'}    = sprintf('%02d',$dth{'%Y'}%100);
    $dth{'%YYY'}   = sprintf('%03d',$dth{'%Y'}%1000);
    $dth{'%YYYY'}  = sprintf('%04d',$dth{'%Y'});
    $dth{'%_Y'}    = sprintf('%2d',$dth{'%Y'}%100);
    $dth{'%_YY'}   = sprintf('%3d',$dth{'%Y'}%1000);
    $dth{'%w'}     = DTF->{DOWS}->[$dt[6] || 0];
    $dth{'%W'}     = DTF->{DOW}->[$dt[6] || 0];
    $dth{'%MON'}   = DTF->{MOYS}->[$dt[4] || 0];
    $dth{'%mon'}   = DTF->{MOYS}->[$dt[4] || 0];
    $dth{'%MONTH'} = DTF->{MOY}->[$dt[4] || 0];
    $dth{'%month'} = DTF->{MOY}->[$dt[4] || 0];

    # Second block
    $dth2{'%G'}    = 'GMT' if $g;
    $dth2{'%U'}    = 'UTC' if $g;
    $dth2{'%Z'}    = $z;
    $dth2{'%%'}    = '%';

    $f =~ s/$_/$dth{$_}/sge for sort { length($b) <=> length($a) } keys %dth;
    $f =~ s/$_/$dth2{$_}/sge for qw/%G %U %Z %%/;

    return $f
}
sub datef { goto &dtf }
sub datetimef { goto &dtf }
sub tz_diff {
    my $tm = shift || time;
    my $diff = Time::Local::timegm(localtime($tm)) - Time::Local::timegm(gmtime($tm));
    my $direc = $diff < 0 ? '-' : '+';
    $diff  = abs($diff);
    my $tz_hr = int( $diff / 3600 );
    my $tz_mi = int( $diff / 60 - $tz_hr * 60 );
    return sprintf("%s%02d%02d", $direc, $tz_hr, $tz_mi);
}

sub variant_stf {
    my $S = shift // '';
    my $length_s = shift || 0;
    my $countpoints;

    $length_s = 3 if $length_s < 3;
    if ($length_s < 6) {
        $countpoints = $length_s - 2;
    }
    else {
        $countpoints = 3;
    }

    my $reallenght = $length_s - $countpoints;

    my ($Snew,$fix,$new_start,$dot,$new_midle,$new_end);
    if (length($S) <= $length_s) {
        $Snew = $S;
    } else {
        $fix= sprintf "%d",($reallenght / 2);
        $new_start = substr($S, 0, ($reallenght - $fix));
        $dot='.';
        $new_midle = $dot x $countpoints;
        $new_end = substr($S,(length($S)-$fix),$fix);
        $new_start=~s/\s+$//;
        $new_end=~s/^\s+//;
        $Snew = $new_start.$new_midle.$new_end;
    }
    return $Snew;
}
sub randomize {
    my $digs = shift || return 0;
    my $rstat;
    for (my $i=0; $i<$digs; $i++) {
       $rstat.=int(rand(10));
    }
    $rstat = substr($rstat,0,abs($digs));
    return "$rstat"
}
sub randchars {
    my $l = shift || return '';
    return '' unless $l =~/^\d+$/;
    my $arr = shift;

    my $result = '';
    my @chars = ($arr && ref($arr) eq 'ARRAY') ? (@$arr) : (0..9,'a'..'z','A'..'Z');
    $result .= $chars[(int(rand($#chars+1)))] for (1..$l);

    return $result;
}
sub shuffle {
    # See List::Util::PP
    return unless @_;
    my @a=\(@_);
    my $n;
    my $i=@_;
    map {
        $n = rand($i--);
        (${$a[$n]}, $a[$n] = $a[$i])[0];
    } @_;
}
sub isTrueFlag {
    my $flag = shift || return 0;
    return $flag =~ /^(on|y|true|enable|1)/i ? 1 : 0;
}
sub isFalseFlag {
    my $flag = shift || return 1;
    return $flag =~ /^(off|n|false|disable|0)/i ? 1 : 0;
}


#
# Files (text mode)
#
sub load_file { # Text mode
    my $filename = shift // return '';
    return '' unless length($filename);
    my $text ='';
    local *FILE;
    if(-e $filename){
        my $ostat = open(FILE,"<",$filename);
        if ($ostat) {
            read(FILE, $text, -s $filename) unless -z $filename;
            close FILE;
        } else {
            carp("fload: Can't open file to load \"$filename\": $!");
        }
    }
    return $text;
}
sub save_file { # Text mode
    my $filename = shift // return 0;
    my $text = shift // '';
    return 0 unless length($filename);
    local *FILE;
    my $ostat = open(FILE,">",$filename);
    if ($ostat) {
        flock (FILE, 2) or carp("fsave: Can't lock file \"$filename\": $!");
        print FILE $text;
        close FILE;
    } else {
        carp("fsave: Can't open file to write \"$filename\": $!");
        return 0;
    }
    return 1;
}
sub fload { goto &load_file }
sub fsave { goto &save_file }

#
# Files (bin mode)
#
sub file_load {
    my $fn     = shift // return '';
    my $onutf8 = shift;
    my $IN;
    return '' unless length($fn);

    if (ref $fn eq 'GLOB') {
        $IN = $fn;
    } else {
        my $ostat = open $IN, '<', $fn;
        unless ($ostat) {
            carp("bload: Can't open file to load \"$fn\": $!");
            return '';
        }
    }
    binmode $IN, ':raw:utf8' if $onutf8;
    binmode $IN unless $onutf8;
    return scalar(do { local $/; <$IN> });
}
sub file_save {
    my $fn      = shift // return 0;
    my $content = shift // '';
    my $onutf8 = shift;
    return 0 unless length($fn);
    my $OUT;
    my $flc = 0;
    if (ref $fn eq 'GLOB') {
       $OUT = $fn;
    } else {
        open($OUT, '>', $fn) or do {
            carp("bsave: Can't open file to write \"$fn\": $!");
            return 0;
        };
        flock($OUT, 2) or carp("bsave: Can't lock file \"$fn\": $!");
        $flc = 1;
    }
    if ($onutf8) {
        binmode($OUT, ':raw:utf8');
    } else {
        binmode($OUT);
    }
    print $OUT $content;
    close $OUT if $flc;
    return 1;
}
sub bload { goto &file_load } # двоичное чтение
sub bsave { goto &file_save } # двоичная запись

#
# Files utilities
#
sub touch {
    # See ExtUtils::Command)
    my $fn  = shift // '';
    return 0 unless length($fn);
    my $t = time;
    my $OUT;
    my $ostat = open $OUT, '>>', $fn;
    unless ($ostat) {
        carp("touch: Can't open file to write \"$fn\": $!");
        return 0;
    }
    close $OUT if $ostat;
    utime($t,$t,$fn);
    return 1;
}
sub eqtime {
    # Делаем файл такой же датой создания и модификации
    my $src = shift // '';
    my $dst = shift // '';
    return 0 unless length($src);
    return 0 unless length($dst);
    unless ($src && -e $src) {
        carp("eqtime: Can't open file to read \"$src\": $!");
        return 0;
    }
    unless (utime((stat($src))[8,9],$dst)) {
        carp("eqtime: Can't change access and modification times on file \"$dst\": $!");
        return 0;
    }
    return 1;
}
sub preparedir {
    my $din = shift // return 0;
    my $chmod = shift; # 0777

    my @dirs;
    if (ref($din) eq 'HASH') {
        foreach my $k (values %$din) { push @dirs, $k if length($k // '') };
    } elsif (ref($din) eq 'ARRAY') {
        @dirs = grep { defined($_) && length($_) } @$din;
    } else { push @dirs, $din if length($din) }
    my $stat = 1;
    foreach my $dir (@dirs) {
        mkpath( $dir, {verbose => 0} ) unless -e $dir; # mkdir $dir unless -e $dir;
        chmod($chmod, $dir) if defined($chmod) && -e $dir;
        unless (-d $dir or -l $dir) {
            $stat = 0;
            carp("preparedir: Directory don't prepare \"$dir\"");
        }
    }
    return $stat;
}
sub scandirs {
    my $dir = shift // cwd() // curdir() // '.';
    my $mask = shift // '';

    my @dirs;

    @dirs = grep {!(/^\.+$/) && -d catdir($dir,$_)} ls($dir, $mask);
    @dirs = sort {$a cmp $b} @dirs;

    return map {[catdir($dir,$_), $_]} @dirs;
}
sub scanfiles {
    my $dir = shift // cwd() // curdir() // '.';
    my $mask = shift // '';

    my @files;
    @files = grep { -f catfile($dir,$_)} ls($dir, $mask);
    @files = sort {$a cmp $b} @files;

    return map {[catfile($dir,$_), $_]} @files;
}
sub ls {
    my $dir = shift // curdir() // '.';
    my $mask = shift // '';

    my @fds;

    my $dh = gensym();
    unless (opendir($dh,$dir)) {
        carp("ls: Can't open directory \"$dir\": $!");
        return @fds;
    }

    @fds = readdir($dh);
    closedir($dh);
    if ($mask && ref($mask) eq 'Regexp') {
        return grep {$_ =~ $mask} @fds;
    } else {
        return grep {/$mask/} @fds if length($mask);
    }
    return @fds;
}
sub getfilelist {
    return [map {$_->[1]} scanfiles(@_)];
}
sub getlist { goto &getfilelist }
sub getdirlist {
    return [map {$_->[1]} scandirs(@_)];
}

#
# Extended
#

sub send_mail { # MIME::Lite interface only
    my @args = @_;
    my ($to, $cc, $from, $subject, $message, $type,
     $sendmail, $charset, $smtp, $smtpuser, $smtppass, $att, $smtpargs) =
    read_attributes([
        ['TO','ADDRESS'],
        ['COPY','CC'],
        ['FROM'],
        ['SUBJECT','SUBJ','SBJ'],
        ['MESSAGE','CONTENT','TEXT'],
        ['TYPE','CONTENT-TYPE','CONTENT_TYPE'],
        ['PROGRAM','SENDMAIL',],
        ['CHARSET','CHARACTER_SET'],
        ['SMTP','MAILSERVER','SERVER','HOST'],
        ['SMTPLOGIN','AUTHLOGIN','LOGIN','SMTPUSER','AUTHUSER','USER'],
        ['SMTPPASSWORD','AUTHPASSWORD','PASSWORD','SMTPPASS','AUTHPASS','PASS'],
        ['ATTACH','ATTACHE','ATT'],
        ['SMTPARGS','ARGS','ARGUMENTS'],
    ],@args) if defined $args[0];

    $to           //= '';
    $cc           //= '';
    $from         //= '';
    $subject      //= '';
    $message      //= '';
    $type         //= "text/plain";
    $sendmail     //= '';
    $charset      //= "utf-8";
    $smtp         //= '';
    $smtpuser     //= '';
    $smtppass     //= '';

    if ($charset !~ /utf\-?8/i) {
        $subject = to_utf8($subject, $charset);
        $message = to_utf8($message, $charset);
    }

    # Object
    my $msg = MIME::Lite->new(
        From     => $from,
        To       => $to,
        $cc ? (Cc => $cc) : (),
        Subject  => $subject, # to_base64($subject),
        Type     => $type,
        Encoding => 'base64',
        Data     => Encode::encode('UTF-8', $message)
    );
    $msg->attr('content-type.charset' => 'UTF-8');
    $msg->attr('Content-Transfer-Encoding' => 'base64');

    # Attaches
    if ($att) {
        if (ref($att) =~ /HASH/i) {
            $msg->attach(%$att);
        } elsif  (ref($att) =~ /ARRAY/i) {
            foreach (@$att) {
                if (ref($_) =~ /HASH/i) {
                    $msg->attach(%$_);
                } else {
                    carp("Can't attach scalar data. Please use hash structure");
                }
            }
        } else {
            carp("Can't attach scalar data. Please use hash structure or array of hashes");
        }
    }

    # Sending
    my $sendstat;
    my %tmp = ($smtpargs && ref($smtpargs) eq 'HASH') ? %$smtpargs : ();
    if ($smtp) { # If SMTP
        $tmp{AuthUser} //= $smtpuser if length($smtpuser);
        $tmp{AuthPass} //= $smtppass if length($smtppass);
        eval { $sendstat = $msg->send('smtp', $smtp, %tmp); };
        carp(sprintf("sendmail (smtp://%s): %s", $smtp, $@)) if $@;
    } elsif ($sendmail && -e $sendmail) { # Try sendmail program
        eval { $sendstat = $msg->send('sendmail', $sendmail); };
        carp(sprintf("sendmail (%s): %s", $sendmail, $@)) if $@;
    } else { # Try without args
        eval { $sendstat = $msg->send(); };
        carp(sprintf("sendmail (default): %s", $@)) if $@;
    }
    return $sendstat ? 1 : 0;
}
sub sendmail { goto &send_mail }
sub ftp {
    #my %ftpct = (
    #    ftphost     => '192.168.1.1',
    #    ftpuser     => 'login',
    #    ftppassword => 'password',
    #    ftpdir      => '~/',
    #    voidfile    => './void.txt',
    #    #ftpattr    => {},
    #);
    #my $rfiles = CTK::ftp(\%ftpct, 'ls');
    #my @remotefiles = $rfiles ? grep {!(/^\./)} @$rfiles : ();
    #ftp(\%ftpct, 'put', catfile($dirin,$file), $file);

    my $ftpconnect  = shift || {};
    my $cmd         = shift || '';
    my $lfile       = shift || '';
    my $rfile       = shift || '';

    unless ($ftpconnect && (ref($ftpconnect) eq 'HASH') && $ftpconnect->{ftphost}) {
        carp("Connect's data missing");
        return undef;
    }

    my $ftphost     = $ftpconnect ? $ftpconnect->{ftphost}     : '';
    my $ftpuser     = $ftpconnect ? $ftpconnect->{ftpuser}     : '';
    my $ftppassword = $ftpconnect ? $ftpconnect->{ftppassword} : '';
    my $ftpdir      = $ftpconnect ? $ftpconnect->{ftpdir}      : '';
    my $attr        = $ftpconnect &&  $ftpconnect->{ftpattr} ? $ftpconnect->{ftpattr} : {};
    $attr->{Debug}  = (DEBUG && DEBUG == 2) ? 1 : 0;

    my $ftp = Net::FTP->new($ftphost, %$attr)
        or do { carp("FTP: Can't connect to remote FTP server $ftphost: $@"); return undef};
    $ftp->login($ftpuser, $ftppassword)
        or do {carp("FTP: Can't login to remote FTP server: ", $ftp->message); return undef};
    if ($ftpdir && !$ftp->cwd($ftpdir)) {
        carp("FTP: Can't change FTP working directory \"$ftpdir\": ", $ftp->message);
        return undef;
    }

    my @out;
    if ( $cmd eq "connect" ){
        return $ftp; # Returns handler
    } elsif ( $cmd eq "ls" ){
        (my @out = $ftp->ls(WIN ? "" : "-1a" ))
            or carp( "FTP: Can't get directory listing (\"$ftpdir\") from remote FTP server $ftphost: ", $ftp->message );
        $ftp->quit;
        return [@out];
    } elsif (!$lfile) {
        carp("FTP: No filename given as parameter to FTP command $cmd");
    } elsif ($cmd eq "delete") {
        $ftp->delete($lfile)
            or carp( "FTP: Can't delete file \"$lfile\" on remote FTP server $ftphost: ", $ftp->message );
    } elsif ($cmd eq "get") {
        $ftp->binary;
        $ftp->get($rfile,$lfile)
            or carp("FTP: Can't get file \"$lfile\" from remote FTP server $ftphost: ", $ftp->message);
    } elsif ($cmd eq "put") {
        $ftp->binary;
        $ftp->put($lfile,$rfile)
            or carp("FTP: Can't put file \"$lfile\" on remote FTP server $ftphost: ", $ftp->message );
    }

    $ftp->quit;
    return 1;
}
sub ftptest {
    my $ftpdata = shift || undef;
    unless ($ftpdata) {
        carp("Connect's data missing");
        return undef;
    }
    my $vfile = '';
    if ($ftpdata->{voidfile}) {
        $vfile = $ftpdata->{voidfile};
    } else {
        $vfile = catfile(tmpdir(), VOIDFILE);
        touch($vfile);
    }
    unless (-e $vfile) {
        carp("VOID file \"$vfile\" missing");
        return undef;
    }
    ftp($ftpdata, 'put', $vfile, VOIDFILE);
    my $rfiles = ftp($ftpdata,'ls');
    my @remotefiles = $rfiles ? grep {!(/^\./)} @$rfiles : ();
    unless (grep {$_ eq VOIDFILE} @remotefiles) {
        carp("Can't connect to remote FTP server {".join(", ",(%$ftpdata))."}");
        return undef;
    }
    ftp($ftpdata, 'delete', VOIDFILE);
    return 1;
}
sub ftpgetlist {
    my $connect  = shift || {};
    my $mask     = shift || '';

    my $rfile = ftp($connect, 'ls');
    my @files = (($rfile && ref($rfile) eq 'ARRAY') ? @$rfile : ());

    if ($mask && ref($mask) eq 'Regexp') {
        @files = grep {$_ =~ $mask} @files;
    } else {
        @files = grep {/$mask/} @files if $mask;
    }

    return [@files];
}
sub execute {
    my $icmd = shift || '';
    my $in   = shift;
    my $out  = '';
    my $err  = shift; # !! REFERENCE TO SCALAR
    my $bm   = shift;

    my @scmd;
    if ($icmd && ref($icmd) eq 'ARRAY') {
        @scmd = @$icmd;
    } else {
        push @scmd, $icmd;
    }

    local (*IN, *OUT, *ERR);
    my $pid	= open3(\*IN, \*OUT, \*ERR, @scmd);

    # 0 Input
    binmode(IN) if defined($bm) && $bm && $bm =~ /^\d+$/;
    binmode(IN, $bm) if defined($bm) && $bm =~ /\:/;
    print IN $in if defined $in;
    close IN;

    # 1 Output
    binmode(OUT) if defined($bm) && $bm && $bm =~ /^\d+$/;
    binmode(OUT, $bm) if defined($bm) && $bm =~ /\:/;
    while (<OUT>) { $out .= $_ }
    close OUT;

    # 2 Error
    my $ierr = '';
    binmode(ERR) if defined($bm) && $bm && $bm =~ /^\d+$/;
    binmode(ERR, $bm) if defined($bm) && $bm =~ /\:/;
    while (<ERR>) { $ierr .= $_ }
    close ERR;

    waitpid($pid, 0);
    if ($err && ref($err) eq 'SCALAR') {
        $$err = $ierr
    } else {
        carp("Executable error (".join(" ", @scmd)."): $ierr") if $ierr;
    }

    return $out;
}
sub exe { goto &execute }
sub which {
    my $cs = shift;
    my $wh = shift;
    return undef unless defined $cs;
    return undef if $cs eq '';
    my @aliases = ($cs);
    if (isostype('Windows')) {
        my @pext = (qw/.com .exe .bat/);
        if ($ENV{PATHEXT}) {
            push @pext, split /\s*\;\s*/, lc($ENV{PATHEXT});
        }
        push @aliases, $cs.$_ for (_uniq(@pext));
    }
    my @path = path();
    unshift @path, curdir();

    my @arr = ();
    foreach my $p ( @path ) {
        foreach my $f ( @aliases ) {
            my $file = catfile($p, $f);
            next if -d $file;
            if (isostype('Windows')) {
                if (-e $file) {
                    my $nospcsf = ($file =~ /\s/) ? sprintf("\"%s\"", $file) : $file;
                    if ($wh) {push @arr, $nospcsf} else {return $nospcsf}
                }
            } elsif (isostype('Unix')) {
                if (-e $file and -x _) {
                    if ($wh) {push @arr, $file} else {return $file}
                }
            } else {
                if (-e $file) {
                    if ($wh) {push @arr, $file} else {return $file}
                }
            }
        }
    }
    return @arr if $wh;
    return undef;
}
sub where { which(shift,1) }

#
# See Sys::Path
#
# prefixdir localstatedir sysconfdir srvdir
# sharedir docdir localedir cachedir syslogdir spooldir rundir lockdir sharedstatedir webdir
#
sub prefixdir {
    my $pfx = __PACKAGE__->ext_syscfg('prefix') ;
    return defined $pfx ? $pfx : '';
}
sub localstatedir {
    my $pfx = prefixdir();
    if ($pfx eq '/usr') {
        return '/var';
    } elsif ($pfx eq '/usr/local') {
        return '/var';
    }
    return catdir($pfx, 'var');
}
sub sysconfdir {
    my $pfx = prefixdir();
    return $pfx eq '/usr' ? '/etc' : catdir($pfx, 'etc');
}
sub srvdir {
    my $pfx = prefixdir();
    if ($pfx eq '/usr') {
        return '/srv';
    } elsif ($pfx eq '/usr/local') {
        return '/srv';
    }
    return catdir($pfx, 'srv');
}
sub webdir {
    my $pfx = prefixdir();
    return $pfx eq '/usr' ? '/var/www' : catdir($pfx, 'www');
}
sub sharedir        { catdir(prefixdir(), 'share') }
sub docdir          { catdir(prefixdir(), 'share', 'doc') }
sub localedir       { catdir(prefixdir(), 'share', 'locale') }
sub cachedir        { catdir(localstatedir(), 'cache') }
sub syslogdir       { catdir(localstatedir(), 'log') }
sub spooldir        { catdir(localstatedir(), 'spool') }
sub rundir          { catdir(localstatedir(), 'run') }
sub lockdir         { catdir(localstatedir(), 'lock') }
sub sharedstatedir  { catdir(localstatedir(), 'lib') }

#
# Sys core utils
#
sub getsyscfg { __PACKAGE__->ext_syscfg(@_) }
sub syscfg { __PACKAGE__->ext_syscfg(@_) }
sub isostype {__PACKAGE__->ext_isostype(@_)}
sub isos {__PACKAGE__->ext_isos(@_)}

#
# API
#
# Smart rearrangement of parameters to allow named parameter calling.
# See also CGI::Util
#
sub read_attributes {
    my ($schema, @param) = @_;
    unless ($schema && ref($schema) eq 'ARRAY') {
        carp("No scheme specified");
        return ();
    }
    my $first = $param[0];
    my %params;
    if (ref($first) eq 'HASH') {
        %params = %$first;
    } elsif (ref($first) eq 'ARRAY') {
        %params = (@$first);
    } elsif (!defined($first)) {
        return ();
    } else {
        %params = @param
    }

    # Map parameters into positional indices
    my %pos; # alias => name
    my $i = 0;
    foreach my $s (@$schema) {
        my @ks = ref($s) eq 'ARRAY' ? @$s : ($s);
        foreach my $k (@ks) {
            $pos{lc($k)} = $i;
        }
        $i++;
    }

    my @result;
    $#result = $#$schema;  # Preextend
    while (my ($k, $v) = each %params) {
        my $key = lc($k);
           $key =~ s/^\-//;
        $result[$pos{$key}] = $v if exists $pos{$key};
    }
    return @result;
}

sub _crlf {
    # Original: CGI::Simple
    return "\015\012" if isostype('Windows');
    return "\012" if isostype('Unix');
    my $OS = $^O || do { require Config; $Config::Config{'osname'} };
    return
        ( $OS =~ m/VMS/i )   ? "\n"
        : ( "\t" ne "\011" ) ? "\r\n"
        :                      "\015\012";
}
sub _proxy_crlf {shift}
sub _uniq {
    # See List::MoreUtils::PP
    my %seen = ();
    my $k;
    my $seen_undef;
    grep { defined $_ ? not $seen{$k = $_}++ : not $seen_undef++ } @_;
}

1;

package  # hide me from PAUSE
    CTK::Util::SysConfig;
use strict;
use vars qw/$VERSION/;
$VERSION = $CTK::Util::VERSION;
use Config qw//;
use Perl::OSType qw//;
sub ext_syscfg {
    my $caller; $caller = shift if (@_ && $_[0] && $_[0] eq 'CTK::Util');
    my $param = shift;
    if (defined $param) {
        return $Config::Config{$param}
    }
    my %locconf = %Config::Config;
    return %locconf;
}
sub ext_isostype {
    my $caller; $caller = shift if (@_ && $_[0] && $_[0] eq 'CTK::Util');
    return Perl::OSType::is_os_type(@_);
}
sub ext_isos {
    my $caller; $caller = shift if (@_ && $_[0] && $_[0] eq 'CTK::Util');
    my $cos = shift;
    my $os = $^O;
    return $cos && (lc($os) eq lc($cos)) && Perl::OSType::os_type($os) ? 1 : 0;
}

1;

__END__
