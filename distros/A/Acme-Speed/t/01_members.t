use strict;
use DateTime;
use Acme::Speed;
use Test::More tests => 1;

my $speed = Acme::Speed->new;

is scalar($speed->members), 4, " members"
