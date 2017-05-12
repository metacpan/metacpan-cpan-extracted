package Data::VarPrint;

require 5.000;
require Exporter;
require AutoLoader;
use strict;
use vars qw(@ISA @EXPORT $VERSION);

@ISA = qw(Exporter AutoLoader);
@EXPORT = qw(&VarPrint &VarPrintAsString);

$VERSION = "1.01";  # $Date: 2002/08/15 2:08:15 $

sub VarPrint {
  print _VarPrintAsString(@_, ""), "\n";
}

sub VarPrintAsString {
  return _VarPrintAsString(@_, "")."\n";
}

sub _SimpleVarPrintAsString {
  my $var = shift;
  my $quot = (($var =~ /^[0-9]*(\.[0-9]*)?$/) && !($var =~ /^\.?$/) ? "" : "'");
  return $quot.$var.$quot;
}

sub _VarPrintAsString {
  my $result = "";
  my $spaces = pop;

#  return _VarPrintAsString(\@_, $spaces) if @_ > 1;

  my $value = shift;
  unless (defined $value) {
    return "undef";
  }

  if (@_ > 1 || ref($value) eq "ARRAY") {
    if (@_ > 1) {
      $result .= "(";
      $value = \@_;
    } else {
      $result .= "[";
    }
    my $separator = "";
    my $nl = ((grep { ref($_) =~ /^(HASH|ARRAY)$/ } @$value) == 0);
    unless ($nl) {
      $spaces .= "  ";
      $result .= "\n$spaces"
    };
    foreach my $item (@$value) {
      $result .= $separator._VarPrintAsString($item, $spaces);
      $separator = ",".($nl ? " " : "\n$spaces");
    }
    $spaces =~ s/  (.*)$/$1/;
    $result .= "\n$spaces" unless $nl;
    $result .= (@_ > 1 ? ")" : "]");
  } elsif (ref($value) eq "HASH") {
    if (keys %$value > 0) {
      $result .= "{\n";
      my $separator = "";
      foreach my $key (sort keys %$value) {
        $result .= $separator.$spaces."  "._SimpleVarPrintAsString($key)." => "._VarPrintAsString($value->{$key}, "$spaces  ");
        $separator = ",\n";
      }
      $result .= "\n$spaces}";
    } else {
      $result .= "{}";
    }
  } elsif (ref($value) eq "") {
    $result .= _SimpleVarPrintAsString($value);
  } elsif (ref($value) eq "SCALAR") {
    $result .= '\\'._SimpleVarPrintAsString($$value);
  } elsif (ref($value) eq "CODE") {
    $result .= "Subroutine";
  } else {
    $result .= "Object of class ".ref($value);
  }
  return $result;
}

1;

__END__

=head1 NAME

VarPrint - display complex variables on STDOUT

=head1 SYNOPSIS

  use Data::VarPrint;
  VarPrint($var1, $var2,... );

or

  use Data::VarPrint;
  VarPrint( { var1 => $var1, var2 => $var2,... } );

or

  use Data::VarPrint;
  my $var_string = VarPrintAsString(...);

=head1 DESCRIPTION

B<Data::VarPrint> module contains two functions: B<VarPrint> and B<VarPrintAsString>.

Function B<VarPrint> displays its I<arguments'> values. The output is structured, so
that complex structures (combinations of hash and array references) are presented in a
way which makes them easy to read.

Function B<VarPrintAsString> returns the same output as a string, which can be usefull 
with error logs.

=head1 OPTIONS

B<VarPrint> and B<VarPrintAsString> take list of variables as arguments.

=head1 AUTHOR

Copyright (c) 2002 V. Sego, vsego@math.hr. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
