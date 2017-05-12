use Test;
BEGIN { plan tests => 2 }
END { ok($loaded) }
use AxKit::XSP::PerForm;
$loaded++;
ok(1);
