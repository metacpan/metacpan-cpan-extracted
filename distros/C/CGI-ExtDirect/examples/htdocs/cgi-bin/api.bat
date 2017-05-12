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

use lib '../../../lib';

# These modules provide demo Ext.Direct remoting and polling APIs
use RPC::ExtDirect::Demo::TestAction;
use RPC::ExtDirect::Demo::Profile;
use RPC::ExtDirect::Demo::PollProvider;

use RPC::ExtDirect::Config;
use CGI::ExtDirect;

my $config = RPC::ExtDirect::Config->new(
    router_path => '/cgi-bin/router.cgi',
    poll_path   => '/cgi-bin/poll.cgi',
);

my $direct = CGI::ExtDirect->new( config => $config );

print $direct->api();

exit 0;

__END__
:endofperl

