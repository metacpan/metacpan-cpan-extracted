package Acrux::Util;
use strict;
use utf8;

=encoding utf8

=head1 NAME

Acrux::Util - The Acrux utilities

=head1 SYNOPSIS

    use Acrux::Util;

=head1 DESCRIPTION

This module provides portable utility functions for Acrux

=head2 clone

    my $copy = clone(\@array);
    my $copy = clone(\%hash);

This function is a proxy function for L<Storable/dclone>

It makes recursive copies of nested hash, array, scalar and reference types, including tied variables and objects.
The C<clone()> takes a scalar argument and duplicates it. To duplicate lists, arrays or hashes, pass them in by reference, e.g.

=head2 color

    say color(blue => "Format %s %s" => "text", "foo");
    say color(cyan => "text");
    say color("red on_bright_yellow" => "text");
    say STDERR color("red on_bright_yellow" => "text");

Returns colored formatted string if is session was runned from terminal

Supported normal foreground colors:

    black, red, green, yellow, blue, magenta, cyan, white

Bright foreground colors:

    bright_black, bright_red,     bright_green, bright_yellow
    bright_blue,  bright_magenta, bright_cyan,  bright_white

Normal background colors:

    on_black, on_red,     on_green, on yellow
    on_blue,  on_magenta, on_cyan,  on_white

Bright background color:

    on_bright_black, on_bright_red,     on_bright_green, on_bright_yellow
    on_bright_blue,  on_bright_magenta, on_bright_cyan,  on_bright_white

See also L<Term::ANSIColor>

=head2 deprecated

    deprecated('foo is DEPRECATED in favor of bar');

Warn about deprecated feature from perspective of caller.
You can also set the C<ACRUX_FATAL_DEPRECATIONS> environment
variable to make them die instead with L<Carp>

=head2 dformat

    $string = dformat( $mask, \%replacehash );
    $string = dformat( $mask, %replacehash );

Replace substrings "[...]" in mask and
returns replaced result. Data for replacing get from \%replacehash

For example:

    # -> 01-foo-bar.baz.tgz
    $string = dformat( "01-[NAME]-bar.[EXT].tgz", {
        NAME => 'foo',
        EXT  => 'baz',
    });

See also L<CTK::Util/dformat>

=head2 dtf

See L</fdt>

=head2 dumper

    my $perl = dumper({some => 'data'});

Dump a Perl data structure with L<Data::Dumper>

=head2 eqtime

    eqtime("from/file", "to/file") or die "Oops";

Sets modified time of destination to that of source

=head2 fbytes

    print fbytes( 123456 );

Returns formatted size value

=head2 fdate

    print fdate( time );

Returns formatted date value

=head2 fdatetime

    print fdatetime( time );

Returns formatted date value

=head2 fdt

    print fdt( $format, $time );
    print fdt( $format, $time, 1 ); # in GMT context

Returns time in your format.
Each conversion specification is replaced by appropriate characters as described in the following list

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
    Z       - Diff of TimeZone in short format (+0300)
    z       - Diff of TimeZone in lomg format (+03:00)
    G       - Short name of TimeZone GMT (for GMT context only)
    U       - Short name of TimeZone UTC (for GMT context only)

Examples:

    # RFC822 (RSS)
    say fdt("%w, %D %MON %YY %hh:%mm:%ss %G", time(), 1); # Tue, 3 Sep 2013 12:31:40 GMT

    # RFC850
    say fdt("%W, %DD-%MON-%YY %hh:%mm:%ss %G", time(), 1); # Tuesday, 03-Sep-13 12:38:41 GMT

    # RFC1036
    say fdt("%w, %D %MON %YY %hh:%mm:%ss %G", time(), 1); # Tue, 3 Sep 13 12:44:08 GMT

    # RFC1123
    say fdt("%w, %D %MON %YYYY %hh:%mm:%ss %G", time(), 1); # Tue, 3 Sep 2013 12:50:42 GMT

    # RFC2822
    say fdt("%w, %DD %MON %YYYY %hh:%mm:%ss %Z"); # Tue, 12 Feb 2013 16:07:05 +0400
    say fdt("%w, %DD %MON %YYYY %hh:%mm:%ss ".tz_diff());

    # W3CDTF, ATOM (Same as RFC 3339/ISO 8601) -- Mail format
    say fdt("%YYYY-%MM-%DDT%hh:%mm:%ss%z"); # 2013-02-12T16:10:28+04:00

    # CTIME
    say fdt("%w %MON %_D %hh:%mm:%ss %YYYY"); # Tue Feb  2 16:15:18 2013

    # Russian date and time format
    say fdt("%DD.%MM.%YYYY %hh:%mm:%ss"); # 12.02.2013 16:16:53

    # DIG form
    say fdt("%YYYY%MM%DD%hh%mm%ss"); # 20130212161844

    # HTTP headers format (See CGI::Util::expires)
    say fdt("%w, %DD %MON %YYYY %hh:%mm:%ss %G", time, 1); # Tue, 12 Feb 2013 13:35:04 GMT

    # HTTP/cookie format (See CGI::Util::expires)
    say fdt("%w, %DD-%MON-%YYYY %hh:%mm:%ss %G", time, 1); # Tue, 12-Feb-2013 13:35:04 GMT

    # COOKIE (RFC2616 as rfc1123-date)
    say fdt("%w, %DD %MON %YYYY %hh:%mm:%ss %G", time, 1); # Tue, 12 Feb 2013 13:35:04 GMT

For more features please use L<Date::Format>, L<DateTime> and L<POSIX/strftime>

=head2 fduration

    print fduration( 123 );

Returns formatted duration value

=head2 humanize_duration

    print humanize_duration ( 123 );

Turns duration value into a simplified human readable format

=head2 humanize_number

    print humanize_number( $number, $sep );

Placement of separators discharges among digits.
For example 1`234`567 if $sep is char "`" (default)

=head2 human2bytes

    my $bytes = human2bytes("100 kB");

Converts a human readable byte count into the pure  number of bytes without any suffix

See also L<Mojo::Util/humanize_bytes>

=head2 indent

    my $indented = indent($str, 4, ' ');
    my $indented = indent($str, 1, "\t");

Indent multi-line string

    # "  foo\n  bar\n  baz\n"
    print indent("foo\nbar\nbaz\n", 2);

You can use number of indent-chars and indent-symbol manuality:

    # "> foo\n> bar\n> baz\n"
    my $data = indent("foo\nbar\nbaz\n", 1, '> ');

See also L<Mojo::Util/unindent> to unindent multi-line strings

=head2 is_os_type

    $is_windows = is_os_type('Windows');
    $is_unix    = is_os_type('Unix', 'dragonfly');

Given an OS type and OS name, returns true or false if the OS name is of the given type.
As with os_type, it will use the current operating system as a default
if no OS name is provided

Original this function see in L<Perl::OSType/is_os_type>

=head2 load_class

    my $error = load_class('Foo::Bar');

Loads a class and returns a false value if loading was successful,
a true value if the class was not found or loading failed.

=head2 os_type

    $os_type = os_type(); # Unix
    $os_type = os_type('MSWin32'); # Windows

Returns a single, generic OS type for a given operating system name.
With no arguments, returns the OS type for the current value of $^O.
If the operating system is not recognized, the function will return the empty string.

Original this function see in L<Perl::OSType/os_type>

=head2 parse_expire

    print parse_expire("+1d"); # 86400
    print parse_expire("-1d"); # -86400

Returns offset of expires time (in secs).

Original this function is the part of CGI::Util::expire_calc!

This internal routine creates an expires time exactly some number of hours from the current time.
It incorporates modifications from  Mark Fisher.

format for time can be in any of the forms:

    now   -- expire immediately
    +180s -- in 180 seconds
    +2m   -- in 2 minutes
    +12h  -- in 12 hours
    +1d   -- in 1 day
    +3M   -- in 3 months
    +2y   -- in 2 years
    -3m   -- 3 minutes ago(!)

If you don't supply one of these forms, we assume you are specifying the date yourself

=head2 parse_time_offset

    my $off = parse_time_offset("1h2m24s"); # 4344
    my $off = parse_time_offset("1h 2m 24s"); # 4344

Returns offset of time (in secs)

=head2 randchars

    $rand = randchars( $n ); # default chars collection: 0..9,'a'..'z','A'..'Z'
    $rand = randchars( $n, \@collection ); # Defined chars collection

Returns random sequence of casual characters by the amount of n

For example:

    $rand = randchars( 8, [qw/a b c d e f/]); # -> cdeccfdf

=head2 slurp

    my $data = slurp($file, %args);
    my $data = slurp($file, { %args });
    slurp($file, { buffer => \my $data });
    my $data = slurp($file, { binmode => ":raw:utf8" });

Reads file $filename into a scalar

    my $data = slurp($file, { binmode => ":unix" });

Reads file in fast, unbuffered, raw mode

    my $data = slurp($file, { binmode => ":unix:encoding(UTF-8)" });

Reads file with UTF-8 encoding

By default it returns this scalar. Can optionally take these named arguments:

=over 4

=item binmode

Set the layers to read the file with. The default will be something sensible on your platform

=item block_size

Set the buffered block size in bytes, default to 1048576 bytes (1 MiB)

=item buffer

Pass a reference to a scalar to read the file into, instead of returning it by value.
This has performance benefits

=back

See also L</spew> to writing data to file

=head2 spew

    spew($file, $data, %args);
    spew($file, $data, { %args });
    spew($file, \$data, { %args });
    spew($file, \@data, { %args });
    spew($file, $data, { binmode => ":raw:utf8" });

Writes data to a file atomically. The only argument is C<binmode>, which is passed to
C<binmode()> on the handle used for writing.

Can optionally take these named arguments:

=over 4

=item append

This argument is a boolean option, defaulted to false (C<0>).
Setting this argument to true (C<1>) will cause the data to be be written at the end of the current file.
Internally this sets the sysopen mode flag C<O_APPEND>

=item binmode

Set the layers to write the file with. The default will be something sensible on your platform

=item locked

This argument is a boolean option, defaulted to false (C<0>).
Setting this argument to true (C<1>) will ensure an that existing file will not be overwritten

=item mode

This numeric argument sets the default mode of opening files to write.
By default this argument to C<(O_WRONLY | O_CREAT)>.
Please DO NOT set this argument unless really necessary!

=item perms

This argument sets the permissions of newly-created files.
This value is modified by your process's umask and defaults to 0666 (same as sysopen)

=back

See also L</slurp> to reading data from file

=head2 spurt

See L</spew>

=head2 touch

    touch( "file" ) or die "Can't touch file";

Makes file exist, with current timestamp

See L<ExtUtils::Command>

=head2 trim

    print '"'.trim( "    string " ).'"'; # "string"

Returns the string with all leading and trailing whitespace removed.
Trim on undef returns undef. Original this function see String::Util

=head2 truncstr

    print truncstr( $string, $cutoff_length, $continued_symbol );

If the $string is longer than the $cutoff_length, then the string will be truncated
to $cutoff_length characters, including the $continued_symbol
(which defaults to '.' if none is specified).

    print truncstr( "qwertyuiop", 3, '.' ); # q.p
    print truncstr( "qwertyuiop", 7, '.' ); # qw...op
    print truncstr( "qwertyuiop", 7, '*' ); # qw***op

Returns a line the fixed length from 3 to the n chars

See also L<CTK::Util/variant_stf>

=head2 tz_diff

    print tz_diff( time ); # +0300
    print tz_diff( time, ':' ); # +03:00

Returns TimeZone difference value

    print fdt("%w, %DD %MON %YYYY %hh:%mm:%ss ".tz_diff(time), time);

Prints RFC-2822 format date

=head2 words

    my $arr = words( ' foo bar,  baz bar ' ); # ['foo', 'bar', 'baz']
    my $arr = words( ' foo bar ', '  baz' ); # ['foo', 'bar', 'baz']
    my $arr = words( [' foo bar ', '  baz'] ); # ['foo', 'bar', 'baz']
    my $arr = words( ['foo, bar'], ['baz bar '] ); # ['foo', 'bar', 'baz']

This function parse string by words and returns as an anonymous array.
All words in the resultating array are unique and arranged
in the order of the input string

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Mojo::Util>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2024 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

our $VERSION = '0.01';

use Carp qw/ carp croak /;
use IO::File qw//;
use Term::ANSIColor qw/ colored /;
use POSIX qw/ :fcntl_h ceil floor strftime /;
use Fcntl qw/ O_WRONLY O_CREAT O_APPEND O_EXCL SEEK_END /;
use Time::Local;
use Data::Dumper qw//;
use Storable qw/dclone/;

use Acrux::Const qw/ IS_TTY DATE_FORMAT DATETIME_FORMAT /;

use base qw/Exporter/;
our @EXPORT = (qw/
        deprecated
        dumper
        clone
    /);
our @EXPORT_OK = (qw/
        fbytes human2bytes humanize_duration humanize_number
        fdt dtf tz_diff fdate fdatetime fduration
        randchars
        dformat trim truncstr indent words
        touch eqtime slurp spew spurt
        parse_expire parse_time_offset
        os_type is_os_type
        color load_class
    /, @EXPORT);

use constant HUMAN_SUFFIXES => {
    'B' => 0,
    'K' => 10, 'KB' => 10, 'KIB' => 10,
    'M' => 20, 'MB' => 20, 'MIB' => 20,
    'G' => 30, 'GB' => 30, 'GIB' => 30,
    'T' => 40, 'TB' => 40, 'TIB' => 40,
    'P' => 50, 'PB' => 50, 'PIB' => 50,
    'E' => 60, 'EB' => 60, 'EIB' => 60,
    'Z' => 70, 'ZB' => 70, 'ZIB' => 70,
    'Y' => 80, 'YB' => 80, 'YIB' => 80,
};

use constant DTF => {
    DOW  => [qw/Sunday Monday Tuesday Wednesday Thursday Friday Saturday/],
    DOWS => [qw/Sun Mon Tue Wed Thu Fri Sat/], # Short
    MOY  => [qw/January February March April May June July August September October November December/],
    MOYS => [qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/], # Short
};

# See Perl::OSType
my %OSTYPES = qw(
    aix         Unix
    bsdos       Unix
    beos        Unix
    bitrig      Unix
    dgux        Unix
    dragonfly   Unix
    dynixptx    Unix
    freebsd     Unix
    linux       Unix
    haiku       Unix
    hpux        Unix
    iphoneos    Unix
    irix        Unix
    darwin      Unix
    machten     Unix
    midnightbsd Unix
    minix       Unix
    mirbsd      Unix
    next        Unix
    openbsd     Unix
    netbsd      Unix
    dec_osf     Unix
    nto         Unix
    svr4        Unix
    svr5        Unix
    sco         Unix
    sco_sv      Unix
    unicos      Unix
    unicosmk    Unix
    solaris     Unix
    sunos       Unix
    cygwin      Unix
    msys        Unix
    os2         Unix
    interix     Unix
    gnu         Unix
    gnukfreebsd Unix
    nto         Unix
    qnx         Unix
    android     Unix

    dos         Windows
    MSWin32     Windows

    os390       EBCDIC
    os400       EBCDIC
    posix-bc    EBCDIC
    vmesa       EBCDIC

    MacOS       MacOS
    VMS         VMS
    vos         VOS
    riscos      RiscOS
    amigaos     Amiga
    mpeix       MPEiX
);


# Common
sub deprecated {
    local $Carp::CarpLevel = 1;
    $ENV{ACRUX_FATAL_DEPRECATIONS} ? croak @_ : carp @_;
}
sub dumper { Data::Dumper->new([@_])->Indent(1)->Sortkeys(1)->Terse(1)->Useqq(1)->Dump }
sub clone { dclone(shift) }
sub load_class {
    my $class = shift // '';
    return "Invalid class name: $class" unless $class =~ /^\w(?:[\w:]*\w)?$/;
    return undef if $class->can('new') || eval "require $class; 1"; # Ok
    return "Class $class not found" if $@ =~ /^Can't\s+locate/i; # Error
    return $@; # Error
}

# Bytes and numbers
sub fbytes {
    my $n = int(shift);
    if ($n >= 1024 ** 3) {
        return sprintf "%.3g GiB", $n / (1024 ** 3);
    } elsif ($n >= 1024 ** 2) {
        return sprintf "%.3g MiB", $n / (1024.0 * 1024);
    } elsif ($n >= 1024) {
        return sprintf "%.3g KiB", $n / 1024.0;
    } else {
        return "$n B"; # bytes
    }
}
sub human2bytes {
    my $h = shift || 0;
    return 0 unless $h;
    my ($bts, $sfx) = $h =~ /([0-9.]+)\s*([a-zA-Z]*)/;
    return 0 unless $bts;
    my $exp = HUMAN_SUFFIXES->{($sfx ? uc($sfx) : "B")} || 0;
    return ceil($bts * (2 ** $exp));
}
sub humanize_duration {
    my $msecs = shift || 0;
    my $secs = int($msecs);
    my $years = int($secs / (60*60*24*365));
       $secs -= $years * 60*60*24*365;
    my $days = int($secs / (60*60*24));
       $secs -= $days * 60*60*24;
    my $hours = int($secs / (60*60));
       $secs -= $hours * 60*60;
    my $mins = int($secs / 60);
       $secs %= 60;
    if ($years) { return sprintf("%d years %d days %s hours", $years, $days, $hours) }
    elsif ($days) { return sprintf("%d days %s hours %d minutes", $days, $hours, $mins) }
    elsif ($hours) { return sprintf("%d hours %d minutes %d seconds", $hours, $mins, $secs) }
    elsif ($mins >= 2) { return sprintf("%d minutes %d seconds", $mins, $secs) }
    elsif ($secs > 5) { return sprintf("%d seconds", $secs + $mins * 60) }
    elsif ($msecs - $secs) { return sprintf("%.4f seconds", $msecs) }
    return sprintf("%d seconds", $secs);
}
sub fduration {
    my $msecs = shift || 0;
    my $secs = int($msecs);
    my $hours = int($secs / (60*60));
       $secs -= $hours * 60*60;
    my $mins = int($secs / 60);
       $secs %= 60;
    if ($hours) {
        return sprintf("%d hours %d minutes", $hours, $mins);
    } elsif ($mins >= 2) {
        return sprintf("%d minutes", $mins);
    } elsif ($secs < 2*60) {
        return sprintf("%.4f seconds", $msecs);
    } else {
        $secs += $mins * 60;
        return sprintf("%d seconds", $secs);
    }
}
sub humanize_number {
    my $var = shift || 0;
    my $sep = shift || "`";
    1 while $var=~s/(\d)(\d\d\d)(?!\d)/$1$sep$2/;
    return $var;
}

# Date and Time utils
sub fdate {
    my $t = shift || time;
    return strftime(DATE_FORMAT, localtime($t));
}
sub fdatetime {
    my $t = shift || time;
    return strftime(DATETIME_FORMAT, localtime($t));
}
sub parse_expire {
    my $t = trim(shift(@_) // 0);
    my %mult = (
            's' => 1,
            'm' => 60,
            'h' => 60*60,
            'd' => 60*60*24,
            'w' => 60*60*24*7,
            'M' => 60*60*24*30,
            'y' => 60*60*24*365
        );
    if (!$t || (lc($t) eq 'now')) {
        return 0;
    } elsif ($t =~ /^\d+$/) {
        return $t; # secs
    } elsif ($t=~/^([+-]?(?:\d+|\d*\.\d*))([smhdwMy])/) {
        return ($mult{$2} || 1) * $1;
    }
    return $t;
}
sub parse_time_offset {
    my $s = trim(shift(@_) // 0);
    return $s if $s =~ /^\d+$/;
    my $r = 0;
    my $c = 0;
    while ($s =~ s/([+-]?(?:\d+|\d*\.\d*)[smhdMy])//) {
        my $i = parse_expire("$1");
        $c++ if $i < 0;
        $r += $i < 0 ? $i*-1 : $i;
    }
    return $c ? $r*-1 : $r;
}
sub fdt {
    my $f = shift || ''; # Format
    my $t = shift || time(); # Time
    my $g = shift || 0; # 0 - Local time; 1 - GMT time

    my (@dt, %dth, %dth2);
    @dt = $g ? gmtime($t) : localtime($t);

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
    $dth2{'%z'}    = tz_diff($t, ':');
    $dth2{'%Z'}    = $dth2{'%z'}; $dth2{'%Z'} =~ s/\://;
    $dth2{'%%'}    = '%';

    $f =~ s/$_/$dth{$_}/sge for sort { length($b) <=> length($a) } keys %dth;
    $f =~ s/$_/$dth2{$_}/sge for qw/%G %U %Z %z %%/;

    return $f
}
sub dtf { goto &fdt }
sub tz_diff {
    my $tm = shift || time;
    my $chr = shift // '';
    my $diff = Time::Local::timegm(localtime($tm)) - Time::Local::timegm(gmtime($tm));
       $diff  = abs($diff);
    my $direc = $diff < 0 ? '-' : '+';
    my $tz_hr = int( $diff / 3600 );
    my $tz_mi = int( $diff / 60 - $tz_hr * 60 );
    return sprintf("%s%02d%s%02d", $direc, $tz_hr, $chr, $tz_mi);
}

# Text utils
sub trim {
    my $val = shift;
    return unless defined $val;
    $val =~ s|^\s+||s; # trim left
    $val =~ s|\s+$||s; # trim right
    return $val;
}
sub dformat { # Simple template
    my $f = shift;
    my $d = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};
    $f =~ s/\[([A-Z0-9_\-.]+?)\]/(defined($d->{$1}) ? $d->{$1} : "[$1]")/eg;
    return $f;
}
sub randchars {
    my $l = shift || return '';
    return '' unless $l =~/^\d+$/;
    my $arr = shift;
    my $r = '';
    my @chars = ($arr && ref($arr) eq 'ARRAY') ? (@$arr) : (0..9,'a'..'z','A'..'Z');
    $r .= $chars[(int(rand($#chars+1)))] for (1..$l);
    return $r;
}
sub truncstr {
    my $string = shift // '';
    my $cutoff = shift || 0;
    my $marker = shift // '.';

    # Get dots dumber
    my $dots = 0;
    $cutoff = 3 if $cutoff < 3;
    if ($cutoff < 6) { $dots = $cutoff - 2 }
    else { $dots = 3 }

    # Real length of cutted string
    my $reallenght = $cutoff - $dots;

    # Input string is too short
    return $string if length($string) <= $cutoff;

    # Truncate
    my $fix = floor($reallenght / 2);
    my $new_start = substr($string, 0, ($reallenght - $fix)); # Start part of string
       $new_start =~ s/\s+$//; # trim
    my $new_midle = $marker x $dots; # Middle part of string
    my $new_end   = substr($string, (length($string) - $fix), $fix); # Last part of string
       $new_end   =~ s/^\s+//; # trim
    return sprintf ("%s%s%s", $new_start, $new_midle, $new_end);
}
sub indent {
    my $str = shift // '';
    my $ind = floor(shift || 0);
    my $chr = shift // ' ';
    return $str unless $ind && $ind <= 65535;
    return join '', map { ($chr x $ind) . $_ . "\n" } split /\n/, $str;
}
sub words {
    my @in;
    foreach my $r (@_) {
        if (ref($r) eq 'ARRAY') { push @in, @$r } else { push @in, $r }
    }
    my %o;
    my $i = 0;
    foreach my $s (@in) {
        $s = trim($s // '');
        next unless length($s) && !ref($s);
        foreach my $w (split(/[\s;,]+/, $s)) {
            next unless length($w);
            $o{$w} = ++$i unless exists $o{$w};
        }
    }
    return [sort {$o{$a} <=> $o{$b}} keys %o ];
}

# File utils
sub touch {
    my $fn  = shift // '';
    return 0 unless length($fn);
    my $t = time;
    my $ostat = open my $fh, '>>', $fn;
    unless ($ostat) {
        carp("Can't touch file \"$fn\": $!");
        return 0;
    }
    close $fh if $ostat;
    utime($t, $t, $fn);
    return 1;
}
sub eqtime {
    my $src = shift // '';
    my $dst = shift // '';
    return 0 unless length($src);
    return 0 unless length($dst);
    unless ($src && -e $src) {
        carp("Can't get access and modification times of file \"$src\": no file found");
        return 0;
    }
    unless (utime((stat($src))[8,9], $dst)) {
        carp("Can't change access and modification times on file \"$dst\": $!");
        return 0;
    }
    return 1;
}
sub slurp {
    my $file = shift // '';
    my $args = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};
    return unless length($file) && -r $file;
    my $cleanup = 1;

    # Open filehandle
    my $fh;
    if (ref($file)) {
        $fh = $file;
        $cleanup = 0; # Disable closing filehandle for passed filehandle
    } else {
        $fh = IO::File->new($file, "r");
        unless (defined $fh) {
            carp qq/Can't open file "$file": $!/;
            return;
        }
    }

    # Set binmode layer
    my $bm = $args->{binmode} // ':raw'; # read in :raw by default
    $fh->binmode($bm);

    # Set buffer
    my $buf;
    my $buf_ref = $args->{buffer} // \$buf;
     ${$buf_ref} = ''; # Set empty string to buffer
    my $blk_size = $args->{block_size} || 1024 * 1024; # Set block size (1 MiB)

    # Read whole file
    my ($pos, $ret) = (0, 0);
    while ($ret = $fh->read(${$buf_ref}, $blk_size, $pos)) {
        $pos += $ret if defined $ret;
    }
    unless (defined $ret) {
        carp qq/Can't read from file "$file": $!/;
        return;
    }

    # Close filehandle
    $fh->close if $cleanup; # automatically closes the file

    # Return content if no buffer specified
    return if defined $args->{buffer};
    return ${$buf_ref};
}
sub spew {
    my $file = shift // '';
    my $data = shift // '';
    my $args = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};
    my $cleanup = 1;

    # Get binmode layer, mode and perms
    my $bm = $args->{binmode} // ':raw'; # read in :raw by default
    my $perms = $args->{perms} // 0666; # set file permissions
    my $mode = $args->{mode} // O_WRONLY | O_CREAT;
       $mode |= O_APPEND if $args->{append};
       $mode |= O_EXCL if $args->{locked};

    # Open filehandle
    my $fh;
    if (ref($file)) {
        $fh = $file;
        $cleanup = 0; # Disable closing filehandle for passed filehandle
    } else {
        $fh = IO::File->new($file, $mode, $perms);
        unless (defined $fh) {
            carp qq/Can't open file "$file": $!/;
            return;
        }
    }

    # Set binmode layer
    $fh->binmode($bm);

    # Set buffer
    my $buf;
    my $buf_ref = \$buf;
    if (ref($data) eq 'SCALAR') {
        $buf_ref = $data;
    } elsif (ref($data) eq 'ARRAY') {
        ${$buf_ref} = join '', @$data;
    } else {
        $buf_ref = \$data;
    }

    # Seek, print, truncate and close
    $fh->seek(0, SEEK_END) if $args->{append}; # SEEK_END == 2
    $fh->print(${$buf_ref}) or return;
    $fh->truncate($fh->tell) if $cleanup;
    $fh->close if $cleanup;

    return 1;
}
sub spurt { goto &spew }

# Colored helper function
sub color {
    my $clr = shift;
    my $txt = (scalar(@_) == 1) ? shift(@_) : sprintf(shift(@_), @_);
    return $txt unless defined($clr) && length($clr);
    return IS_TTY ? colored([$clr], $txt) : $txt;
}

# Misc
sub os_type {
    my $os = shift // $^O;
    return $OSTYPES{$os} || '';
}
sub is_os_type {
    my $type = shift || return;
    return os_type(shift) eq $type;
}

1;

__END__
