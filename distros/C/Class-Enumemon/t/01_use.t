use strict;
use warnings;

use Test::More 0.98;
use Scalar::Util qw(refaddr);

{
    package TestPkg::IdolType;
    use Class::Enumemon (
        values => 1,
        getter => 1,
        indexer => {
            by_id     => 'id',
            from_type => 'type'
        },
        {
            id   => 1,
            type => 'cute',
        },
        {
            id   => 2,
            type => 'cool',
        },
        {
            id   => 3,
            type => 'passion',
        },
    );
}

subtest 'values option' => sub {

    subtest 'values' => sub {
        ok +TestPkg::IdolType->can('values');

        my $values = TestPkg::IdolType->values;
        is scalar @$values, 3, '';
        isa_ok $values->[0], 'TestPkg::IdolType';
        isa_ok $values->[1], 'TestPkg::IdolType';
        isa_ok $values->[2], 'TestPkg::IdolType';

        is_deeply [ map { $_->{id}   } @$values ], [ 1, 2, 3 ];
        is_deeply [ map { $_->{type} } @$values ], [ qw(cute cool passion) ];

        is refaddr $values->[0], refaddr +TestPkg::IdolType->from_type('cute');
        is refaddr $values->[1], refaddr +TestPkg::IdolType->by_id(2);
    };

    subtest 'with context' => sub {
        my $scalar_values = TestPkg::IdolType->values;
        my @array_values  = TestPkg::IdolType->values;

        is scalar @$scalar_values, 3;
        is scalar @array_values, 3;

        is refaddr $scalar_values->[0], refaddr $array_values[0];
        is refaddr $scalar_values->[1], refaddr $array_values[1];
        is refaddr $scalar_values->[2], refaddr $array_values[2];
    };

    subtest 'save original values' => sub {
        my $values = TestPkg::IdolType->values;
        $values->[0] = 'hoge';
        isa_ok +TestPkg::IdolType->values->[0], 'TestPkg::IdolType';
    };

    subtest 'without values' => sub {
        {
            package TestPkg::WithoutValues;
            use Class::Enumemon (
                indexer => { from_id => 'id' },
                { id =>  0 },
                { id => -1 },
            );
        }

        is +TestPkg::WithoutValues->can('values'), undef;

        subtest 'can get values other way' => sub {
            isa_ok +TestPkg::WithoutValues->from_id(0), 'TestPkg::WithoutValues';
            is +TestPkg::WithoutValues->from_id(-1)->{id}, -1;
        };
    };
};

subtest 'indexer option' => sub {
    subtest 'indexer' => sub {
        ok +TestPkg::IdolType->can('by_id');

        my $cute = TestPkg::IdolType->by_id(1);
        isa_ok $cute, 'TestPkg::IdolType';
        is $cute->{id}, 1;
        is $cute->{type}, 'cute';

        my $cool = TestPkg::IdolType->from_type('cool');
        isa_ok $cool, 'TestPkg::IdolType';
        is $cool->{id}, 2;
        is $cool->{type}, 'cool';

        subtest 'returns same address objects' => sub {
            my $c1 = TestPkg::IdolType->by_id(1);
            my $c2 = TestPkg::IdolType->from_type('cute');
            is refaddr($c1), refaddr($c2);
        };
    };

    subtest 'without indexer' => sub {
        {
            package TestPkg::WithoutIndexer;
            use Class::Enumemon (
                values => 1,
                { id => 1 },
                { id => 2 },
            );
        }

        is +TestPkg::WithoutIndexer->can('by_id'), undef;

        subtest 'can get values other way' => sub {
            my $values = TestPkg::WithoutIndexer->values;
            isa_ok $values->[0], 'TestPkg::WithoutIndexer';
            is $values->[1]->{id}, 2;
        };
    };
};

subtest 'getter option' => sub {
    subtest 'getter' => sub {
        my $cool = TestPkg::IdolType->by_id(2);
        ok $cool->can('id');
        ok $cool->can('type');
        is $cool->id, 2;
        is $cool->type, 'cool';

        my $passion = TestPkg::IdolType->by_id(3);
        ok $passion->can('id');
        ok $passion->can('type');
        is $passion->id, 3;
        is $passion->type, 'passion';
    };

    subtest 'with bumpy values' => sub {
        {
            package TestPkg::BumpyValue;
            use Class::Enumemon (
                values => 1,
                getter => 1,
                { id => 1, name => 'cocoa' },
                { id => 2, is_admin => 1, company => 'kadokawa' },
            );
        }

        my $values = TestPkg::BumpyValue->values;
        is $values->[0]->id, 1;
        is $values->[0]->name, 'cocoa';
        is $values->[0]->is_admin, undef;
        is $values->[0]->company, undef;

        is $values->[1]->id, 2;
        is $values->[1]->name, undef;
        is $values->[1]->is_admin, 1;
        is $values->[1]->company, 'kadokawa';
    };

    subtest 'without getter' => sub {
        {
            package TestPkg::WithoutGetter;
            use Class::Enumemon (
                indexer => { from_id => 'id' },
                { id => 1 },
            );
        }
        ok !TestPkg::WithoutGetter->from_id('1')->can('id');
    };
};

subtest 'local' => sub {
    subtest 'guard' => sub {
        my $cute_before_guard = TestPkg::IdolType->by_id(1);

        {
            my $guard = TestPkg::IdolType->local(
                { id => 4, type => 'vocal'  },
                { id => 5, type => 'dance'  },
                { id => 6, type => 'visual' },
            );

            my $vocal = TestPkg::IdolType->by_id(4);
            isa_ok $vocal, 'TestPkg::IdolType';
            is $vocal->{id}, 4;
            is $vocal->{type}, 'vocal';

            my $visual = TestPkg::IdolType->from_type('visual');
            isa_ok $visual, 'TestPkg::IdolType';
            is $visual->{id}, 6;
            is $visual->{type}, 'visual';

            subtest 'masked original definitions' => sub {
                is +TestPkg::IdolType->by_id(1), undef;
                is +TestPkg::IdolType->from_type('cool'), undef;
            };

            my $values = TestPkg::IdolType->values;
            is scalar @$values, 3;
        }

        my $cute_after_guard = +TestPkg::IdolType->by_id(1);
        isa_ok $cute_after_guard, 'TestPkg::IdolType';
        is $cute_after_guard->{id}, 1;
        is $cute_after_guard->{type}, 'cute';

        is refaddr $cute_before_guard, refaddr $cute_after_guard;
    };

    subtest 'with empty data' => sub {
        my $guard = TestPkg::IdolType->local();
        is_deeply scalar +TestPkg::IdolType->values, [];
        is scalar @{TestPkg::IdolType->values}, 0;
        is +TestPkg::IdolType->by_id(1), undef;
        is +TestPkg::IdolType->from_type('cool'), undef;
    };

    subtest 'nested guard' => sub {
        {
            package TestPkg::NestedGuard;
            use Class::Enumemon (values => 1, { level => 1 });
        }
        is +TestPkg::NestedGuard->values->[0]->{level}, 1;

        {
            my $g = TestPkg::NestedGuard->local({ level => 2 });
            is +TestPkg::NestedGuard->values->[0]->{level}, 2;

            {
                my $g = TestPkg::NestedGuard->local({ level => 3 });
                is +TestPkg::NestedGuard->values->[0]->{level}, 3;
            }

            is +TestPkg::NestedGuard->values->[0]->{level}, 2;
        }

        is +TestPkg::NestedGuard->values->[0]->{level}, 1;
    };

    subtest 'error in void context' => sub {
        local $@;
        eval { TestPkg::IdolType->local() };
        like $@, qr/\ACannot use TestPkg::IdolType::local in void context /;
    };
};

done_testing;
