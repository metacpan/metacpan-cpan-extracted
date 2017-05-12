use strict;

use Test::More tests => 2;

use DateTime;
use DateTime::Calendar::Christian;
use DateTime::Event::NameDay;

my $nameday = 'DateTime::Event::NameDay';

my $dt1 = DateTime->new
    ( year   => 2000,
      month  => 1,
      day    => 3,
      );
my $dt2 = DateTime::Calendar::Christian->new
    ( year   => 1500,
      month  => 1,
      day    => 3,
      reform_date => $dt1,
      );
my $dt3 = DateTime->from_object(object => $dt2);

{
    my @names = $nameday->get_daynames(country => 'sweden',
				       date    => $dt1);
    my $names = join ":", @names;
    is( $names, 'Alfred:Alfrida', 'class sub get_daynames' );

    my @names = $nameday->get_daynames(country => 'sweden',
				    date    => $dt3);
    my $names = join ":", @names;
    is( $names, 'Alfred:Alfrida', 'class sub get_daynames before reform ('.$dt3->ymd.')' );
}
