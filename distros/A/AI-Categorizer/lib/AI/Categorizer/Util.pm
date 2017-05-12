package AI::Categorizer::Util;

use Exporter;
use base qw(Exporter);
@EXPORT_OK = qw(intersection average max min random_elements binary_search);

use strict;

# It's possible that this can be a class - something like 
# 
# $e = Evaluate->new(); $e->correct([...]); $e->assigned([...]); print $e->precision;

# A simple binary search
sub binary_search {
  my ($arr, $target) = @_;
  my ($low, $high) = (0, scalar @$arr);
  use integer;
  while ( $low < $high ) {
    my $cur = ($low + $high)/2;
    if ( $arr->[$cur] < $target ) {
      $low = $cur + 1;
    } else {
      $high = $cur;
    }
  }
  return $low;
}

sub max {
  return undef unless @_;
  my $max = shift;
  foreach (@_) {
    $max = $_ if $_ > $max;
  }
  return $max;
}

sub min {
  return undef unless @_;
  my $min = shift;
  foreach (@_) {
    $min = $_ if $_ > $min;
  }
  return $min;
}

sub average {
  return undef unless @_;
  my $total;
  $total += $_ foreach @_;
  return $total/@_;
}

sub intersection {
  my ($one, $two) = @_;
  $two = _hashify($two);

  return UNIVERSAL::isa($one, 'HASH') ?	# Accept hash or array for $one
    grep {exists $two->{$_}} keys %$one :
    grep {exists $two->{$_}} @$one;
}

sub _hashify {
  return $_[0] if UNIVERSAL::isa($_[0], 'HASH');
  return {map {$_=>1} @{$_[0]}};
}

sub random_elements {
  my ($a_ref, $n) = @_;
  return @$a_ref if $n >= @$a_ref;
  
  my ($select, $mode) = ($n < @$a_ref/2) ? ($n, 'include') : (@$a_ref - $n, 'exclude');

  my %i;
  $i{int rand @$a_ref} = 1 while keys(%i) < $select;

  return @{$a_ref}[keys %i] if $mode eq 'include';
  return map {$i{$_} ? () : $a_ref->[$_]} 0..$#$a_ref;
}

1;
