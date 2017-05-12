# $Id: 20_truncate.t 22 2012-07-05 21:36:33Z jim $

use Test::More tests => 5;

BEGIN { use_ok('DateTime::Fiscal::Retail454') };

my $r454 = DateTime::Fiscal::Retail454->now();
my $r454_2 = $r454->clone;

ok($r454->r454_period_start eq "".$r454_2->truncate( to => 'period' ),
  'can truncate to start of R454 period');
ok($r454->r454_start eq "".$r454_2->truncate( to => 'r454year' ),
  'can truncate to start of R454 year');

isa_ok($r454_2,'DateTime::Fiscal::Retail454');
isa_ok($r454_2,'DateTime');

exit;

__END__

