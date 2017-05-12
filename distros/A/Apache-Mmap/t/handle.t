##
## handle.t -- Apache::Mmap::Handle tie test 
##

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use Carp;
use Fcntl qw(O_WRONLY O_CREAT O_TRUNC);

use Apache::Mmap qw( :DEFAULT );

## Black magic from h2xs's test.pl
BEGIN { $| = 1; print "1..2\n"; }
END { print "not ok 1\n" unless $loaded; }
use Apache::Mmap::Handle ();
$loaded = 1;
print "ok 1\n";
## End black magic from h2xs's test.pl

$tmp = "mmap.tmp";		# Temporary filename

## mmap errors will usually cause a SIGBUS.
$SIG{'BUS'} = sub { 
  die "SIGBUS recieved.  Exiting!\n"
};

## Put 'ok 2' message into file
sysopen(FOO, $tmp, O_WRONLY|O_CREAT|O_TRUNC) or die "$tmp: $!\n";
print FOO "ok 2\n";
close FOO;

## Open and tie FOO to $tmp read-only
tie *FOO, 'Apache::Mmap', $tmp, 'r';
print <FOO>;
close *FOO;

unlink($tmp);			# Clean up our tmp file
