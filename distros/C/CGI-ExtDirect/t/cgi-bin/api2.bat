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

use CGI::ExtDirect;

use RPC::ExtDirect::API     Namespace       => 'myApp.ns',
                            Router_path     => '/router.cgi',
                            Poll_path       => '/poll.cgi',
                            Remoting_var    => 'Ext.app.REMOTE_CALL',
                            Polling_var     => 'Ext.app.REMOTE_POLL',
                            Auto_Connect    => 1;

use RPC::ExtDirect::Test::Pkg::Foo;
use RPC::ExtDirect::Test::Pkg::Bar;
use RPC::ExtDirect::Test::Pkg::Qux;
use RPC::ExtDirect::Test::Pkg::Meta;

my $cgi = CGI::ExtDirect->new({ debug => 1 });

print $cgi->api();

exit 0;

__END__
:endofperl

