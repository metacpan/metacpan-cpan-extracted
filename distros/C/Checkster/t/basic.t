use strict;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

# use checkster with check sub
use Checkster 'check';

# default constructor
subtest 'constructor' => sub {
    my $obj = Checkster->new;
    isa_ok $obj, 'Checkster';
};

# check (sub) constructor
subtest 'check function' => sub {
    my $var = check;
    isa_ok $var, 'Checkster'; 
};


done_testing;
