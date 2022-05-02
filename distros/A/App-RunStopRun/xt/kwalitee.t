use strict;
use warnings;
use Test::More;

eval "use Test::Kwalitee qw(kwalitee_ok); 1" or do {
    plan skip_all => 'Test::Kwalitee not installed; skipping';
};

kwalitee_ok();

done_testing;
