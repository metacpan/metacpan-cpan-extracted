use Test;
BEGIN { plan tests => 2 }
END { ok($loaded) }
use AxKit::XSP::WebUtils;
$loaded++;
ok(1);
