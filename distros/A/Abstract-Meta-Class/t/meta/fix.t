
use strict;
use warnings;

use Test::More tests => 6;

#BUG 0.09-1
#deserialized object breaks on accessing array, hash attribute perl type.

{
    package SuperDummy;
    use Abstract::Meta::Class ':all';
    has '@.x' => (default => 'x value');
    has '%.z' => (default => 'z value');
}

my $obj = bless {}, 'SuperDummy';
my $x = $obj->x;
my $z = $obj->z;
is(ref($x), 'ARRAY', 'should have an array');
is(ref($z), 'HASH', 'should have a hash');
    

{
    package Req;
    use Abstract::Meta::Class ':all';
    has '@.x' => (required => 1);
    has '%.z' => (required => 1);
}

eval {
    Req->new(z => {a => 1});
};
like($@, qr{x is required}, 'should catch required value');



eval {
    Req->new(x => [z => 1]);
};
like($@, qr{z is required}, 'should catch required value');



{
    package ReqArray;
    use Abstract::Meta::Class ':all';
    storage_type 'Array';
    has '@.x' => (required => 1);
    has '%.z' => (required => 1);
}


eval {
    Req->new(z => {a => 1});
};
like($@, qr{x is required}, 'should catch required value');



eval {
    Req->new(x => [z => 1]);
};
like($@, qr{z is required}, 'should catch required value');

    