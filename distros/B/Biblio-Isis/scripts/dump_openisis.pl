#!/usr/bin/perl -w

# this utility emulates output of openisis -db "database"
# so you can test if perl can read your isis file

#use strict;
use OpenIsis;
use Data::Dumper;

my $db = OpenIsis::open( shift @ARGV || '/data/isis_data/ps/LIBRI/LIBRI' );
my $debug = shift @ARGV;
my $maxmfn = OpenIsis::maxRowid( $db ) || 1;

print "rows: $maxmfn\n\n";

for (my $mfn = 1; $mfn <= $maxmfn; $mfn++) {
	print "0\t$mfn\n";
	my $row = OpenIsis::read( $db, $mfn );
	if ($debug)  {
		print STDERR Dumper($row),"\n";
		my $rec;
		foreach my $f (keys %{$row}) {
			foreach my $v (@{$row->{$f}}) {
				push @{$rec->{$f}}, OpenIsis::subfields($v);
			}
		}
		print STDERR Dumper($rec),"\n";
	}
	foreach my $k (sort keys %{$row}) {
		next if ($k eq 'mfn');
		print "$k\t",join("\n$k\t",@{$row->{$k}}),"\n";
	}
	print "\n";
}

