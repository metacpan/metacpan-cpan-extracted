#!./perl

use ARS;
require './t/config.cache';

my $NT = 7;
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
	print "ok [", $TN++,"] login\n";
}

# submit some records into "ARSperl Test2"

my %ft = ars_GetFieldTable($ctrl, "ARSperl Test2");

if (%ft) {
	print "ok [", $TN++, "] GFT\n";
} else {
	print "not ok [", $TN++, "]\n";
	while($TN <= $NT) {
		print "not ok [", $TN++, "]\n";
	}
	exit(0);
}

#print join("\n", keys %ft), "\n";

# add a record

my $ok = 0;
for (my $loop = 0 ; $loop < 5 ; $loop++) {
	my $rv = ars_CreateEntry($ctrl, "ARSperl Test2", 
				 $ft{'Submitter-AT2'}, 'jcmurphy',
				 $ft{'Status-AT2'}, 1,
				 $ft{'SD-AT2'}, 'short desc'
				 );
	$ok++ if defined $rv;
}

if ($ok != 5) {
	print "not ok [", $TN++, "]\n";
	while($TN <= $NT) {
		print "not ok [", $TN++, "] ($ars_errstr)\n";
	}
	exit(0);
}
print "ok [", $TN++, "] CE\n";


# get the fields from the join form

my %jft = ars_GetFieldTable($ctrl, "ARSperl Test-join");

if( %jft ) {
	print "ok [", $TN++, "] GFT\n";
} else {
	print "not ok [", $TN++, "]\n";
	while($TN <= $NT) {
		print "not ok [", $TN++, "] ($ars_errstr)\n";
	}
	exit(0);
}

# fetch a list of records

my $q = ars_LoadQualifier($ctrl, "ARSperl Test-join", "(1 = 1)");

if(defined($q)) {
	print "ok [", $TN++, "] LQ\n";
} else {
	print "not ok [", $TN++, "]\n";
	while($TN <= $NT) {
		print "not ok [", $TN++, "] ($ars_errstr)\n";
	}
	exit(0);
}


my @matches = ars_GetListEntry($ctrl, "ARSperl Test-join", $q, 0, 0);

if ($#matches != -1) {
	print "ok [", $TN++, "] GLE (got $#matches matches)\n";
} else {
	print "not ok [", $TN++, "] ($ars_errstr)\n";
	while($TN <= $NT) {
		print "not ok [", $TN++, "]\n";
	}
	exit(0);
}

print join("\n", @matches), "\n";

# do alot of GetFields on the Join

$ok = 1;
foreach my $fn (keys %jft) {
	my $fh1 = ars_GetField($ctrl, "ARSperl Test-join", $jft{$fn});
	$ok = 0 if (!defined($fh1));
}

if($ok) {
	print "ok [", $TN++, "] GF\n";
} else {
	print "not ok [", $TN++, "] GF\n";
}

exit 0;

