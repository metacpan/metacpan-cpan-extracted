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
undef(@rem=@rem);
######################################################################
#
# App::japerl - JPerl-again Perl glocalization scripting environment
#
# https://metacpan.org/dist/App-japerl
#
# Copyright (c) 2018, 2019, 2021, 2023 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

$VERSION = '0.15';
$VERSION = $VERSION;
BEGIN { pop @INC if $INC[-1] eq '.' } # CVE-2016-1238: Important unsafe module load path flaw
use FindBin;
use Config;

use 5.00503;
use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;

# command-line parameter not found
unless (@ARGV) {
    die <<END;
usage:

    @{[__FILE__]} [switches] [--] script.pl [arguments]
END
}

# mb.pm modulino exists or not
my @PERL_LOCAL_LIB_ROOT = ();
if (defined $ENV{'PERL_LOCAL_LIB_ROOT'}) {
    @PERL_LOCAL_LIB_ROOT = split(/$Config{'path_sep'}/, $ENV{'PERL_LOCAL_LIB_ROOT'});
}
my($mbpm_modulino) = grep(-e, map {"$_/mb.pm"}
    @PERL_LOCAL_LIB_ROOT,
    $FindBin::Bin,
    "$FindBin::Bin/lib",
    @INC,
);
if (not defined $mbpm_modulino) {
    die sprintf(<<'END', __FILE__, join("\n",map{"    $_/mb.pm"} @PERL_LOCAL_LIB_ROOT), "    $FindBin::Bin/mb.pm", "    $FindBin::Bin/lib/mb.pm", join("\n",map{"    $_/mb.pm"} @INC));
%s: "mb.pm" modulino not found anywhere.

@PERL_LOCAL_LIB_ROOT
%s
$FindBin::Bin
%s
$FindBin::Bin/lib
%s
@INC
%s

see you again on https://metacpan.org/dist/mb
END
}

# configuration of this software
my %x = (
    'PERL5BIN' => $^X,

    'PERL5LIB' => [

        # local::lib compatible
        @PERL_LOCAL_LIB_ROOT,
    ],

    # The PERL5OPT environment variable (for passing command line arguments
    # to Perl) didn't work for more than a single group of options. [561]

    'PERL5OPT' => join(' ',
        '-w',
        (exists $ENV{'PERL5OPT'}) ? $ENV{'PERL5OPT'} : '',
    ),
);

# get command-line switches
my @switch = ();
while ((defined $ARGV[0]) and ($ARGV[0] =~ /^-/)) {
    if ($ARGV[0] eq '--') {
        shift @ARGV;
        last;
    }
    elsif ($ARGV[0] =~ /I$/) {     # -I Include/Path
        push @switch, shift @ARGV; # -I
        push @switch, shift @ARGV; #    Include/Path
    }
    else {
        push @switch, shift @ARGV;
    }
}

# script file exists or not
if (not -e $ARGV[0]) {
    die "@{[__FILE__]}: script $ARGV[0] not found.\n";
}

# local $ENV{'PATH'} = '.';
local @ENV{qw(IFS CDPATH ENV BASH_ENV)}; # Make %ENV safer

# remove environment variable PERL5OPT
local $ENV{'PERL5OPT'};

# execute escaped script
$| = 1;
system(
    "$x{'PERL5BIN'}",
    (map { "-I$_" } grep { -e $_ } @{$x{'PERL5LIB'}}),
    (map { "-I$_" } grep { -e $_ } $FindBin::Bin),
    (map { "-I$_" } grep { -e $_ } "$FindBin::Bin/lib"),
    @switch,
    $x{'PERL5OPT'},
    '--',
    $mbpm_modulino,
    @ARGV,
);
exit($? >> 8);

__END__

=pod

=head1 NAME

App::japerl - JPerl-again Perl glocalization scripting environment

=head1 SYNOPSIS

  japerl [switches] [--] MBCS_script.pl [arguments]

=head1 DESCRIPTION

japerl.bat is a wrapper for the mb.pm modulino.
This software assists in the execution of Perl scripts written in MBCS encoding.

It differs in function and purpose from jacode.pl, which has a similar name and is often misunderstood.
jacode.pl is mainly used to convert I/O data encoding.

On the other hand, mb.pm modulino handles script you wrote, and it does not convert its encoding.

       software
  <<elder   younger>>     software purpose
  ----------------------+---------------------------------------
  jcode.pl  jacode.pl   | to convert encoding of data for I/O
  ----------------------+---------------------------------------
  jperl     japerl.bat  | to execute native encoding scripts
                        | (NEVER convert script encoding)
  ----------------------+---------------------------------------

This software can do the following.

=over 2

=item *

choose one perl interpreter in system

=item *

select local use libraries

=item *

execute script written in system native encoding

=back

=head1 How to find mb.pm modulino ?

Running japerl.bat requires mb.pm modulino.
japerl.bat finds for mb.pm modulino in the following order and uses the first mb.pm found.

=over 2

=item 1

@PERL_LOCAL_LIB_ROOT

=item 2

$FindBin::Bin

=item 3

$FindBin::Bin/lib

=item 4

@INC

=back

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
