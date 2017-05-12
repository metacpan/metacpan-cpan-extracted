use strict;
use Test::More tests => 2;

BEGIN { use_ok 'Date::Japanese::Holiday' }

my $d = Date::Japanese::Holiday->new;

ok($d->isa('Date::Simple'));
