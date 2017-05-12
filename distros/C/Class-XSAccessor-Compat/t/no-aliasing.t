#!perl
# Practically verbatim from Class::Accessor::Fast::XS!
use strict;
use Test::More tests => 15;

for my $class (qw(Class::Accessor::Fast Class::XSAccessor::Compat)) {
    require_ok($class);
    my $silly = "Silly::$class";
    {
        no strict 'refs';
        @{"${silly}::ISA"} = ($class);
        *{"${silly}::car"} = sub { shift->_car_accessor(@_); };
        *{"${silly}::mar"} = sub { return "Overloaded"; };
        $silly->mk_accessors(qw( foo bar yar car mar ));
        $silly->mk_ro_accessors(qw(static unchanged));
        $silly->mk_wo_accessors(qw(sekret double_sekret));
    }

    my $test = $silly->new({
            static       => "variable",
            unchanged    => "dynamic",
        });
    {
        my $s = "qwe";
        $test->foo($s);
        is($test->foo, "qwe", "set foo");
        $s = "asd";
        is($test->foo, "qwe", "foo still the same");
    }
    if ( $class ne 'Class::Accessor::Fast' ) {
        my ($s1, $s2) = ("foo", "bar");
        $test->foo($s1, $s2);
        ok( ref $test->foo, "set foo");
        is($test->foo->[0], "foo", "foo still the same");
        is($test->foo->[1], "bar", "foo still the same");
        $s1 = "asd";
        is($test->foo->[0], "foo", "foo still the same");
        is($test->foo->[1], "bar", "foo still the same");
    }
    {
        my $s = $test->foo("qwe");
        is($test->foo, "qwe", "set foo");
        $s = "asd";
        is($test->foo, "qwe", "foo still the same");
    }
}

