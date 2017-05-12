#!/usr/bin/perl -w

use strict;

eval { require XML::Comma; };
my $comma_installed = $@ ? 0 : 1;
unless($comma_installed) {
	warn "install-extras.pl is a null step without comma installed\n";
	exit 0;
}

my @dd = sort { $b =~ /macro(s)?$/ ? 1 : 0 } @{XML::Comma->defs_directories};
my $found = undef;
foreach my $d (@dd) {
   $found = "$d/cache_static.macro" if(-e "$d/cache_static.macro");
}
unless($found) {
	my $installed = undef;
	foreach my $d (@dd) {
		if(-w $d) {
			my $macro_file = "$d/cache_static.macro";
			eval {
				open(IN, "misc/extensions/XML_Comma/cache_static.macro");
				open(OUT, ">$macro_file");
				print OUT join("", <IN>);
				close(IN);
				close(OUT);
			}; if($@) {
				warn "couldn't write to directory: $d...\n"
			} else {
				$installed = $macro_file;
				last;
			}
		}
	}
	if($installed) {
		print "installed cache_static.macro in $installed\n";
		exit 0;
	} else {
		warn "couldn't install cache_static.macro - please copy this to one\n";
		warn "of your Comma defs directories by hand if you intend on using\n";
		warn "XML::Comma dependencies\n";
		exit 1;
	}
} else {
	print "found cache_static.macro in $found\n";
	exit 0;
}
