package Local::Over;


use Class::Injection qw/Local::Target add/;



sub test {
  my $this=shift;

  print "this is the new method\n";
  
}



1;