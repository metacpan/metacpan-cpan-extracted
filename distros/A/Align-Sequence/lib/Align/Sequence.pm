package Align::Sequence;

use strict;
use 5.010_001;
our $VERSION = '0.01';

sub new {
  my $class = shift;
  # uncoverable condition false
  bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
}

sub align {
  my ($self, $X, $Y) = @_;
  
  my $YPos;
  my $index;
  push @{ $YPos->{$_} },$index++ for @$Y;
  
  my $Xmatches;
  @$Xmatches = grep { exists( $YPos->{$X->[$_]} ) } 0..$#$X;
  
  my $Xcurrent = -1;
  my $Ycurrent = -1;
  my $Xtemp;
  my $Ytemp;
  
  my @L; # LCS
  my $R = 0;  # records the position of last selected symbol
  my $i;
  
  my $Pi;
  my $Pi1;
  
  my $hunk;
   
  for ($i = 0; $i <= $#$Xmatches; $i++) {
    $hunk = [];
    $Pi  =  $YPos->{$X->[$Xmatches->[$i]]}->[0] // $#$Y+1; # Position in Y of ith symbol
    $Pi1 =  ($i < $#$Xmatches && defined $YPos->{$X->[$Xmatches->[$i+1]]}->[0]) 
  	  ? $YPos->{$X->[$Xmatches->[$i+1]]}->[0] : -1; # Position in Y of i+1st symbol
    #print STDERR '$i: ',$i,' $Pi: ',$Pi,' $Pi1: ',$Pi1,' $R: ',$R,"\n";
    while ($Pi1 < $R && $Pi1 > -1) { 
      #print STDERR '$Pi1 < $R',"\n";
      shift @{$YPos->{$X->[$Xmatches->[$i+1]]}};
      $Pi1 = $YPos->{$X->[$Xmatches->[$i+1]]}->[0] // -1;
    }
    while ($Pi < $R && $Pi < $#$Y+1) {
      #print STDERR '$Pi < $R',"\n";
      shift @{$YPos->{$X->[$Xmatches->[$i]]}};
      $Pi =  $YPos->{$X->[$Xmatches->[$i]]}->[0] // $#$Y+1;
    }
    if ($Pi > $Pi1 && $Pi1 > $R) {
      $hunk = [$Xmatches->[$i+1],$Pi1];
      shift @{$YPos->{$X->[$Xmatches->[$i+1]]}};
      $R = $Pi1;
      $i = $i+1;
    } 
    elsif ($Pi <  $#$Y+1) {
      $hunk = [$Xmatches->[$i],$Pi];
      shift @{$YPos->{$X->[$Xmatches->[$i]]}}; 
      $R = $Pi;
    }

    if (scalar @$hunk) { 
      while ($Xcurrent+1 < $hunk->[0] ||  $Ycurrent+1 < $hunk->[1] ) {
        $Xtemp = '';
        $Ytemp = '';
        if ($Xcurrent+1 < $hunk->[0]) {
          $Xcurrent++;
          $Xtemp = $X->[$Xcurrent];
        }
        if ($Ycurrent+1 < $hunk->[1]) {
          $Ycurrent++;
          $Ytemp = $Y->[$Ycurrent];
        }
        push @L,[$Xtemp,$Ytemp];
      }
      $Xcurrent = $hunk->[0];
      $Ycurrent = $hunk->[1];
      #push @L,$hunk; # indices
      push @L,[$X->[$Xcurrent],$Y->[$Ycurrent]]; # elements
    }
  }
  while ($Xcurrent+1 <= $#$X ||  $Ycurrent+1 <= $#$Y ) {
    $Xtemp = '';
    $Ytemp = '';
    if ($Xcurrent+1 <= $#$X) {
      $Xcurrent++;
      $Xtemp = $X->[$Xcurrent];
    }
    if ($Ycurrent+1 <= $#$Y) {
      $Ycurrent++;
      $Ytemp = $Y->[$Ycurrent];
    }
    push @L,[$Xtemp,$Ytemp];
  }  
  return \@L;
}

sub hunks2sequences {
  my $self = shift;
  my $hunks = shift;
  
  my $gap = '';

  my $a = [];
  my $b = [];
  
  for my $hunk (@$hunks) {
     push @$a, $hunk->[0];
     push @$b, $hunk->[1];
  }
  return ($a,$b); 
}


1;
__END__

=encoding utf-8

=head1 NAME

Align::Sequence - Align two sequences

=head1 SYNOPSIS

  use Align::Sequence;

=head1 DESCRIPTION

Align::Sequence is an implementation based on a LCS algorithm.

=head1 AUTHOR

Helmut Wollmersdorfer E<lt>helmut.wollmersdorfer@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2014- Helmut Wollmersdorfer

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
