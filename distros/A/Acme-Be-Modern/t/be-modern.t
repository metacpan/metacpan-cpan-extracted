use Test::More tests => 1;
use Module::Loaded;

use Acme::Be::Modern;

be modern;

ok(is_loaded('Modern::Perl'));

