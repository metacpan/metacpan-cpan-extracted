#!/usr/bin/env perl

use warnings;
use strict;
use 5.010;

use Bio::Gonzales::Range::GroupedOverlap;
use Data::Dumper;

use Bio::Gonzales::Util::Cerial;

use Pod::Usage;
use Getopt::Long;

my %opt;
GetOptions( \%opt, 'acols=s', 'bcols=s') or pod2usage(2);

my ( $a_f, $b_f ) = @ARGV;
pod2usage("$a_f is no file") unless ( -f $a_f );
pod2usage("$b_f is no file") unless ( -f $b_f );



# g = grp, b=begin, e=end
my ($ag_idx, $ab_idx, $ae_idx, $aid_idx) = split /,/, $opt{a_cols};
my ($bg_idx, $bb_idx, $be_idx, $bid_idx) = split /,/, $opt{b_cols};

my @ranges;

my $a_fh = openod($a_f, '<');
while(<$a_fh>) {
  my ($ag, $ab, $ae, $aid) = (split /\t/)[$ag_idx, $ab_idx, $ae_idx, $aid_idx];
  ($ab, $ae) = ($ae, $ab) if ($ab > $ae);
  push @ranges, [$ag, $ab, $ae, $aid_idx];
}
$a_fh->close;

my $go = Bio::Gonzales::Range::GroupedOverlap->new(ranges => \@ranges);

my $b_fh = openod($b_f, '<');
while(<$b_fh>) {
  my ($bg, $bb, $be) = (split /\t/)[$bg_idx, $bb_idx, $be_idx];
  ($bb, $be) = ($be, $bb) if ($bb > $be);

  my $z = $go->overlaps_with( $bg, $bb, $be);
  die Dumper $z;
}
$b_fh->close;
