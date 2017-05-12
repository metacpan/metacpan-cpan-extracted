use Test;
BEGIN { plan tests => 2 }
END { ok($loaded) }
use AxKit::XSP::IfParam;
$loaded++;
ok(1);
