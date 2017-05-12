#!/usr/bin/perl

use Net::Telnet ();
$t = new Net::Telnet (Timeout => 10);
$t->open(Host=>"localhost",Port=>9999);

while(1) {
	print "OMLsql> ";
	$cmd = <STDIN>;
	chomp $cmd;
	$cmd eq 'quit' and last;
	$t->print($cmd);
	$n = $t->getline;
	chomp $n;
	my $i = 1;
	my @l, my @h;
   while($i++<=$n) {
		@l = ();
		@h = ();
		$line = $t->getline;
		foreach (split /\s+/, $line) {
			m/(\w+)=(\w+)/ and push @l, $2;
			$i == 2 and push @h, $1;
		}
		pretty_header(@h) if $i==2;
		pretty_line(@l);
	}
	pretty_end(@l);
}

sub pretty_header {
	my @l = @_;

	foreach (@l) { print '+'.'-'x20; }
	print "+\n";
	pretty_line(@l);
	foreach (@l) { print '+'.'-'x20; }
	print "+\n";
}

sub pretty_line {
   foreach (@_) { printf "| %-19s" ,$_; }
	print "|\n";
}

sub pretty_end {
	my @l = @_;

	foreach (@l) { print '+'.'-'x20; }
	print "+\n";
}
