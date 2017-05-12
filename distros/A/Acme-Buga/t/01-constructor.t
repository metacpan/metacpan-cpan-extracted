use strict;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Acme::Buga 'buga';

subtest 'test constuctor' => sub {
    my $obj = Acme::Buga->new;

    ok $obj;
    isa_ok $obj, 'Acme::Buga';
};

subtest 'test alternative constuctor' => sub {
    my $obj = buga('');

    ok $obj;
    isa_ok $obj, 'Acme::Buga';
};

done_testing;
