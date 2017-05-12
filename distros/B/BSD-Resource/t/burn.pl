#
# burn.pl
#

# Burn some user and system time.

sub fac { $_[0] < 2 ? 1 : $_[0] * fac($_[0] - 1) }

sub burn {
  my $s = 0;
  my $t0 = time();
  while (time() - $t0 < 3) {
    # Accumulate user time.
    for my $n (10..20) {
      $s += fac($n);
    }
  }
  my $t1 = time();
  # Accumulate system time.
  while (time() - $t1 < 3) {
    for (1..1E4) {
      $s += time() * $$;
    }
    for (1..1E3) {
      mkdir "x", 0777;
      open FH, ">x/y";
      print FH "$s\n";
      close FH;
      opendir DH, "x";
      readdir DH;
      closedir DH;
      unlink "x/y";
      rmdir "x";
    }
  }
}

1;
