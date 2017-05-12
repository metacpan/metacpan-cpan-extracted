##
## tie.t -- Apache::Mmap tie test 
##

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use Carp;
use FileHandle;

## Black magic from h2xs's test.pl
BEGIN { $| = 1; print "1..4\n"; }
END { print "not ok 1\n" unless $loaded; }
use Apache::Mmap qw(PROT_READ PROT_WRITE MAP_SHARED);
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

## Open $tmp and tie $foo to it read-only
sysopen(FOO, $tmp, O_RDONLY) or die "$tmp: $!\n";
tie $foo, 'Apache::Mmap', *FOO, 0, PROT_READ, MAP_SHARED;
close FOO;

print $foo;			# Should print 'ok 2'
untie $foo;			# untie $foo from file

## Open $tmp read/write and tie it read/write to $foo
sysopen(FOO, $tmp, O_RDWR) or die "$tmp: $!\n";
tie $foo, 'Apache::Mmap', *FOO, 0, PROT_READ|PROT_WRITE, MAP_SHARED;
close FOO;

## Change 'ok 2' to 'ok 3'
substr($foo, 3, 1) = "3";
print $foo;

## Change 'ok 3' to 'ok 4' and untie $foo
substr($foo, 3, 1) = "4";
untie $foo;
undef $foo;

## Check that $tmp really has 'ok 4' in it
open( FOO, $tmp ) or die "$tmp: $!\n";
print <FOO>;
close( FOO );	

unlink($tmp);			# Clean up our tmp file
