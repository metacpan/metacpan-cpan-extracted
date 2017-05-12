#!/usr/bin/perl -w

# $Id: alvis-pipeline-filter.pl,v 1.2 2005/09/30 16:20:20 mike Exp $

use strict;
use warnings;
use Alvis::Pipeline;

die "Usage: $0 <readport> <spooldir> <writehost> <writeport>" if @ARGV != 4;
my($readPort, $spooldir, $writeHost, $writePort) = @ARGV;

my $in = new Alvis::Pipeline::Read(port => $readPort, spooldir => $spooldir)
    or die "can't create read-pipe for port $readPort, spooldir $spooldir: $!";

my $out = new Alvis::Pipeline::Write(host => $writeHost, port => $writePort)
    or die "can't create write-pipe for host $writeHost, port $writePort: $!";

while (my $xml = $in->read(1)) {
    $out->write($xml);
}
