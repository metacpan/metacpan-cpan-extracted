#!/usr/bin/perl

#boring example logger
#could log via DBI or whatever
#we've been opened via:
# Apache::LogFile->new("|/path/to/this_script.pl");

use IO::File ();

my $fh = IO::File->new(">>/tmp/my_log_file");
$fh->autoflush(1);

while(<>) {
    #sleep 20; #pretend this is going to take a while
               #scripts/modules who write to the pipe handle
               #will not have to wait for this!
    print $fh $_;
}

close $fh;


