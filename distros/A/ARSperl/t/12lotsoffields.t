#!./perl

use ARS;
require './t/config.cache';

my $GETLOOPS = 100;
my $NT = 5 + $GETLOOPS - 1;
my $TN = 1;

print "1..$NT\n";


my($ctrl) = ars_Login(&CCACHE::SERVER, 
		      &CCACHE::USERNAME, 
 		      &CCACHE::PASSWORD, "","", &CCACHE::TCPPORT);

if(!defined($ctrl)) {
	print "not ok [", $TN++, "]\n";
	while($TN <= $NT) {
		print "not ok [", $TN++, "]\n";
	}
	exit(0);
} else {
	print "ok [", $TN++,"]\n";
}

my %ft = ars_GetFieldTable($ctrl, "ARSperl Test");

if (%ft) {
	print "ok [", $TN++, "]\n";
} else {
	print "not ok [", $TN++, "]\n";
	while($TN <= $NT) {
		print "not ok [", $TN++, "]\n";
	}
	exit(0);
}

#print join("\n", keys %ft), "\n";

# add a record

my @vals;
my @intFids;
foreach my $fn (keys %ft) {
	next if $fn !~ /^Integer/;
	push @vals, $ft{$fn};
	push @vals, $ft{$fn};
	push @intFids, $ft{$fn};
}

my $rv = ars_CreateEntry($ctrl, "ARSperl Test", 
	$ft{'Submitter'}, 'jcmurphy',
	$ft{'Status'}, 1,
	$ft{'Short Description'}, 'short desc',
	@vals);

if (!defined($rv)) {
	print "not ok [", $TN++, "]\n";
	while($TN <= $NT) {
		print "not ok [", $TN++, "]\n";
	}
	exit(0);
}
print "ok [", $TN++, "]\n";


# retrieve the record (all values)

my %recvals = ars_GetEntry($ctrl, "ARSperl Test",
	$rv);

if (! %recvals) {
	print "not ok [", $TN++, "] ($ars_errstr)\n";
} else {
	my @foo = keys %recvals;
	print "ok [", $TN++, "] (got ", $#foo, " values)\n";
}


# retrieve the record (only the integer fields)

for (my $loop = 0 ; $loop < $GETLOOPS ; $loop++) {
	my %intvals = ars_GetEntry($ctrl, "ARSperl Test",
				   $rv, @intFids);

	if (!%recvals) {
		print "not ok [", $TN++, "] ($ars_errstr)\n";
	} else {
		my @foo = keys %intvals;
		if($#foo == $#intFids) {
			print "ok [", $TN++, "] (got $#foo values)\n";
		} else {
			print "not ok [", $TN++, "] (got $#foo values, expected $#intFids)\n";
		}
	}
}



exit 0;

