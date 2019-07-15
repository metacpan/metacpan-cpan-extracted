@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S "%0" %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
exit /b %errorlevel%
goto endofperl
@rem ';
#!perl
#line 15
undef @rem;
######################################################################
#
# App::japerl - JPerl-again Perl glocalization scripting environment
#
# https://metacpan.org/release/App-japerl
#
# Copyright (c) 2018, 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

$VERSION = '0.12';
$VERSION = $VERSION;
BEGIN { pop @INC if $INC[-1] eq '.' } # CVE-2016-1238: Important unsafe module load path flaw
use FindBin;

use 5.00503;
use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; $^W=1;

# configuration of this software
%_ = (
    PERL5BIN => $^X,

    PERL5LIB => [

        # local::lib compatible
        defined($ENV{PERL_LOCAL_LIB_ROOT}) ? ($ENV{PERL_LOCAL_LIB_ROOT}) : (),

        # path of Char::* modules
        $FindBin::Bin,
    ],

    ENCODING => (

        # Windows system
        # Code Page Identifiers (Windows)
        # Identifier .NET Name Additional information
        ($^O =~ /MSWin32/) ? ({
              '708' => 'Arabic',      # ASMO-708 Arabic (ASMO 708)
              '874' => 'TIS620',      # windows-874 ANSI/OEM Thai (same as 28605, ISO 8859-15); Thai (Windows)
              '932' => 'Sjis',        # shift_jis ANSI/OEM Japanese; Japanese (Shift-JIS)
              '936' => 'GBK',         # gb2312 ANSI/OEM Simplified Chinese (PRC, Singapore); Chinese Simplified (GB2312)
              '949' => 'UHC',         # ks_c_5601-1987 ANSI/OEM Korean (Unified Hangul Code)
              '950' => 'Big5Plus',    # big5 ANSI/OEM Traditional Chinese (Taiwan; Hong Kong SAR, PRC); Chinese Traditional (Big5)
              '951' => 'Big5HKSCS',   # HKSCS support on top of traditional Chinese Windows
             '1252' => 'Windows1252', # windows-1252 ANSI Latin 1; Western European (Windows)
             '1255' => 'Hebrew',      # windows-1255 ANSI Hebrew; Hebrew (Windows)
             '1258' => 'Windows1258', # windows-1258 ANSI/OEM Vietnamese; Vietnamese (Windows)
            '20127' => 'USASCII',     # us-ascii US-ASCII (7-bit)
            '20866' => 'KOI8R',       # koi8-r Russian (KOI8-R); Cyrillic (KOI8-R)
            '20932' => 'EUCJP',       # EUC-JP Japanese (JIS 0208-1990 and 0121-1990)
            '21866' => 'KOI8U',       # koi8-u Ukrainian (KOI8-U); Cyrillic (KOI8-U)
            '28591' => 'Latin1',      # iso-8859-1 ISO 8859-1 Latin 1; Western European (ISO)
            '28592' => 'Latin2',      # iso-8859-2 ISO 8859-2 Central European; Central European (ISO)
            '28593' => 'Latin3',      # iso-8859-3 ISO 8859-3 Latin 3
            '28594' => 'Latin4',      # iso-8859-4 ISO 8859-4 Baltic
            '28595' => 'Cyrillic',    # iso-8859-5 ISO 8859-5 Cyrillic
            '28596' => 'Arabic',      # iso-8859-6 ISO 8859-6 Arabic
            '28597' => 'Greek',       # iso-8859-7 ISO 8859-7 Greek
            '28598' => 'Hebrew',      # iso-8859-8 ISO 8859-8 Hebrew; Hebrew (ISO-Visual)
            '28599' => 'Latin5',      # iso-8859-9 ISO 8859-9 Turkish
            '28603' => 'Latin7',      # iso-8859-13 ISO 8859-13 Estonian
            '28605' => 'Latin9',      # iso-8859-15 ISO 8859-15 Latin 9
            '51932' => 'EUCJP',       # euc-jp EUC Japanese
            '54936' => 'GB18030',     # GB18030 Windows XP and later: GB18030 Simplified Chinese (4 byte); Chinese Simplified (GB18030)
            '65001' => 'UTF2',        # utf-8 Unicode (UTF-8)
        }->{(qx{chcp 2>NUL} =~ m/([0-9]{3,5})/oxms)[0]} || 'USASCII')

        # other system
        : 'UTF2', # UTF-8,
    ),

    # The PERL5OPT environment variable (for passing command line arguments
    # to Perl) didn't work for more than a single group of options. [561]

    PERL5OPT => join(' ',
        '-w',
        # '-MFake::Our',
        # '-MModern::Open',
        (exists $ENV{PERL5OPT}) ? $ENV{PERL5OPT} : '',
    ),
);

# get command-line switches
my @switch = ();
while ((defined $ARGV[0]) and ($ARGV[0] =~ /^-/)) {
    if ($ARGV[0] eq '--') {
        shift @ARGV;
        last;
    }
    elsif ($ARGV[0] =~ /e$/) {     # -e "one line perl script"
        push @switch, shift @ARGV; # -e
        push @switch, shift @ARGV; #    "one line perl script"
    }
    elsif ($ARGV[0] =~ /E$/) {     # -E "ONE LINE PERL SCRIPT"
        push @switch, shift @ARGV; # -E
        push @switch, shift @ARGV; #    "ONE LINE PERL SCRIPT"
    }
    elsif ($ARGV[0] =~ /I$/) {     # -I Include/Path
        push @switch, shift @ARGV; # -I
        push @switch, shift @ARGV; #    Include/Path
    }
    else {
        push @switch, shift @ARGV;
    }
}

# command-line parameter not found
unless (@ARGV) {
    die <<END;
usage:

    @{[__FILE__]} [switches] [--] script.pl [arguments]
END
}

# script file exists or not
if (not -e $ARGV[0]) {
    die "@{[__FILE__]}: script $ARGV[0] not found.\n";
}

# script file already escaped
if ($ARGV[0] =~ /\.e$/i) {
    # nothing to do
}

# script file is encoded in something
elsif (exists $_{ENCODING}) {

    # escaped script not found or older than source script
    if ((not -e "$ARGV[0].e") or ((stat "$ARGV[0].e")[9] < (stat $ARGV[0])[9])) {

        # got source filter
        if (my($source_filter_dir) = grep { -e "$_/$_{ENCODING}.pm" } @{$_{PERL5LIB}}, @INC) {

            # escape source script
            my $return = system(join ' ', 
                $_{PERL5BIN},
                "-I$source_filter_dir",
                "$source_filter_dir/$_{ENCODING}.pm",
                $ARGV[0],
                '>',
                "$ARGV[0].e",
            );
            if ($return >> 8) {
                die "$source_filter_dir/$_{ENCODING}.pm: $ARGV[0] had compilation errors.\n";
            }
            $ARGV[0] = "$ARGV[0].e";
        }

        # source filter not found
        else {
            die sprintf(<<'END', __FILE__, $_{ENCODING}, join('', map {"  $_\n"} @{$_{PERL5LIB}}), join('', map{"  $_\n"} @INC));
%s: source filter %s.pm not found in

@{$_{PERL5LIB}}
%s
@INC
%s
If you had install it, you can set PERL_LOCAL_LIB_ROOT of shell.
END
        }
    }
}

# local $ENV{PATH} = '.';
local @ENV{qw(IFS CDPATH ENV BASH_ENV)}; # Make %ENV safer

# remove environment variable PERL5OPT
local $ENV{PERL5OPT};

# execute escaped script
my $return = system(
    $_{PERL5BIN},
    (map { "-I$_" } grep { -e $_ } @{$_{PERL5LIB}}),
    @switch,
    $_{PERL5OPT},
    '--',
    @ARGV,
);

exit($return >> 8);

__END__

=pod

=head1 NAME

App::japerl - JPerl-again Perl glocalization scripting environment

=head1 SYNOPSIS

  japerl [switches] [--] script.pl [arguments]

=head1 DESCRIPTION

japerl was created with the intention of succeeding JPerl.
japerl provides glocalization script environment on both modern Perl
and traditional Perl by using Char::* software family.

This is often misunderstood, but japerl and jacode.pl have different
purposes and functions.

       software
  <<elder   younger>>     software purpose
  ----------------------+---------------------------------------
  jcode.pl  jacode.pl   | to convert encoding of data for I/O
  ----------------------+---------------------------------------
  jperl     japerl.bat  | to execute native encoding scripts
                        | (NEVER convert script encoding)
  ----------------------+---------------------------------------

This software can do the following.

=over 4

=item * choose one perl interpreter in system

=item * select local use libraries

=item * execute script written in system native encoding

=back

May you do good magic with japerl.

=head1 AUTHOR

INABA Hitoshi E<lt>ina@cpan.orgE<gt> in a CPAN

This project was originated by INABA Hitoshi.

=head1 LICENSE AND COPYRIGHT

This software is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

:endofperl
