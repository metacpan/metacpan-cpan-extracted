#!/usr/bin/perl -It/
# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Class-Property.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Test::More;
BEGIN { use_ok('Class::Property') };

use Foo;

my $foo = Foo->new(
    'price' => 123
    , 'price_ro' => 456
    , 'price_wo' => 789
    , 'custom_get' => 999
);

my $foo2 = Foo->new(
    'price' => 123
    , 'price_ro' => 456
    , 'price_wo' => 789
    , 'custom_get' => 999
);

# foo 1
is( $foo->price, $foo->{'price'}, 'RW property inited in constructor');
$foo->price = 100;
is( $foo->price, $foo->{'price'}, 'RW property setting via assignment');

is( $foo->price_ro, $foo->{'price_ro'}, 'RO property inited in constructor');
$foo->{'price_ro'} = 456456;
is( $foo->price_ro, $foo->{'price_ro'}, 'RO property set indirectly');

eval{ $foo->price_ro = 123; };
ok( $@ =~ /Unable to set read-only property/, 'RO property writing protection ');

eval{ my $var = $foo->price_wo; };
ok( $@ =~ /Unable to read write-only property/, 'WO property reading protection');

$foo->price_wo = 987;
is( $foo->{'price_wo'}, 987, 'WO property setter');

$foo->custom = 150;
is( $foo->{'supercustom'}, 150, 'RW custom property setter' );
is( $foo->{'supercustom'}, $foo->custom, 'RW custom property getter' );

is( $foo->custom_get, $foo->{'custom_get'} + 1, 'RW custom property getter with def setter' );
$foo->custom_get = 123;
is( $foo->custom_get, 123 + 1, 'RW custom property getter with def setter' );

is( $foo->custom_lazy, 100, 'Lazy init works');
$foo->custom_lazy = 200;
is( $foo->{'custom_lazy'}, 200, 'Setter works with lazy init' );
is( $foo->custom_lazy, 200, 'Lazy init passed a second time');

is( $foo->custom_lazy2, 300, 'Lazy init works on other field');
$foo->custom_lazy2 = 400;
is( $foo->custom_lazy2, 400, 'Lazy init passed a second time on other field');

$foo->custom_lazy3 = 700;
is( $foo->custom_lazy3, 700, 'Lazy init passed if setter been called before');

is( $foo->lazy_ro, 123456, 'Lazy init on RO property');
eval{ $foo->lazy_ro = 123; };
ok( $@ =~ /Unable to set read-only property/, 'RO lazy property writing protection');

$foo->{'lazy_ro'} = 9887987;
is( $foo->lazy_ro, $foo->{'lazy_ro'}, 'Lazy init passed on second read of RO property');

# foo 2

is( $foo2->price, $foo2->{'price'}, 'RW property inited in constructor');
$foo2->price = 100;
is( $foo2->price, $foo2->{'price'}, 'RW property setting via assignment');

is( $foo2->price_ro, $foo2->{'price_ro'}, 'RO property inited in constructor');
$foo2->{'price_ro'} = 456456;
is( $foo2->price_ro, $foo2->{'price_ro'}, 'RO property set indirectly');

eval{ $foo2->price_ro = 123; };
ok( $@ =~ /Unable to set read-only property/, 'RO property writing protection ');

eval{ my $var = $foo2->price_wo; };
ok( $@ =~ /Unable to read write-only property/, 'WO property reading protection');

$foo2->price_wo = 987;
is( $foo2->{'price_wo'}, 987, 'WO property setter');

$foo2->custom = 150;
is( $foo2->{'supercustom'}, 150, 'RW custom property setter' );
is( $foo2->{'supercustom'}, $foo2->custom, 'RW custom property getter' );

is( $foo2->custom_get, $foo2->{'custom_get'} + 1, 'RW custom property getter with def setter' );
$foo2->custom_get = 123;
is( $foo2->custom_get, 123 + 1, 'RW custom property getter with def setter' );

is( $foo2->custom_lazy, 100, 'Lazy init works');
$foo2->custom_lazy = 200;
is( $foo2->{'custom_lazy'}, 200, 'Setter works with lazy init' );
is( $foo2->custom_lazy, 200, 'Lazy init passed a second time');

is( $foo2->custom_lazy2, 300, 'Lazy init works on other field');
$foo2->custom_lazy2 = 400;
is( $foo2->custom_lazy2, 400, 'Lazy init passed a second time on other field');

$foo2->custom_lazy3 = 700;
is( $foo2->custom_lazy3, 700, 'Lazy init passed if setter been called before');

is( $foo2->lazy_ro, 123456, 'Lazy init on RO property');
eval{ $foo2->lazy_ro = 123; };
ok( $@ =~ /Unable to set read-only property/, 'RO lazy property writing protection');

$foo2->{'lazy_ro'} = 9887987;
is( $foo2->lazy_ro, $foo2->{'lazy_ro'}, 'Lazy init passed on second read of RO property');


use Bar;
my $bar = Bar->new(
    'price' => 123
    , 'price_ro' => 456
    , 'price_wo' => 789
    , 'price_bar' => 1239
    , 'price_bar_ro' => 4569
    , 'price_bar_wo' => 7899
);

is( $bar->price, $bar->{'price'}, 'Inheritance: RW property inited in constructor');
$bar->price = 100;
is( $bar->price, $bar->{'price'}, 'Inheritance: RW property setting via assignment');

is( $bar->price_ro, $bar->{'price_ro'}, 'Inheritance: RO property inited in constructor');
$bar->{'price_ro'} = 456456;
is( $bar->price_ro, $bar->{'price_ro'}, 'Inheritance: RO property set indirectly');

eval{ $bar->price_ro = 123; };
ok( $@ =~ /Unable to set read-only property/, 'Inheritance: RO property writing protection');

eval{ my $var = $bar->price_wo; };
ok( $@ =~ /Unable to read write-only property/, 'Inheritance: WO property reading protection');

$bar->price_wo = 9871;
is( $bar->{'price_wo'}, 9871, 'Inheritance: WO property setter');

is( $bar->price_bar, $bar->{'price_bar'}, 'Inheritance: RW property inited in constructor');
$bar->price_bar = 100;
is( $bar->price_bar, $bar->{'price_bar'}, 'Inheritance: RW property setting via assignment');

is( $bar->price_bar_ro, $bar->{'price_bar_ro'}, 'Inheritance: RO property inited in constructor');

eval{ my $var = $bar->price_bar_wo; };
ok( $@ =~ /Unable to read write-only property/, 'Inheritance: WO property reading protection');

done_testing();
