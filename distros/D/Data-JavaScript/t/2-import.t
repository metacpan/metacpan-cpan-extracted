BEGIN { $| = 1; print "1..3\n"; }

#Test imports

{
  package Fred;
  use Data::JavaScript qw(:all);
    
  $_ = eval{ __quotemeta("Hello World\n") };
  print 'not ' unless $_ eq 'Hello World\n';
  print "ok 1 #$_\n";
}

{
  package Barney;
  use Data::JavaScript qw(jsdump);
  
  $_ = eval{ __quotemeta("Hello World\n") } || '';
  print 'not ' if $_ eq 'Hello World\n';
  print "ok 2 #$_\n";

  $_ = join('', jsdump('narf', 'Troz!'));
  print 'not ' unless $_ eq 'var narf = "Troz!";';
  print "ok 3 #$_\n";
}
