use Test;
BEGIN { plan tests => 1 }
END { ok($loaded) }
use B::Deobfuscate;
$loaded++;