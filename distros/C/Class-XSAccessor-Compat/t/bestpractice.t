#!perl
# Practically verbatim from Class::Accessor::Fast::XS!
use strict;
use warnings;

use constant HAS_BEST_PRACTICE => eval "use Class::Accessor 0.25; 1;";

use Test::More;
unless ( HAS_BEST_PRACTICE ) {
    plan skip_all =>
        'This test requires Class::Accessor'
        .' with support of follow_best_practice'
        .' (0.25 or newer)';
}
else {
    plan tests => 24;
}


for my $class (qw(Class::Accessor::Fast Class::XSAccessor::Compat)) {
    require_ok($class);
    my $silly = "Silly::$class";
    {
        no strict 'refs';
        @{"${silly}::ISA"} = ($class);
        $silly->follow_best_practice;
        $silly->mk_accessors(qw( foo ));
        $silly->mk_ro_accessors(qw(roro));
        $silly->mk_wo_accessors(qw(wowo));
    }

    for my $f (qw/foo roro /) {
        ok $silly->can("get_$f"), "'get_$f' method exists";
    }

    for my $f (qw/foo wowo/) {
        ok $silly->can("set_$f"), "'set_$f' method exists";
    }

    for my $f (qw/foo roro wowo set_roro get_wowo/) {
        ok !$silly->can($f), "no '$f' method";
    }

    my $test = $silly->new({
            foo => "bar",
            roro => "boat",
            wowo => "huh",
        });

    is($test->get_foo, "bar", "initial foo");
    $test->set_foo("stuff");
    is($test->get_foo, "stuff", "new foo");
}
