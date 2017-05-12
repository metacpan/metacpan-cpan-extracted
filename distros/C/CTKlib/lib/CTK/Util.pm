package CTK::Util; # $Id: Util.pm 198 2017-04-30 19:24:58Z minus $
use strict; # use Data::Dumper; $Data::Dumper::Deparse = 1;

=head1 NAME

CTK::Util - CTK Utilities

=head1 VERSION

Version 2.76

=head1 SYNOPSIS

    use CTK::Util;
    use CTK::Util qw( :BASE ); # Export only BASE subroutines. See TAGS section

    my @ls = ls(".");

    # or (for CTK module)

    use CTK;
    my @ls = CTK::ls(".");

    # or (for core and extended subroutines only)

    use CTK;
    my $c = new CTK;
    my $prefix = $c->getsyscfg("prefix");

=head1 DESCRIPTION

Public subroutines

=head2 SUBROUTINES

All subroutines are listed in alphabetical order

=head3 basetime

    $secs = basetime();

The time at which the program began running, in seconds.
This function returns result of expression:

    time() - $^T

Tags: BASE, DATE

=head3 bload

    $bindata = bload( $file_or_fh, $onutf8 );

Reading file in binary mode as ':raw:utf8' layer (if $onutf8 is true) or regular binary layer.

Tags: BASE, FILE, ATOM

=head3 bsave

    $status = bsave( $file_or_fh, $bindata, $onutf8 );

Saving file in binary mode as ':raw:utf8' layer (if $onutf8 is true) or regular binary layer.

Tags: BASE, FILE, ATOM

=head3 catdir, catfile, rootdir, tmpdir, updir, curdir, path, splitpath, splitdir

This is the L<File::Spec> functions, and exported here for historical reasons.

See L<File::Spec::Functions> and L<File::Spec> for details

=over 4

=item B<catdir>

    $path = catdir( @directories );

Concatenate two or more directory names to form a complete path ending with a directory.
But remove the trailing slash from the resulting string, because it doesn't look good, isn't
necessary and confuses OS/2. Of course, if this is the root directory, don't cut off the
trailing slash :-)

=item B<catfile>

    $path = catfile( @directories, $filename );

Concatenate one or more directory names and a filename to form a complete path ending with a filename

=item B<curdir>

    $curdir = curdir();

Returns a string representation of the current directory.

=item B<path>

    @PATH = path();

Takes no argument. Returns the environment variable PATH (or the local platform's equivalent) as a list.

=item B<rootdir>

    $rootdir = rootdir();

Returns a string representation of the root directory.

=item B<splitdir>

    @dirs = splitdir( $directories );

The opposite of "catdir"

=item B<splitpath>

    ($volume,$directories,$file) = splitpath( $path );
    ($volume,$directories,$file) = splitpath( $path, $no_file );

Splits a path in to volume, directory, and filename portions. On systems with no concept of volume,
returns '' for volume.

For systems with no syntax differentiating filenames from directories, assumes that the last file is
a path unless $no_file is true or a trailing separator or /. or /.. is present. On Unix, this means
that $no_file true makes this return ( '', $path, '' ).

=item B<tmpdir>

    $tmpdir = tmpdir();

Returns a string representation of the first writable directory from a list of possible temporary
directories. Returns the current directory if no writable temporary directories are found. The list
of directories checked depends on the platform; e.g. File::Spec::Unix checks $ENV{TMPDIR} (unless
taint is on) and /tmp.

=item B<updir>

    $updir = updir();

Returns a string representation of the parent directory.

=back

Tags: API, BASE

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

=head3 date_time2dig

    $dtd = date_time2dig( $datetime );

Returns $datetime (or current) in format yyyymmddhhmmss

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

For more features please use L<Date::Format> and L<DateTime>

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

=head3 file_lf_normalize

    file_lf_normalize( "file.txt" ) or die("Can't normalize file");

Runs L</"file_lf_normalize"> for every string of the file and save result to this file

Tags: BASE, FORMAT

=head3 file_nl_normalize

See L</"file_lf_normalize">

Tags: BASE, FORMAT

=head3 file_load

See L</"bload">

Tags: BASE, FILE, ATOM

=head3 file_save

See L</"bsave">

Tags: BASE, FILE, ATOM

=head3 fload

    $textdata = fload( $file );

Reading file in regular text mode

Tags: BASE, FILE, ATOM

=head3 fsave

    $status = fsave( $file, $textdata );

Saving file in regular text mode

Tags: BASE, FILE, ATOM

=head3 getdirlist

    $listref = getdirlist( $dir, $mask );

Returns reference to array directories of directory $dir by $mask (regexp or scalar string).

See also L</"ls">

Tags: BASE, FILE, ATOM

=head3 getfilelist

    $listref = getlist( $dir, $mask );

Returns reference to array files of directory $dir by $mask (regexp or scalar string).

See also L</"ls">

Tags: BASE, FILE, ATOM

=head3 getlist

See L</"getfilelist">

Tags: BASE, FILE, ATOM

=head3 lf_normalize

    my $normalized_string = lf_normalize( $string );

Returns CR/LF normalized string

Tags: BASE, FORMAT

=head3 load_file

See L</"fload">

Tags: BASE, FILE, ATOM

=head3 localtime2date

    $date = localtime2date( time() )

Returns time in format dd.mm.yyyy

Tags: BASE, DATE

=head3 localtime2date_time

    $datetime = localtime2date_time( time() )

Returns time in format dd.mm.yyyy hh.mm.ss

Tags: BASE, DATE

=head3 ls

    @list = ls( $dir);
    @list = ls( $dir, $mask );

A function returns list content of directory $dir by $mask (regexp or scalar string)

Tags: BASE, FILE, ATOM

=head3 nl_normalize

See L</"lf_normalize">

Tags: BASE, FORMAT

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

Tags: BASE, FORMAT

=head3 randomize

    $rand = randomize( $n );

Returns random number of the set amount of characters

Tags: BASE, FORMAT

=head3 save_file

See L</"fsave">

Tags: BASE, FILE, ATOM

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

=head3 shred

    $stat = shred( $file );

Do a more secure overwrite of given files or devices, to make it harder for even very
expensive hardware probing to recover the data.

Tags: BASE, FILE, ATOM

=head3 shuffle

    @cards = shuffle(0..51); # 0..51 in a random order

Returns the elements of LIST in a random order

Pure-Perl implementation of Function List::Util::PP::shuffle
(Copyright (c) 1997-2009 Graham Barr <gbarr@pobox.com>. All rights reserved.)

See also L<List::Util>

Tags: BASE, FORMAT

=head3 slash

    $slashed = slash( $string );

Escaping symbols \ and ' and returns strings \\ and \'

Tags: BASE, FORMAT

=head3 splitformat

See L</"fformat">

Tags: BASE, FORMAT

=head3 tag

    $detagged = tag( $string );

<, >, " and ' chars convert to &lt;, &gt;, &quot; and &#39; strings.

Tags: BASE, FORMAT

=head3 tag_create

    $string = tag_create( $detagged );

Reverse function L</"tag">

Tags: BASE, FORMAT

=head3 timef

See L</"dtf">

Tags: BASE, DATE

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

=head3 to_cp1251

See L</"to_windows1251">

Tags: BASE, FORMAT

=head3 to_utf8

    $utf8_text = to_utf8( $win1251_text )
    $utf8_text = to_utf8( $win1251_text, "Windows-1251" )

Decodes a sequence of octets ($win1251_text) assumed to be in I<ENCODING> (Windows-1251) into Perl's
internal form and returns the resulting string.  As in encode(),
ENCODING can be either a canonical name or an alias. For encoding names
and aliases, see L<Encode>.

Obsolete alias: B<CP1251toUTF8>

Tags: BASE, FORMAT

=head3 to_windows1251

    $win1251_text = to_windows1251( $utf8_text )
    $win1251_text = to_windows1251( $utf8, "Windows-1251" )

Encodes a string from Perl's internal form into I<ENCODING> (Windows-1251) and returns
a sequence of octets ($win1251_text).  ENCODING can be either a canonical name or
an alias. For encoding names and aliases, see L<Encode>.

Obsolete alias: B<UTF8toCP1251>

Tags: BASE, FORMAT

=head3 touch

    touch( "file" );

Makes file exist, with current timestamp

Tags: BASE, FILE, ATOM

=head3 translate

    $string = translate( $rus_string );

Translation russian (windows-1251/CP-1251) chars in latin symbols (poland transcription)

Tags: BASE, FORMAT

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

=head2 UTILITY SUBROUTINES

=head3 com

See L</"execute">

Tags: UTIL, ATOM

=head3 exe

See L</"execute">

Tags: UTIL, ATOM

=head3 execute

    $out = execute( "ls -la" );
    $out = execute( "ls -la", $in, \$err, $binmode );

Executing external (system) command with IPC::Open3 using.

Variables $in, $err and $binmode is OPTIONAL.

$binmode set up binary mode layer as ':raw:utf8' layer (if $binmode is ':raw:utf8', for example) or
regular binary layer (if $binmode is true).

See also L<IPC::Open3>

Tags: UTIL, ATOM

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

Tags: UTIL, ATOM

=head3 ftpgetlist

    $rfiles = ftpgetlist( \%ftpct, $mask);

Returns reference to array of remote source listing by mask (as regexp, optional)

See L</"ftp">

Tags: UTIL, ATOM

=head3 ftptest

    $status = ftptest( \%ftpct );

FTP connect testing.

See L</"ftp">

Tags: UTIL, ATOM

=head3 proccmd, proccommand, procexe, procexec, procrun

Aliases for L</"execute"> command

Tags: UTIL, ATOM

=head3 sendmail

    my $sent = sendmail(
        -to       => 'to@example.com',
        -cc       => 'cc@example.com',     ### OPTIONAL
        -from     => 'from@example.com',
        -subject  => 'my subject',
        -message  => 'my message',
        -type     => 'text/plain',
        -sendmail => '/usr/sbin/sendmail', ### OPTIONAL
        -charset  => 'windows-1251',
        -flags    => '-t',                 ### OPTIONAL
        -smtp     => '192.168.1.1',        ### OPTIONAL
        -authuser => '',                   ### OPTIONAL
        -authpass => '',                   ### OPTIONAL
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
    debug($sent ? 'mail has been sent :)' : 'mail was not sent :(');

Send mail. See L<MIME::Lite> for details

Tags: UTIL, ATOM

=head3 send_mail

See L</"sendmail">

Tags: UTIL, ATOM

=head2 EXTENDED SUBROUTINES

=head3 cachedir

    my $value = cachedir();
    my $value = $c->cachedir();

For example value can be set as: /var/cache

/var/cache is intended for cached data from applications. Such data is locally generated as a result of
time-consuming I/O or calculation. The application must be able to regenerate or restore the data. Unlike
/var/spool, the cached files can be deleted without data loss. The data must remain valid between invocations
of the application and rebooting the system.

Files located under /var/cache may be expired in an application specific manner, by the system administrator,
or both. The application must always be able to recover from manual deletion of these files (generally because of
a disk space shortage). No other requirements are made on the data format of the cache directories.

See L<http://www.pathname.com/fhs/pub/> and L<Sys::Path/"cachedir">

Tags: API, BASE

=head3 docdir

    my $value = docdir();
    my $value = $c->docdir();

For example value can be set as: /usr/share/doc

See L<Sys::Path/"docdir">

Tags: API, BASE

=head3 localedir

    my $value = localedir();
    my $value = $c->localedir();

For example value can be set as: /usr/share/locale

See L<Sys::Path/"localedir">

Tags: API, BASE

=head3 localstatedir

    my $value = localstatedir();
    my $value = $c->localstatedir();

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

See L<http://www.pathname.com/fhs/pub/> and L<Sys::Path/"localstatedir">

Tags: API, BASE

=head3 lockdir

    my $value = lockdir();
    my $value = $c->lockdir();

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

See L<http://www.pathname.com/fhs/pub/> and L<Sys::Path/"lockdir">

Tags: API, BASE

=head3 prefixdir

    my $value = prefixdir();
    my $value = $c->prefixdir();

For example value can be set as: /usr

/usr - $Config::Config{'prefix'}

Is a helper function and should not be used directly.

/usr is the second major section of the filesystem. /usr is shareable, read-only data. That means that /usr
should be shareable between various FHS-compliant hosts and must not be written to. Any information that is
host-specific or varies with time is stored elsewhere.

Large software packages must not use a direct subdirectory under the /usr hierarchy.

See L<http://www.pathname.com/fhs/pub/> and L<Sys::Path/"prefix">

Tags: API, BASE

=head3 rundir

    my $value = rundir();
    my $value = $c->rundir();

For example value can be set as: /var/run

This directory contains system information data describing the system since it was booted. Files under this
directory must be cleared (removed or truncated as appropriate) at the beginning of the boot process. Programs
may have a subdirectory of /var/run; this is encouraged for programs that use more than one run-time file. 7
Process identifier (PID) files, which were originally placed in /etc, must be placed in /var/run. The naming
convention for PID files is <program-name>.pid. For example, the crond PID file is named
/var/run/crond.pid.

See L<http://www.pathname.com/fhs/pub/> and L<Sys::Path/"rundir">

Tags: API, BASE

=head3 sharedir

    my $value = sharedir();
    my $value = $c->sharedir();

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

See L<http://www.pathname.com/fhs/pub/> and L<Sys::Path/"datadir">

Tags: API, BASE

=head3 sharedstatedir

    my $value = sharedstatedir();
    my $value = $c->sharedstatedir();

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

See L<http://www.pathname.com/fhs/pub/> and L<Sys::Path/"sharedstatedir">

Tags: API, BASE

=head3 spooldir

    my $value = spooldir();
    my $value = $c->spooldir();

For example value can be set as: /var/spool

/var/spool contains data which is awaiting some kind of later processing. Data in /var/spool represents
work to be done in the future (by a program, user, or administrator); often data is deleted after it has been
processed.

See L<http://www.pathname.com/fhs/pub/> and L<Sys::Path/"spooldir">

Tags: API, BASE

=head3 srvdir

    my $value = srvdir();
    my $value = $c->srvdir();

For example value can be set as: /srv

/srv contains site-specific data which is served by this system.

See L<http://www.pathname.com/fhs/pub/> and L<Sys::Path/"srvdir">

Tags: API, BASE

=head3 sysconfdir

    my $value = sysconfdir();
    my $value = $c->sysconfdir();

For example value can be set as: /etc

The /etc hierarchy contains configuration files. A "configuration file" is a local file used to control the operation
of a program; it must be static and cannot be an executable binary.

See L<http://www.pathname.com/fhs/pub/> and L<Sys::Path/"sysconfdir">

Tags: API, BASE

=head3 syslogdir

    my $value = syslogdir();
    my $value = $c->syslogdir();

For example value can be set as: /var/log

This directory contains miscellaneous log files. Most logs must be written to this directory or an appropriate
subdirectory.

See L<http://www.pathname.com/fhs/pub/> and L<Sys::Path/"logdir">

Tags: API, BASE

=head3 webdir

    my $value = webdir();
    my $value = $c->webdir();

For example value can be set as: /var/www

Directory where distribution put static web files.

See L<Sys::Path/"webdir">

Tags: API, BASE

=head2 CORE SUBROUTINES

=head3 carp, croak, cluck, confess

This is the L<Carp> functions, and exported here for historical reasons.

=over 4

=item B<carp>

    carp( "string trimmed to 80 chars" );

Warn user (from perspective of caller)

=item B<croak>

    croak( "We're outta here!" );

Die of errors (from perspective of caller)

=item B<cluck>

    cluck( "This is how we got here!" );

Warn user (more detailed what carp with stack backtrace)

=item B<confess>

    confess( "not implemented" );

Die of errors with stack backtrace

=back

Tags: API, BASE

=head3 getsyscfg

See L</"syscfg">

Tags: API, BASE

=head3 isos

Returns true or false if the OS name is of the current value of C<$^O>

    isos('mswin32') ? "OK" : "NO";
    # or
    $c->isos('mswin32') ? "OK" : "NO";

See L<Perl::OSType> for details

Tags: API, BASE

=head3 isostype

Given an OS type and OS name, returns true or false if the OS name is of the
given type.

    isostype('Windows') ? "OK" : "NO";
    isostype('Unix', 'dragonfly') ? "OK" : "NO";
    # or
    $c->isostype('Windows') ? "OK" : "NO";
    $c->isostype('Unix', 'dragonfly') ? "OK" : "NO";

See L<Perl::OSType/"is_os_type">

Tags: API, BASE

=head3 read_attributes

Smart rearrangement of parameters to allow named parameter calling.
We do the rearrangement if the first parameter begins with a -

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

=head3 syscfg

Returns all hash %Config from system module L<Config> or one value of this hash

    my %syscfg = syscfg();
    my $prefix = syscfg( "prefix" );
    # or
    my %syscfg = $c->syscfg();
    my $prefix = $c->syscfg( "prefix" );

See L<Config> module for details

Tags: API, BASE

=head2 TAGS

=head3 ALL, DEFAULT

Export all subroutines, default:

C<CP1251toUTF8>,
C<UTF8toCP1251>,
L</"basetime">,
L</"bload">,
L</"bsave">,
L</"cachedir">,
L</"carp">,
L</"catdir">,
L</"catfile">,
L</"cdata">,
L</"cluck">,
L</"com">,
L</"confess">,
L</"correct_date">,
L</"correct_dig">,
L</"correct_number">,
L</"croak">,
L</"curdir">,
L</"current_date">,
L</"current_date_time">,
L</"date2dig">,
L</"date2localtime">,
L</"date_time2dig">,
L</"datef">,
L</"datetime2localtime">,
L</"datetimef">,
L</"dformat">,
L</"dig2date">,
L</"dig2date_time">,
L</"docdir">,
L</"dtf">,
L</"eqtime">,
L</"escape">,
L</"exe">,
L</"execute">,
L</"fformat">,
L</"file_load">,
L</"file_save">,
L</"fload">,
L</"fsave">,
L</"ftp">,
L</"ftpgetlist">,
L</"ftptest">,
L</"getdirlist">,
L</"getfilelist">,
L</"getlist">,
L</"getsyscfg">,
L</"isos">,
L</"isostype">,
L</"load_file">,
L</"localedir">,
L</"localstatedir">,
L</"localtime2date">,
L</"localtime2date_time">,
L</"lockdir">,
L</"ls">,
L</"path">,
L</"prefixdir">,
L</"preparedir">,
L</"randchars">,
L</"randomize">,
L</"read_attributes">,
L</"rootdir">,
L</"rundir">,
L</"save_file">,
L</"scandirs">,
L</"scanfiles">,
L</"send_mail">,
L</"sendmail">,
L</"sharedir">,
L</"sharedstatedir">,
L</"shuffle">,
L</"slash">,
L</"splitdir">,
L</"splitformat">,
L</"splitpath">,
L</"spooldir">,
L</"srvdir">,
L</"syscfg">,
L</"sysconfdir">,
L</"syslogdir">,
L</"tag">,
L</"tag_create">,
L</"timef">,
L</"tmpdir">,
L</"to_base64">,
L</"to_cp1251">,
L</"to_utf8">,
L</"to_windows1251">,
L</"touch">,
L</"translate">,
L</"unescape">,
L</"updir">,
L</"variant_stf">,
L</"visokos">,
L</"webdir">

=head3 BASE

Export only base subroutines:

C<CP1251toUTF8>,
C<UTF8toCP1251>,
L</"basetime">,
L</"bload">,
L</"bsave">,
L</"cachedir">,
L</"carp">,
L</"catdir">,
L</"catfile">,
L</"cdata">,
L</"cluck">,
L</"confess">,
L</"correct_date">,
L</"correct_dig">,
L</"correct_number">,
L</"croak">,
L</"curdir">,
L</"current_date">,
L</"current_date_time">,
L</"date2dig">,
L</"date2localtime">,
L</"date_time2dig">,
L</"datef">,
L</"datetime2localtime">,
L</"datetimef">,
L</"dformat">,
L</"dig2date">,
L</"dig2date_time">,
L</"docdir">,
L</"dtf">,
L</"eqtime">,
L</"escape">,
L</"fformat">,
L</"file_lf_normalize">,
L</"file_nl_normalize">,
L</"file_load">,
L</"file_save">,
L</"fload">,
L</"fsave">,
L</"getdirlist">,
L</"getfilelist">,
L</"getlist">,
L</"getsyscfg">,
L</"isos">,
L</"isostype">,
L</"lf_normalize">,
L</"load_file">,
L</"localedir">,
L</"localstatedir">,
L</"localtime2date">,
L</"localtime2date_time">,
L</"lockdir">,
L</"ls">,
L</"nl_normalize">,
L</"path">,
L</"prefixdir">,
L</"preparedir">,
L</"randchars">,
L</"randomize">,
L</"read_attributes">,
L</"rootdir">,
L</"rundir">,
L</"save_file">,
L</"scandirs">,
L</"scanfiles">,
L</"sharedir">,
L</"sharedstatedir">,
L</"shred">,
L</"shuffle">,
L</"slash">,
L</"splitdir">,
L</"splitformat">,
L</"splitpath">,
L</"spooldir">,
L</"srvdir">,
L</"syscfg">,
L</"sysconfdir">,
L</"syslogdir">,
L</"tag">,
L</"tag_create">,
L</"timef">,
L</"tmpdir">,
L</"to_base64">,
L</"to_cp1251">,
L</"to_utf8">,
L</"to_windows1251">,
L</"touch">,
L</"translate">,
L</"unescape">,
L</"updir">,
L</"variant_stf">,
L</"visokos">,
L</"webdir">

=head3 FORMAT

Export only text format subroutines:

C<CP1251toUTF8>,
C<UTF8toCP1251>,
L</"cdata">,
L</"correct_dig">,
L</"correct_number">,
L</"dformat">,
L</"escape">,
L</"fformat">,
L</"file_lf_normalize">,
L</"file_nl_normalize">,
L</"lf_normalize">,
L</"nl_normalize">,
L</"randchars">,
L</"randomize">,
L</"shuffle">,
L</"slash">,
L</"splitformat">,
L</"tag">,
L</"tag_create">,
L</"to_base64">,
L</"to_cp1251">,
L</"to_utf8">,
L</"to_windows1251">,
L</"translate">,
L</"unescape">,
L</"variant_stf">

=head3 DATE

Export only date and time subroutines:

L</"basetime">,
L</"correct_date">,
L</"current_date">,
L</"current_date_time">,
L</"date2dig">,
L</"date2localtime">,
L</"date_time2dig">,
L</"datef">,
L</"datetime2localtime">,
L</"datetimef">,
L</"dig2date">,
L</"dig2date_time">,
L</"dtf">,
L</"localtime2date">,
L</"localtime2date_time">,
L</"timef">,
L</"visokos">

=head3 FILE

Export only file and directories subroutines:

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
L</"shred">,
L</"touch">

=head3 UTIL

Export only utility subroutines:

L</"com">,
L</"exe">,
L</"execute">,
L</"ftp">,
L</"ftpgetlist">,
L</"ftptest">,
L</"send_mail">,
L</"sendmail">

=head3 ATOM

Export only processing subroutines:

L</"bload">,
L</"bsave">,
L</"com">,
L</"eqtime">,
L</"exe">,
L</"execute">,
L</"file_load">,
L</"file_save">,
L</"fload">,
L</"fsave">,
L</"ftp">,
L</"ftpgetlist">,
L</"ftptest">,
L</"getdirlist">,
L</"getfilelist">,
L</"getlist">,
L</"load_file">,
L</"ls">,
L</"preparedir">,
L</"save_file">,
L</"scandirs">,
L</"scanfiles">,
L</"send_mail">,
L</"sendmail">,
L</"shred">,
L</"touch">

=head3 API

Export only inerface subroutines:

L</"cachedir">,
L</"carp">,
L</"catdir">,
L</"catfile">,
L</"cluck">,
L</"confess">,
L</"croak">,
L</"curdir">,
L</"docdir">,
L</"getsyscfg">,
L</"isos">,
L</"isostype">,
L</"localedir">,
L</"localstatedir">,
L</"lockdir">,
L</"path">,
L</"prefixdir">,
L</"read_attributes">,
L</"rootdir">,
L</"rundir">,
L</"sharedir">,
L</"sharedstatedir">,
L</"splitdir">,
L</"splitpath">,
L</"spooldir">,
L</"srvdir">,
L</"syscfg">,
L</"sysconfdir">,
L</"syslogdir">,
L</"tmpdir">,
L</"updir">,
L</"webdir">

=head1 SEE ALSO

L<MIME::Lite>, L<CGI::Util>, L<Time::Local>, L<Net::FTP>, L<IPC::Open3>, L<List::Util>

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) L<http://www.serzik.com> E<lt>minus@mail333.comE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms and conditions as Perl itself.

This program is distributed under the GNU LGPL v3 (GNU Lesser General Public License version 3).

See C<LICENSE> file

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

use vars qw/$VERSION/;
$VERSION = '2.76';

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
use CTK::XS::Util;

use Carp qw/carp croak cluck confess/;
# carp    -- просто пишем
# croak   -- просто пишем и убиваем
# cluck   -- пишем но с подробностями
# confess -- пишем с подробностями и убиваем

use base qw /Exporter/;
my @est_core = qw(
        syscfg getsyscfg isos isostype
        carp croak cluck confess
        catdir catfile rootdir tmpdir updir curdir path splitpath splitdir
        prefixdir localstatedir sysconfdir srvdir
        sharedir docdir localedir cachedir syslogdir spooldir rundir lockdir sharedstatedir webdir
        read_attributes
    );
my @est_encoding = qw(
        to_utf8 to_windows1251 to_cp1251 CP1251toUTF8 UTF8toCP1251 to_base64
    );
my @est_format = qw(
        escape unescape slash tag tag_create cdata dformat fformat splitformat
        lf_normalize nl_normalize file_lf_normalize file_nl_normalize
        correct_number correct_dig
        translate variant_stf randomize randchars shuffle
    );
my @est_datetime = qw(
        current_date current_date_time localtime2date localtime2date_time correct_date date2localtime
        datetime2localtime visokos date2dig dig2date date_time2dig dig2date_time basetime
        dtf datetimef timef datef
    );
my @est_file = qw(
        load_file save_file file_load file_save fsave fload bsave bload touch eqtime shred
    );
my @est_dir = qw(
        ls scandirs scanfiles getlist getfilelist getdirlist
        preparedir

    );
my @est_util = qw(
        sendmail send_mail
        ftp ftptest ftpgetlist
        procexec procexe proccommand proccmd procrun exe com execute
    );

our @EXPORT = (
        @est_core, @est_encoding, @est_format, @est_datetime,
        @est_file, @est_dir, @est_util,
    );
our @EXPORT_OK = @EXPORT;
our %EXPORT_TAGS = (
        ALL     => [@EXPORT],
        DEFAULT => [@EXPORT],
        API     => [
                @est_core,
            ],
        BASE    => [
                @est_core,
                @est_encoding, @est_format,
                @est_datetime,
                @est_file, @est_dir,
            ],
        FORMAT  => [
                @est_encoding, @est_format,
            ],
        DATE    => [
                @est_datetime,
            ],
        FILE    => [
                @est_file, @est_dir,
            ],
        UTIL    => [
                @est_util,
            ],
        ATOM   => [
                @est_file, @est_dir,
                @est_util,
            ],
    );

# Модули OOP которые должны вызываться ТОЛЬКО внутри этого модуля, все остальные запросы
# должны идти через оболочку!!!
push @CTK::Util::ISA, qw/CTK::Util::SysConfig/;

my $CRLF = _crlf();

sub to_utf8 {
    # Конвертирование строки в UTF-8 из указанной кодировки
    # to_utf8( $string, $charset ) # charset is 'Windows-1251' as default

    my $ss = shift; # Сообщение
    return '' unless defined($ss);
    my $ch = shift || 'Windows-1251'; # Перекодировка
    return Encode::decode($ch,$ss)
}
sub to_windows1251 {
    # Конвертирование строки из UTF-8 в указанную кодировку
    # to_windows1251( $string, $charset ) # charset is 'Windows-1251' as default

    my $ss = shift; # Сообщение
    return '' unless defined($ss);
    my $ch = shift || 'Windows-1251'; # Перекодировка
    return Encode::encode($ch,$ss)
}
sub to_cp1251 { goto &to_windows1251 };
sub CP1251toUTF8 { goto &to_utf8 };
sub UTF8toCP1251 { goto &to_windows1251 };
sub to_base64 {
    # Конвертирование строки UTF-8 в base64 (RFC 2047)
    # to_base64( $utf8_string )

    my $ss = shift; # Сообщение
    return '=?UTF-8?B??=' unless defined($ss);
    return '=?UTF-8?B?'.MIME::Base64::encode(Encode::encode('UTF-8',$ss),'').'?=';
}

#
# Форматные функции
#
sub slash {
    #
    # Процедура удаляет системные данные из строки заменяя их
    #
    my $data_staring = shift;
    return '' unless defined($data_staring);

    $data_staring =~ s/\\/\\\\/g;
    $data_staring =~ s/'/\\'/g;

    return $data_staring;
}
sub tag {
    #
    # Процедура удаляет системные данные из строки заменяя их
    #
    # <, >, " and ' chars convert to &lt;, &gt;, &quot; and &#39; strings
    #
    my $data_staring = shift;
    return '' unless defined($data_staring);

    $data_staring =~ s/</&lt;/g;
    $data_staring =~ s/>/&gt;/g;
    $data_staring =~ s/\"/&quot;/g;
    $data_staring =~ s/\'/&#39;/g;

    return $data_staring;
}
sub tag_create {
    #
    # Процедура восстанавливает теги
    #
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
    # Константы
    my $ss  = '<![CDATA[';
    my $sf  = ']]>';
    if (defined $s) {
        return to_utf8($ss).$s.to_utf8($sf);
    }
    return '';
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
sub dformat { # маска, данные для замены в виде ссылки на хэш
    # Заменяет во входном шаблоне внутренние параметры на подставляемые
    my $fmt = shift || ''; # Формат для замены
    my $fd  = shift || {}; # Данные для замены
    $fmt =~ s/\[(.+?)\]/(defined $fd->{uc($1)} ? $fd->{uc($1)} : '')/eg;
    return $fmt;
}
sub fformat { # маска, имя файла
    # Заменяет во входном шаблоне внутренние параметры на разделенные
    # [FILENAME] -- Только имя файла
    # [NAME]     -- Только имя файла
    # [FILEEXT]  -- Только расширение файла
    # [EXT]      -- Только расширение файла
    # [FILE]     -- Все имя файла и расширрение вместе
    my $fmt = shift || ''; # Формат. Например такй: [FILENAME]-blah-blah-blah.[FILEEXT]
    my $fin = shift || ''; # Имя файла которое будем всталять "по формату", например void.txt

    my ($fn,$fe) = ($fin =~ /^(.+)\.([0-9a-zA-Z]+)$/) ? ($1,$2) : ($fin,'');
    $fmt =~ s/\[FILENAME\]/$fn/ig;
    $fmt =~ s/\[NAME\]/$fn/ig;
    $fmt =~ s/\[FILEEXT\]/$fe/ig;
    $fmt =~ s/\[EXT\]/$fe/ig;
    $fmt =~ s/\[FILE\]/$fin/ig;
    return $fmt; # void-blah-blah-blah.txt
}
sub splitformat { goto &fformat }
#
# Корректировочные функции
#
sub correct_number {
    # Расстановка разрядов в числе
    my $var = shift || 0;
    my $sep = shift || "`";
    1 while $var=~s/(\d)(\d\d\d)(?!\d)/$1$sep$2/;
    return $var;
}
sub correct_dig {
    # Процедура корректировки значения на факт числа. Если значение состоит НЕ из цифр то возвращается 0
    my $dig = shift || '';
    if ($dig =~/^\s*(\d+)\s*$/) {
        return $1;
    }
    return 0;
}

#
# Конверторы дат и времени
#

sub localtime2date {
    # Преобразование времени в дату формата 02.12.2010
    # localtime2date ( time() ) # => 02.12.2010

    my $dandt = shift || time();
    my @dt = localtime($dandt);
    #my $cdt=(($dt[3]>9)?$dt[3]:'0'.$dt[3]).'.'.(($dt[4]+1>9)?$dt[4]+1:'0'.($dt[4]+1)).'.'.($dt[5]+1900);
    #return $cdt;
    return sprintf (
        "%02d.%02d.%04d",
        $dt[3], # День
        $dt[4]+1, # Месяц
        $dt[5]+1900 # Год
    );
}
sub localtime2date_time {
    my $dandt = shift || time();
    my @dt = localtime($dandt);
    #my $cdt=(($dt[3]>9)?$dt[3]:'0'.$dt[3]).'.'.(($dt[4]+1>9)?$dt[4]+1:'0'.($dt[4]+1)).'.'
    #.($dt[5]+1900)." ".(($dt[2]>9)?$dt[2]:'0'.$dt[2]).":".(($dt[1]>9)?$dt[1]:'0'.$dt[1]).':'
    #.(($dt[0]>9)?$dt[0]:'0'.$dt[0]);
    #return $cdt;
    return sprintf (
        "%02d.%02d.%04d %02d:%02d:%02d",
        $dt[3], # День
        $dt[4]+1, # Месяц
        $dt[5]+1900, # Год
        $dt[2], # Час
        $dt[1], # Мин
        $dt[0]  # Сек
    );

}
sub current_date { localtime2date() }
sub current_date_time { localtime2date_time() }
sub correct_date {
    #
    # Приведение даты в корректный правильный формат dd.mm.yyyy
    #
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
    # Процедура конфертирует русскоязычную дату DD.MM.YYYY в числовое значение time()
    my $dtin= shift || return 0;
    if ($dtin=~/^\s*(\d{1,2})\.+(\d{1,2})\.+(\d{4}).*$/) {
        return timelocal(0,0,0,$1,$2-1,$3-1900);
    }
    return 0
}
sub datetime2localtime {
    # Процедура конфертирует русскоязычную датувремя DD.MM.YYYY HH:MM:SS в числовое значение time()
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
    # Преобразование даты в формат 02.12.2010 => 20101202
    # date2dig( $date ) # 02.12.2010 => 20101202

    my $val = shift || &localtime2date();
    my $stat=$val=~s/^\s*(\d{1,2})\.+(\d{1,2})\.+(\d{4}).*$/$3$2$1/;
    $val = '' unless $stat;
    return $val;
}
sub dig2date {
    # Преобразование даты из числового формата YYYYMMDD в русскоязычный формат DD.MM.YYYY
    my $val = shift || date2dig();
    my $stat=$val=~s/^\s*(\d{4})(\d{2})(\d{2}).*$/$3.$2.$1/;
    $val = '' unless $stat;
    return $val;
}
sub date_time2dig {
    # Преобразование даты и времени из русскоязычного формата в числовой формата: YYYYMMDDHHMMSS
    my $val = shift || current_date_time();
    my $stat=$val=~s/^\s*(\d{2})\.+(\d{2})\.+(\d{4})\D+(\d{2}):(\d{2}):(\d{2}).*$/$3$2$1$4$5$6/;
    $val = '' unless $stat;
    return $val;
}
sub dig2date_time {
    # Преобразование даты и времени из числового формата YYYYMMDDHHMMSS в русскоязычный формат DD.MM.YYYY HH:MM:SS
    my $val = shift || date_time2dig();
    my $stat=$val=~s/^\s*(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2}).*$/$3.$2.$1 $4:$5:$6/;
    $val = '' unless $stat;
    return $val;
}
sub basetime {
    # Количество секунд с момента старта скрипта
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
sub timef { goto &dtf }
sub datef { goto &dtf }
sub datetimef { goto &dtf }

#
# Специфические преобразования и вычисления
#
sub translate {
    # Транслитерация русских букв в латинские (польскобуквенный вариант)
    my $text = shift;
    return '' unless defined($text);

    #$text=~tr/\xA8\xC0-\xDF/\xB8\xE0-\xFF/; # UP -> down
    $text=~tr/\xA8\xC0-\xC5\xC7-\xD6\xDB\xDD/EABWGDEZIJKLMNOPRSTUFHCYE/; # UP
    $text=~s/\xC6/Rz/g;
    $text=~s/\xD7/Cz/g;
    $text=~s/\xD8/Sz/g;
    $text=~s/\xD9/Sz/g;
    $text=~s/\xDA//g;
    $text=~s/\xDC//g;
    $text=~s/\xDE/Ju/g;
    $text=~s/\xDF/Ja/g;

    $text=~tr/\xB8\xE0-\xE5\xE7-\xF6\xFB\xFD/eabwgdezijklmnoprstufhcye/; # down
    $text=~s/\xE6/rz/g;
    $text=~s/\xF7/cz/g;
    $text=~s/\xF8/sz/g;
    $text=~s/\xF9/sz/g;
    $text=~s/\xFA//g;
    $text=~s/\xFC//g;
    $text=~s/\xFE/ju/g;
    $text=~s/\xFF/ja/g;
    #$text=~tr/\x00-\x1F/_/;
    #$text=~s/[,!?:;'<>=*'"`~ ]/_/g; # Замена знаков препинания

    return $text;
}
sub variant_stf {
    my $S = shift;
    $S = '' unless defined($S);
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
    # Вычисление случайного числа с заданным количеством знаков
    my $digs = shift || return 0;
    my $rstat;
    for (my $i=0; $i<$digs; $i++) {
       $rstat.=int(rand(10));
    }
    $rstat=substr ($rstat,0,abs($digs));
    return "$rstat"
}
sub randchars {
    # Вычисление случайного символьного значения с заданным количеством знаков и заданным массивом
    my $l = shift || return '';
    return '' unless $l =~/^\d+$/;
    my $arr = shift;

    my $result = '';
    my @chars = ($arr && ref($arr) eq 'ARRAY') ? (@$arr) : (0..9,'a'..'z','A'..'Z');
    $result .= $chars[(int(rand($#chars+1)))] for (1..$l);

    return $result;
}
sub shuffle {
    # Процедура шаффлинга взятая из удаленного модуля List::Util::PP
    return unless @_;
    my @a=\(@_);
    my $n;
    my $i=@_;
    map {
        $n = rand($i--);
        (${$a[$n]}, $a[$n] = $a[$i])[0];
    } @_;
}

#
# Процедуры чтения и записи текстовых массивов из файла/в файл
#
sub load_file {
    # Чтение фала блоком размером в файл
    my $filename = shift || return ''; # АБСОЛЮТНОЕ имя файла
    my $text ='';
    local *FILE;
    if(-e $filename){
        my $ostat = open(FILE,"<",$filename);
        if ($ostat) {
            read(FILE,$text,-s $filename) unless -z $filename;
            close FILE;
        } else {
            _error("[FILE TEXT: Can't open file to load '$filename'] $!");
        }
    }
    return $text; # Принятый текст
}
sub save_file {
    # Запсиь блока НЕДВОИЧНЫХ данных в файл
    my $filename = shift || return 0; # АБСОЛЮТНОЕ имя файла
    my $text = shift || ''; # Текстовый массив
    local *FILE;
    my $ostat = open(FILE,">",$filename);
    if ($ostat) {
        flock (FILE, 2) or _error("[FILE TEXT: Can't lock file '$filename'] $!");
        print FILE $text;
        close FILE;
    } else {
        _error("[FILE TEXT: Can't open file to write '$filename'] $!");
    }
    return 1; # статус выполнения операции
}
sub fload { goto &load_file } # текстовое чтение
sub fsave { goto &save_file } # текстовая запись

#
# Процедуры чтения и записи двоичных массивов из файла/в файл
#
sub file_load {
    # Чтение ДВОИЧНЫХ данных из фала
    my $fn     = shift || '';
    my $onutf8 = shift;
    my $IN;
    return 0 unless $fn;

    if (ref $fn eq 'GLOB') {
        $IN = $fn;
    } else {
        my $ostat = open $IN, '<', $fn;
        unless ($ostat) {
            _error("[FILE BIN: Can't open file to load \'$fn\'] $!");
            return '';
        }
    }
    binmode $IN, ':raw:utf8' if $onutf8;
    binmode $IN unless $onutf8;
    return scalar(do { local $/; <$IN> });
}
sub file_save {
    # Запсиь ДВОИЧНЫХ данных в файл
    my $fn      = shift || '';
    my $content = shift || '';
    my $onutf8 = shift;
    my $OUT;
    return 0 unless $fn;

    my $flc = 0;
    if (ref $fn eq 'GLOB') {
       $OUT = $fn;
    } else {
        my $ostat = open $OUT, '>', $fn;
        unless ($ostat) {
            _error("[FILE BIN: Can't open file to write '$fn'] $!");
            return 0;
        }
        flock $OUT, 2 or _error("[FILE BIN: Can't lock file \'$fn\']");
        $flc = 1;
    }

    binmode $OUT, ':raw:utf8' if $onutf8;
    binmode $OUT unless $onutf8;
    print $OUT $content;
    close $OUT if $flc;
    return 1; # статус выполнения операции
}
sub bload { goto &file_load } # двоичное чтение
sub bsave { goto &file_save } # двоичная запись

#
# Файловые процедуры и процедуры работы с каталогами и списками каталогов
#
sub touch {
    # Трогаем файл (взято с ExtUtils::Command)
    my $fn  = shift || '';
    return 0 unless $fn;
    my $t   = time;
    my $OUT;
    my $ostat = open $OUT, '>>', $fn;
    unless ($ostat) {
        _error("[TOUCH: Can't open file to write] $!");
        return 0;
    }

    close $OUT if $ostat;
    utime($t,$t,$fn);
    return 1;
}
sub eqtime {
    # Делаем файл такой же датой создания и модификации
    my $src = shift || '';
    my $dst = shift || '';

    unless ($src && -e $src) {
        _error("[EQTIME: Can't open file to read] $!");
        return 0;
    }
    unless (utime((stat($src))[8,9],$dst)) {
        _error("[EQTIME: Can't change access and modification times on file] $!");
        return 0;
    }
    return 1;
}
sub preparedir {
    # Подготовка директории к работе
    # Ссоздание каталога, если его нет, выставление прав на запись 0777
    my $din = shift || return 0;
    my $chmod = shift || undef; #0777

    my @dirs;
    if (ref($din) eq 'HASH') {
        foreach my $k (values %$din) { push @dirs, $k };
    } elsif (ref($din) eq 'ARRAY') {
        @dirs = @$din;
    } else { push @dirs, $din }
    my $stat = 1;
    foreach my $dir (@dirs) {
        mkpath( $dir, {verbose => 0} ) unless -e $dir; # mkdir $dir unless -e $dir;
        #CTK::say("!!!! ",$dir);
        chmod($chmod,$dir) if defined($chmod) && -e $dir;
        unless ($dir && (-d $dir or -l $dir)) {
            $stat = 0;
            cluck("Directory don't prepare: \"$dir\"");
        }
    }
    return $stat;
}
sub scandirs {
    # Получаем список каталогов [путь,имя]
    my $dir = shift || cwd() || curdir() || '.'; # по умолчанию - текущий каталог
    my $mask = shift || ''; # по умолчанию - все файлы

    my @dirs;

    @dirs = grep {!(/^\.+$/) && -d catdir($dir,$_)} ls($dir, $mask);
    @dirs = sort {$a cmp $b} @dirs;

    return map {[catdir($dir,$_), $_]} @dirs;
}
sub scanfiles {
    # Получаем список файлов [путь,имя]
    my $dir = shift || cwd() || curdir() || '.'; # по умолчанию - текущий каталог
    my $mask = shift || ''; # по умолчанию - все файлы

    my @files;
    @files = grep { -f catfile($dir,$_)} ls($dir, $mask);
    @files = sort {$a cmp $b} @files;

    return map {[catfile($dir,$_), $_]} @files;
}
sub ls {
    # Получаем список каталога
    my $dir = shift || curdir() || '.'; # по умолчанию - текущий каталог
    my $mask = shift || ''; # по умолчанию - все файлы

    my @fds;

    my $dh = gensym();
    unless (opendir($dh,$dir)) {
        _error("[LS: Can't open directory \"$dir\"] $!");
        return @fds;
    }

    @fds = readdir($dh);# ищем все файлы в указаной папке
    closedir($dh);

    # выкидываем все файлы не по маске!
    if ($mask && ref($mask) eq 'Regexp') {
        return grep {$_ =~ $mask} @fds;
    } else {
        return grep {/$mask/} @fds if $mask;
    }
    return @fds;
}
sub getfilelist {
    # Получение списка ФАЙЛОВ в указанной директории по маске (отличие только в возврате вывода)
    return [map {$_->[1]} scanfiles(@_)];
}
sub getlist { goto &getfilelist }
sub getdirlist {
    # Получение списка ПАПОК в указанной директории по маске (отличие только в возврате вывода)
    return [map {$_->[1]} scandirs(@_)];
}

#
# Процедуры группы Util (Atom)
#
sub send_mail {
    # Version 3.01 (with UTF-8 as default character set and attachment support)
    #
    # Отправка письма посредством модуля MIME::Lite в кодировке UTF-8
    # Возвращает статус отправки. 1 - удача, 0 - неудача. Данные записались в лог
    #

    my @args = @_;
    my ($to, $cc, $from, $subject, $message, $type,
        $sendmail, $charset, $mailer_flags, $smtp, $smtpuser, $smtppass,$att);

    # Приём данных
    ($to, $cc, $from, $subject, $message, $type,
     $sendmail, $charset, $mailer_flags, $smtp, $smtpuser, $smtppass, $att) =
    read_attributes([
        ['TO','KOMU','ADDRESS'],
        ['COPY','CC'],
        ['FROM','OT','OTKOGO','OT_KOGO'],
        ['SUBJECT','SUBJ','SBJ','TEMA','DESCRIPTION'],
        ['MESSAGE','CONTENT','TEXT','MAIL','DATA'],
        ['TYPE','CONTENT-TYPE','CONTENT_TYPE'],
        ['PROGRAM','SENDMAIL','PRG'],
        ['CHARSET','CHARACTER_SET'],
        ['FLAG','FLAGS','MAILERFLAGS','MAILER_FLAGS','SENDMAILFLAGS','SENDMAIL_FLAGS'],
        ['SMTP','MAILSERVER','SERVER','HOST'],
        ['SMTPLOGIN','AUTHLOGIN','LOGIN','SMTPUSER','AUTHUSER','USER'],
        ['SMTPPASSWORD','AUTHPASSWORD','PASSWORD','SMTPPASS','AUTHPASS','PASS'],
        ['ATTACH','ATTACHE','ATT'],
    ],@args) if defined $args[0];

    # По умолчанию берутся пустые данные, в дальнейшем -- данные конфигурации
    $to           ||= '';
    $cc           ||= '';
    $from         ||= '';
    $subject      ||= '';
    $message      ||= '';
    $type         ||= "text/plain";
    $sendmail     ||= "/usr/lib/sendmail";
    $sendmail       = "/usr/sbin/sendmail" if !-e $sendmail;
    $sendmail       = "" if (-e $sendmail) && (-l $sendmail);
    $charset      ||= "Windows-1251";
    $mailer_flags ||= "-t";
    $smtp         ||= '';
    $smtpuser     ||= '';
    $smtppass     ||= '';
    $att          ||= '';

    # Преобразование полей темы и данных в выбранную кодировку
    if ($charset !~ /utf\-?8/i) {
        $subject = to_utf8($subject,$charset);
        $message = to_utf8($message,$charset);
    }

    # Формирую объект
    my $msg = MIME::Lite->new(
        From     => $from,
        To       => $to,
        Cc       => $cc,
        Subject  => to_base64($subject),
        Type     => $type,
        Encoding => 'base64',
        Data     => Encode::encode('UTF-8',$message)
    );
    # Устанавливаем кодовую таблицу
    $msg->attr('content-type.charset' => 'UTF-8');
    $msg->attr('Content-Transfer-Encoding' => 'base64');

    # Аттач (если он есть)
    if ($att) {
        if (ref($att) =~ /HASH/i) {
            $msg->attach(%$att);
        } elsif  (ref($att) =~ /ARRAY/i) {
            foreach (@$att) {
                if (ref($_) =~ /HASH/i) {
                    $msg->attach(%$_);
                } else {
                    _debug("невозможно присоединить множественные данные или файл к отправляемому письму");
                }
            }
        } else {
            _debug("невозможно присоединить данные или файл к отправляемому письму");
        }
    }

    # Отправка письма
    my $sendstat;
    if ($sendmail && -e $sendmail) {
        # sendmail указан и он существует
        $sendstat = $msg->send(sendmail => "$sendmail $mailer_flags");
        _debug("[SENDMAIL: program sendmail not found! \"$sendmail $mailer_flags\"] $!") unless $sendstat;

    } else {
        # Попытка использовать SMTP сервер
        my %auth;
        %auth = (AuthUser=>$smtpuser, AuthPass=>$smtppass) if $smtpuser;
        eval { $sendstat = $smtp ? $msg->send('smtp',$smtp,%auth) : $msg->send(); };
        _debug("[SENDMAIL: bad send message ($smtp)!] $@") if $@;
        _debug("[SENDMAIL: bad method send($smtp)!] $!") unless $sendstat;
    }
    #_debug("[SENDMAIL: The mail has been successfully sent to $to ",::tms(),"]") if $sendstat;

    return $sendstat ? 1 : 0;
}
sub sendmail { goto &send_mail }
sub ftp {
    # Упрощенная работа с FTP
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

    my $ftpconnect  = shift || {}; # Параметры коннекта {}
    my $cmd         = shift || ''; # Команда
    my $lfile       = shift || ''; # Локальный файл (с путем)
    my $rfile       = shift || ''; # Удаленный файл (только имя)

    # Проверка на вшивость:
    unless ($ftpconnect && (ref($ftpconnect) eq 'HASH') && $ftpconnect->{ftphost}) {
        _exception("Connect's data missing");
        return undef;
    }

    # Данные для коннекта к FTP-директории и Атрибуты коннекта {}
    my $ftphost     = $ftpconnect ? $ftpconnect->{ftphost}     : '';
    my $ftpuser     = $ftpconnect ? $ftpconnect->{ftpuser}     : '';
    my $ftppassword = $ftpconnect ? $ftpconnect->{ftppassword} : '';
    my $ftpdir      = $ftpconnect ? $ftpconnect->{ftpdir}      : '';
    my $attr        = $ftpconnect &&  $ftpconnect->{ftpattr} ? $ftpconnect->{ftpattr} : {};
    $attr->{Debug}  = (DEBUG && DEBUG == 2) ? 1 : 0;

    # создаем соединение
    my $ftp = Net::FTP->new($ftphost, %$attr)
        or (_debug("FTP: Can't connect to remote FTP server $ftphost: $@") && return undef);
    # логинимся
    $ftp->login($ftpuser, $ftppassword)
        or (_debug("FTP: Can't login to remote FTP server: ", $ftp->message) && return undef);
    # выбираем рабочую директорию
    if($ftpdir && !$ftp->cwd($ftpdir)) {
        _debug("FTP: Can't change FTP working directory \"$ftpdir\": ", $ftp->message);
        return undef;
    }


    my @out; # вывод
    if ( $cmd eq "connect" ){
        # Возвращаем хэндлер на коннект
        return $ftp;
    } elsif ( $cmd eq "ls" ){
        # получаем список в виде массива
        (my @out = $ftp->ls(WIN ? "" : "-1a" ))
            or _debug( "FTP: Can't get directory listing (\"$ftpdir\") from remote FTP server $ftphost: ", $ftp->message );
        $ftp->quit;
        return [@out];
    } elsif (!$lfile) {
        # не выбран файл - ошибка
        _debug("FTP: No filename given as parameter to FTP command $cmd");
    } elsif ($cmd eq "delete") {
        # удаляем файл
        $ftp->delete($lfile)
            or _debug( "FTP: Can't delete file \"$lfile\" on remote FTP server $ftphost: ", $ftp->message );
    } elsif ($cmd eq "get") {
        # получаем файл
        $ftp->binary;
        $ftp->get($rfile,$lfile)
            or _debug("FTP: Can't get file \"$lfile\" from remote FTP server $ftphost: ", $ftp->message);
    } elsif ($cmd eq "put") {
        # отправляем файл
        $ftp->binary;
        $ftp->put($lfile,$rfile)
            or _debug("FTP: Can't put file \"$lfile\" on remote FTP server $ftphost: ", $ftp->message );
    }

    $ftp->quit; # закрываем соединение и выходим
    return 1;
}
sub ftptest {
    # Проверка RW соединения FTP и возвращение 1 в случае успеха
    my $ftpdata = shift || undef;
    unless ($ftpdata) {
        _error("Connect's data missing"); # Данные соединения с FTP
        return undef;
    }
    my $vfile = '';
    if ($ftpdata->{voidfile}) {
        $vfile = $ftpdata->{voidfile};
    } else {
        $vfile = catfile(tmpdir(),VOIDFILE);
        touch($vfile);
    }
    unless (-e $vfile) {
        _debug("VOID file \"$vfile\" missing"); # Данные соединения с FTP
        return undef;
    }
    ftp($ftpdata, 'put', $vfile, VOIDFILE);
    my $rfiles = ftp($ftpdata,'ls');
    my @remotefiles = $rfiles ? grep {!(/^\./)} @$rfiles : ();
    unless (grep {$_ eq VOIDFILE} @remotefiles) {
        _debug("Can't connect to remote FTP server {".join(", ",(%$ftpdata))."}");
        return undef;
    }
    ftp($ftpdata, 'delete', VOIDFILE);
    return 1;
}
sub ftpgetlist {
    # Получение списка файлов на удаленном ресурсе по маске
    my $connect  = shift || {}; # Данные соединения
    my $mask     = shift || ''; # Маска файлов

    my $rfile = ftp($connect, 'ls');
    my @files = (($rfile && ref($rfile) eq 'ARRAY') ? @$rfile : ());

    # выкидываем все файлы не по маске!
    if ($mask && ref($mask) eq 'Regexp') {
        @files = grep {$_ =~ $mask} @files;
    } else {
        @files = grep {/$mask/} @files if $mask;
    }

    return [@files];
}
sub execute {
    # Выполнение внешней команды IPC
    my $icmd = shift || ''; # команда и аргументы (ссылка на массив или строка)
    my $in   = shift;
    my $out  = '';
    my $err  = shift; # !! REFERENCE TO SCALAR
    my $bm   = shift;

    my @scmd;
    if ($icmd && ref($icmd) eq 'ARRAY') { @scmd = @$icmd } else { push @scmd, $icmd }

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
        _debug("Executable error (".join(" ",@scmd)."): $ierr") if $ierr;
    }

    return $out;
}
sub exe { goto &execute }
sub com { goto &execute }
sub procexec { goto &execute }
sub procexe { goto &execute }
sub proccommand { goto &execute }
sub proccmd { goto &execute }
sub procrun { goto &execute }

#
# Расширенный утилитарий (Extended)
#

#
# Утилиты базирующиеся на работах автора модуля Sys::Path
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
# Системный утилитарий (Core)
#
sub getsyscfg { __PACKAGE__->ext_syscfg(@_) }
sub syscfg { __PACKAGE__->ext_syscfg(@_) }
sub isostype {__PACKAGE__->ext_isostype(@_)}
sub isos {__PACKAGE__->ext_isos(@_)}

#
# Утилитарные процедуры модуля (API)
#
# Smart rearrangement of parameters to allow named parameter calling.
# See CGI::Util
#
sub read_attributes {
    my($order,@param) = @_;
    return () unless @param;

    if (ref($param[0]) eq 'HASH') {
    @param = %{$param[0]};
    } else {
        return @param unless (defined($param[0]) && substr($param[0],0,1) eq '-');
    }

    # map parameters into positional indices
    my ($i,%pos);
    $i = 0;
    foreach (@$order) {
    foreach (ref($_) eq 'ARRAY' ? @$_ : $_) {
            $pos{lc($_)} = $i;
        }
    $i++;
    }

    my (@result,%leftover);
    $#result = $#$order;  # preextend
    while (@param) {
    my $key = lc(shift(@param));
    $key =~ s/^\-//;
        if (exists $pos{$key}) {
        $result[$pos{$key}] = shift(@param);
    } else {
        $leftover{$key} = shift(@param);
    }
    }

    push (@result,_make_attributes(\%leftover,1)) if %leftover;
    @result;
}
sub _make_attributes {
    my $attr = shift;
    return () unless $attr && ref($attr) && ref($attr) eq 'HASH';
    my $escape = shift || 0;
    my(@att);
    foreach (keys %{$attr}) {
    my($key) = $_;
        $key=~s/^\-//;
    ($key="\L$key") =~ tr/_/-/; # parameters are lower case, use dashes
    my $value = $escape ? $attr->{$_} : $attr->{$_};
    push(@att,defined($attr->{$_}) ? qq/$key="$value"/ : qq/$key/);
    }
    return @att;
}

sub _debug { goto &carp } # Просто пишем дебаггером
sub _error { goto &carp } # Пишем в стандартный вывод STDERROR, ТОЛЬКО ДЛЯ СИСТЕМНЫХ ПРОБЛЕМ!!!
sub _exception { goto &confess } # Пишем в стандартный вывод STDERROR и убиваем, ТОЛЬКО ДЛЯ СИСТЕМНЫХ ПРОБЛЕМ!!!

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

1;

package  # hide me from PAUSE
    CTK::Util::SysConfig;
use strict;
use vars qw/$VERSION/;
$VERSION = $CTK::Util::VERSION;
use Config qw//;
use Perl::OSType qw//;
sub ext_syscfg {
    # Принимаем значение системной конфигурации
    my $caller; $caller = shift if (@_ && $_[0] && $_[0] eq 'CTK::Util');
    my $self; $self = shift if (@_ && $_[0] && ref($_[0]) eq 'CTK');

    my $param = shift;
    if (defined $param) {
        return $Config::Config{$param}
    }
    my %locconf = %Config::Config;
    return %locconf;
}
sub ext_isostype {
    # Принимаем типы операционных систем и смотрим, если тип соответствует искомому, то TRUE
    my $caller; $caller = shift if (@_ && $_[0] && $_[0] eq 'CTK::Util');
    my $self; $self = shift if (@_ && $_[0] && ref($_[0]) eq 'CTK');
    return Perl::OSType::is_os_type(@_);
}
sub ext_isos {
    # Принимаем имена операционных систем и смотрим, если такой тип соответствует искомому, то TRUE
    my $caller; $caller = shift if (@_ && $_[0] && $_[0] eq 'CTK::Util');
    my $self; $self = shift if (@_ && $_[0] && ref($_[0]) eq 'CTK');
    my $cos = shift;
    my $os = $^O;
    return $cos && (lc($os) eq lc($cos)) && Perl::OSType::os_type($os) ? 1 : 0;
}
1;

__END__
