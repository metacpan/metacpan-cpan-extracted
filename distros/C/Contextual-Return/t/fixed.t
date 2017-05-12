use Contextual::Return;

sub foo {
    return FIXED (
        BOOL      { 0 }
        LIST      { 1,2,3 }
        NUM       { 42 }
        STR       { 'forty-two' }
        SCALAR    { 86 }
        SCALARREF { \7 }
        HASHREF   { { name => 'foo', value => 99} }
        ARRAYREF  { [3,2,1] }
        GLOBREF   { \*STDERR }
        CODEREF   { \&baz }
        OBJREF    { bless {}, 'Bar' }
    );
}

sub bar {
    return FIXED
        STR       { 'forty-two' }
        LIST      { 1,2,3 }
    ;
}

sub bar_list {
    return FIXED
        STR       { 'forty-two' }
        LIST      { 1,2,3 }
    ;
}

sub baz {
    return 'in baz';
}

package Other;
use Test::More 'no_plan';

# We only need to test the scalar contexts, because LIST and VOID are
# optimized out by checks against wantarray().

my $CLASS = 'Contextual::Return::Value';

my $bool = ::foo();
is ref($bool), $CLASS                         => 'Before usage, it is a C::R::V';
is do{ $bool ? 'true' : 'false' }, 'false'    => 'BOOLEAN context';
isnt ref($bool), $CLASS                       => 'After usage, it is not a C::R::V';

my $num = ::foo();
is ref($num), $CLASS                         => 'Before usage, it is a C::R::V';
is $num+0, 42                                => 'NUMERIC context';
isnt ref($num), $CLASS                       => 'After usage, it is not a C::R::V';

my $str = ::foo();
is ref($str), $CLASS                         => 'Before usage, it is a C::R::V';
is "".$str, 'forty-two'                      => 'STRING context';
isnt ref($str), $CLASS                       => 'After usage, it is not a C::R::V';

my $sref = ::foo();
is ref($sref), $CLASS                         => 'Before usage, it is a C::R::V';
is ${$sref}, 7                                => 'SCALARREF context';
isnt ref($sref), $CLASS                       => 'After usage, it is not a C::R::V';

my $sref2 = ::bar();
is ref($sref2), $CLASS                     => 'Before usage, it is a C::R::V';
is ${$sref2}, 'forty-two'                  => 'SCALARREF context (no SCALARREF provided)';
isnt ref($sref2), $CLASS                   => 'After usage, it is not a C::R::V';

my $href = ::foo();
is ref($href), $CLASS                     => 'Before usage, it is a C::R::V';
is_deeply \%{$href},
          { name => 'foo', value => 99}         => 'HASHREF context';
isnt ref($href), $CLASS                   => 'After usage, it is not a C::R::V';

my $aref = ::foo();
is ref($aref), $CLASS                     => 'Before usage, it is a C::R::V';
is_deeply \@{$aref}, [3,2,1]                  => 'ARRAYREF context';
isnt ref($aref), $CLASS                   => 'After usage, it is not a C::R::V';

my $aref2 = ::bar();
is ref($aref2), $CLASS                     => 'Before usage, it is a C::R::V';
is_deeply \@{$aref2}, [1,2,3]              => 'ARRAYREF context (no ARRAYREF provided)';
isnt ref($aref2), $CLASS                   => 'After usage, it is not a C::R::V';

my $gref = ::foo();
is ref($gref), $CLASS                     => 'Before usage, it is a C::R::V';
is \*{$gref}, \*STDERR                        => 'GLOBREF context';
isnt ref($gref), $CLASS                   => 'After usage, it is not a C::R::V';

my $cref = ::foo();
is ref($cref), $CLASS                     => 'Before usage, it is a C::R::V';
is $cref->(), 'in baz'                          => 'CODEREF context';
isnt ref($cref), $CLASS                   => 'After usage, it is not a C::R::V';

my $oref = ::foo();
is ref($oref), $CLASS                     => 'Before usage, it is a C::R::V';
is $oref->bar, "baaaaa!\n"                => 'OBJREF context';
isnt ref($oref), $CLASS                   => 'After usage, it is not a C::R::V';

my @bar_list = ::bar_list();
is_deeply \@bar_list, [1,2,3]             => 'List context works correctly';

package Bar;

sub bar { return "baaaaa!\n"; }
