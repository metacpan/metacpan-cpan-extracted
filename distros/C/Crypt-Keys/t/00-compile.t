# $Id: 00-compile.t,v 1.1 2001/07/11 07:22:31 btrott Exp $

my $loaded;
BEGIN { print "1..1\n" }
use Crypt::Keys;
$loaded++;
print "ok 1\n";
END { print "not ok 1\n" unless $loaded }
