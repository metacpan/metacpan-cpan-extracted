use Test;
BEGIN { plan tests => 1 }
END { ok($loaded) }
use AxKit::XSP::Wiki;
$loaded++;
