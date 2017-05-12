  use strict;
  use warnings;
  use lib qw(../lib lib .);
  use Data::Range::Compare qw(HELPER_CB);

  my %helper=HELPER_CB;

  my @tom;
  my @harry;
  my @sally;

  push @tom,Data::Range::Compare->new(\%helper,0,1);
  push @tom,Data::Range::Compare->new(\%helper,3,7);

  push @harry,Data::Range::Compare->new(\%helper,9,11);

  push @sally,Data::Range::Compare->new(\%helper,6,7);

  my @cmp=(\@tom,\@harry,\@sally);

  my $sub=Data::Range::Compare->range_compare(\%helper,\@cmp);
  while(my @row=$sub->()) {
    my $common_range=Data::Range::Compare->get_common_range(\%helper,\@row);
    print "Common Range: $common_range\n";
    my ($tom,$harry,$sally)=@row;
    print "tom:   $tom\n";
    print "harry: $harry\n";
    print "sally: $sally\n";
  }

