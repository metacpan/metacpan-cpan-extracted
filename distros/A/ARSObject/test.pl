#!perl -w
use strict;
use Test;


BEGIN { plan tests => 2 + 5 + 1}

if (1) {
   print "\nRequired modules:\n";
   foreach my $m ('ARS', 'POSIX') {
     print "use $m\t";
     ok(eval("use $m; 'ok'"), 'ok');
   }
}

if (1) {
   print "\nOptional modules:\n";
   foreach my $m ('Data::Dumper', 'Storable', 'DBI', 'CGI', 'SMTP') {
     print "use $m\t";
     skip(!eval("use $m; 1"), 1);
   }
}


if (1) {
   print "\nPackaged modules:\n";
   foreach my $m ('ARSObject') {
     print "use ${m}\t";
     ok(eval("use ${m}; 1"), 1);
   }
}
