# $Id: 00-compile.t,v 1.1.1.1 2004/08/15 14:55:43 btrott Exp $

my $loaded;
BEGIN { print "1..1\n" }
use Class::ErrorHandler;
$loaded++;
print "ok 1\n";
END { print "not ok 1\n" unless $loaded }
