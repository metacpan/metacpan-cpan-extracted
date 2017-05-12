#testing if the methods roman and ical works when given a parameter.
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

use Test::More tests => 6 * @data + 6;

my $rdate = Date::Roman->new(roman => "id 3 702");
my $idate = Date::Roman->new(ical => "-510315");

ok(defined $rdate,"roman base object created");
ok(defined $idate,"ical base object created");

is($rdate->roman(),"id 3 702","roman value checked");
is($rdate->ical(),"-510315","ical value checked");

is($idate->roman(),"id 3 702","roman value checked");
is($idate->ical(),"-510315","ical value checked");


foreach (@data) {
  my $rval = $rdate->roman($_->{roman});
  my $ival = $idate->ical($_->{ical});
  
  is($rval,$_->{roman});
  is($ival,$_->{ical});
  is($rdate->ical(),$_->{ical},"test ical for $_->{standard}");
  is($rdate->roman(),$_->{roman},"test roman for $_->{standard}");
  is($idate->ical(),$_->{ical},"test ical for $_->{standard}");
  is($idate->roman(),$_->{roman},"test roman for $_->{standard}");
}
