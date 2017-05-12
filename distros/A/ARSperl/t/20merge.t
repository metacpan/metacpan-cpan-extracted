#!./perl
use ARS;
require './t/config.cache';

my $maxtest = 5;

print "1..$maxtest\n";

my $c = ars_Login(&CCACHE::SERVER, 
		  &CCACHE::USERNAME, 
		  &CCACHE::PASSWORD, "","", &CCACHE::TCPPORT);

if(!defined($c)) {
	for(my $i = 1 ; $i <= $maxtest ; $i++) {
		print "not ok [$i] [ctrl]\n";
	}
	exit 0;
} else {
	print "ok [1]\n";
}

my %fids = ars_GetFieldTable($c, "ARSperl Test");

if(!(%fids)) {
	for(my $i = 2 ; $i <= $maxtest ; $i++) {
		print "not ok [$i] [gft]\n";
	}
	exit 0;
} else {
	print "ok [2]\n";
}


# There are three conditions to detect after ars__MergeEntry(...). 
# 1. A non-null value returned means that a new entry was created. 
# 2. A null value returned, plus $ars_errstr empty, means that an existing
#   entry was replaced. 
# 3. A null value returned, plus $ars_errstr non-empty, means there was some
#   error.


# merge in a new entry. we should get an entry-id back


my $eid = ars_MergeEntry($c, "ARSperl Test", 2, 
			 $fids{'Submitter'}, 'jcmurphy',
			 $fids{'Short Description'}, 'foobar',
			 $fids{'Status'}, 0);

if(!defined($eid)) {
	print "not ok [3] [$ars_errstr]\n";
} else {
	print "ok [3]\n";
}

# replace the entry with something new. we should get the 
# same entry-id back

my $eid2 = ars_MergeEntry($c, "ARSperl Test", 
			  &ARS::AR_MERGE_ENTRY_DUP_MERGE, 
			  1, $eid,
			  $fids{'Submitter'}, 'jcm',
			  $fids{'Short Description'}, 'foobar2',
			  $fids{'Status'}, 1);

if(!defined($eid2)) {
	print "not ok [4] ndef eid  [$ars_errstr]\n";
} 
elsif($eid2 eq "") {
	# currently, 
	# if $ars_errstr contains any errors, and $eid2
	# is "", then something is awry.
	if($ARS::ars_errhash{numItems} > 0) {
		for(my $i = 0 ; $i < $ARS::ars_errhash{numItems} ; $i++) {
			if(@{$ARS::ars_errhash{'messageType'}}[$i] >= 
			   &ARS::AR_RETURN_ERROR) {
				print "not ok [4]\n";
			}
		}
	}
} 

print "ok [4]\n";


# now do it again, but via the OO layer

my $ooc = new ARS(-ctrl  => $c,
		  -catch => { ARS::AR_RETURN_ERROR => undef,
			      ARS::AR_RETURN_WARNING => undef,
			      ARS::AR_RETURN_FATAL => undef
			    },
		  -debug => undef
		 );


my $oof = $ooc->openForm(-form => 'ARSperl Test');

$eid2 = $oof->merge(-type => &ARS::AR_MERGE_ENTRY_DUP_MERGE, 
		    -values => {
				'Request ID' => $eid, 
				'Submitter' => 'xyz',
				'Short Description' => 'oo-foobar',
				'Status' => 'Rejected'
				}
		    );

# since we disabled exception handling (in the 'new' above)
# we can test $eid2 

if($eid2 eq $eid) {
	print "ok [5]\n";
} else {
	# if $eid2 is "", then the op failed completely
	# if $eid2 ne $eid, then the op succeeded, but 
	#    created a new entry - which shouldnt happen
	#    since we specified DUP_MERGE _unless_ you
	#    forgot to specify an entry-id in your values 
	#    hash
	print "not ok [5] (eid2=$eid2 ; eid=$eid ; err=$ars_errstr)\n";
}

ars_DeleteEntry($c, "ARSperl Test", $eid);
ars_Logoff($c);

exit 0;
