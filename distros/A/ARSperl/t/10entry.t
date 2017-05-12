#!./perl

# 
# test out creating and deleting an entry
#

use ARS;
require './t/config.cache';

# notice the use of a custom error handler.

sub mycatch {
  my ($type, $msg) = (shift, shift);
  die "not ok ($msg)\n";
}

if(ars_APIVersion() >= 4) {
  print "1..10\n";
} else {
  print "1..7\n";
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
print "ok [1 cnx]\n";

my $s  = $c->openForm(-form => "ARSperl Test");
print "ok [2 openform]\n";

# test 1:  create an entry

my $id = $s->create("-values" => { 'Submitter' => &CCACHE::USERNAME,
				 'Status' => 'Assigned',
				 'Short Description' => 'A test submission',
				   'Diary Field' => 'A diary entry'
			       }
		   );
print "ok [3 create]\n";

# test 2: retrieve the entry to see if it really worked

my($v_status,
   $v_diary) = $s->get(-entry => $id, -field => [ 'Status', 'Diary Field' ] );

# status should be "Assigned" and the diary should contain
# the expected text, with user=ourusername
#use Data::Dumper;
#print "vd ", Dumper($v_diary), "\n";

if( ($v_status ne "Assigned") || 
    ($v_diary->[0]->{'value'} ne "A diary entry") ||
    ($v_diary->[0]->{'user'} ne &CCACHE::USERNAME) ) {
  print "not ok [4 $v]\n";
} else {
  print "ok [4 get]\n";
}

# test 3: set the entry to something different

$s->set(-entry => $id, -values => { 'Status' => 'Rejected' });
print "ok [5 set]\n";

# test 4: retrieve the value and check it

$v = $s->get(-entry => $id, -field => [ 'Status' ] );
if($v ne "Rejected") {
  print "not ok [6 $v]\n";
} else {
  print "ok [6 get]\n";
}

# test 6: add an attachment to the existing entry

if(ars_APIVersion() >= 4) {
  my $filename = "t/aptest40.def";

  $s->set(-entry => $id, 
	  "-values" => { 'Attachment Field' => 
		       { file => $filename,
		         size => (stat($filename))[7]
		       }
		     }
	 );

  # retrieve it "in core" 

  my $ic = $s->getAttachment(-entry => $id,
			     -field => 'Attachment Field');

  open(FD, $filename) || die "not ok [open $!]\n";
  binmode FD;
  my $fc;
  while(<FD>) {
    $fc .= $_;
  }
  close(FD);

  if($fc ne $ic) {
    print "not ok [attach (create) cmp] fc ", length($fc), " ic ", length($ic), "\n";
  } else {
    print "ok [attach (set) test ; fclen=", length($fc),
		" iclen=", length($ic), "]\n";
  }
}

# test 7: create a new entry with an attachment

if(ars_APIVersion() >= 4) {
  my $filename = "t/aptest40.def";

  my $nid = $s->create(
		       "-values" => { 'Attachment Field' => 
				      { file => $filename,
					size => (stat($filename))[7]
				      },
				      'Submitter' => &CCACHE::USERNAME,
				      'Status' => 'Assigned',
				      'Short Description' => 'attach-create'
				    }
		      );
  # retrieve it "in core" 

  my $ic = $s->getAttachment(-entry => $nid,
			     -field => 'Attachment Field');


  open(FD, $filename) || die "not ok [open $!]";
  binmode FD;
  my $fc;
  while(<FD>) {
    $fc .= $_;
  }
  close(FD);

  if($fc ne $ic) {
    print "not ok [attach (create) cmp]\n";
  } else {
    print "ok [attach (create) test ; fclen=", length($fc),
		" iclen=", length($ic), "]\n";
  }


  # retrieve it as a file

  my $ga_rv = $s->getAttachment(-entry => $nid,
				-field => 'Attachment Field',
				-file  => 'attach.txt');

  open(FD, 'attach.txt') || die "not ok [open $!]";
  binmode FD;
  my $fc2;
  while(<FD>) {
    $fc2 .= $_;
  }
  close(FD);

  if ($fc2 ne $ic) {
    print "not ok [get attach to file]\n";
  } else {
    print "ok [get attach to file]\n";
  }

  # cleanup
  unlink ('attach.txt');
  $s->delete(-entry => $nid);
}


# test 8: finally, delete the newly created entry

$s->delete(-entry => $id);
	   
print "ok [delete]\n";

exit 0;

