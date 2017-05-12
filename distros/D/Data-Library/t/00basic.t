use Test;
BEGIN { plan tests => 1 }
END { ok($loaded) }
use Data::Library::OnePerFile;
use Data::Library::ManyPerFile;
$loaded++;
