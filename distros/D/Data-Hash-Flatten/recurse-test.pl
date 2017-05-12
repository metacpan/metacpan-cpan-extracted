sub r {
  my $x = shift;

  warn "in $x";

  r(++$x) unless $x > 5;
  
  warn "depth on way back: $x";
}

r(2);
