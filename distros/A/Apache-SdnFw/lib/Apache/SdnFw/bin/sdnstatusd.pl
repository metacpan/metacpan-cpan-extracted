#!/usr/bin/perl

use strict;
use IO::Socket;
use XML::Dumper;

my $maxlen = 1024000;
my $newlog;

my %x;

# first setup a way for the UDP listener
# to send data back to the parent

pipe(CHILD, TO_PARENT);
select((select(TO_PARENT), $| = 1)[0]); # autoflush

my $pid = fork;
my $tsock;
if ($pid == 0) {
	# we are the listener
	getdata();
} else {
	# start tcp server so we can report what our UDP server is getting for us
	$tsock = IO::Socket::INET->new(
		LocalPort => 11272,
		Listen => 1,
		Reuse => 1,
		Blocking => 0,
		Proto => 'tcp') || die "socket: $!";

	#print "UDP Listener started with pid $pid\n";
}

while(1) {
	my $line = <CHILD>;
	#print "From listener: $line" if ($line);
	parse($line) if ($line);

#	print(report());
	while (my $client = $tsock->accept()) {
		#print "Report request....\n";
		#my $addr = gethostbyaddr($client->peeraddr, AF_INET);
		$client->print(report());
		$client->close();
	}
}

$tsock->close if (defined($tsock));

sub report {

	my $dump = new XML::Dumper;
	my $output = $dump->pl2xml(\%x);
	$output =~ s/\n//g;
	return $output;
}

sub getdata {
	my $sock = IO::Socket::INET->new(
			LocalPort => 11271,
			Proto => 'udp') || die "socket: $!";

	while ($sock->recv($newlog,$maxlen)) {
		syswrite(TO_PARENT, "$newlog\n");
	}
	$sock->close();
}

sub parse {
	my $raw = shift;

	my $start;
	my $url;
	my $pagetime;
	foreach my $seg (split "\t", $raw) {
		if ($seg =~ m/^!!!(.+)$/) {
			($start,$url) = split '\|', $1;
			$x{page}{$url}{count}++;
			$x{page}{$url}{last} = $start;
		} elsif ($seg =~ m/^###\((.+)\)$/) {
			$x{page}{$url}{total} += $1;
			$x{page}{$url}{avg} = sprintf "%.4f", $x{page}{$url}{total}/$x{page}{$url}{count}
				if ($x{page}{$url}{count} != 0);
		} elsif ($seg =~ m/^---(.+)$/) {
			my @l = split '\|', $1;
			my $id = "$l[3]-$l[2]";
			$x{code}{$id}{count}++;
			$x{code}{$id}{last} = $start;
			$x{code}{$id}{total} += $l[4];
			unless(defined($x{code}{$id}{min})) {
				$x{code}{$id}{min} = sprintf "%.4f", $l[4];
			} elsif ($x{code}{$id}{min} > $l[4]) {
				$x{code}{$id}{min} = sprintf "%.4f", $l[4];
			}
			unless(defined($x{code}{$id}{max})) {
				$x{code}{$id}{max} = sprintf "%.4f", $l[4];
			} elsif ($x{code}{$id}{max} < $l[4]) {
				$x{code}{$id}{max} = sprintf "%.4f", $l[4];
			}
			$x{code}{$id}{avg} = sprintf "%.4f", $x{code}{$id}{total}/$x{code}{$id}{count}
				if ($x{code}{$id}{count} != 0);
		}
	}
}
