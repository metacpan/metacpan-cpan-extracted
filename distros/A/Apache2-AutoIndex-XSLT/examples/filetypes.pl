#!/usr/bin/perl -w

use strict;
use Data::Dumper;

my %data;
my $ext = '';
while (local $_ = <>) {
	if (my ($k,$v) = $_ =~ /^\s*(\S+)\s*:\s*(\S.*?)\s*$/) {
		if ($k =~ /ext(ension)?/i) {
			$v =~ s/^\.//;
			$ext = $v || '';
		} elsif ($v) {
			$data{$ext}->{$k} = $v;
		}
	}
}

print Dumper(\%data);

__END__

Extension:      .cmd
  Type:         cmdfile
  MimeType:     
  DisplayName:  Windows NT Command Script
  IconDesc:     C:\WINDOWS\System32\shell32.dll,-153

