use strict;
use Test::More 0.98;
use lib '../lib', 'lib';
use Affix;
#
subtest 'coderef' => sub {
    my $ptr = Affix::sv2ptr( sub { pass 'coderef called'; return 'Okay' }, CodeRef [ [] => Str ] );
    isa_ok $ptr, 'Affix::Pointer';
    my $cv = Affix::ptr2sv( $ptr, CodeRef [ [] => Str ] );
    isa_ok $cv, 'CODE';
    is $cv->(), 'Okay', 'return value from coderef';
    subtest 'inside struct' => sub {
        my $type = Struct [ cb => CodeRef [ [Str] => Str ] ];
        my $ptr  = Affix::sv2ptr( { cb => sub { pass 'hi'; 'Yes' } }, $type );
        isa_ok $ptr, 'Affix::Pointer';
        my $cv = Affix::ptr2sv( $ptr, $type );
        isa_ok $cv->{cb}, 'CODE';
        is $cv->{cb}->(), 'Yes', 'return value from coderef';
    };
};
subtest array => sub {
    subtest 'ArrayRef [ Int, 3 ]' => sub {
        my $type = ArrayRef [ Int, 3 ];
        my $data = [ 5, 10, 15 ];
        my $ptr  = Affix::sv2ptr( $data, $type );
        isa_ok $ptr, 'Affix::Pointer';
        is_deeply [ Affix::ptr2sv( $ptr, $type ) ], [$data], 'round trip is correct';
    };
    subtest 'ArrayRef [ CodeRef [ [Str] => Str ], 3 ]' => sub {
        my $type = ArrayRef [ CodeRef [ [Str] => Str ], 3 ];
        my $ptr  = Affix::sv2ptr(
            [   sub { is shift, 'one',   'proper args passed to 1st'; 'One' },
                sub { is shift, 'two',   'proper args passed to 2nd'; 'Two' },
                sub { is shift, 'three', 'proper args passed to 3rd'; 'Three' }
            ],
            $type
        );
        isa_ok $ptr, 'Affix::Pointer';
        my $cv = Affix::ptr2sv( $ptr, $type );
        is scalar @$cv,         3,       '3 coderefs unpacked';
        is $cv->[0]->('one'),   'One',   'proper return value from 1st';
        is $cv->[1]->('two'),   'Two',   'proper return value from 2nd';
        is $cv->[2]->('three'), 'Three', 'proper return value from 3rd';
    };
    subtest 'ArrayRef [ Struct [ alpha => Str, numeric => Int ], 3 ]' => sub {
        my $type = ArrayRef [ Struct [ alpha => Str, numeric => Int ], 3 ];
        my $data = [
            { alpha => 'Smooth',   numeric => 4 },
            { alpha => 'Move',     numeric => 2 },
            { alpha => 'Ferguson', numeric => 0 }
        ];
        my $ptr = Affix::sv2ptr( $data, $type );
        isa_ok $ptr, 'Affix::Pointer';
        is_deeply [ Affix::ptr2sv( $ptr, $type ) ], [$data], 'round trip is correct';
    };
};
done_testing;
