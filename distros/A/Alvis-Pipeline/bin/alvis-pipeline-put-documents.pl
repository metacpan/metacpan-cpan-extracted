#!/usr/bin/perl -w

# $Id: alvis-pipeline-put-documents.pl,v 1.1 2006/07/11 10:36:37 mike Exp $

use strict;
use warnings;
use IO::File;
use Alvis::Pipeline;

die "Usage: $0 <host> <port> <file> ..." if @ARGV < 3;
my $host = shift();
my $port = shift();
my $loglevel = 3;		### should be settable from command-line

my $pipe = new Alvis::Pipeline::Write(host => $host, port => $port,
				      loglevel => $loglevel)
    or die "can't create write-pipe for host '$host', port '$port': $!";

foreach my $filename (@ARGV) {
    my $fh = new IO::File("<$filename")
	or die "can't open '$filename' for reading: $!";
    my $xml = join("", <$fh>);
    $fh->close();
    $pipe->write($xml);
}

$pipe->close();
# Ha!  That was easy :-)
