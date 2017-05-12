#!./perl

# 
# test out creating/retrieving lots of entries 
# to test for memory leaks. by default, we bypass this test
# because it takes a long time and the user needs to do
# extra work to watch process-size, etc.


use ARS;
require './t/config.cache';

# notice the use of a custom error handler.

sub mycatch {
  my ($type, $msg) = (shift, shift);
  die "not ok ($msg)\n";
}

print "1..5\n";

if( 1 ) { # BYPASS
	for(my $i = 1 ; $i < 6 ; $i++) {
		print "ok [$i]\n";
	}
	exit 0;
}

my $c = new ARS(-server => &CCACHE::SERVER, 
		-username => &CCACHE::USERNAME,
		-password => &CCACHE::PASSWORD,
		-tcpport  => &CCACHE::TCPPORT,
                -catch => { ARS::AR_RETURN_ERROR => "main::mycatch",
                            ARS::AR_RETURN_WARNING => "main::mycatch",
                            ARS::AR_RETURN_FATAL => "main::mycatch"
                          },
		-debug => undef);
print "ok [1]\n";

my $s  = $c->openForm(-form => "ARSperl Test");
print "ok [2]\n";

# test 1:  create many

my %eids;

for(my $loop = 0; $loop < 10000 ; $loop++) {
	my $id = $s->create("-values" => { 'Submitter' => &CCACHE::USERNAME,
				 'Status' => 'Assigned',
				 'Short Description' => $loop
			       }
		   );
	$eids{$id} = $loop;
$|=1;
print "$id  $loop         \r";
}

print "ok [3]\n";

# test 2: retrieve the entries 

foreach my $id (keys %eids) {
	my @v = $s->get(-entry => $id );
print "$id        \r";
}

print "ok [4]\n";

# test 5: finally, delete the newly created entry

foreach my $id (keys %eids) {
	$s->delete(-entry => $id);
}

print "ok [5]\n";

exit 0;

