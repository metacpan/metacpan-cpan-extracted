# $Id: 11_clone.t 22 2012-07-05 21:36:33Z jim $

use Test::More tests => 8;

BEGIN { use_ok('DateTime::Fiscal::Retail454') };

my $r454 = DateTime::Fiscal::Retail454->now();
isa_ok($r454,'DateTime::Fiscal::Retail454');
isa_ok($r454,'DateTime');

my $r454yr = $r454->r454_year;
ok($r454yr > 0,'Got a real year prior to cloning');

my $r454A = $r454->clone;
isa_ok($r454A,'DateTime::Fiscal::Retail454');
isa_ok($r454A,'DateTime');
ok($r454A->{_R454_year} == $r454yr,'_R454_year attribute cloned');

is_deeply($r454,$r454A,'Cloned structures');

exit;

__END__

