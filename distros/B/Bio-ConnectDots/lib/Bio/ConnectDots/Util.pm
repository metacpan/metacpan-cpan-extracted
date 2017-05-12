package Bio::ConnectDots::Util;

# Utility functions for ConnectDots

use Exporter();
use Scalar::Util qw(blessed);
@ISA=qw(Exporter);
@EXPORT=qw(&blessed 
	   &joindef &value_as_string &is_number &is_alpha 
	   &min &max &minmax &mina &maxa &minmaxa &minb &maxb &minmaxb
	   &avg &mean &sum &eq_list &uniq);

sub joindef {
  my $join=shift @_;
  join($join,grep {defined $_} @_);
}

sub value_as_string {
  my($value)=@_;
  my $result;
  if (!ref $value) {
    $result=$value;
  } elsif ('ARRAY' eq ref $value) {
    $result='['.join(', ',map {value_as_string($_)} @$value).']';
  } else {
    my @result;
    while(my($key,$val)=each %$value) {
      push(@result,"$key=>".value_as_string($val));
    }
    $result='{'.join(', ',@result).'}';
  }
  $result;
}

# pattern copied from Regexp::Common by Damian Conway
# change to looks_like_number from Scalar::Util
my $pattern='(?:(?:[+-]?)(?:\d+))|(?:(?i)(?:[+-]?)(?:(?=[0123456789]|[.])(?:[0123456789]*)(?:(?:[.])(?:[0123456789]{0,}))?)(?:(?:[E])(?:(?:[+-]?)(?:[0123456789]+))|))';
sub is_number {
  my($value)=@_;
  return $value=~/$pattern/;
}
sub is_alpha {
  my($value)=@_;
  return $value!~/$pattern/;
}

# can change these to use List::Util
# the following do numeric comparisons
sub min {
  if ($#_==0) {@_=@{$_[0]} if 'ARRAY' eq ref $_[0];}
  @_=grep {defined $_} @_; 
  return undef unless @_;
  if ($#_==1) {my($x,$y)=@_; return ($x<=$y?$x:$y);}
  my $min=shift @_;
  map {$min=$_ if $_<$min} @_;
  $min;
}
sub max {
  if ($#_==0) {@_=@{$_[0]} if 'ARRAY' eq ref $_[0];}
  return undef unless @_;
  if ($#_==1) {my($x,$y)=@_; return ($x>=$y?$x:$y);}
  my $max=shift @_;
  map {$max=$_ if $_>$max} @_;
  $max;
}
sub minmax {
  if ($#_==0) {@_=@{$_[0]} if 'ARRAY' eq ref $_[0];}
  return undef unless @_;
  if ($#_==1) {my($x,$y)=@_; return ($x<=$y?($x,$y):($y,$x));}
  my $min=shift @_;
  my $max=$min;
  map {if ($_<$min) {$min=$_;} elsif ($_>$max) {$max=$_;}} @_;
  ($min,$max);
}
# the following use alpha comparisons
sub mina {
  if ($#_==0) {@_=@{$_[0]} if 'ARRAY' eq ref $_[0];}
  @_=grep {defined $_} @_; 
  return undef unless @_;
  if ($#_==1) {my($x,$y)=@_; return ($x le $y?$x:$y);}
  my $min=shift @_;
  map {$min=$_ if $_ lt $min} @_;
  $min;
}
sub maxa {
  if ($#_==0) {@_=@{$_[0]} if 'ARRAY' eq ref $_[0];}
  return undef unless @_;
  if ($#_==1) {my($x,$y)=@_; return ($x ge $y?$x:$y);}
  my $max=shift @_;
  map {$max=$_ if $_ gt $max} @_;
  $max;
}
sub minmaxa {
  if ($#_==0) {@_=@{$_[0]} if 'ARRAY' eq ref $_[0];}
  return undef unless @_;
  if ($#_==1) {my($x,$y)=@_; return ($x le $y?($x,$y):($y,$x));}
  my $min=shift @_;
  my $max=$min;
  map {if ($_ lt $min) {$min=$_;} elsif ($_ gt $max) {$max=$_;}} @_;
  ($min,$max);
}
# the following use numeric or alpha comparisons as appropriate
sub maxb {
  if ($#_==0) {@_=@{$_[0]} if 'ARRAY' eq ref $_[0];}
  return maxa(@_) if grep {is_alpha($_)} @_;
  return max(@_);
}
sub minb {
  if ($#_==0) {@_=@{$_[0]} if 'ARRAY' eq ref $_[0];}
  return mina(@_) if grep {is_alpha($_)} @_;
  return min(@_);
}
sub minmaxb {
  if ($#_==0) {@_=@{$_[0]} if 'ARRAY' eq ref $_[0];}
  return minmaxa(@_) if grep {is_alpha($_)} @_;
  return minmax(@_);
}

sub avg {
  if ($#_==0) {@_=@{$_[0]} if 'ARRAY' eq ref $_[0];}
  return undef unless @_;
  if ($#_==1) {my($x,$y)=@_; return ($x+$y)/2;}
  my $sum;
  map {$sum+=$_} @_;
  $sum/(@_+0);
}
sub mean {avg @_;}

sub sum {
  if ($#_==0) {@_=@{$_[0]} if 'ARRAY' eq ref $_[0];}
  return undef unless @_;
  if ($#_==1) {my($x,$y)=@_; return $x+$y;}
  my $sum;
  map {$sum+=$_} @_;
  $sum;
}

# test equality of two lists
sub eq_list {
  my($a,$b)=@_;
  return undef unless 'ARRAY' eq ref $a && 'ARRAY' eq ref $b;  
  return undef unless @$a==@$b;
  for(my $i=0;$i<@$a;$i++) {
    return undef unless $a->[$i] eq $b->[$i];
  }
  return 1;
}

# uniquify a list, ie, eliminate duplicates)
sub uniq {
  my %hash;
  my $output=[];
  if ('ARRAY' eq ref $_[0]) {
    my($input)=@_;
    @hash{@$input}=@$input;
  }
  else {
    @hash{@_}=@_;
  }
  @$output=values(%hash);
  wantarray? @$output: $output;
}


1;
