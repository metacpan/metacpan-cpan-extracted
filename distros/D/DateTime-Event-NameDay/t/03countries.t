use strict;

use Test::More;

use DateTime;
use DateTime::Event::NameDay;

my %countries =
    (france   => "Geneviève",
     SLOVAKIA => "Daniela",
     swEden   => "Alfred:Alfrida",
     );
plan( tests => int keys(%countries) + 1 );


my $nameday = 'DateTime::Event::NameDay';

my $dt1 = DateTime->new
    ( year   => 2000,
      month  => 1,
      day    => 3,
      );


foreach my $country (sort keys %countries) {
    my @names = $nameday->get_daynames(country => $country,
				       date    => $dt1);
    my $names = join ":", @names;
    is( $names, $countries{$country}, "country '$country'" );
}


# Try a bogus country
eval {
    my @names = $nameday->get_daynames(country => "foo",
				       date    => $dt1);
};
ok($@ ne "", "bogus country 'foo'");
