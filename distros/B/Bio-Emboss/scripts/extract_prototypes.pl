#!/usr/bin/perl

foreach $file (@ARGV) {
    next unless $file =~ m:/:;
    $out = $file;
    $out =~ s:.*/::;

    open (CPP, "cpp -P -I- $file |") || warn ("cpp error");
    open (OUT, ">$out" . ".proto");

    while (<CPP>) {
	next unless /\S/;
	next if /typedef/;
	next if /extern/;

	next if /\.\.\./;

	next unless /\(/;

	# --- AjO...*  => AjP...
	s/AjO(\w+)\*/AjP$1/g;

	while (! /;/) {
	    $a = <CPP>;
	    chomp;
	    $a =~ s/\s+/ /;
	    $_ .= $a;
	}

	print OUT;
    }

    close (OUT);
    close (CPP);
}
