use strict;

use Test::More tests => 2;

use DateTime;
use DateTime::Set;
use DateTime::Span;
use DateTime::Calendar::Christian;
use DateTime::Event::NameDay;

my $nameday = 'DateTime::Event::NameDay';

my $dt1 = DateTime->new
    ( year   => 1752,
      month  => 1,
      day    => 1,
      );
my $dt2 = DateTime::Calendar::Christian->new
    ( year   => 1755,
      month  => 1,
      day    => 3,
      reform_date => $dt1,
      );
my $dt3 = DateTime->from_object(object => $dt2);

{
    my $namedays = $nameday->get_namedays(country => 'sweden',
					  name    => 'Alfred');
    $namedays = $namedays->intersection( DateTime::Span->new(start => $dt1, end => $dt2) );
    my $iter = $namedays->iterator();
    my @res = ();
    while (my $dt = $iter->next()) {
	push @res, $dt->ymd();
    }
    my $res = join " ", @res;

    is( $res, '1752-01-14 1753-01-14 1754-01-03 1755-01-03', 'class sub namedays' );
}

{
    my $namedays = $nameday->get_namedays(country => 'sweden',
					  name    => 'aLFred');
    $namedays = $namedays->intersection( DateTime::Span->new(start => $dt1, end => $dt2) );
    my $iter = $namedays->iterator();
    my @res = ();
    while (my $dt = $iter->next()) {
	push @res, $dt->ymd();
    }
    my $res = join " ", @res;

    is( $res, '1752-01-14 1753-01-14 1754-01-03 1755-01-03', 'clean name' );
}
