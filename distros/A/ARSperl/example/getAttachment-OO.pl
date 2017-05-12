#!/oratest/perl/bin/perl

use ARS;

$c = new ARS(shift, shift, shift);
$s = $c->openForm("ARSperl Test");
%v = $s->getAsHash(-entry => "000000000000002");

print "field/value dump:\n";

foreach (keys %v) {
  print "$_ = $v{$_}\n";
  dh($v{$_}) if $s->getFieldType(-field => $_) eq "attach";
  ra($_) if $s->getFieldType(-field => $_) eq "attach";
}

exit 0;

sub ra {
  my $field = shift;

  print "\t[Retrieving attachment.]\n";

  # file: $a = 0 || 1
  # buff: $a = undef || attachment

  $s->getAttachment(-entry => "000000000000002",
		    -field => $field,
		    -file  => "/tmp/attachtest");

  my $a = $s->getAttachment(-entry => "000000000000002",
			    -field => $field);

  print "\tattachment size = ".length($a)."\n";
  open(FD, ">/tmp/attachtest2") || die "open: $!";
  print FD $a;
  close(FD);

  # if you "cmp" the files, they should be identical.
}

sub dh {
  my $h = shift;
  foreach (keys %$h) {
    print "\t$_ = $h->{$_}\n";
  }
}
