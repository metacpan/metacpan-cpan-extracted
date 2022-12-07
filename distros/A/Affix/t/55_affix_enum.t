use strict;
use Test::More 0.98;
BEGIN { chdir '../' if !-d 't'; }
use lib '../lib', 'lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
use Affix;
$|++;
use t::lib::nativecall;
#
compile_test_lib('55_affix_enum');
#
{
    my $ab = IntEnum [ 'alpha', 'beta' ];
    isa_ok $ab, 'Affix::Type::Enum';
    is_deeply $ab->{values}, [ 'alpha', 'beta' ], qq![ 'alpha', 'beta' ] values!;
    is int $ab->{values}[0], 0, 'alpha == 0';
    is int $ab->{values}[1], 1, 'beta == 1';
}
{
    my $ab = Enum [ 'alpha', [ 'beta' => 5 ] ];
    is_deeply $ab->{values}, [ 'alpha', 'beta' ], qq![ 'alpha', [ 'beta' => 5 ] ] values!;
    is int $ab->{values}[0], 0, 'alpha == 0';
    is int $ab->{values}[1], 5, 'beta == 5';
}
{
    my $ab = Affix::Enum [ 'alpha', [ 'beta' => 5 ], 'gamma' ];
    isa_ok $ab, 'Affix::Type::Enum';
    is_deeply $ab->{values}, [ 'alpha', 'beta', 'gamma' ],
        qq![ 'alpha', [ 'beta' => 5 ], 'gamma' ] values!;
    is int $ab->{values}[0], 0, 'alpha == 0';
    is int $ab->{values}[1], 5, 'beta == 5';
    is int $ab->{values}[2], 6, 'gamma == 6';
}
{
    my $ab = Affix::Enum [ 'alpha', [ 'beta' => 5 ], [ 'gamma' => 'alpha' ] ];
    isa_ok $ab, 'Affix::Type::Enum';
    is_deeply $ab->{values}, [ 'alpha', 'beta', 'gamma' ],
        qq![ 'alpha', [ 'beta' => 5 ], [ 'gamma' => 'alpha' ] ] values!;
    is int $ab->{values}[0], 0, 'alpha == 0';
    is int $ab->{values}[1], 5, 'beta == 5';
    is int $ab->{values}[2], 0, 'gamma == 0';
}
{
    my $ab = Affix::Enum [ 'alpha', [ 'beta' => 5 ], [ 'gamma' => 'alpha - beta' ] ];
    isa_ok $ab, 'Affix::Type::Enum';
    is_deeply $ab->{values}, [ 'alpha', 'beta', 'gamma' ],
        qq![ 'alpha', [ 'beta' => 5 ], [ 'gamma' => 'alpha - beta' ] ] values!;
    is int $ab->{values}[0], 0,  'alpha == 0';
    is int $ab->{values}[1], 5,  'beta == 5';
    is int $ab->{values}[2], -5, 'gamma == -5';
}
{
    my $ab = Affix::Enum [ 'alpha', [ 'beta' => 5 ], [ 'gamma' => 'beta*beta' ] ];
    isa_ok $ab, 'Affix::Type::Enum';
    is_deeply $ab->{values}, [ 'alpha', 'beta', 'gamma' ],
        qq![ 'alpha', [ 'beta' => 5 ], [ 'gamma' => 'beta * beta' ] ] values!;
    is int $ab->{values}[0], 0,  'alpha == 0';
    is int $ab->{values}[1], 5,  'beta == 5';
    is int $ab->{values}[2], 25, 'gamma == 25';
}
subtest 'typedef' => sub {
    typedef TV => Enum [
        [ FOX   => 11 ],
        [ CNN   => 25 ],
        [ ESPN  => 15 ],
        [ HBO   => 22 ],
        [ MAX   => 30 ],
        [ NBC   => 32 ],
        [ MSN   => 45 ],
        [ MSNBC => 'MSN + NBC' ]
    ];
    isa_ok TV(), 'Affix::Type::Enum', 'TV';
    is TV::FOX(),     'FOX', 'typedef makes dualvar constants of enum values [str]';
    is int TV::FOX(), 11,    'typedef makes dualvar constants of enum values [num]';
    subtest ':Native' => sub {
        sub TakeEnum : Native('t/55_affix_enum') : Signature([TV]=>Int);
        is TakeEnum( TV::FOX() ),  -11, 'FOX';
        is TakeEnum( TV::ESPN() ), -1,  'ESPN';
    };
    subtest 'wrapped function' => sub {
        my $cv = wrap 't/55_affix_enum', 'TakeEnum', [ TV() ], TV();
        isa_ok( TV(), 'Affix::Type::Enum', 'typedef TV' );
        is TV::FOX(),            'FOX',   'typedef Enum results in dualvars [FOX string]';
        is int TV::FOX(),        11,      'typedef Enum results in dualvars [FOX numeric]';
        is TV::MSNBC(),          'MSNBC', 'typedef Enum results in dualvars [MSNBC string]';
        is int TV::MSNBC(),      77,      'typedef Enum results in dualvars [MSNBC numeric]';
        is TakeEnum(11),         -11,     'FOX used in affixed function';
        is TakeEnum(15),         -1,      'ESPN used in affixed function';
        is $cv->( TV::FOX() ),   -11,     'TV::FOX() used in wrapped function';
        is $cv->( TV::CNN() ),   -1,      'TV::CNN() used in wrapped function';
        is $cv->( TV::MSNBC() ), -1,      'TV::MSNBC() used in wrapped function';
    }
};
done_testing;
