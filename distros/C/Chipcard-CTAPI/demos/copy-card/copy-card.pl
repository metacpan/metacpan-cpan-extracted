#!/usr/local/bin/perl

# This program is part of a collection of simple demonstrations for
# Chipcard::CTAPI's capabilities.

use strict;
use warnings;
use Chipcard::CTAPI;

my $port = 0;
my $force = 0;
my $debug = 0;

$| = 1; # unbuffer STDOUT

# process command line arguments
while (my $arg = shift) {
    if ($arg eq "-f") {
        $force = 1;
    }
    if ($arg eq "-p") {
        $port = shift;
    }
    if ($arg eq "-d") {
        $debug = 1;
    }
    if ($arg eq "--help") {
        Usage();
        exit 0;
    }
}

# initialize the card terminal
my $ct = new Chipcard::CTAPI('interface' => $port, 'debug' => $debug)
    or die "Can't communicate with card terminal on port $port.\n".
           "Try specifying a different port with the -p option.\n";
           
# check whether we started with a card inserted 
if ($ct->getMemorySize == 0) {
    print "Please insert the card to copy and hit Enter.\n";
    <STDIN>;
    $ct->reset;
    die "No card detected.\n" unless ($ct->getMemorySize);
}

# start the download
print "Downloading data from card...";
my $old_size = $ct->getMemorySize;

$ct->read(0, $old_size)
    or die " Error while reading from card.\n";

print " OK\n";

# wait for new card
print "Please insert the new card and hit Enter.\n";
<STDIN>;

$ct->reset;
my $new_size = $ct->getMemorySize;

if ($new_size == 0) {
    print "Sorry, no card detected.\n";
    exit 1;
}
elsif ($new_size < $old_size) {
    print "Warning: new card's memory is smaller than old one's!\n";
    unless ($force) {
        print "If you want to ignore this, use the -f command line option!\n";
        exit 1;
    }
}
elsif ($ct->checkSixtyTwoOne) { # see manpage
    print "You didn't change the card ;-) Going to overwrite it...\n";
}
 
# start the upload
print "Uploading data to new card... ";
$ct->write(0, $new_size) 
    or die "Error while writing to card!\n";

print "OK.\n";

# We're done
exit 0;


##################################


sub Usage {
print << "snip";
Usage: $0 [-p X] [-f]

Copies the content of one memory chipcard to another.

Options:
    -p X      set the port your card terminal is attached to.
              0 = COM1, 1 = COM2, 2 = COM3, 3 = COM4
              For non-serial terminals, consult your CTAPI
              documentation.
    -f        Force the copying to the new card, even if it has
              less memory.
    -d        Turn on debugging to see the communcation between
              your machine and the card terminal.
snip
}


