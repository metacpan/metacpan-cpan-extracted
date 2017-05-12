#!/usr/bin/env perl
# created on 2013-11-18

use warnings;
use strict;
use 5.010;

use Bio::Gonzales::Matrix::IO;
use Pod::Usage;
use Getopt::Long qw(:config auto_help);

my %opt = (sep => "\t");
GetOptions( \%opt, 'sep=s','h', 'c=i@' ) or pod2usage(2);

$opt{c} //= [0,1];
say STDERR "using columns: " . join ", ", @{$opt{c}};
my $f = shift;

$f = \*STDIN if($f eq '-');

my $mit = miterate($f, { sep => $opt{sep}});
  $mit->() if($opt{h});

my %n;

while(my $e = $mit->()) {
  for my $c ( @{ $opt{c} } ) {
    $n{ $e->[$c] }++;
  }
}

say join "\n", keys %n;
