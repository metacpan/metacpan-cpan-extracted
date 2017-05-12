#!/usr/local/bin/perl

use strict;
use warnings;

use Fcntl;

use Chipcard::CTAPI;

use Expect;

# ================= CONFIGURATION START

# encryption algorithm (passed as -e parameter to losetup)
# note that your system must support this algorithm. that's usually
# the case only when you've installed aes-loopback or the kerneli 
# patch. some distributions, such as newer SuSE ones, come with 
# support for encrypted file systems as well.
my $ALG = "twofish";

# if losetup asks for a keysize with the algorithm you specified,
# send this value:
my $keysize = "256";

# name of the container file to be created
my $CONTAINER = "demo_fs_container";

# which loopback device to use
my $LOOPBACK = "/dev/loop4";

# command to set up the loopback device
my $LOSETUP = "/sbin/losetup -e $ALG $LOOPBACK $CONTAINER";

# your card terminal's port for ctapi (0 = COM1, 1 = COM2, ...)
my $PORT = 1;

# command for mounting the encrypted filesystem
my $MOUNT = "mount $LOOPBACK /mnt/test";

# =================== CONFIGURATION END


if (! -f $CONTAINER) {
    print << "snip";
$CONTAINER not found. Please run the script to create a container
file first...\n
snip
    exit 0;
}

print "* Downloading the password from card...\n";
my $ct = new Chipcard::CTAPI(interface => $PORT)
    or die "Can't communicate with card terminal...\n";

while ($ct->getMemorySize == 0) {
    print "Please insert the card with your password and hit Enter...\n";
    <STDIN>;
    $ct->reset;
}

$ct->read(1, $ct->getMemorySize - 1);
my $pw = substr($ct->getData, 0, $ct->getIndex(0));
$ct->close;


print "* Setting up the loopback device...\n";
# Using Expect has the advantage that the generated password doesn't
# have to be written to a temporary file on disk.
my $exp=Expect->spawn($LOSETUP);
$exp->expect(5,
             [ qr'size', sub { my $f = shift; $f->send("$keysize\n");
                               exp_continue; }],
             [ qr'asswor', sub { my $f = shift; $f->send("$pw\n");
                                 exp_continue; }],
             '-re', '[\]\$\>\#]\s$');



print "* Mounting the encrypted file system...\n";
system($MOUNT);

print "* For unmounting, use the provided unmount-script...\n";

exit 0;

