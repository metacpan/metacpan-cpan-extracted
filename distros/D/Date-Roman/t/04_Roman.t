#testing if the 
#Date::Roman->new(ad => $ad,...) works.
use Date::Roman;
use strict;
my @data;

BEGIN {
  open DATA,"<test-data/years.txt" || die "can't open test-data/years.txt: $!";
  while (<DATA>) {
    next if /^#/;
    my ($roman,$ical,$standard,$christian,$Roman) = split ";";
    my $chunk = {roman => $roman,
		 ical => $ical,
		 standard => $standard};

    foreach (split /,/,$christian) {
      my ($key,$value) = /(.*)\s+=>\s+(.*)/;
      $chunk->{christian}{$key} = $value;
    }
    foreach (split /,/,$Roman) {
      my ($key,$value) = /(.*)\s+=>\s+(.*)/;
      $chunk->{Roman}{$key} = $value;
    }
    push @data,$chunk;
  }
  close DATA;
}

use Test::More tests => 4 * @data;

foreach (@data) {
  my $date = Date::Roman->new(%{$_->{Roman}});
  ok(defined $date,"creating for $_->{standard}");
  ok($date->isa('Date::Roman'),"good class for $_->{standard}");
  
  is($date->ical(),$_->{ical},"test ical for $_->{standard}");
  is($date->roman(),$_->{roman},"test roman for $_->{standard}");
}


