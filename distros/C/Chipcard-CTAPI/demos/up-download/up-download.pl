#!/usr/local/bin/perl

# This program is part of a collection of simple demonstrations for
# Chipcard::CTAPI's capabilities.

use strict;
use warnings;
use Chipcard::CTAPI;

my $port = 0;
my $debug = 0;
my $upload = 0;
my $filename;

$| = 1; # unbuffer STDOUT

# process command line arguments
while (my $arg = shift) {
    if ($arg eq "-p") {
        $port = shift;
    }
    elsif ($arg eq "-d") {
        $debug = 1;
    }
    elsif ($arg eq "-u") {
        $upload = 1;
    }
    elsif ($arg eq "--help") {
        Usage();
        exit 0;
    }
    else { $filename = $arg; }
}

die "No filename specified! Try $0 --help\n" unless (defined $filename);

# if we're going to upload, check whether we can access the file
if ($upload) {
    die "Can't read $filename\n" unless (-r $filename);
}
else {
    # we're going to download, check whether we can create the file
    open(F, "> $filename") or die "Can't create $filename: $!\n";
    close(F);
}

# initialize the card terminal
my $ct = new Chipcard::CTAPI('interface' => $port, 'debug' => $debug)
    or die "Can't communicate with card terminal on port $port.\n".
           "Try specifying a different port with the -p option.\n";
           
# check whether we started with a card inserted 
if ($ct->getMemorySize == 0) {
    print "Please insert the card and hit Enter.\n";
    <STDIN>;
    $ct->reset;
    die "No card detected.\n" unless ($ct->getMemorySize);
}

if ($upload) {
    print "Starting upload of $filename to card... ";
    $ct->upload($filename) or die "Error while writing to card!\n";
}
else {
    print "Starting download to file $filename... ";
    $ct->download($filename) or die "Error while reading from card!\n";
}

print "OK\n";

exit 0;


sub Usage {
print << "snip";
Tool for up- and downloading memory card images.

Usage: $0 [-u] [-p X] [-d] filename

In download mode your card's whole memory will be retrieved and stored
in the file with the given name. In upload mode, the content of the
given file will be stored on the card (note that the data will be truncated
if the file is larger than the card's memory).

Options:

    -p X      set the port your card terminal is attached to.
              0 = COM1, 1 = COM2, 2 = COM3, 3 = COM4
              For non-serial terminals, consult your CTAPI
              documentation.
    -d        Turn on debugging to see the communcation between
              your machine and the card terminal.
    -u        Switch to upload mode.

Examples: 
$0 -p 1 card_memory_dump.bin
$0 -p 0 -u upload_this_file.bin
snip
}

