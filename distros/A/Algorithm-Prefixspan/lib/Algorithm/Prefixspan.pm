package Algorithm::Prefixspan;
use 5.008001;
use strict;
use warnings;

use Moo;
use MooX::Types::MooseLike::Base qw( ArrayRef HashRef Num Int Str );
use namespace::clean;
use Carp;

our $VERSION = "0.04";

has data => (
    is       => 'rw',
    isa      => ArrayRef,
    required => 1,
);

has out => (
    is       => 'rw',
    isa      => HashRef,
);

has minsup => (
    is      => 'rw',
    isa     => Int,
    default => sub { 2 },
);

has len => (
    is      => 'rw',
    isa     => Int,
    default => sub { 1 },
);

sub run {
  my $self = shift;

  $self->prefixspan("", $self->{data});

  return $self->{out};
}


sub prefixspan {
  my $self = shift; 
  my $prefix = shift;
  my $seq = shift;

  if (ref $seq eq "ARRAY") {
    my $pattern = $self->extract($self->{minsup}, $seq);
    if (ref $pattern eq "HASH") {
      
      foreach my $i (keys %{$pattern}) {
        my $p = $i;
        if ($prefix ne "") {
          $p = join " ", ($prefix, $i);
        }
        my $count = (() = $p =~ /\s+/g);
        if ($count >= $self->{len} - 1) {
          $self->{out}{"$p"} = $pattern->{$i};
        }   
        my $j = $self->projection($seq, $i);
        $self->prefixspan($p, $j);
      } 
    } 
  } 
}

sub extract {
  my $self = shift;
  my $minsup = shift;
  my $seq = shift;
  my $h;

  for (my $i = 0; $i < @$seq; $i++) {
    my @dist = split /\s+/, $seq->[$i];
    map {$h->{$_}++} @dist;
  } 
  foreach my $i (keys %{$h}) {
    if ($h->{$i} < $minsup) {
      delete $h->{$i};
    } 
  } 

  return $h;
}

sub projection {
  my $self = shift;
  my $seq = shift;
  my $b = shift;
  my $h;

  foreach my $i (@{$seq}) {
    my @list = split /\s+/, $i;
    for (my $j = 0; $j < @list; $j++) {
      if ($list[$j] eq $b) {
        splice @list, 0, ($j +1);
        if (@list > 0) {
          push @{$h}, join " ", @list;
        }
      }
    }
  }

  return $h;
}


1;
__END__

=encoding utf-8

=head1 NAME

Algorithm::Prefixspan - Perl implementation for the algorithm PrefixSpan (Prefix-projected Sequential Pattern mining).

=head1 SYNOPSIS

    use Algorithm::Prefixspan;
    my $data = [
                "a c d",
                "a b c",
                "c b a",
                "a a b",
               ];
    
    my $prefixspan = Algorithm::Prefixspan->new(
                                 data => $data,
                                );
    
    my $pattern = $prefixspan->run; 
    # $pattern got as follow.   
    # {
    #           'c' => 3,
    #           'a c' => 2,
    #           'a' => 5,
    #           'b' => 3,
    #           'a b' => 2
    # };

    options:
    # set minimum support (default: 2)
    $prefixspan->{'minsup'} = 2
    
    # set minimum pattern length (default: 1)
    $prefixspan->{'len'} = 1


=head1 DESCRIPTION

Algorithm::Prefixspan is pure perl implementation
for the algorithm PrefixSpan (Prefix-projected Sequential Pattern mining) 
by designed Pei et al.

This module is not fast.

Reference

* PrefixSpan: Mining Sequential Patterns Efficiently by Prefix-Projected Pattern Growth Jian Pei, Jiawei Han, Behzad Mortazavi-asl, Helen Pinto, Qiming Chen, Umeshwar Dayal and Mei-chun Hsu IEEE Computer Society, 2001, pages 215.


=head1 LICENSE

Copyright (C) Yukio HORI.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yukio HORI E<lt>horiyuki@cpan.orgE<gt>

=cut

