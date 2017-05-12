@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S %0 %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
if errorlevel 1 goto script_failed_so_exit_with_non_zero_val 2>nul
goto endofperl
@rem ';
#!perl
#line 15

use CGI;
use CGI::ExtDirect;

use RPC::ExtDirect::Test::Pkg::PollProvider;

local $RPC::ExtDirect::Test::Pkg::PollProvider::WHAT_YOURE_HAVING = '';

my $q = CGI->new();

my $extdirect = CGI::ExtDirect->new({ cgi => $q, debug => 1 });

my $cookie = $q->cookie(-name=>'sessionID',
                        -value=>'xyzzy',
                        -expires=>'Thursday, 25-Apr-1999 00:40:33 GMT',
                        -path=>'/cgi-bin/database',
                        -domain=>'.capricorn.org',
                        -secure=>1);

my %headers = (
    '-Status'           => '204 No Response',
    '-Content-type'     => 'text/plain',
    '-ChArSeT'          => 'iso-8859-1',
    '-Content_Length'   => '123123',
    '-cookie'           => $cookie,
);

print $extdirect->poll( %headers );

exit 0;

__END__
:endofperl

