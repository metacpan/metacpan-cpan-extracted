use Test::More tests => 1;

my $ok;
END { BAIL_OUT "Could not load all modules" unless $ok }

use Acme::Lelek;

ok 1, 'All modules loaded successfully';
$ok = 1;
