#!/usr/bin/perl -w

package Data::Fallback::WholeFile;

use strict;

use Data::Fallback;
use vars qw(@ISA);
@ISA = qw(Data::Fallback);
use Carp qw(confess);

sub GET {
  my $self = shift;
  my $hash = shift;
  my $return = 0;
  if( (defined $self->{info}{WholeFile}{data}{$hash->{group}}) && length $self->{info}{WholeFile}{data}{$hash->{group}}) {
    if( (defined $self->{info}{WholeFile}{data}{$hash->{group}}{$hash->{item}}) && 
         length $self->{info}{WholeFile}{data}{$hash->{group}}{$hash->{item}}) {
          $hash->{item} = $self->{info}{WholeFile}{data}{$hash->{group}}{$hash->{item}};
          $return = 1;
    }
  } elsif(-e $hash->{group}) {
    my $text = Include($hash->{group});
    $self->{info}{WholeFile}{data}{$hash->{group}} = $text;
    $hash->{item} = $text;
    $return = 1;
  } else {
    # do nothing
  }

  return $return;
}

sub textToHash {
  my $text_ref = shift;
  my %hash = $$text_ref =~ /(.+?)\s+(.+)/g;
  return \%hash;
}

sub Include {
  my $filename = shift;
  open(FILE, $filename) || confess "couldn't open $filename: $!";
  my $txt = join("", <FILE>);
  close(FILE);
  return $txt;

}

1;
