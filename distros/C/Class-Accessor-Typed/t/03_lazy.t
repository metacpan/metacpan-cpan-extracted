use strict;
use warnings;
use Test::More;
use Test::Exception;

{
    package
        L;

    use Class::Accessor::Typed (
        rw_lazy => {
            rw1 => { isa => 'Str', default => 'default' },
            rw2 => { isa => 'Str', builder => 'builder_for_rw2' },
            rw3 => 'Int',
            rw4 => 'Int',
        },
        ro_lazy => {
            ro1 => { isa => 'Str', default => 'default' },
            ro2 => { isa => 'Str', builder => 'builder_for_ro2' },
            ro3 => 'Int',
            ro4 => 'Int',
        },
        new => 1,
    );

    sub _build_rw1 { 'rw1' }
    sub _build_ro1 { 'ro1' }
    sub builder_for_rw2 { 'rw2' }
    sub builder_for_ro2 { 'ro2' }
    sub _build_rw3 { 1 }
    sub _build_ro3 { 2 }
    sub _build_rw4 { undef }
    sub _build_ro4 { undef }
}

subtest 'new' => sub {
    my $obj = L->new();
    isa_ok $obj, 'L';
};

subtest 'getter (1)' => sub {
    my $obj = L->new();

    ok ! exists $obj->{rw1};
    ok ! exists $obj->{rw2};
    ok ! exists $obj->{rw3};
    ok ! exists $obj->{rw4};

    is $obj->rw1, 'rw1';
    is $obj->rw2, 'rw2';
    is $obj->rw3, 1;
    throws_ok {
        $obj->rw4;
    } qr/'rw4': Validation failed for 'Int' with value undef/;

    ok ! exists $obj->{ro1};
    ok ! exists $obj->{ro2};
    ok ! exists $obj->{ro3};
    ok ! exists $obj->{ro4};

    is $obj->ro1, 'ro1';
    is $obj->ro2, 'ro2';
    is $obj->ro3, 2;
    throws_ok {
        $obj->ro4;
    } qr/'ro4': Validation failed for 'Int' with value undef/;
};

subtest 'getter (2)' => sub {
    my $obj = L->new(
        rw1 => 'rw1',
        rw2 => 'rw2',
        rw3 => 1,
        rw4 => 2,
        ro1 => 'ro1',
        ro2 => 'ro2',
        ro3 => 3,
        ro4 => 4,
    );

    ok exists $obj->{rw1};
    ok exists $obj->{rw2};
    ok exists $obj->{rw3};
    ok exists $obj->{rw4};

    is $obj->rw1, 'rw1';
    is $obj->rw2, 'rw2';
    is $obj->rw3, 1;
    is $obj->rw4, 2;

    ok exists $obj->{ro1};
    ok exists $obj->{ro2};
    ok exists $obj->{ro3};
    ok exists $obj->{ro4};

    is $obj->ro1, 'ro1';
    is $obj->ro2, 'ro2';
    is $obj->ro3, 3;
    is $obj->ro4, 4;
};

subtest 'setter' => sub {
    my $obj = L->new();

    $obj->rw1('rw');
    is $obj->rw1, 'rw';

    throws_ok {
        $obj->rw2(undef);
    } qr/'rw2': Validation failed for 'Str' with value undef/;
};

done_testing;
