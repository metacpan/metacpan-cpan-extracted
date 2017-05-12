
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 1;
use Test::Output;

sub use_it { eval "use Acme::this;"; }

stdout_like(\&use_it, qr/The Zen of Perl/, "use Acme::this;");
