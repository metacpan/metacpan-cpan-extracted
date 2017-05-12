#!/usr/bin/perl -w

# $Id: alvis-pipeline-put.pl,v 1.4 2005/09/30 16:20:37 mike Exp $

use strict;
use warnings;
use IO::File;
use Alvis::Pipeline;

die "Usage: $0 <host> <port>" if @ARGV != 2;
my($host, $port) = @ARGV;
my $loglevel = 3;		### should be settable from command-line

my $pipe = new Alvis::Pipeline::Write(host => $host, port => $port,
				      loglevel => $loglevel)
    or die "can't create write-pipe for host '$host', port '$port': $!";

my $count = 1;
while (1) {
    my $xml = <<__EOT__;
<?xml version="1.0" encoding="UTF-8"?>
<count>This is document number $count</count>
__EOT__
    $pipe->write($xml);
    print "Wrote document $count to the pipe\n";
    $count++;
    sleep(int(rand() * 5) + 1);
}
