# t/sort_tests.pl -- utility routines for Data::Sorting test scripts.

# Inspiried by test.pl from Sort::Naturally by Sean M. Burke

sub shuffle {
  my @out;
  while(@_) { push @out, splice @_, rand(@_), 1 };
  return @out
}

sub arrays_match {
  my $array = shift;
  # warn "Checking: " . join( ', ', map "'$_'", @$array ) . "\n";
  CANDIDATE: foreach my $candidate (@_) {
    # warn "Against: " . join( ', ', map "'$_'", @$candidate ) . "\n";
    next CANDIDATE unless ( $#$array = $#$candidate );
    foreach my $idx ( 0 .. $#$array ) {
      next CANDIDATE unless ( $array->[$idx] eq $candidate->[$idx] 
    or $array->[$idx] != 0 and $array->[$idx] == $candidate->[$idx] );
    }
    # warn "Matched!";
    return 1;
  }
  # warn( "Didn't match!" );
  return
}

sub test_sort_cases {
  my @tests = @_;

  foreach my $test ( @tests ) {
    my @values = @{ $test->{values} };
    my @acceptable = (
      $test->{okvals} ? @{ $test->{okvals} } :
      $test->{okidxs} ? map({[ map $values[$_-1], @$_ ]} @{ $test->{okidxs} }) :
			$test->{values}
    );
    # warn "Values: " . join( ', ', map "'$_'", @values ) . "\n";
    # warn "Acceptable: " . join( ', ', map "'$_'", @acceptable ) . "\n";
  
    my @params = @{ $test->{sorted} };
    # warn "Sorting: " . join(', ', Data::Sorting::sort_description('text', @params) ) . "\n";
    my $sort_function = Data::Sorting::sort_function( @params );
    
    unless ( arrays_match( [ $sort_function->( @values ) ], \@values ) ) {
      ok( 0, "not stable" );
      next;
    };
    
    my @rc;    
    foreach ( 1 .. 10 ) {
      my @shuffled = shuffle( @values );
      # warn "Shuffled: " . join( ', ', map "'$_'", @shuffled ) . "\n";
      
      my @sorted = $sort_function->( @shuffled );
      # warn "Sorted: " . join( ', ', map "'$_'", @sorted ) . "\n";
  
      # warn "Match: " . join( ', ', map "'$_'", \@sorted, @acceptable ) . "\n";
      push @rc, arrays_match( \@sorted, @acceptable );
    }
    ok( ! grep { ! $_ } @rc, "not repeatable" );
  }
}

1;
