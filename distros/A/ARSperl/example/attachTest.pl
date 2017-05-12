#!/oratest/perl/bin/perl

use ARS;

$c = ars_Login(shift, shift, shift);
%f = ars_GetFieldTable($c, "ARSperl Test");
foreach (keys %f) {
  $r{$f{$_}} = $_;
}

print "Creating new entry with an attachment..\n";

($id = ars_CreateEntry($c, "ARSperl Test", 
		$f{'Attachment Field'}, { file => "/tmp/test", size => 0 },
		#$f{'Attachment Field'}, { buffer => "/tmp/test", size => 9 },
		$f{'Submitter'}, "jeff",
		$f{'Status'}, 1,
		$f{'Short Description'}, "none")) || 
  die "CreateEntry: $ars_errstr";

print "Created entry $id\n";

print "Fetching the entry we just made..\n";

%v = ars_GetEntry($c, "ARSperl Test", $id);
foreach (keys %v) {
  print "$r{$_} = $v{$_}\n";
  dh($v{$_}) if $r{$_} eq "Attachment Field";
  ra($_) if $r{$_} eq "Attachment Field";
}

ars_Logoff($c);

exit 0;

#sub AR_LOC_FILENAME { 1;}
#sub AR_LOC_BUFFER { 2;}

sub ra {
  my $fid = shift;

  print "\t[Retrieving attachment.]\n";

  
  # file: $a = 0 || 1
  # buff: $a = undef || attachment


  ars_GetEntryBLOB($c, "ARSperl Test", $id,
		   $fid, 
		   ARS::AR_LOC_FILENAME,
		   "/tmp/attachtest") || 
		     die ("GetEntryBLOB: $ars_errstr");

  my $a = ars_GetEntryBLOB($c, "ARSperl Test", $id,,
			   $fid, 
			   ARS::AR_LOC_BUFFER);

  die "GetEntryBLOB: $ars_errstr" if(!defined($a));
  print "\tattachment size = ".length($a)."\n";
  open(FD, ">/tmp/attachtest2") || die "open: $!";
  print FD $a;
  close(FD);
}

sub dh {
  my $h = shift;
  foreach (keys %$h) {
    print "\t$_ = $h->{$_}\n";
  }
}
