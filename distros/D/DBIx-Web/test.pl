#!perl -w
use strict;
use Test;
BEGIN { plan tests => 19 }

if (1) {
   print "\nRequired modules:\n";
   foreach my $m ('DBIx::Web', 'POSIX', 'Sys::Hostname', 'Fcntl', 'Symbol', 'IPC::Open2', 'File::Copy', 'Data::Dumper', 'Safe', 'CGI', 'CGI::Carp') {
     print "use $m\t";
     ok(eval("use $m; 'ok'"), 'ok');
   }
}

if (1) {
   print "\nOptional modules, dependent on features used:\n";
   foreach my $m ('Apache'
   , 'DBI'
   , 'DB_File'
   , 'Algorithm::Diff') {
     print "use $m\t";
     skip(!eval("use $m; 1"), 1);
   }
}

if (1 && $^O eq 'MSWin32') {
   print "\nWin32 modules, dependent on features used:\n";
   foreach my $m ('Win32','Win32::API','Win32::TieRegistry') {
     print "use $m\t";
     ok(eval("use $m; 'ok'"), 'ok');
     # skip(!eval("use $m; 1"), 1);
   }
   foreach my $m ('cacls.exe') {
     print "$m\t";
     # ok(eval(!(`$m /?` && 1)), 'ok');
     skip(!(`$m /?` && 1), 1);
   }
}

