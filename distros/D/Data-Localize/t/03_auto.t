use strict;
use Cwd ();
BEGIN {
   unshift @INC, Cwd::abs_path()
}
use Test::More (tests => 4);
use t::Data::Localize::Test;

use_ok "Data::Localize";

my $loc = Data::Localize->new( auto => 1 );

# make sure no localizers are present
is($loc->count_localizers, 0, "no localizers");
is($loc->localize("Hello, [_1]!", "John Doe"), "Hello, John Doe!", "localization works without a localizer, and auto = 1");

$loc->auto(0);
is($loc->localize("Hello, [_1]!", "John Doe"), undef, "localization does not work when auto = 0 and no localizers");
