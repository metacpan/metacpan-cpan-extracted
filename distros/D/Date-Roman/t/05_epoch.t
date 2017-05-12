#testing if the Date::Roman->new(epoch => something) works
use Date::Roman;
use strict;
my @data;

BEGIN {
  open DATA,"<test-data/epoch.txt" || die "can't open test-data/epoch.txt: $!";
  while (<DATA>) {
    next if /^#/;
    chomp;
    my ($roman,$epoch,$ical) = split ";";
    push @data,{
		roman => $roman,
		epoch => $epoch,
		ical  => $ical
	       };
  }
  close DATA;
}

use Test::More tests => 4 * @data;

$ENV{TZ} = "MET"; #so we can predict the result of localtime()

foreach (@data) {
  my $date = Date::Roman->new(epoch => $_->{epoch});
  ok(defined $date);
  ok($date->isa('Date::Roman'));

  is($date->roman(),$_->{roman});
  is($date->ical(),$_->{ical});
}
