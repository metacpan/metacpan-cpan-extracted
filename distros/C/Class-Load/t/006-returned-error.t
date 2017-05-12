use strict;
use warnings;
use Test::More 0.88;
use lib 't/lib';
use Test::Class::Load ':all';

{
    ok(try_load_class('Class::Load::OK'), "loaded class OK");
    my ($r, $e) = try_load_class('Class::Load::OK');
    is($e, undef);
}

{
    ok(!try_load_class('Class::Load::Nonexistent'), "didn't load class Nonexistent");
    my ($r, $e) = try_load_class('Class::Load::Nonexistent');
    like($e, qr{^Can't locate Class/Load/Nonexistent.pm in \@INC});
}

{
    ok(try_load_class('Class::Load::OK'), "loaded class OK");
    my ($r, $e) = try_load_class('Class::Load::OK');
    is($e, undef);
}

{
    ok(!try_load_class('Class::Load::SyntaxError'), "didn't load class SyntaxError");
    delete $INC{'Class/Load/SyntaxError.pm'};
    my ($r, $e) = try_load_class('Class::Load::SyntaxError');
    like($e, qr{^Missing right curly or square bracket at });
}

ok(is_class_loaded('Class::Load::OK'));
ok(!is_class_loaded('Class::Load::Nonexistent'));
ok(!is_class_loaded('Class::Load::SyntaxError'));

{
    $@ = "foo";
    ok(try_load_class('Class::Load::OK'), "loaded class OK");
    is($@, "foo");
}

{
    $@ = "foo";
    ok(!try_load_class('Class::Load::Nonexistent'), "didn't load class Nonexistent");
    is($@, "foo");
}

done_testing;
