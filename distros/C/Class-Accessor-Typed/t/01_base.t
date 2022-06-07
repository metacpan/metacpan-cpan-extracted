use strict;
use warnings;
use Test::More;
use Test::Exception;

{
    package
        L;

    use Class::Accessor::Typed (
        rw => {
            rw1 => { isa => 'Str', default => 'default value' },
            rw2 => 'Int',
        },
        ro => {
            ro1 => 'Str',
            ro2 => 'Int',
        },
        wo => {
            wo => 'Int',
        },
    );
}
{
    package
        M;

    use Class::Accessor::Typed (
        rw => {
            rw => 'Str',
        },
        new => 0,
    );
}
{
    package
        N;

    use Class::Accessor::Typed (
        rw => {
            rw1 => 'Str',
            rw2 => { isa => 'Int', optional => 1 },
        },
    );
}

subtest 'new' => sub {
    my $obj = L->new(
        rw1 => 'RW1',
        rw2 => 321,
        ro1 => 'RO1',
        ro2 => 123,
        wo  => 222,
    );
    isa_ok $obj, 'L';

    subtest 'validation error' => sub {
        throws_ok {
            L->new(
                rw1 => 'RW1',
                rw2 => 'RW2',
                ro1 => 'RO1',
                ro2 => 123,
                wo  => 222,
            );
        } qr/'rw2': Validation failed for 'Int' with value RW2/;
    };

    subtest 'missing mandatory parameter' => sub {
        throws_ok {
            L->new(
                rw1 => 'RW1',
                rw2 => 321,
                ro1 => 'RO1',
                ro2 => 123,
            );
        } qr/missing mandatory parameter named '\$wo'/;
    };

    subtest 'default option' => sub {
        my $obj = L->new(
            rw2 => 321,
            ro1 => 'RO1',
            ro2 => 123,
            wo  => 222,
        );

        is $obj->rw1, 'default value';
    };

    subtest 'optional option' => sub {
        my $obj1 = N->new(rw1 => 'RW1', rw2 => 123);
        is $obj1->rw1, 'RW1';
        is $obj1->rw2, 123;

        my $obj2 = N->new(rw1 => 'RW1');
        is $obj2->rw1, 'RW1';
        is $obj2->rw2, undef;

        $obj2->rw2(234);
        is $obj2->rw1, 'RW1';
        is $obj2->rw2, 234;

        throws_ok {
            $obj2->rw2('RW2');
        } qr/'rw2': Validation failed for 'Int' with value RW2/;
    };

    subtest 'unknown arguments' => sub {
        my $warn = '';
        local $SIG{__WARN__} = sub {
            $warn .= "@_";
        };

        my $obj = L->new(
            rw1     => 'RW1',
            rw2     => 321,
            ro1     => 'RO1',
            ro2     => 123,
            wo      => 222,
            unknown => 'unknown',
        );

        like $warn,  qr/unknown arguments: unknown/;
        isa_ok $obj, 'L';
        ok !exists $obj->{unknown};
    };

    subtest 'disable new option' => sub {
        throws_ok {
            M->new(rw => 'RW');
        } qr/Can't locate object method "new" via package "M"/;
    };
};

subtest 'getter' => sub {
    my $obj = L->new(
        rw1 => 'RW1',
        rw2 => 321,
        ro1 => 'RO1',
        ro2 => 123,
        wo  => 222,
    );

    is $obj->rw1, 'RW1';
    is $obj->rw2, 321;
    is $obj->ro1, 'RO1';
    is $obj->ro2, 123;

    throws_ok {
        $obj->wo;
    } qr/cannot alter the value of 'wo' on objects of class 'L'/;
};

subtest 'setter' => sub {
    my $obj = L->new(
        rw1 => 'RW1',
        rw2 => 321,
        ro1 => 'RO1',
        ro2 => 123,
        wo  => 222,
    );

    $obj->rw1('sample');
    is $obj->rw1, 'sample';

    throws_ok {
        $obj->rw2('sample');
    } qr/'rw2': Validation failed for 'Int' with value sample/;

    throws_ok {
        $obj->ro1('sample');
    } qr/cannot access the value of 'ro1' on objects of class 'L'/;

    $obj->wo(333);
    is $obj->{wo}, 333;
};

done_testing;
