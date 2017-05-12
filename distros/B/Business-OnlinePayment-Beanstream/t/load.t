use Test;
BEGIN{ plan test=>1 }

eval{ require Business::OnlinePayment::Beanstream };
ok(!$@);
