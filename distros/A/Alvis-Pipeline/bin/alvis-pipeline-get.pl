#!/usr/bin/perl -w

# $Id: alvis-pipeline-get.pl,v 1.4 2005/09/30 16:20:28 mike Exp $

use strict;
use warnings;
use Alvis::Pipeline;

die "Usage: $0 <port> <spooldir>" if @ARGV != 2;
my($port, $spooldir) = @ARGV;
my $pipe = new Alvis::Pipeline::Read(port => $port, spooldir => $spooldir)
    or die "can't create read-pipe on port $port: $!";

my $n = 0;
while (my $xml = $pipe->read(1)) {
    $xml .= "\n" if $xml !~ /\n$/;
    print "=== new document ===\n$xml";
    $n++;
}

$pipe->close();
print "No documents in pipeline\n"
    if $n == 0;
