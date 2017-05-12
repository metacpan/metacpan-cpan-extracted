#!perl -w
use strict;
use Test;
BEGIN { plan tests => 23 }

if (1) {
   print "\nRequired modules:\n";
   foreach my $m ('CGI::Bus', 'CGI', 'CGI::Carp', 'Sys::Hostname', 'POSIX') {
     print "use $m\t";
     ok(eval("use $m; 'ok'"), 'ok');
   }
}

if (1) {
   print "\nOptional modules, dependent on features used:\n";
   foreach my $m ('Apache', 'CGI::Fast'
   , 'DBI'
   , 'Data::Dumper', 'Safe'
   , 'IPC::Open2'
   , 'IO::File', 'Fcntl', 'File::Copy', 'File::Compare', 'File::Find'
   , 'Digest') {
     print "use $m\t";
     skip(!eval("use $m; 1"), 1);
   }
}

if (1 && $^O eq 'MSWin32') {
   print "\nWin32 optional modules, dependent on features used:\n";
   foreach my $m ('Win32','Win32::API','Win32::TieRegistry', 'Win32API::Net', 'Win32::OLE') {
     print "use $m\t";
     skip(!eval("use $m; 1"), 1);
   }
   foreach my $m ('cacls.exe') {
     print "$m\t";
     skip(!(`$m /?` && 1), 1);
   }
}

