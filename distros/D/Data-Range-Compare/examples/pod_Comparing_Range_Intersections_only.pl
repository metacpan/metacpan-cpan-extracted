#!/usr/bin/perl

use lib qw(..lib .);
use Data::Range::Compare qw(HELPER_CB);
use strict;
use warnings;

my %helper=HELPER_CB;

  my @list_a=(
    Data::Range::Compare->new(\%helper,1,2)
    ,Data::Range::Compare->new(\%helper,2,3)
  );
  my @list_b=(
    Data::Range::Compare->new(\%helper,0,1)
    ,Data::Range::Compare->new(\%helper,4,7)
  );

  my @compaire_all=(\@list_a,\@list_b);
  my $cmp=Data::Range::Compare->range_compare(
                                               \%helper
                                               ,\@compaire_all
                                             );
  while(my ($column_a,$column_b) = $cmp->() ) {
    next if $column_a->missing;
    next if $column_b->missing;
    my $common=Data::Range::Compare->get_common_range(
      \%helper
        ,[
          $column_a
          ,$column_b
        ]
    );
    print "Column_a and Column_b intersect at: ",$common,"\n";

  }

