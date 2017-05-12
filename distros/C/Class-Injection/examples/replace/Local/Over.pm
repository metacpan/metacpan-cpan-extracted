package Local::Over;


use Class::Injection qw/Local::Target/;



sub test {
  my $this=shift;

  print "this is the new method\n";
  
}



1;