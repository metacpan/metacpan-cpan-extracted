#!/usr/bin/perl -w

# $Id: alvis-zsink.pl,v 1.6 2006/08/31 16:13:16 mike Exp $
#
# This is an Alvis Sink -- that is, a program that sits at the end of
# an Alvis pipeline absorbing documents that are fed to it from an
# Alvis Source, most likely through a series of one or more filters
# that add semantic annotation.  It deals with the records by feeding
# them to an Extended-Services-compliant Z39.50 server, most likely
# Zebra.
#
# The program needs to be told what port to listen on (for the
# pipeline) and what host/port to write to (for the Z39.50 server).
# For example, to listen on port 8021 and feed documents to a server
# on localhost:1314, use:
#	alvis-zsink.pl 8021 localhost:1314

use strict;
use warnings;
use Alvis::Pipeline 0.07;
use Net::Z3950::ZOOM 1.11;	# We don't use this, but it's ZOOM's release
use ZOOM;

if (@ARGV != 2 && @ARGV != 4) {
    print STDERR <<__EOT__;
Usage: $0 <listen-port> <z-host> [<user> <password>]
    <listen-port> is the port on which to listen for documents being
    fed down the Alvis pipeline; <z-host> is ZOOM-style Z39.50 host
    string such as 'localhost:1314' or 'tcp:alvis.indexdata.com:8122'
__EOT__
    exit 1;
}

my($port, $zhost, $user, $password) = @ARGV;
my $pipe = new Alvis::Pipeline::Read(port => $port,
				     spooldir => "/tmp/alvis-spool")
    or die "can't create read-pipe on port $port: $!";
$pipe->option(sleep => 1);
print "Listening on pipeline\n";

my $options = new ZOOM::Options();
$options->option(user => $user) if defined $user;
$options->option(password => $password) if defined $password;
my $conn = create ZOOM::Connection($options);
my $connected = 0;

my $n = 0;
$| = 1;
while (my $xml = $pipe->read(1)) {
    eval {
	$conn->connect($zhost);
    }; if ($@ && ref $@ && $@->isa("ZOOM::Exception") &&
	   $@->diagset() eq "Bib-1" && $@->code() == 224) {
	# Do nothing: this allows for a bug in ZOOM-C (as of YAZ
	# version 2.1.27) whereby a no-opping call to connect() does
	# not clear any old error indication.
	print "ignoring re-occurrence of old error in connect()\n";
    } elsif ($@) {
	die $@; # re-throw
    }

    if (!$connected) {
	print "connected to Z39.50 server\n";
	$connected = 1;
    }
    print "got document ", ++$n, " ... ";

    eval {
	my $p = $conn->package();
	$p->option(action => "specialUpdate");
	$p->option(record => $xml);
	eval { $p->send("update"); };
	if ($@) { die $@; }
	print "sent package ... ";
	$p->destroy();
	$p = $conn->package();
	$p->option(action => "commit");
	$p->send("commit");
	print "commit ... ";
    };

    if (!$@) {
	print "added document\n";
	next;
    } elsif (!ref $@ || !$@->isa("ZOOM::Exception")) {
	# A non-ZOOM error, which is totally unexepected.  Treat this
	# as fatal: we need to shut the read-pipe down properly so
	# that the spooling child process is killed.
	$pipe->close();
	die $@;
    } else {
	# A ZOOM error, e.g. BIB-1 224, "ES: immediate execution
	# failed".  Most such cases need not be treated as fatal, so
	# we just log it and continue to listen for subsequent
	# documents.
	print "failed\n";
	warn "discarding record: $@\n";
    }
}
