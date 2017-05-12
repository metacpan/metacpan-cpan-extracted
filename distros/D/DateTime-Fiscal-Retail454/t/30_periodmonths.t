# $Id: 30_periodmonths.t 22 2012-07-05 21:36:33Z jim $

use Test::More tests => 13;

BEGIN { use_ok('DateTime::Fiscal::Retail454') };

my @months = qw(
  not_used
  February
  March
  April
  May
  June
  July
  August
  September
  October
  November
  December
  January
);

my $r454 = DateTime::Fiscal::Retail454->now();

for ( 1 .. 12 ) {
  ok($r454->r454_period_month( period => $_ ) eq $months[$_],"Correct month for period $_");
}

exit;

__END__

