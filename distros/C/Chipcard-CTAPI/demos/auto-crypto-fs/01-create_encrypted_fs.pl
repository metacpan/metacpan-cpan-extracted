#!/usr/local/bin/perl

use strict;
use warnings;

use Fcntl;

use Chipcard::CTAPI;

use Expect;

# ================= CONFIGURATION START

# size of the file system in megabytes
my $FSIZE = 16;

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

# sources for truly random bytes and random bytes
# set $URANDOM to /dev/zero if you don't mind your container being
# created with zeros instead of random bytes. Otherwise, /dev/urandom
# is a good choice as /dev/random is far too slow usually.
my $RANDOM  = "/dev/random";
my $URANDOM = "/dev/zero";

# length of the randomly created password
my $PWLEN = 16;

# which loopback device to use
my $LOOPBACK = "/dev/loop4";

# command to set up the loopback device
my $LOSETUP = "/sbin/losetup -e $ALG $LOOPBACK $CONTAINER";

# command to create a file system on the loopback device
my $MKFS = "/sbin/mke2fs $LOOPBACK";

# command to shut the loopback device down
my $LODOWN = "/sbin/losetup -d $LOOPBACK";

# your card terminal's port for ctapi (0 = COM1, 1 = COM2, ...)
my $PORT = 1;

# =================== CONFIGURATION END


if (-f $CONTAINER."xxx") {
    print << "snip";
Warning: file $CONTAINER already exists.
$0 is not supposed to be run multiple times.
If you're sure you want to re-create the encrypted file system,
please delete $CONTAINER first.
snip
    exit 1;
}

print << "snip";
This is a proof-of-concept implementation demonstrating how encrypted
loopback filesystems can be created under Linux with their random 
password being stored on a memory chip card.

You should have a look at $0 and change the settings in there 
to your needs; as some commands executed by this tool might require 
root privileges on your system, you also should carefully read it and
understand what it does.

Please note that this is a very primitive implementation. As the
password is stored in clear text on the memory card, the created
file system can not be considered secure in any way.

If you've read, changed and understood $0, please hit Enter 
now to proceed, or Ctrl-C to abort.
snip

<STDIN>;



print "* Creating container file with random content: " . 
      "$CONTAINER, $FSIZE MB...\n";
my $ONE_KB = 1024;
my $COUNT = $ONE_KB * $FSIZE;
system("dd if=$URANDOM of=$CONTAINER bs=1024 count=$COUNT");



my $PWBUF;
my $PW = '';
print "* Generating a random password (length: $PWLEN characters)...\n";
sysopen(F, $RANDOM, O_RDONLY) or die "Can't read from $RANDOM -> $!\n";

while(length $PW < $PWLEN) {
    sysread(F, $PWBUF, 1);
    # accept bytes in range 33-126, skip some
    next if ((ord $PWBUF) < 33);
    next if ((ord $PWBUF) > 126);
    next if ((ord $PWBUF) == 34); # "
    next if ((ord $PWBUF) == 39); # '
    next if ((ord $PWBUF) == 92); # \
    $PW .= $PWBUF;
}
close(F);



print "* Setting up the loopback device...\n";
# Using Expect has the advantage that the generated password doesn't
# have to be written to a temporary file on disk.
my $exp=Expect->spawn($LOSETUP);
$exp->expect(5,
             [ qr'size', sub { my $f = shift; $f->send("$keysize\n");
                               exp_continue; }],
             [ qr'asswor', sub { my $f = shift; $f->send("$PW\n");
                                 exp_continue; }],
             '-re', '[\]\$\>\#]\s$');


print "* Creating the file system...\n";
system($MKFS);



print "* Turning the loopback device off again...\n";
system($LODOWN);



print "* Storing the password on card...\n";
my $ct = new Chipcard::CTAPI(interface => $PORT)
    or die "Can't communicate with card terminal...\n";

while ($ct->getMemorySize < $PWLEN) {
    print "Please insert a memory card with at least $PWLEN bytes capacity " .
          "and hit Enter...\n";
    <STDIN>;
    $ct->reset;
}
$ct->setData($PW . "\000");
$ct->write(1, $ct->getDataLength) or die "writing to card failed\n";

print "* Password saved on card. You can now use the mount-script to mount\n" .
      "  your encrypted file system...\n";

$ct->close;
      
exit 0;

